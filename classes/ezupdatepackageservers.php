<?php
/**
 * @package eZUpdate
 * @class   eZUpdatePackageServers
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 **/

/**
 * The Exponential package servers (.ezpkg): the server the setup wizard uses
 * (package.ini [RepositorySettings] RemotePackagesIndexURL, shown read-only)
 * and the servers added in the admin, kept in
 * settings/override/ezupdate.ini.append.php [PackageServerSettings] Servers[<name>]=<url>.
 *
 * A server answers <url>/index.xml with <packages><package name= type= url=/>...,
 * the format the setup wizard reads. Fetching a package downloads its .ezpkg and
 * imports it into the local package repository; installing it is then done with
 * the kernel's own package views.
 */
class eZUpdatePackageServers
{
    const NAME_PATTERN = '#^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$#';
    const OVERRIDE_FILE = 'ezupdate.ini.append.php';
    const OVERRIDE_DIR = 'settings/override';

    /** @var string Error text of the last failed call */
    public $error = '';

    /**
     * The override file itself, read directly (no cache, no merged view), so
     * the admin and the command line always see the same list.
     */
    private static function overrideINI()
    {
        return new eZINI( self::OVERRIDE_FILE, self::OVERRIDE_DIR, null, false, null, true );
    }

    /**
     * @return array name => hash name, url, builtin (bool)
     */
    public function servers()
    {
        $list = array();
        $builtin = self::builtinIndexURL();
        if ( $builtin !== '' )
        {
            $list['exponential'] = array( 'name' => 'exponential', 'url' => $builtin, 'builtin' => true );
        }
        $ini = self::overrideINI();
        if ( $ini->hasVariable( 'PackageServerSettings', 'Servers' ) )
        {
            foreach ( (array)$ini->variable( 'PackageServerSettings', 'Servers' ) as $name => $url )
            {
                if ( is_string( $name ) && preg_match( self::NAME_PATTERN, $name ) && !isset( $list[$name] ) )
                {
                    $list[$name] = array( 'name' => $name, 'url' => (string)$url, 'builtin' => false );
                }
            }
        }
        return $list;
    }

    /**
     * The server the setup wizard uses, resolved the way it resolves it.
     */
    public static function builtinIndexURL()
    {
        $ini = eZINI::instance( 'package.ini' );
        $url = trim( (string)$ini->variable( 'RepositorySettings', 'RemotePackagesIndexURL' ) );
        if ( $url === '' && $ini->hasVariable( 'RepositorySettings', 'RemotePackagesIndexURLBase' ) )
        {
            $base = trim( (string)$ini->variable( 'RepositorySettings', 'RemotePackagesIndexURLBase' ) );
            // ExponentialSDK in Exponential 6, eZPublishSDK before it.
            $sdk = class_exists( 'ExponentialSDK' ) ? 'ExponentialSDK' : 'eZPublishSDK';
            if ( $base !== '' && class_exists( $sdk ) )
            {
                $url = rtrim( $base, '/' ) . '/' . $sdk::version( false, false, false ) . '/' . $sdk::version();
            }
        }
        return rtrim( $url, '/' );
    }

    public static function validate( $name, $url )
    {
        if ( !is_string( $name ) || !preg_match( self::NAME_PATTERN, $name ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The name may use letters, digits, dot, dash and underscore.' );
        }
        if ( $name === 'exponential' )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'This name is reserved for the server in package.ini.' );
        }
        if ( !is_string( $url ) || strpos( $url, 'https://' ) !== 0 || filter_var( $url, FILTER_VALIDATE_URL ) === false )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The address must be an https:// URL.' );
        }
        return false;
    }

    /**
     * Adds or replaces a server. Returns true, or false with $this->error set.
     */
    public function add( $name, $url )
    {
        $url = rtrim( trim( (string)$url ), '/' );
        $error = self::validate( $name, $url );
        if ( $error !== false )
        {
            $this->error = $error;
            return false;
        }
        return $this->writeServer( $name, $url );
    }

    public function remove( $name )
    {
        if ( !is_string( $name ) || !preg_match( self::NAME_PATTERN, $name ) )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'The name may use letters, digits, dot, dash and underscore.' );
            return false;
        }
        return $this->writeServer( $name, null );
    }

    private function writeServer( $name, $url )
    {
        $ini = self::overrideINI();
        $servers = $ini->hasVariable( 'PackageServerSettings', 'Servers' )
            ? (array)$ini->variable( 'PackageServerSettings', 'Servers' ) : array();
        if ( $url === null )
        {
            unset( $servers[$name] );
        }
        else
        {
            $servers[$name] = $url;
        }
        $ini->setVariable( 'PackageServerSettings', 'Servers', $servers );
        if ( !$ini->save() )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'Could not write %file.', null,
                                         array( '%file' => self::OVERRIDE_DIR . '/' . self::OVERRIDE_FILE ) );
            return false;
        }
        return true;
    }

    /**
     * The packages a server offers.
     *
     * @return array|false name => hash name, type, url, summary, version,
     *                     local_version (false when not in the local repository)
     */
    public function packages( $serverName )
    {
        $servers = $this->servers();
        if ( !isset( $servers[$serverName] ) )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'Unknown package server.' );
            return false;
        }
        $xml = self::download( $servers[$serverName]['url'] . '/index.xml', 1048576, $this->error );
        if ( $xml === false )
        {
            return false;
        }

        $dom = new DOMDocument( '1.0', 'utf-8' );
        $previous = libxml_use_internal_errors( true );
        $loaded = $dom->loadXML( $xml, LIBXML_NONET );
        libxml_use_internal_errors( $previous );
        if ( !$loaded || $dom->documentElement->localName !== 'packages' )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'The server did not answer with a package index.' );
            return false;
        }

        $packages = array();
        foreach ( $dom->documentElement->childNodes as $node )
        {
            if ( $node->nodeType !== XML_ELEMENT_NODE || $node->localName !== 'package' )
            {
                continue;
            }
            $name = $node->getAttribute( 'name' );
            if ( !preg_match( self::NAME_PATTERN, $name ) )
            {
                continue;
            }
            $local = eZPackage::fetch( $name, false, false, false );
            $packages[$name] = array(
                'name'          => $name,
                'type'          => $node->getAttribute( 'type' ),
                'url'           => $node->getAttribute( 'url' ),
                'summary'       => $node->getAttribute( 'summary' ),
                'version'       => $node->getAttribute( 'version' ),
                'local_version' => $local instanceof eZPackage ? $local->getVersion() : false,
            );
        }
        ksort( $packages );
        return $packages;
    }

    /**
     * Downloads a package from a server and imports it into the local package
     * repository. Returns the eZPackage, or false with $this->error set.
     */
    public function fetchPackage( $serverName, $packageName, $replace = false )
    {
        $packages = $this->packages( $serverName );
        if ( $packages === false )
        {
            return false;
        }
        if ( !isset( $packages[$packageName] ) )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'The server does not offer this package.' );
            return false;
        }
        $url = $packages[$packageName]['url'];
        if ( strpos( $url, 'https://' ) !== 0 )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'The package address must be an https:// URL.' );
            return false;
        }

        $existing = eZPackage::fetch( $packageName, false, false, false );
        if ( $existing instanceof eZPackage )
        {
            if ( !$replace )
            {
                $this->error = ezpI18n::tr( 'extension/ezupdate', 'The package is already in the local repository.' );
                return false;
            }
            $existing->remove();
        }

        $data = self::download( $url, 268435456, $this->error );
        if ( $data === false )
        {
            return false;
        }
        $dir = eZSys::cacheDirectory() . '/ezupdate';
        eZDir::mkdir( $dir, false, true );
        $file = $dir . '/' . $packageName . '.ezpkg';
        if ( file_put_contents( $file, $data ) === false )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'Could not write %file.', null, array( '%file' => $file ) );
            return false;
        }

        $importName = $packageName;
        $package = eZPackage::import( $file, $importName );
        @unlink( $file );
        if ( !$package instanceof eZPackage )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'The file is not a valid package.' );
            return false;
        }
        return $package;
    }

    /**
     * GETs an https URL with curl: time limits, a size limit, redirects only to https.
     *
     * @return string|false the body, or false with $error set
     */
    public static function download( $url, $maxBytes, &$error )
    {
        if ( !function_exists( 'curl_init' ) )
        {
            $error = ezpI18n::tr( 'extension/ezupdate', 'The PHP curl extension is needed to reach a server.' );
            return false;
        }
        $body = '';
        $curl = curl_init( $url );
        curl_setopt_array( $curl, array(
            CURLOPT_PROTOCOLS       => CURLPROTO_HTTPS,
            CURLOPT_REDIR_PROTOCOLS => CURLPROTO_HTTPS,
            CURLOPT_FOLLOWLOCATION  => true,
            CURLOPT_MAXREDIRS       => 5,
            CURLOPT_CONNECTTIMEOUT  => 15,
            CURLOPT_TIMEOUT         => 300,
            CURLOPT_FAILONERROR     => true,
            CURLOPT_USERAGENT       => 'Exponential ezupdate',
            CURLOPT_WRITEFUNCTION   => function ( $curl, $chunk ) use ( &$body, $maxBytes )
            {
                if ( strlen( $body ) + strlen( $chunk ) > $maxBytes )
                {
                    return 0; // abort: too large
                }
                $body .= $chunk;
                return strlen( $chunk );
            },
        ) );
        $proxy = eZINI::instance()->hasVariable( 'ProxySettings', 'ProxyServer' ) ? eZINI::instance()->variable( 'ProxySettings', 'ProxyServer' ) : '';
        if ( $proxy )
        {
            curl_setopt( $curl, CURLOPT_PROXY, $proxy );
        }
        $ok = curl_exec( $curl );
        if ( $ok === false )
        {
            $error = ezpI18n::tr( 'extension/ezupdate', 'Could not fetch %url: %reason', null,
                                   array( '%url' => $url, '%reason' => curl_error( $curl ) ) );
            curl_close( $curl );
            return false;
        }
        curl_close( $curl );
        return $body;
    }
}
