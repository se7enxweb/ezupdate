<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * The packages of an Exponential .ezpkg server, and fetching one into the local
 * package repository. Installing it is done with the kernel's package views.
 **/

require_once __DIR__ . '/classes.php';

$module  = $Params['Module'];
$http    = eZHTTPTool::instance();
$servers = new eZUpdatePackageServers();
$list    = $servers->servers();
$server  = isset( $Params['Server'] ) && $Params['Server'] !== '' ? $Params['Server'] : (string)key( $list );
$error   = null;
$message = null;

if ( !isset( $list[$server] ) )
{
    return $module->handleError( eZError::KERNEL_NOT_FOUND, 'kernel' );
}

if ( $module->isCurrentAction( 'FetchPackage' ) )
{
    $user = eZUser::currentUser();
    $access = $user->hasAccessTo( 'update', 'manage' );
    $name = $http->hasPostVariable( 'PackageName' ) ? (string)$http->postVariable( 'PackageName' ) : '';
    if ( $access['accessWord'] === 'no' )
    {
        return $module->handleError( eZError::KERNEL_ACCESS_DENIED, 'kernel' );
    }
    $package = $servers->fetchPackage( $server, $name, $http->hasPostVariable( 'Replace' ) );
    if ( $package instanceof eZPackage )
    {
        $message = ezpI18n::tr( 'extension/ezupdate', 'The package %package %version is in the local package repository now.', null,
                                array( '%package' => $package->attribute( 'name' ), '%version' => $package->getVersion() ) );
    }
    else
    {
        $error = $servers->error;
    }
}

$packages = $servers->packages( $server );
if ( $packages === false && $error === null )
{
    $error = $servers->error;
}

$user = eZUser::currentUser();
$access = $user->hasAccessTo( 'update', 'manage' );

$tpl = eZTemplate::factory();
$tpl->setVariable( 'server', $list[$server] );
$tpl->setVariable( 'servers', $list );
$tpl->setVariable( 'packages', $packages ? $packages : array() );
$tpl->setVariable( 'error', $error );
$tpl->setVariable( 'message', $message );
$tpl->setVariable( 'can_manage', $access['accessWord'] !== 'no' );

$Result = array();
$Result['content'] = $tpl->fetch( 'design:ezupdate/packages.tpl' );
$Result['path']    = array(
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => 'update/dashboard' ),
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Package servers' ), 'url' => 'update/servers' ),
    array( 'text' => $server, 'url' => false ),
);
