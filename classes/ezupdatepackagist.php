<?php
/**
 * @package eZUpdate
 * @class   eZUpdatePackagist
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 **/

/**
 * Reads the packagist.org API to find and study packages before installing them:
 *
 *   https://packagist.org/search.json?q=&type=&page=&per_page=   search
 *   https://packagist.org/packages/<vendor>/<name>.json          details, downloads
 *
 * Answers are cached in the cache directory for [PackagistSettings] CacheTime
 * seconds, so browsing does not ask packagist.org again for every page view.
 */
class eZUpdatePackagist
{
    /** @var string Error text of the last failed call */
    public $error = '';

    /** @var eZINI */
    private $ini;

    public function __construct()
    {
        $this->ini = eZINI::instance( 'ezupdate.ini' );
    }

    private function setting( $name, $default )
    {
        return $this->ini->hasVariable( 'PackagistSettings', $name ) ? $this->ini->variable( 'PackagistSettings', $name ) : $default;
    }

    public function baseURL()
    {
        return rtrim( (string)$this->setting( 'URL', 'https://packagist.org' ), '/' );
    }

    /**
     * The package types offered in the search form: type => label.
     */
    public function types()
    {
        $types = (array)$this->setting( 'Types', array() );
        return $types ? $types : array( 'ezpublish-legacy-extension' => 'Extension', '' => 'Any' );
    }

    /**
     * @return array|false hash results (list of name, description, url,
     *                     repository, downloads, favers), total, page, pages
     */
    public function search( $query, $type = '', $page = 1 )
    {
        $query = trim( (string)$query );
        $type = (string)$type;
        $page = max( 1, (int)$page );
        if ( strlen( $query ) > 100 || ( $type !== '' && !preg_match( '#^[a-z0-9-]{1,64}$#', $type ) ) )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'The search is not valid.' );
            return false;
        }
        $perPage = max( 5, min( 100, (int)$this->setting( 'PerPage', 25 ) ) );
        $parameters = array( 'q' => $query, 'page' => $page, 'per_page' => $perPage );
        if ( $type !== '' )
        {
            $parameters['type'] = $type;
        }
        $data = $this->get( '/search.json?' . http_build_query( $parameters ) );
        if ( $data === false )
        {
            return false;
        }

        $results = array();
        foreach ( isset( $data['results'] ) ? $data['results'] : array() as $item )
        {
            $results[] = array(
                'name'        => isset( $item['name'] ) ? (string)$item['name'] : '',
                'description' => isset( $item['description'] ) ? (string)$item['description'] : '',
                'url'         => isset( $item['url'] ) ? (string)$item['url'] : '',
                'repository'  => isset( $item['repository'] ) ? (string)$item['repository'] : '',
                'downloads'   => isset( $item['downloads'] ) ? (int)$item['downloads'] : 0,
                'favers'      => isset( $item['favers'] ) ? (int)$item['favers'] : 0,
                'abandoned'   => !empty( $item['abandoned'] ),
            );
        }
        $total = isset( $data['total'] ) ? (int)$data['total'] : count( $results );
        return array(
            'results' => $results,
            'total'   => $total,
            'page'    => $page,
            'pages'   => max( 1, (int)ceil( $total / $perPage ) ),
        );
    }

    /**
     * @return array|false hash name, description, type, repository, homepage,
     *                     license, downloads (total, monthly, daily), favers,
     *                     abandoned, maintainers, versions (newest first: version,
     *                     time, license, require, description, stable)
     */
    public function package( $name )
    {
        if ( !eZUpdateManager::isPackageName( $name ) )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'This is not a package name.' );
            return false;
        }
        $data = $this->get( '/packages/' . $name . '.json' );
        if ( $data === false || !isset( $data['package'] ) )
        {
            return false;
        }
        $package = $data['package'];

        $versions = array();
        foreach ( isset( $package['versions'] ) ? $package['versions'] : array() as $key => $version )
        {
            $number = isset( $version['version'] ) ? (string)$version['version'] : (string)$key;
            $versions[] = array(
                'version'     => $number,
                'time'        => isset( $version['time'] ) ? strtotime( $version['time'] ) : 0,
                'license'     => isset( $version['license'] ) ? implode( ', ', (array)$version['license'] ) : '',
                'require'     => isset( $version['require'] ) && is_array( $version['require'] ) ? $version['require'] : array(),
                'description' => isset( $version['description'] ) ? (string)$version['description'] : '',
                'homepage'    => isset( $version['homepage'] ) ? (string)$version['homepage'] : '',
                'stable'      => strpos( $number, 'dev' ) === false && !preg_match( '#(alpha|beta|rc)#i', $number ),
                // Where "source" clones from (a git URL and the commit of this
                // version) and what "dist" downloads (an archive).
                'source'      => self::reference( isset( $version['source'] ) ? $version['source'] : null ),
                'dist'        => self::reference( isset( $version['dist'] ) ? $version['dist'] : null ),
            );
        }
        usort( $versions, function ( $a, $b ) { return $b['time'] - $a['time']; } );

        $latest = null;
        foreach ( $versions as $version )
        {
            if ( $version['stable'] )
            {
                $latest = $version;
                break;
            }
        }
        if ( $latest === null && $versions )
        {
            $latest = $versions[0];
        }

        $maintainers = array();
        foreach ( isset( $package['maintainers'] ) ? $package['maintainers'] : array() as $maintainer )
        {
            if ( isset( $maintainer['name'] ) )
            {
                $maintainers[] = (string)$maintainer['name'];
            }
        }

        return array(
            'name'        => (string)$package['name'],
            'description' => isset( $package['description'] ) ? (string)$package['description'] : '',
            'type'        => isset( $package['type'] ) ? (string)$package['type'] : '',
            'repository'  => isset( $package['repository'] ) ? (string)$package['repository'] : '',
            'homepage'    => $latest ? $latest['homepage'] : '',
            'license'     => $latest ? $latest['license'] : '',
            'latest'      => $latest ? $latest['version'] : '',
            'require'     => $latest ? $latest['require'] : array(),
            'source'      => $latest ? $latest['source'] : false,
            'dist'        => $latest ? $latest['dist'] : false,
            'downloads'   => array(
                'total'   => isset( $package['downloads']['total'] ) ? (int)$package['downloads']['total'] : 0,
                'monthly' => isset( $package['downloads']['monthly'] ) ? (int)$package['downloads']['monthly'] : 0,
                'daily'   => isset( $package['downloads']['daily'] ) ? (int)$package['downloads']['daily'] : 0,
            ),
            'favers'      => isset( $package['favers'] ) ? (int)$package['favers'] : 0,
            'abandoned'   => !empty( $package['abandoned'] ),
            'maintainers' => $maintainers,
            'versions'    => $versions,
            'url'         => $this->baseURL() . '/packages/' . $package['name'],
        );
    }

    private static function reference( $block )
    {
        if ( !is_array( $block ) || empty( $block['url'] ) )
        {
            return false;
        }
        $reference = isset( $block['reference'] ) ? (string)$block['reference'] : '';
        return array(
            'type'      => isset( $block['type'] ) ? (string)$block['type'] : '',
            'url'       => (string)$block['url'],
            'reference' => $reference,
            'short'     => preg_match( '#^[0-9a-f]{40}$#', $reference ) ? substr( $reference, 0, 10 ) : $reference,
        );
    }

    /**
     * GETs a JSON document from packagist, through the cache.
     */
    private function get( $path )
    {
        $cacheTime = (int)$this->setting( 'CacheTime', 900 );
        $cacheFile = eZSys::cacheDirectory() . '/ezupdate/packagist/' . md5( $this->baseURL() . $path ) . '.json';
        if ( $cacheTime > 0 && is_file( $cacheFile ) && filemtime( $cacheFile ) > time() - $cacheTime )
        {
            $data = json_decode( (string)file_get_contents( $cacheFile ), true );
            if ( is_array( $data ) )
            {
                return $data;
            }
        }

        $body = eZUpdatePackageServers::download( $this->baseURL() . $path, 8388608, $this->error );
        if ( $body === false )
        {
            return false;
        }
        $data = json_decode( $body, true );
        if ( !is_array( $data ) )
        {
            $this->error = ezpI18n::tr( 'extension/ezupdate', 'packagist.org did not answer with JSON.' );
            return false;
        }
        if ( $cacheTime > 0 )
        {
            eZFile::create( basename( $cacheFile ), dirname( $cacheFile ), $body, true );
        }
        return $data;
    }
}
