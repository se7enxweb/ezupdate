<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    01 Oct 2026
 *
 * What is installed, from every place that says so, matched up: composer.json
 * (what is required, and with which constraint), composer.lock (the version
 * that was resolved), vendor/composer/installed.json (what is on disk and
 * where), the extension directories, and the ActiveExtensions and
 * ActiveAccessExtensions of the settings (which of them run, and where).
 *
 * Nothing is run: the files are read, and a git working copy's branch and
 * commit are read from its .git directory, so the page stays quick with a
 * hundred packages.
 **/

class eZUpdateInventory
{
    /** @var eZUpdateManager */
    private $manager;

    public function __construct( eZUpdateManager $manager )
    {
        $this->manager = $manager;
    }

    /**
     * Every package and every extension directory, one row each, and the counts
     * the page's summary and filters show.
     *
     * @return array( 'rows' => array, 'summary' => array, 'sources' => array )
     */
    public function build()
    {
        $root = rtrim( $this->manager->projectPath(), '/' );
        $composer = self::readJson( $root . '/composer.json' );
        $lock = self::readJson( $root . '/composer.lock' );
        $installedFile = $root . '/vendor/composer/installed.json';
        $installed = self::readJson( $installedFile );

        $required = array();
        foreach ( array( 'require' => false, 'require-dev' => true ) as $key => $dev )
        {
            foreach ( ( isset( $composer[$key] ) && is_array( $composer[$key] ) ) ? $composer[$key] : array() as $name => $constraint )
            {
                if ( strpos( $name, '/' ) !== false )
                    $required[strtolower( $name )] = array( 'constraint' => (string)$constraint, 'dev' => $dev );
            }
        }

        $locked = array();
        foreach ( array( 'packages' => false, 'packages-dev' => true ) as $key => $dev )
        {
            foreach ( ( isset( $lock[$key] ) && is_array( $lock[$key] ) ) ? $lock[$key] : array() as $package )
            {
                if ( isset( $package['name'] ) )
                    $locked[strtolower( $package['name'] )] = array( 'version' => isset( $package['version'] ) ? (string)$package['version'] : '',
                                                                     'reference' => self::shortReference( $package ),
                                                                     'dev' => $dev );
            }
        }

        $active = $this->activeExtensions();
        $extensionDir = eZExtension::baseDirectory();
        $extensionPath = realpath( $root . '/' . $extensionDir );

        $rows = array();
        $extensionsByComposer = array();
        $packages = is_array( $installed ) ? ( isset( $installed['packages'] ) ? $installed['packages'] : $installed ) : array();
        foreach ( $packages as $package )
        {
            if ( !isset( $package['name'] ) )
                continue;
            $name = (string)$package['name'];
            $key = strtolower( $name );
            $path = isset( $package['install-path'] ) ? realpath( dirname( $installedFile ) . '/' . $package['install-path'] ) : false;
            $extension = false;
            if ( $path && $extensionPath && dirname( $path ) === $extensionPath )
            {
                $extension = basename( $path );
                $extensionsByComposer[$extension] = true;
            }
            $rows[$key] = array(
                'name'        => $name,
                'vendor'      => strtok( $name, '/' ),
                'description' => isset( $package['description'] ) ? (string)$package['description'] : '',
                'type'        => isset( $package['type'] ) ? (string)$package['type'] : 'library',
                'kind'        => $extension ? 'extension' : ( ( isset( $package['type'] ) && $package['type'] === 'composer-plugin' ) ? 'plugin' : 'library' ),
                'composer'    => true,
                'required'    => isset( $required[$key] ) ? $required[$key]['constraint'] : '',
                'dev'         => isset( $required[$key] ) ? $required[$key]['dev'] : ( isset( $locked[$key] ) && $locked[$key]['dev'] ),
                'locked'      => isset( $locked[$key] ) ? $locked[$key]['version'] : '',
                'locked_ref'  => isset( $locked[$key] ) ? $locked[$key]['reference'] : '',
                'installed'   => isset( $package['version'] ) ? (string)$package['version'] : '',
                'installed_ref' => self::shortReference( $package ),
                'method'      => isset( $package['installation-source'] ) ? (string)$package['installation-source'] : '',
                'source_url'  => isset( $package['source']['url'] ) ? (string)$package['source']['url'] : '',
                'homepage'    => isset( $package['homepage'] ) ? (string)$package['homepage'] : '',
                'license'     => isset( $package['license'] ) ? implode( ', ', (array)$package['license'] ) : '',
                'path'        => $path ? self::relative( $path, $root ) : '',
                'path_exists' => $path && is_dir( $path ),
                'extension'   => $extension,
                'active'      => $extension ? self::activeIn( $extension, $active ) : array(),
                'git'         => $path ? self::gitHead( $path ) : false,
                'ext_version' => $extension ? self::extensionVersion( $path ) : '',
            );
        }

        // Required in composer.json and not installed at all
        foreach ( $required as $key => $info )
        {
            if ( isset( $rows[$key] ) )
                continue;
            $rows[$key] = self::emptyRow( $key ) + array();
            $rows[$key]['required'] = $info['constraint'];
            $rows[$key]['dev'] = $info['dev'];
            $rows[$key]['locked'] = isset( $locked[$key] ) ? $locked[$key]['version'] : '';
            $rows[$key]['locked_ref'] = isset( $locked[$key] ) ? $locked[$key]['reference'] : '';
        }

        // Extension directories Composer did not install
        if ( $extensionPath )
        {
            foreach ( scandir( $extensionPath ) as $dir )
            {
                if ( $dir[0] === '.' || isset( $extensionsByComposer[$dir] ) || !is_dir( $extensionPath . '/' . $dir ) )
                    continue;
                $path = $extensionPath . '/' . $dir;
                $row = self::emptyRow( $extensionDir . '/' . $dir );
                $row['kind'] = 'extension';
                $row['composer'] = false;
                $row['installed'] = '';
                $row['path'] = self::relative( $path, $root );
                $row['path_exists'] = true;
                $row['extension'] = $dir;
                $row['active'] = self::activeIn( $dir, $active );
                $row['git'] = self::gitHead( $path );
                $row['ext_version'] = self::extensionVersion( $path );
                $row['description'] = self::extensionName( $dir );
                $rows['~ext/' . $dir] = $row;
            }
        }

        // Active in the settings, but no such directory
        foreach ( $active['all'] as $extension => $where )
        {
            if ( $extensionPath && !is_dir( $extensionPath . '/' . $extension ) )
            {
                $row = self::emptyRow( $extensionDir . '/' . $extension );
                $row['kind'] = 'extension';
                $row['composer'] = false;
                $row['extension'] = $extension;
                $row['active'] = $where;
                $row['path'] = $extensionDir . '/' . $extension;
                $rows['~ext/' . $extension] = $row;
            }
        }

        $summary = array( 'all' => 0, 'required' => 0, 'composer' => 0, 'extension' => 0, 'library' => 0,
                          'active' => 0, 'inactive' => 0, 'local' => 0, 'issues' => 0, 'git' => 0 );
        foreach ( $rows as $key => $row )
        {
            $row['issues'] = self::issues( $row );
            $row['filters'] = self::filters( $row );
            $rows[$key] = $row;
            $summary['all']++;
            foreach ( $row['filters'] as $filter )
            {
                if ( isset( $summary[$filter] ) )
                    $summary[$filter]++;
            }
        }
        uasort( $rows, function ( $a, $b ) {
            return strcasecmp( $a['name'], $b['name'] );
        } );

        return array(
            'rows'    => array_values( $rows ),
            'summary' => $summary,
            'sources' => array(
                'composer_json' => is_array( $composer ),
                'composer_lock' => is_array( $lock ),
                'installed_json' => is_array( $installed ),
                'lock_age'      => is_file( $root . '/composer.lock' ) ? filemtime( $root . '/composer.lock' ) : 0,
                'installed_age' => is_file( $installedFile ) ? filemtime( $installedFile ) : 0,
                'siteaccesses'  => $active['siteaccesses'],
                'extension_dir' => $extensionDir,
            ),
        );
    }

    /**
     * The extensions the settings switch on: ActiveExtensions (everywhere) and
     * each siteaccess's ActiveAccessExtensions.
     *
     * @return array( 'global' => array, 'access' => array( ext => list of siteaccesses ), 'all' => array, 'siteaccesses' => array )
     */
    private function activeExtensions()
    {
        $ini = eZINI::instance();
        $global = array_values( array_unique( array_filter( (array)$ini->variable( 'ExtensionSettings', 'ActiveExtensions' ) ) ) );
        $access = array();
        $siteaccesses = array_values( array_unique( array_filter( (array)$ini->variable( 'SiteAccessSettings', 'AvailableSiteAccessList' ) ) ) );
        foreach ( $siteaccesses as $siteaccess )
        {
            $saINI = eZSiteAccess::getIni( $siteaccess, 'site.ini' );
            if ( !$saINI instanceof eZINI || !$saINI->hasVariable( 'ExtensionSettings', 'ActiveAccessExtensions' ) )
                continue;
            foreach ( array_filter( (array)$saINI->variable( 'ExtensionSettings', 'ActiveAccessExtensions' ) ) as $extension )
                $access[$extension][] = $siteaccess;
        }
        $all = array();
        foreach ( $global as $extension )
            $all[$extension] = array( 'everywhere' );
        foreach ( $access as $extension => $list )
        {
            if ( !isset( $all[$extension] ) )
                $all[$extension] = array_values( array_unique( $list ) );
        }
        return array( 'global' => $global, 'access' => $access, 'all' => $all, 'siteaccesses' => $siteaccesses );
    }

    private static function activeIn( $extension, array $active )
    {
        return isset( $active['all'][$extension] ) ? $active['all'][$extension] : array();
    }

    private static function emptyRow( $name )
    {
        return array( 'name' => $name, 'vendor' => strtok( $name, '/' ), 'description' => '', 'type' => '', 'kind' => 'library',
                      'composer' => true, 'required' => '', 'dev' => false, 'locked' => '', 'locked_ref' => '',
                      'installed' => '', 'installed_ref' => '', 'method' => '', 'source_url' => '', 'homepage' => '',
                      'license' => '', 'path' => '', 'path_exists' => false, 'extension' => false, 'active' => array(),
                      'git' => false, 'ext_version' => '' );
    }

    /** What does not agree between the sources, worded for the page. */
    private static function issues( array $row )
    {
        $issues = array();
        if ( $row['composer'] && $row['required'] !== '' && $row['installed'] === '' )
            $issues[] = array( 'bad', ezpI18n::tr( 'extension/ezupdate', 'Required, not installed' ) );
        if ( $row['composer'] && $row['installed'] !== '' && $row['locked'] === '' )
            $issues[] = array( 'warn', ezpI18n::tr( 'extension/ezupdate', 'Not in composer.lock' ) );
        if ( $row['locked'] !== '' && $row['installed'] !== '' && $row['locked'] !== $row['installed'] )
            $issues[] = array( 'warn', ezpI18n::tr( 'extension/ezupdate', 'Locked %locked, installed %installed', null,
                                                    array( '%locked' => $row['locked'], '%installed' => $row['installed'] ) ) );
        if ( $row['locked'] !== '' && $row['required'] !== '' && ( $floor = self::constraintFloor( $row['required'] ) ) !== false
             && version_compare( self::plainVersion( $row['locked'] ), $floor, '<' ) )
            $issues[] = array( 'warn', ezpI18n::tr( 'extension/ezupdate', 'Lock older than composer.json (%constraint)', null,
                                                    array( '%constraint' => $row['required'] ) ) );
        if ( $row['locked_ref'] !== '' && $row['installed_ref'] !== '' && $row['locked_ref'] !== $row['installed_ref']
             && $row['locked'] === $row['installed'] )
            $issues[] = array( 'warn', ezpI18n::tr( 'extension/ezupdate', 'Other commit than the lock' ) );
        if ( $row['composer'] && $row['installed'] !== '' && !$row['path_exists'] )
            $issues[] = array( 'bad', ezpI18n::tr( 'extension/ezupdate', 'Missing on disk' ) );
        if ( $row['extension'] && !$row['path_exists'] && $row['active'] )
            $issues[] = array( 'bad', ezpI18n::tr( 'extension/ezupdate', 'Active, but not on disk' ) );
        // a clone made by hand where Composer installed a dist: the next update replaces it
        if ( $row['git'] && $row['method'] === 'dist' )
            $issues[] = array( 'warn', ezpI18n::tr( 'extension/ezupdate', 'Git clone of a dist install' ) );
        return $issues;
    }

    /**
     * The lowest version a simple constraint allows: ~1.4.9, ^1.4, >=1.4.9,
     * =1.4.9 or 1.4.9; false for anything else (ranges, |, *, dev branches),
     * which is not judged.
     */
    private static function constraintFloor( $constraint )
    {
        if ( !preg_match( '/^\s*(?:~|\^|>=|=)?\s*v?(\d+(?:\.\d+){0,3})\s*$/', (string)$constraint, $m ) )
            return false;
        return $m[1];
    }

    /** "v1.4.3" -> "1.4.3"; a branch or an unparsable version -> "0". */
    private static function plainVersion( $version )
    {
        return preg_match( '/^v?(\d+(?:\.\d+){0,3})/', (string)$version, $m ) ? $m[1] : '0';
    }

    /** The filter names a row answers to (data-filters on the page). */
    private static function filters( array $row )
    {
        $f = array();
        if ( $row['required'] !== '' ) $f[] = 'required';
        if ( $row['composer'] && $row['installed'] !== '' ) $f[] = 'composer';
        $f[] = $row['kind'] === 'extension' ? 'extension' : 'library';
        if ( $row['extension'] )
            $f[] = $row['active'] ? 'active' : 'inactive';
        if ( !$row['composer'] ) $f[] = 'local';
        if ( $row['issues'] ) $f[] = 'issues';
        if ( $row['git'] ) $f[] = 'git';
        return $f;
    }

    /**
     * Branch and commit of a git working copy, read from its .git directory
     * (HEAD, the ref file or packed-refs), without running git.
     *
     * @return array|false branch ('' when detached), commit (short), detached
     */
    public static function gitHead( $path )
    {
        $git = $path . '/.git';
        if ( is_file( $git ) )
        {
            // a worktree or submodule: "gitdir: <path>"
            if ( !preg_match( '/^gitdir:\s*(.+)$/m', (string)@file_get_contents( $git ), $m ) )
                return false;
            $git = $m[1][0] === '/' ? trim( $m[1] ) : $path . '/' . trim( $m[1] );
        }
        if ( !is_dir( $git ) || !is_file( $git . '/HEAD' ) )
            return false;
        $head = trim( (string)@file_get_contents( $git . '/HEAD' ) );
        if ( strpos( $head, 'ref: ' ) !== 0 )
            return array( 'branch' => '', 'commit' => substr( $head, 0, 7 ), 'detached' => true );
        $ref = substr( $head, 5 );
        $commit = '';
        $common = is_file( $git . '/commondir' ) ? $git . '/' . trim( (string)@file_get_contents( $git . '/commondir' ) ) : $git;
        foreach ( array( $git, $common ) as $dir )
        {
            if ( is_file( $dir . '/' . $ref ) )
            {
                $commit = trim( (string)@file_get_contents( $dir . '/' . $ref ) );
                break;
            }
            if ( is_file( $dir . '/packed-refs' ) && preg_match( '/^([0-9a-f]{40}) ' . preg_quote( $ref, '/' ) . '$/m', (string)@file_get_contents( $dir . '/packed-refs' ), $m ) )
            {
                $commit = $m[1];
                break;
            }
        }
        return array( 'branch' => preg_replace( '#^refs/heads/#', '', $ref ), 'commit' => substr( $commit, 0, 7 ), 'detached' => false );
    }

    /** An extension's own version: extension.xml <version>, else ezinfo.php's. */
    private static function extensionVersion( $path )
    {
        if ( is_file( $path . '/extension.xml' ) && preg_match( '#<version>\s*([^<]+?)\s*</version>#', (string)@file_get_contents( $path . '/extension.xml' ), $m ) )
            return $m[1] === '//autogentag//' ? '' : $m[1];
        if ( is_file( $path . '/ezinfo.php' ) && preg_match( '#[\'"]Version[\'"]\s*=>\s*[\'"]([^\'"]+)[\'"]#', (string)@file_get_contents( $path . '/ezinfo.php' ), $m ) )
            return $m[1] === '//autogentag//' ? '' : $m[1];
        return '';
    }

    private static function extensionName( $extension )
    {
        $info = eZExtension::extensionInfo( $extension );
        return is_array( $info ) && !empty( $info['name'] ) ? (string)$info['name'] : '';
    }

    private static function shortReference( array $package )
    {
        foreach ( array( 'source', 'dist' ) as $key )
        {
            if ( !empty( $package[$key]['reference'] ) )
                return substr( (string)$package[$key]['reference'], 0, 7 );
        }
        return '';
    }

    private static function relative( $path, $root )
    {
        return strpos( $path, $root . '/' ) === 0 ? substr( $path, strlen( $root ) + 1 ) : $path;
    }

    private static function readJson( $file )
    {
        if ( !is_file( $file ) )
            return null;
        $data = json_decode( (string)file_get_contents( $file ), true );
        return is_array( $data ) ? $data : null;
    }
}
