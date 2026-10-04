<?php
/**
 * @package eZUpdate
 * @class   eZUpdateManager
 * @author  7x <info@se7enx.com>
 * @author  Serhey Dolgushev <dolgushev.serhey@gmail.com> (original skeleton)
 * @date    28 Sep 2026
 **/

/**
 * Runs Composer for the installation this extension belongs to.
 *
 * Composer is started without a shell (proc_open with an argument list), in the
 * installation root, with a time limit and an environment that works under a web
 * server (COMPOSER_HOME, PATH and HOME set when the server gives none). Where the
 * binary lives, how long it may run and whether the dashboard may update at all
 * are settings in ezupdate.ini.
 */
class eZUpdateManager
{
    const PACKAGE_NAME_PATTERN = '#^[a-z0-9]([_.-]?[a-z0-9]+)*/[a-z0-9](([_.]|-{1,2})?[a-z0-9]+)*$#';

    /** @var eZINI */
    private $ini;

    /** @var array|null|false Cached result of composerCommand() */
    private $command = null;

    /** @var array|null The result of the last run() */
    private $lastResult = null;

    private function __construct()
    {
        $this->ini = eZINI::instance( 'ezupdate.ini' );
    }

    /**
     * A new manager for this request. Nothing is kept in a static, so a web
     * server that keeps PHP alive across requests always reads current settings.
     */
    public static function getInstance()
    {
        return new self();
    }

    public function ini()
    {
        return $this->ini;
    }

    /**
     * The installation root Composer runs in.
     */
    public function projectPath()
    {
        return eZSys::rootDir();
    }

    public function hasComposerJson()
    {
        return is_file( $this->projectPath() . '/composer.json' );
    }

    public function isUpdateAllowed()
    {
        return $this->ini->variable( 'UpdateSettings', 'AllowUpdate' ) === 'enabled';
    }

    public function isInstallAllowed()
    {
        return $this->ini->variable( 'UpdateSettings', 'AllowInstall' ) === 'enabled';
    }

    /**
     * The file Composer is started from, or false when none is found.
     */
    public function composerBinary()
    {
        $command = $this->composerCommand();
        return $command ? end( $command ) : false;
    }

    /**
     * The command that starts Composer, as an argument list:
     * array( '/path/composer' ) for an executable, or
     * array( '/path/php', '/path/composer.phar' ) for a PHP script.
     *
     * @return array|false
     */
    public function composerCommand()
    {
        if ( $this->command !== null )
        {
            return $this->command;
        }

        $this->command = false;
        $binary = $this->findBinary();
        if ( $binary === false )
        {
            return false;
        }

        // A file open_basedir hides cannot be inspected: the configured file is
        // trusted, a .phar runs through PHP and anything else as an executable.
        $hidden = !$this->pathAllowed( $binary );
        if ( $hidden ? substr( $binary, -5 ) === '.phar' : self::isPhpScript( $binary ) )
        {
            $php = $this->phpBinary();
            $this->command = $php ? array( $php, $binary ) : false;
        }
        else if ( $hidden || is_executable( $binary ) )
        {
            $this->command = array( $binary );
        }
        return $this->command;
    }

    /**
     * The directories PHP's open_basedir allows, or an empty array when it is not set.
     */
    public static function openBasedir()
    {
        $value = trim( (string)ini_get( 'open_basedir' ) );
        if ( $value === '' )
        {
            return array();
        }
        return array_values( array_filter( array_map( 'trim', explode( PATH_SEPARATOR, $value ) ), 'strlen' ) );
    }

    /**
     * Whether PHP's file functions may look at $path (always true without open_basedir).
     */
    public function pathAllowed( $path )
    {
        $allowed = self::openBasedir();
        if ( !$allowed )
        {
            return true;
        }
        $path = self::normalize( $path );
        foreach ( $allowed as $dir )
        {
            if ( $dir === '.' )
            {
                $dir = $this->projectPath();
            }
            $dir = self::normalize( $dir );
            // open_basedir is a prefix match: "/a/b" also admits "/a/bc"; a directory with a trailing slash admits only itself.
            if ( $path === rtrim( $dir, '/' ) || strpos( $path . '/', rtrim( $dir, '/' ) . '/' ) === 0 )
            {
                return true;
            }
        }
        return false;
    }

    private static function normalize( $path )
    {
        $path = preg_replace( '#/+#', '/', (string)$path );
        $out = array();
        foreach ( explode( '/', $path ) as $part )
        {
            if ( $part === '..' )
            {
                array_pop( $out );
            }
            else if ( $part !== '.' )
            {
                $out[] = $part;
            }
        }
        return implode( '/', $out );
    }

    /**
     * A SearchPath entry as an absolute directory: relative entries (var/ezupdate/,
     * vendor/bin/, ./) are below the installation root.
     */
    private function absoluteDir( $dir )
    {
        $dir = trim( (string)$dir );
        if ( $dir === '' )
        {
            return '';
        }
        if ( $dir[0] !== '/' )
        {
            $dir = rtrim( $this->projectPath(), '/' ) . '/' . ( $dir === '.' || $dir === './' ? '' : $dir );
        }
        return rtrim( $dir, '/' ) . '/';
    }

    /** @var array Where findBinary() looked: array( file, state ), state one of missing, hidden */
    private $searched = array();

    /** @var bool Whether the binary was taken from the settings without being checked (open_basedir) */
    private $trusted = false;

    /**
     * What the last search looked at, for the message when nothing was found.
     *
     * @return array of array( 'file' => string, 'state' => 'missing'|'hidden' )
     */
    public function searchedPlaces()
    {
        $this->composerCommand();
        return $this->searched;
    }

    /**
     * True when Composer was taken from the settings although open_basedir does
     * not let PHP check that the file is there.
     */
    public function isTrusted()
    {
        $this->composerCommand();
        return $this->trusted;
    }

    /**
     * Finds the binary. [ComposerSettings] Binary may be a full path; else Path +
     * Binary when Path is set, else each directory of SearchPath (relative
     * entries are below the installation root), each name of BinaryNames.
     *
     * Where open_basedir hides the place, a configured Path/Binary is trusted
     * (it is started with proc_open, which open_basedir does not restrict); an
     * automatic search skips it and notes it in searchedPlaces().
     */
    private function findBinary()
    {
        $this->searched = array();
        $this->trusted = false;

        $binary = trim( (string)$this->ini->variable( 'ComposerSettings', 'Binary' ) );
        $path = trim( (string)$this->ini->variable( 'ComposerSettings', 'Path' ) );
        $names = $binary !== '' ? array( $binary ) : (array)$this->ini->variable( 'ComposerSettings', 'BinaryNames' );

        // Explicitly configured: the full path in Binary, or Path with Binary / the first name.
        $configured = false;
        if ( $binary !== '' && strpos( $binary, '/' ) !== false )
        {
            $configured = $binary[0] === '/' ? $binary : $this->absoluteDir( dirname( $binary ) ) . basename( $binary );
        }
        else if ( $path !== '' )
        {
            $configured = false;
            foreach ( $names as $name )
            {
                $file = $this->absoluteDir( $path ) . $name;
                if ( !$this->pathAllowed( $file ) )
                {
                    $this->searched[] = array( 'file' => $file, 'state' => 'hidden' );
                    $this->trusted = true;
                    return $file;
                }
                if ( is_file( $file ) && is_readable( $file ) )
                {
                    return $file;
                }
                $this->searched[] = array( 'file' => $file, 'state' => 'missing' );
            }
            return false;
        }
        if ( $configured !== false )
        {
            if ( !$this->pathAllowed( $configured ) )
            {
                $this->searched[] = array( 'file' => $configured, 'state' => 'hidden' );
                $this->trusted = true;
                return $configured;
            }
            if ( is_file( $configured ) && is_readable( $configured ) )
            {
                return $configured;
            }
            $this->searched[] = array( 'file' => $configured, 'state' => 'missing' );
            return false;
        }

        foreach ( (array)$this->ini->variable( 'ComposerSettings', 'SearchPath' ) as $dir )
        {
            $dir = $this->absoluteDir( $dir );
            if ( $dir === '' )
            {
                continue;
            }
            foreach ( $names as $name )
            {
                $file = $dir . $name;
                if ( !$this->pathAllowed( $file ) )
                {
                    $this->searched[] = array( 'file' => $file, 'state' => 'hidden' );
                    continue;
                }
                if ( is_file( $file ) && is_readable( $file ) )
                {
                    return $file;
                }
                $this->searched[] = array( 'file' => $file, 'state' => 'missing' );
            }
        }
        return false;
    }

    /**
     * Why no Composer was found: where it was looked for, that open_basedir hides
     * system folders (when it does), and what to do about it.
     */
    public function notFoundMessage()
    {
        $text = ezpI18n::tr( 'extension/ezupdate', 'Composer was not found. Set [ComposerSettings] Path, Binary or PHPBinary in ezupdate.ini.' );
        $missing = array();
        $hidden = array();
        foreach ( $this->searchedPlaces() as $place )
        {
            if ( $place['state'] === 'hidden' )
            {
                $hidden[] = $place['file'];
            }
            else
            {
                $missing[] = $place['file'];
            }
        }
        if ( $missing )
        {
            $text .= "\n" . ezpI18n::tr( 'extension/ezupdate', 'Looked in: %places.', null, array( '%places' => implode( ', ', $missing ) ) );
        }
        $allowed = self::openBasedir();
        if ( $allowed )
        {
            $text .= "\n" . ezpI18n::tr( 'extension/ezupdate', 'PHP runs with open_basedir (%dirs), which hides system folders such as /usr/local/bin from the search%skipped.', null,
                array( '%dirs' => implode( ':', $allowed ), '%skipped' => $hidden ? ' (' . implode( ', ', $hidden ) . ')' : '' ) );
        }
        $text .= "\n" . ezpI18n::tr( 'extension/ezupdate', 'Press "Get Composer" on the Overview to download the official composer.phar into var/ezupdate/, or set [ComposerSettings] Path, Binary and PHPBinary in ezupdate.ini to a Composer outside open_basedir.' );
        return $text;
    }

    /** The place "Get Composer" puts composer.phar. */
    public function localComposerFile()
    {
        return rtrim( $this->projectPath(), '/' ) . '/var/ezupdate/composer.phar';
    }

    /**
     * Downloads the official composer.phar into var/ezupdate/ and checks it
     * against the published SHA-256 before it is put in place.
     *
     * @return true|string true, or the reason it failed
     */
    public function downloadComposer()
    {
        $url = trim( (string)$this->ini->variable( 'ComposerSettings', 'DownloadURL' ) );
        if ( $url === '' )
        {
            $url = 'https://getcomposer.org/download/latest-stable/composer.phar';
        }
        $sumUrl = trim( (string)$this->ini->variable( 'ComposerSettings', 'ChecksumURL' ) );
        if ( $sumUrl === '' )
        {
            $sumUrl = $url . '.sha256sum';
        }

        $sum = self::fetch( $sumUrl );
        if ( $sum === false || !preg_match( '/\b([0-9a-f]{64})\b/i', $sum, $m ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The checksum of composer.phar could not be fetched from %url.', null, array( '%url' => $sumUrl ) );
        }
        $expected = strtolower( $m[1] );

        $phar = self::fetch( $url );
        if ( $phar === false || $phar === '' )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'composer.phar could not be downloaded from %url.', null, array( '%url' => $url ) );
        }
        if ( !hash_equals( $expected, hash( 'sha256', $phar ) ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The downloaded composer.phar does not match its published SHA-256 checksum and was discarded.' );
        }

        $target = $this->localComposerFile();
        $dir = dirname( $target );
        if ( !is_dir( $dir ) && !eZDir::mkdir( $dir, false, true ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The directory %dir could not be created.', null, array( '%dir' => $dir ) );
        }
        $temporary = $target . '.' . getmypid() . '.tmp';
        if ( file_put_contents( $temporary, $phar ) === false )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The directory %dir is not writable.', null, array( '%dir' => $dir ) );
        }
        @chmod( $temporary, 0755 );
        if ( !rename( $temporary, $target ) )
        {
            @unlink( $temporary );
            return ezpI18n::tr( 'extension/ezupdate', 'composer.phar could not be put in place in %dir.', null, array( '%dir' => $dir ) );
        }
        $this->command = null;
        return true;
    }

    /**
     * The body of a URL, or false. http(s) through cURL when there is one, else
     * through PHP's streams.
     */
    private static function fetch( $url )
    {
        if ( preg_match( '#^https?://#i', $url ) && function_exists( 'curl_init' ) )
        {
            $curl = curl_init( $url );
            curl_setopt_array( $curl, array(
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_MAXREDIRS      => 5,
                CURLOPT_CONNECTTIMEOUT => 15,
                CURLOPT_TIMEOUT        => 120,
                CURLOPT_SSL_VERIFYPEER => true,
                CURLOPT_PROTOCOLS      => CURLPROTO_HTTPS | CURLPROTO_HTTP,
            ) );
            $body = curl_exec( $curl );
            $code = (int)curl_getinfo( $curl, CURLINFO_RESPONSE_CODE );
            curl_close( $curl );
            return $body !== false && $code === 200 ? $body : false;
        }
        $context = stream_context_create( array( 'http' => array( 'timeout' => 120, 'follow_location' => 1 ) ) );
        return @file_get_contents( $url, false, $context );
    }

    /**
     * A .phar, or a file whose first line is a PHP open tag or a php shebang.
     */
    private static function isPhpScript( $file )
    {
        if ( substr( $file, -5 ) === '.phar' )
        {
            return true;
        }
        $handle = @fopen( $file, 'rb' );
        if ( !$handle )
        {
            return false;
        }
        $line = (string)fgets( $handle, 256 );
        fclose( $handle );
        return strpos( $line, '<?php' ) === 0 || preg_match( '/^#!.*\bphp[0-9.]*\s*$/', $line ) === 1;
    }

    /** @var string|false|null Cached result of phpBinary() */
    private $php = null;

    /**
     * The PHP command-line binary. [ComposerSettings] PHPBinary wins, unchecked.
     * Under the command line it is the running binary. Under PHP-FPM / lsphp
     * PHP_BINARY is the daemon, so the php next to it (PHP_BINDIR) is used: when
     * open_basedir keeps PHP from checking that file it is still taken, because
     * it is the command line of the running PHP. Candidates are asked for their
     * version, and one with the running major.minor is preferred, since a
     * composer.phar and the jobs must see the extensions and syntax of the web PHP.
     */
    public function phpBinary()
    {
        if ( $this->php !== null )
        {
            return $this->php;
        }
        $configured = trim( (string)$this->ini->variable( 'ComposerSettings', 'PHPBinary' ) );
        if ( $configured !== '' )
        {
            return $this->php = $configured;
        }
        if ( PHP_SAPI === 'cli' && PHP_BINARY !== '' )
        {
            return $this->php = PHP_BINARY;
        }

        $running = PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;
        $candidates = array( PHP_BINDIR . '/php' );
        foreach ( (array)$this->ini->variable( 'ComposerSettings', 'PHPSearchPath' ) as $template )
        {
            $candidates[] = str_replace( array( '%version%', '%nodot%' ), array( $running, str_replace( '.', '', $running ) ), $template );
        }

        $fallback = false;
        foreach ( array_unique( $candidates ) as $index => $file )
        {
            $visible = $this->pathAllowed( $file );
            if ( $visible && !is_executable( $file ) )
            {
                continue;
            }
            // Hidden by open_basedir: only the php next to the running PHP is taken on trust.
            if ( !$visible && $index !== 0 )
            {
                continue;
            }
            $version = self::phpVersionOf( $file );
            if ( $version === $running )
            {
                return $this->php = $file;
            }
            if ( $fallback === false && ( $version !== false || ( !$visible && $index === 0 ) ) )
            {
                $fallback = $file;
            }
        }
        return $this->php = $fallback;
    }

    /**
     * "major.minor" of a php binary, asked of the binary itself, or false.
     */
    public static function phpVersionOf( $file )
    {
        $spawned = self::spawn( array( $file, '-n', '-r', 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;' ) );
        if ( !$spawned )
        {
            return false;
        }
        list( $process, $pipe ) = $spawned;
        stream_set_timeout( $pipe, 10 );
        $output = trim( (string)stream_get_contents( $pipe ) );
        fclose( $pipe );
        proc_close( $process );
        return preg_match( '/^\d+\.\d+$/', $output ) ? $output : false;
    }

    public function composerVersion()
    {
        $result = $this->run( array( '--version', '--no-ansi' ), 60 );
        if ( $result['exit'] !== 0 )
        {
            return false;
        }
        // Warnings (running as root, a missing extension) may come first.
        foreach ( explode( "\n", $result['output'] ) as $line )
        {
            if ( stripos( $line, 'Composer version' ) === 0 )
            {
                return trim( $line );
            }
        }
        return trim( strtok( $result['output'], "\n" ) );
    }

    /**
     * The installed packages that have a newer release, from `composer outdated`.
     *
     * @return array|false list of hashes name, version, latest, status, description;
     *                     false when Composer failed (lastOutput() tells why)
     */
    public function outdatedPackages( $directOnly = true )
    {
        $arguments = array( 'outdated', '--format=json', '--no-ansi' );
        if ( $directOnly )
        {
            $arguments[] = '--direct';
        }
        $result = $this->run( $arguments );

        // The JSON is the last thing printed; warnings may come first on the merged stream.
        $json = strpos( $result['output'], "{\n" );
        $data = $json === false ? null : json_decode( substr( $result['output'], $json ), true );
        if ( !is_array( $data ) )
        {
            return false;
        }

        $packages = array();
        foreach ( isset( $data['installed'] ) ? $data['installed'] : array() as $package )
        {
            $packages[] = array(
                'name'        => (string)$package['name'],
                'version'     => isset( $package['version'] ) ? (string)$package['version'] : '',
                'latest'      => isset( $package['latest'] ) ? (string)$package['latest'] : '',
                'status'      => isset( $package['latest-status'] ) ? (string)$package['latest-status'] : '',
                'description' => isset( $package['description'] ) ? (string)$package['description'] : '',
            );
        }
        return $packages;
    }

    /**
     * The output of the last Composer run.
     */
    public function lastOutput()
    {
        return $this->lastResult ? $this->lastResult['output'] : '';
    }

    /**
     * `composer show` for an installed package, as HTML-ready text; false for a
     * name that is not a package name.
     */
    public function packageInfo( $packageName )
    {
        if ( !self::isPackageName( $packageName ) )
        {
            return false;
        }
        return $this->run( array( 'show', '--ansi', $packageName ), 120 );
    }

    /**
     * The installed version of $packageName from vendor/composer/installed.json,
     * or false when it is not installed.
     */
    public function installedVersion( $packageName )
    {
        $installed = $this->installedPackages();
        return isset( $installed[$packageName] ) ? $installed[$packageName] : false;
    }

    /**
     * name => version of every installed package (vendor/composer/installed.json).
     */
    public function installedPackages()
    {
        $file = $this->projectPath() . '/vendor/composer/installed.json';
        $data = is_file( $file ) ? json_decode( (string)file_get_contents( $file ), true ) : null;
        if ( !is_array( $data ) )
        {
            return array();
        }
        $packages = isset( $data['packages'] ) ? $data['packages'] : $data;
        $result = array();
        foreach ( $packages as $package )
        {
            if ( isset( $package['name'] ) )
            {
                $result[$package['name']] = isset( $package['version'] ) ? $package['version'] : '';
            }
        }
        return $result;
    }

    /**
     * How an installed package was fetched, from vendor/composer/installed.json:
     * installation-source (dist or source), the source and dist type, URL and
     * reference (the git commit), the install path, and for a source install the
     * git branch and commit found in its working copy.
     *
     * @return array|false
     */
    public function installedPackageInfo( $packageName )
    {
        $file = $this->projectPath() . '/vendor/composer/installed.json';
        $data = is_file( $file ) ? json_decode( (string)file_get_contents( $file ), true ) : null;
        if ( !is_array( $data ) )
        {
            return false;
        }
        foreach ( isset( $data['packages'] ) ? $data['packages'] : $data as $package )
        {
            if ( !isset( $package['name'] ) || $package['name'] !== $packageName )
            {
                continue;
            }
            $path = isset( $package['install-path'] )
                ? realpath( dirname( $file ) . '/' . $package['install-path'] ) : false;
            $info = array(
                'version'  => isset( $package['version'] ) ? (string)$package['version'] : '',
                'method'   => isset( $package['installation-source'] ) ? (string)$package['installation-source'] : '',
                'source'   => self::reference( isset( $package['source'] ) ? $package['source'] : null ),
                'dist'     => self::reference( isset( $package['dist'] ) ? $package['dist'] : null ),
                'path'     => $path ? $path : '',
                'git'      => false,
            );
            if ( $path && is_dir( $path . '/.git' ) )
            {
                $info['git'] = self::gitInfo( $path );
            }
            return $info;
        }
        return false;
    }

    private static function reference( $block )
    {
        if ( !is_array( $block ) )
        {
            return false;
        }
        return array(
            'type'      => isset( $block['type'] ) ? (string)$block['type'] : '',
            'url'       => isset( $block['url'] ) ? (string)$block['url'] : '',
            'reference' => isset( $block['reference'] ) ? (string)$block['reference'] : '',
        );
    }

    /**
     * Branch, commit, last commit subject and whether the working copy has
     * changes, read with git (no shell) from a package's own clone.
     */
    public static function gitInfo( $path )
    {
        $git = function ( array $arguments ) use ( $path )
        {
            $started = eZUpdateManager::spawn( array_merge( array( 'git', '-c', 'safe.directory=*', '-C', $path ), $arguments ) );
            if ( !$started )
            {
                return '';
            }
            list( $process, $stdout ) = $started;
            $out = stream_get_contents( $stdout );
            fclose( $stdout );
            return proc_close( $process ) === 0 ? trim( (string)$out ) : '';
        };
        return array(
            'branch'  => $git( array( 'rev-parse', '--abbrev-ref', 'HEAD' ) ),
            'commit'  => $git( array( 'rev-parse', '--short', 'HEAD' ) ),
            'subject' => $git( array( 'log', '-1', '--format=%s (%cr)' ) ),
            'tag'     => $git( array( 'describe', '--tags', '--always' ) ),
            'remote'  => $git( array( 'remote', 'get-url', 'origin' ) ),
            'changed' => $git( array( 'status', '--porcelain', '--untracked-files=no' ) ) !== '',
        );
    }

    /**
     * `composer search` over every repository composer.json names (Packagist
     * included unless it is switched off there).
     *
     * @return array|false list of hashes name, description, url
     */
    public function search( $query )
    {
        $query = trim( (string)$query );
        if ( $query === '' || strlen( $query ) > 100 || $query[0] === '-' )
        {
            return false;
        }
        $result = $this->run( array( 'search', '--format=json', '--no-ansi', $query ), 120 );
        $json = strpos( $result['output'], '[' );
        $data = $json === false ? null : json_decode( substr( $result['output'], $json ), true );
        if ( !is_array( $data ) )
        {
            return false;
        }
        $list = array();
        foreach ( $data as $item )
        {
            $list[] = array(
                'name'        => isset( $item['name'] ) ? (string)$item['name'] : '',
                'description' => isset( $item['description'] ) ? (string)$item['description'] : '',
                'url'         => isset( $item['url'] ) ? (string)$item['url'] : '',
            );
        }
        return $list;
    }

    /**
     * The Composer arguments of an update, a dry run first when $dryRun is set.
     */
    public function updateArguments( $dryRun = false, $method = null )
    {
        $arguments = array( 'update' );
        if ( $dryRun )
        {
            $arguments[] = '--dry-run';
        }
        return array_merge( $arguments, $this->methodArguments( $method ), $this->configuredArguments( 'UpdateArguments' ) );
    }

    /**
     * How packages are fetched: 'dist' (release archives, fast), 'source' (git
     * clones: each package keeps its .git, so its history, branch and commit can
     * be read and worked on) or 'auto' (Composer decides: source for dev
     * versions, dist for releases).
     */
    public static $installMethods = array( 'auto', 'dist', 'source' );

    /**
     * The method to use: $method when it is one of $installMethods, else
     * [UpdateSettings] PreferredInstall.
     */
    public function installMethod( $method = null )
    {
        if ( in_array( $method, self::$installMethods, true ) )
        {
            return $method;
        }
        $configured = $this->ini->hasVariable( 'UpdateSettings', 'PreferredInstall' )
            ? (string)$this->ini->variable( 'UpdateSettings', 'PreferredInstall' ) : 'auto';
        return in_array( $configured, self::$installMethods, true ) ? $configured : 'auto';
    }

    private function methodArguments( $method )
    {
        switch ( $this->installMethod( $method ) )
        {
            case 'dist':   return array( '--prefer-dist' );
            case 'source': return array( '--prefer-source' );
        }
        return array();
    }

    /**
     * The Composer arguments that install $packageName at $constraint (empty:
     * Composer chooses), or false when the name or constraint is not valid.
     */
    public function requireArguments( $packageName, $constraint = '', $dryRun = false, $method = null )
    {
        if ( !self::isPackageName( $packageName ) || !self::isConstraint( $constraint ) )
        {
            return false;
        }
        $arguments = array( 'require' );
        if ( $dryRun )
        {
            $arguments[] = '--dry-run';
        }
        $arguments[] = $constraint === '' ? $packageName : $packageName . ':' . $constraint;
        return array_merge( $arguments, $this->methodArguments( $method ), $this->configuredArguments( 'RequireArguments' ) );
    }

    private function configuredArguments( $name )
    {
        if ( !$this->ini->hasVariable( 'UpdateSettings', $name ) )
        {
            return array();
        }
        return array_values( array_filter( (array)$this->ini->variable( 'UpdateSettings', $name ), 'strlen' ) );
    }

    /**
     * A version constraint Composer accepts, without anything a command line
     * could read as an option: digits, letters, . * ~ ^ < > = ! | , @ - and spaces.
     */
    public static function isConstraint( $constraint )
    {
        return is_string( $constraint )
            && ( $constraint === '' || ( strlen( $constraint ) <= 64 && $constraint[0] !== '-'
                 && preg_match( '#^[A-Za-z0-9.*~^<>=!|,@ _-]+$#', $constraint ) === 1 ) );
    }

    public static function isPackageName( $name )
    {
        return is_string( $name ) && preg_match( self::PACKAGE_NAME_PATTERN, $name ) === 1;
    }

    /**
     * Runs Composer with the given arguments (no shell is involved).
     *
     * @return array hash output (stdout and stderr merged), exit (int, -1 when it
     *               could not start or ran out of time), timed_out (bool), seconds
     */
    public function run( array $arguments, $timeout = null, $onOutput = null )
    {
        $started = microtime( true );
        $command = $this->composerCommand();
        if ( !$command )
        {
            return $this->lastResult = array(
                'output'    => $this->notFoundMessage(),
                'exit'      => -1,
                'timed_out' => false,
                'seconds'   => 0,
            );
        }
        if ( $timeout === null )
        {
            $timeout = (int)$this->ini->variable( 'ComposerSettings', 'Timeout' );
        }
        if ( $timeout > 0 )
        {
            @set_time_limit( $timeout + 30 );
        }
        $arguments[] = '--no-interaction';

        $spawned = self::spawn( array_merge( $command, $arguments ), $this->projectPath(), $this->environment() );
        if ( !$spawned )
        {
            $last = error_get_last();
            return $this->lastResult = array( 'output' => 'Composer could not be started' . ( $last ? ': ' . $last['message'] : '' ),
                                              'exit' => -1, 'timed_out' => false, 'seconds' => 0 );
        }
        list( $process, $stdout ) = $spawned;

        stream_set_blocking( $stdout, false );
        $output = '';
        $timedOut = false;
        while ( true )
        {
            $read = array( $stdout );
            $write = $except = null;
            if ( @stream_select( $read, $write, $except, 1 ) )
            {
                $chunk = fread( $stdout, 65536 );
                if ( $chunk !== false && $chunk !== '' )
                {
                    $output .= $chunk;
                    if ( $onOutput )
                    {
                        call_user_func( $onOutput, $chunk );
                    }
                }
            }
            if ( feof( $stdout ) )
            {
                break;
            }
            if ( $timeout > 0 && microtime( true ) - $started > $timeout )
            {
                $timedOut = true;
                proc_terminate( $process );
                break;
            }
        }
        fclose( $stdout );
        $exit = proc_close( $process );

        if ( $timedOut )
        {
            $note = "\n" . ezpI18n::tr( 'extension/ezupdate', 'Composer was stopped after %seconds seconds ([ComposerSettings] Timeout).', null, array( '%seconds' => $timeout ) );
            $output .= $note;
            if ( $onOutput )
            {
                call_user_func( $onOutput, $note );
            }
            $exit = -1;
        }
        eZDebug::writeNotice( 'composer ' . implode( ' ', $arguments ) . ' exit ' . $exit, __METHOD__ );

        return $this->lastResult = array(
            'output'    => rtrim( $output ),
            'exit'      => (int)$exit,
            'timed_out' => $timedOut,
            'seconds'   => round( microtime( true ) - $started, 1 ),
        );
    }

    /**
     * The environment of the Composer process. A web server often passes an empty
     * environment (PHP-FPM clear_env), and Composer needs a home directory, a PATH
     * to find git and unzip, and must not ask questions.
     */
    private function environment()
    {
        $env = getenv();
        if ( !is_array( $env ) )
        {
            $env = array();
        }
        if ( empty( $env['PATH'] ) )
        {
            $env['PATH'] = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';
        }
        if ( empty( $env['COMPOSER_HOME'] ) )
        {
            $home = (string)$this->ini->variable( 'ComposerSettings', 'ComposerHome' );
            if ( $home !== '' && $home[0] !== '/' )
            {
                $home = $this->projectPath() . '/' . $home;
            }
            if ( $home !== '' )
            {
                // One home per system account: the web server's user and root
                // (the command line) must not share Composer's cache, or the
                // first to create a directory locks the other out of it.
                $home .= '/' . self::accountName();
                if ( !is_dir( $home ) )
                {
                    eZDir::mkdir( $home, false, true );
                }
                $env['COMPOSER_HOME'] = $home;
                if ( empty( $env['HOME'] ) )
                {
                    $env['HOME'] = $home;
                }
            }
        }
        $env['COMPOSER_NO_INTERACTION'] = '1';
        return $env;
    }

    /**
     * Starts $command (an argument list, no shell) with stdin at end of file and
     * stdout and stderr on one pipe.
     *
     * Only pipes are handed to the child: under a web server that serves files
     * through its own stream wrapper (Exponential Velocity), a 'file'
     * descriptor cannot be passed to a child process at all. And under such a
     * server the child must not inherit the server's listening sockets and
     * client connections, or a long Composer run (or a detached job) would hold
     * them: its engine's descriptor helper covers every other descriptor.
     *
     * @return array|false array( process, stdout pipe ), or false
     */
    public static function spawn( array $command, $cwd = null, $env = null )
    {
        $spec = array( 0 => array( 'pipe', 'r' ), 1 => array( 'pipe', 'w' ), 2 => array( 'redirect', 1 ) );
        $engine = class_exists( 'Q_WebServer_Shell_Exec', false );
        if ( $engine )
        {
            $spec = Q_WebServer_Shell_Exec::descriptors( $spec );
        }
        $process = @proc_open( $command, $spec, $pipes, $cwd, $env );
        if ( !is_resource( $process ) )
        {
            return false;
        }
        if ( $engine )
        {
            Q_WebServer_Shell_Exec::closeExtra( $pipes );
        }
        fclose( $pipes[0] ); // stdin: end of file at once
        return array( $process, $pipes[1] );
    }

    /**
     * The name of the system account PHP runs as, safe for a directory name.
     */
    public static function accountName()
    {
        $name = '';
        if ( function_exists( 'posix_geteuid' ) && function_exists( 'posix_getpwuid' ) )
        {
            $info = posix_getpwuid( posix_geteuid() );
            $name = $info ? $info['name'] : (string)posix_geteuid();
        }
        if ( $name === '' )
        {
            $name = get_current_user();
        }
        $name = preg_replace( '/[^A-Za-z0-9_.-]/', '_', $name );
        return $name !== '' ? $name : 'default';
    }

    /**
     * Turns Composer output with ANSI colour codes into HTML. The text is escaped
     * first, so nothing in the output (package descriptions included) becomes markup.
     */
    public static function ansiToHtml( $text )
    {
        $colours = array(
            '30' => '#000', '31' => '#c00', '32' => '#0a0', '33' => '#a50',
            '34' => '#00a', '35' => '#a0a', '36' => '#0aa', '37' => '#aaa',
            '90' => '#555', '91' => '#f55', '92' => '#5f5', '93' => '#ff5',
            '94' => '#55f', '95' => '#f5f', '96' => '#5ff', '97' => '#fff',
        );

        $text = htmlspecialchars( (string)$text, ENT_QUOTES, 'UTF-8' );
        $open = false;
        $styles = array();

        $html = preg_replace_callback(
            '/\x1b\[([0-9;]*)m/',
            function ( $m ) use ( $colours, &$open, &$styles )
            {
                foreach ( explode( ';', $m[1] ) as $code )
                {
                    if ( $code === '' || $code === '0' )
                    {
                        $styles = array();
                    }
                    else if ( $code === '39' )
                    {
                        unset( $styles['color'] );
                    }
                    else if ( $code === '22' )
                    {
                        unset( $styles['font-weight'] );
                    }
                    else if ( $code === '1' )
                    {
                        $styles['font-weight'] = 'bold';
                    }
                    else if ( isset( $colours[$code] ) )
                    {
                        $styles['color'] = $colours[$code];
                    }
                }
                $html = $open ? '</span>' : '';
                $open = false;
                if ( $styles )
                {
                    $css = array();
                    foreach ( $styles as $property => $value )
                    {
                        $css[] = $property . ':' . $value;
                    }
                    $html .= '<span style="' . implode( ';', $css ) . '">';
                    $open = true;
                }
                return $html;
            },
            $text
        );
        // Drop any other escape sequence (cursor movement, erase line).
        $html = preg_replace( '/\x1b\[[0-9;?]*[A-Za-z]/', '', $html );
        return $open ? $html . '</span>' : $html;
    }
}
