<?php
/**
 * @package eZUpdate
 * @class   eZUpdateComposerServers
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 **/

/**
 * The Composer package servers of the installation: the "repositories" of its
 * composer.json. That file is what Composer itself reads, so the list shown in
 * the admin, the command line and Composer can never disagree. Changes are made
 * with `composer config`, which keeps the file's formatting.
 */
class eZUpdateComposerServers
{
    const NAME_PATTERN = '#^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$#';

    /** Server types that can be added from the admin. */
    public static $types = array( 'composer', 'vcs', 'git' );

    /** @var eZUpdateManager */
    private $manager;

    public function __construct( eZUpdateManager $manager )
    {
        $this->manager = $manager;
    }

    /**
     * Every repository composer.json names, in its order.
     *
     * @return array list of hashes name, type, url, removable (bool: it has a
     *               name `composer config --unset` can address)
     */
    public function servers()
    {
        $repositories = $this->repositories();
        $list = array();
        foreach ( $repositories as $key => $repository )
        {
            if ( !is_array( $repository ) )
            {
                continue; // "packagist.org": false, reported by packagistEnabled()
            }
            $named = is_string( $key );
            $list[] = array(
                'name'      => $named ? $key : ( isset( $repository['name'] ) ? (string)$repository['name'] : '#' . ( $key + 1 ) ),
                'type'      => isset( $repository['type'] ) ? (string)$repository['type'] : '',
                'url'       => isset( $repository['url'] ) ? (string)$repository['url'] : '',
                'removable' => $named || isset( $repository['name'] ),
            );
        }
        return $list;
    }

    /**
     * False when composer.json switches packagist.org off.
     */
    public function packagistEnabled()
    {
        foreach ( $this->repositories() as $key => $repository )
        {
            if ( in_array( $key, array( 'packagist', 'packagist.org' ), true ) && $repository === false )
            {
                return false;
            }
            if ( is_array( $repository ) && isset( $repository['packagist.org'] ) && $repository['packagist.org'] === false )
            {
                return false;
            }
        }
        return true;
    }

    private function repositories()
    {
        $file = $this->manager->projectPath() . '/composer.json';
        $data = is_file( $file ) ? json_decode( (string)file_get_contents( $file ), true ) : null;
        return is_array( $data ) && isset( $data['repositories'] ) && is_array( $data['repositories'] )
            ? $data['repositories'] : array();
    }

    /**
     * Checks a new server. Returns an error text, or false when it is valid.
     */
    public static function validate( $name, $type, $url )
    {
        if ( !is_string( $name ) || !preg_match( self::NAME_PATTERN, $name ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The name may use letters, digits, dot, dash and underscore.' );
        }
        if ( in_array( strtolower( $name ), array( 'packagist', 'packagist.org' ), true ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'This name is reserved for packagist.org.' );
        }
        if ( !in_array( $type, self::$types, true ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'Unknown server type.' );
        }
        if ( !is_string( $url ) || strpos( $url, 'https://' ) !== 0 || filter_var( $url, FILTER_VALIDATE_URL ) === false )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The address must be an https:// URL.' );
        }
        return false;
    }

    /**
     * Adds (or replaces) a named server. Returns the Composer run result, or an
     * error text when the input is not valid.
     */
    public function add( $name, $type, $url )
    {
        $error = self::validate( $name, $type, $url );
        if ( $error !== false )
        {
            return $error;
        }
        return $this->manager->run( array( 'config', 'repositories.' . $name, $type, $url ), 120 );
    }

    public function remove( $name )
    {
        if ( !is_string( $name ) || !preg_match( self::NAME_PATTERN, $name ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'The name may use letters, digits, dot, dash and underscore.' );
        }
        return $this->manager->run( array( 'config', '--unset', 'repositories.' . $name ), 120 );
    }

    /**
     * Switches packagist.org on or off for this installation.
     */
    public function setPackagistEnabled( $enabled )
    {
        return $enabled
            ? $this->manager->run( array( 'config', '--unset', 'repositories.packagist.org' ), 120 )
            : $this->manager->run( array( 'config', 'repositories.packagist.org', 'false' ), 120 );
    }
}
