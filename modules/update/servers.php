<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * The package servers: Composer repositories (composer.json) and Exponential
 * .ezpkg servers (settings/override/ezupdate.ini.append.php).
 **/

require_once __DIR__ . '/classes.php';

$module   = $Params['Module'];
$http     = eZHTTPTool::instance();
$manager  = eZUpdateManager::getInstance();
$composer = new eZUpdateComposerServers( $manager );
$ezpkg    = new eZUpdatePackageServers();
$error    = null;
$message  = null;

$post = function ( $name ) use ( $http )
{
    return $http->hasPostVariable( $name ) ? trim( (string)$http->postVariable( $name ) ) : '';
};
// A Composer run answers an array; validation answers a text.
$composerResult = function ( $result, $done ) use ( &$error, &$message )
{
    if ( is_string( $result ) )
    {
        $error = $result;
    }
    else if ( $result['exit'] !== 0 )
    {
        $error = $result['output'];
    }
    else
    {
        $message = $done;
    }
};

if ( $module->isCurrentAction( 'AddComposerServer' ) )
{
    $composerResult( $composer->add( $post( 'ServerName' ), $post( 'ServerType' ), $post( 'ServerURL' ) ),
                     ezpI18n::tr( 'extension/ezupdate', 'The Composer server was added to composer.json.' ) );
}
else if ( $module->isCurrentAction( 'RemoveComposerServer' ) )
{
    $composerResult( $composer->remove( $post( 'ServerName' ) ),
                     ezpI18n::tr( 'extension/ezupdate', 'The Composer server was removed from composer.json.' ) );
}
else if ( $module->isCurrentAction( 'PackagistOn' ) || $module->isCurrentAction( 'PackagistOff' ) )
{
    $composerResult( $composer->setPackagistEnabled( $module->isCurrentAction( 'PackagistOn' ) ),
                     ezpI18n::tr( 'extension/ezupdate', 'composer.json was changed.' ) );
}
else if ( $module->isCurrentAction( 'AddPackageServer' ) )
{
    if ( $ezpkg->add( $post( 'ServerName' ), $post( 'ServerURL' ) ) )
    {
        $message = ezpI18n::tr( 'extension/ezupdate', 'The package server was added.' );
    }
    else
    {
        $error = $ezpkg->error;
    }
}
else if ( $module->isCurrentAction( 'RemovePackageServer' ) )
{
    if ( $ezpkg->remove( $post( 'ServerName' ) ) )
    {
        $message = ezpI18n::tr( 'extension/ezupdate', 'The package server was removed.' );
    }
    else
    {
        $error = $ezpkg->error;
    }
}

$tpl = eZTemplate::factory();
$tpl->setVariable( 'error', $error );
$tpl->setVariable( 'message', $message );
$tpl->setVariable( 'composer_servers', $composer->servers() );
$tpl->setVariable( 'composer_types', eZUpdateComposerServers::$types );
$tpl->setVariable( 'packagist_enabled', $composer->packagistEnabled() );
$tpl->setVariable( 'package_servers', $ezpkg->servers() );
$tpl->setVariable( 'composer_json_writable', is_writable( $manager->projectPath() . '/composer.json' ) );
$tpl->setVariable( 'override_file', eZUpdatePackageServers::OVERRIDE_DIR . '/' . eZUpdatePackageServers::OVERRIDE_FILE );

$Result = array();
$Result['content'] = $tpl->fetch( 'design:ezupdate/servers.tpl' );
$Result['path']    = array(
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => 'update/dashboard' ),
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Package servers' ), 'url' => false ),
);
