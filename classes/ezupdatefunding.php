<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * Who the installed packages ask to be funded by: what "composer fund" shows,
 * read without running Composer, and more.
 *
 * Two sources, for every package vendor/composer/installed.json lists:
 * - the package's "funding" metadata (composer.json, or what Packagist derives
 *   from the repository), which is what "composer fund" reads;
 * - the package's .github/FUNDING.yml, GitHub's own file, which many packages
 *   carry without repeating it in composer.json. The installation's own
 *   extensions, checked out from git, are among them.
 *
 * Only http and https links are kept. Links are grouped the way "composer
 * fund" groups them: by vendor, then by link, with the packages each supports.
 */
class eZUpdateFunding
{
    /** FUNDING.yml platform => address of an account on it (%s: the account). */
    private static $platforms = array(
        'github'           => 'https://github.com/sponsors/%s',
        'patreon'          => 'https://www.patreon.com/%s',
        'open_collective'  => 'https://opencollective.com/%s',
        'ko_fi'            => 'https://ko-fi.com/%s',
        'tidelift'         => 'https://tidelift.com/funding/github/%s',
        'community_bridge' => 'https://funding.communitybridge.org/projects/%s',
        'liberapay'        => 'https://liberapay.com/%s',
        'issuehunt'        => 'https://issuehunt.io/r/%s',
        'lfx_crowdfunding' => 'https://crowdfunding.lfx.linuxfoundation.org/projects/%s',
        'polar'            => 'https://polar.sh/%s',
        'buy_me_a_coffee'  => 'https://www.buymeacoffee.com/%s',
        'thanks_dev'       => 'https://thanks.dev/%s',
        'otechie'          => 'https://otechie.com/%s',
    );

    /** Link type => how it is named on the page. */
    private static $labels = array(
        'github' => 'GitHub Sponsors', 'patreon' => 'Patreon', 'open_collective' => 'Open Collective',
        'opencollective' => 'Open Collective', 'ko_fi' => 'Ko-fi', 'tidelift' => 'Tidelift',
        'community_bridge' => 'LFX Mentorship', 'liberapay' => 'Liberapay', 'issuehunt' => 'IssueHunt',
        'lfx_crowdfunding' => 'LFX Crowdfunding', 'polar' => 'Polar', 'buy_me_a_coffee' => 'Buy Me a Coffee',
        'thanks_dev' => 'thanks.dev', 'otechie' => 'Otechie', 'custom' => 'Website', 'other' => 'Other',
    );

    /** @var eZUpdateManager */
    private $manager;

    public function __construct( eZUpdateManager $manager )
    {
        $this->manager = $manager;
    }

    /**
     * Every installed package with its funding links.
     *
     * @return array name => array( 'name', 'version', 'direct', 'links' =>
     *               array( array( 'type', 'url', 'from' ) ) )
     */
    public function packages()
    {
        $file = $this->manager->projectPath() . '/vendor/composer/installed.json';
        $data = is_file( $file ) ? json_decode( (string)file_get_contents( $file ), true ) : null;
        if ( !is_array( $data ) )
            return array();
        $direct = $this->directDependencies();

        $result = array();
        foreach ( isset( $data['packages'] ) ? $data['packages'] : $data as $package )
        {
            if ( !isset( $package['name'] ) || !is_string( $package['name'] ) )
                continue;
            $links = array();
            foreach ( isset( $package['funding'] ) && is_array( $package['funding'] ) ? $package['funding'] : array() as $entry )
            {
                if ( is_array( $entry ) && isset( $entry['url'] ) )
                    self::add( $links, isset( $entry['type'] ) ? (string)$entry['type'] : 'other', (string)$entry['url'], 'composer' );
            }
            $path = isset( $package['install-path'] ) ? realpath( dirname( $file ) . '/' . $package['install-path'] ) : false;
            if ( $path && is_file( $path . '/.github/FUNDING.yml' ) )
            {
                foreach ( self::fundingYml( (string)file_get_contents( $path . '/.github/FUNDING.yml' ) ) as $entry )
                    self::add( $links, $entry['type'], $entry['url'], 'FUNDING.yml' );
            }
            $result[$package['name']] = array(
                'name'    => $package['name'],
                'version' => isset( $package['version'] ) ? (string)$package['version'] : '',
                'direct'  => isset( $direct[$package['name']] ),
                'links'   => array_values( $links ),
            );
        }
        ksort( $result );
        return $result;
    }

    /**
     * The funding of one package, or an empty list.
     */
    public function forPackage( $name )
    {
        $packages = $this->packages();
        return isset( $packages[$name] ) ? $packages[$name]['links'] : array();
    }

    /**
     * As "composer fund" lists it: vendor => link => the packages it funds.
     *
     * @param bool $directOnly only the packages composer.json requires itself
     * @return array vendor => array( 'vendor', 'links' => array( array( 'type',
     *               'url', 'from', 'packages' => array( name ... ) ) ) )
     */
    public function byVendor( $directOnly = false )
    {
        $vendors = array();
        foreach ( $this->packages() as $package )
        {
            if ( $directOnly && !$package['direct'] )
                continue;
            $vendor = strstr( $package['name'], '/', true );
            $vendor = $vendor === false ? $package['name'] : $vendor;
            foreach ( $package['links'] as $link )
            {
                if ( !isset( $vendors[$vendor]['links'][$link['url']] ) )
                    $vendors[$vendor]['links'][$link['url']] = $link + array( 'packages' => array() );
                $vendors[$vendor]['links'][$link['url']]['packages'][] = $package['name'];
            }
        }
        ksort( $vendors );
        foreach ( $vendors as $vendor => $entry )
        {
            $vendors[$vendor] = array( 'vendor' => $vendor, 'links' => array_values( $entry['links'] ) );
        }
        return $vendors;
    }

    /**
     * Counts: packages, packages with funding, vendors, distinct links.
     */
    public function summary( $directOnly = false )
    {
        $packages = 0;
        $funded = 0;
        $urls = array();
        foreach ( $this->packages() as $package )
        {
            if ( $directOnly && !$package['direct'] )
                continue;
            $packages++;
            if ( $package['links'] )
                $funded++;
            foreach ( $package['links'] as $link )
                $urls[$link['url']] = true;
        }
        return array( 'packages' => $packages, 'funded' => $funded,
                      'vendors' => count( $this->byVendor( $directOnly ) ), 'links' => count( $urls ) );
    }

    /**
     * The same as "composer fund" prints: vendor, then its links, each with
     * the packages it funds.
     */
    public function asText( $directOnly = false )
    {
        $lines = array();
        foreach ( $this->byVendor( $directOnly ) as $vendor )
        {
            $lines[] = $vendor['vendor'];
            foreach ( $vendor['links'] as $link )
            {
                $names = array();
                foreach ( $link['packages'] as $name )
                    $names[] = substr( $name, strlen( $vendor['vendor'] ) + 1 );
                $lines[] = '  ' . implode( ', ', $names );
                $lines[] = '    ' . $link['url'];
            }
            $lines[] = '';
        }
        return implode( "\n", $lines );
    }

    /**
     * The funding links of a .github/FUNDING.yml. A small reader for the
     * file's one shape: "key: value" or "key: [a, b]" or a "- item" list under
     * a key, comments with #.
     *
     * @return array array( array( 'type', 'url' ) )
     */
    public static function fundingYml( $text )
    {
        $values = array();
        $key = null;
        foreach ( preg_split( '/\r\n|\r|\n/', (string)$text ) as $line )
        {
            $line = preg_replace( '/\s+#.*$|^\s*#.*$/', '', $line );
            if ( trim( $line ) === '' )
                continue;
            if ( preg_match( '/^([a-z_]+)\s*:\s*(.*)$/', $line, $m ) )
            {
                $key = $m[1];
                $values[$key] = self::ymlItems( $m[2] );
            }
            else if ( $key !== null && preg_match( '/^\s+-\s*(.+)$/', $line, $m ) )
            {
                $values[$key] = array_merge( $values[$key], self::ymlItems( $m[1] ) );
            }
        }
        $links = array();
        foreach ( $values as $platform => $items )
        {
            foreach ( $items as $item )
            {
                if ( $platform === 'custom' && preg_match( '#^https?://#i', $item ) )
                    $links[] = array( 'type' => 'custom', 'url' => $item );
                else if ( isset( self::$platforms[$platform] ) && preg_match( '#^[A-Za-z0-9_./-]+$#', $item ) )
                    $links[] = array( 'type' => $platform, 'url' => sprintf( self::$platforms[$platform], $item ) );
            }
        }
        return $links;
    }

    /** A YAML scalar or inline list, as a list of strings without quotes. */
    private static function ymlItems( $value )
    {
        $value = trim( $value );
        if ( $value === '' || $value === '~' || strtolower( $value ) === 'null' )
            return array();
        if ( $value[0] === '[' )
            $value = trim( $value, '[] ' );
        $items = array();
        foreach ( explode( ',', $value ) as $item )
        {
            $item = trim( trim( $item ), '"\'' );
            if ( $item !== '' )
                $items[] = $item;
        }
        return $items;
    }

    /** Adds a link, once per address, when it is an http or https one. */
    private static function add( array &$links, $type, $url, $from )
    {
        $url = trim( $url );
        if ( !preg_match( '#^https?://[^\s<>"]+$#i', $url ) )
            return;
        $key = rtrim( strtolower( $url ), '/' );
        if ( isset( $links[$key] ) )
        {
            if ( strpos( $links[$key]['from'], $from ) === false )
                $links[$key]['from'] .= ', ' . $from;
            return;
        }
        $type = $type !== '' ? strtolower( $type ) : 'other';
        $links[$key] = array( 'type' => $type, 'label' => isset( self::$labels[$type] ) ? self::$labels[$type] : ucfirst( $type ),
                              'url' => $url, 'host' => (string)parse_url( $url, PHP_URL_HOST ), 'from' => $from );
    }

    /** The packages composer.json requires itself (require and require-dev). */
    private function directDependencies()
    {
        $file = $this->manager->projectPath() . '/composer.json';
        $json = is_file( $file ) ? json_decode( (string)file_get_contents( $file ), true ) : null;
        $direct = array();
        foreach ( array( 'require', 'require-dev' ) as $section )
        {
            if ( isset( $json[$section] ) && is_array( $json[$section] ) )
                $direct += array_fill_keys( array_keys( $json[$section] ), true );
        }
        return $direct;
    }
}
