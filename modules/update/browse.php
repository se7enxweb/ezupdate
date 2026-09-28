<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * Find packages: packagist.org search (with a type filter) and `composer search`
 * over the Composer servers of the installation.
 **/

require_once __DIR__ . '/classes.php';

$http     = eZHTTPTool::instance();
$manager  = eZUpdateManager::getInstance();
$packagist = new eZUpdatePackagist();

$query  = $http->hasGetVariable( 'q' ) ? trim( (string)$http->getVariable( 'q' ) ) : '';
$source = $http->hasGetVariable( 'source' ) && $http->getVariable( 'source' ) === 'composer' ? 'composer' : 'packagist';
$types  = $packagist->types();
$type   = $http->hasGetVariable( 'type' ) ? (string)$http->getVariable( 'type' ) : (string)key( $types );
if ( !array_key_exists( $type, $types ) )
{
    $type = (string)key( $types );
}
$page   = isset( $Params['Page'] ) ? max( 1, (int)$Params['Page'] ) : 1;
$result = null;
$error  = null;

if ( $source === 'packagist' && ( $query !== '' || $type !== '' ) )
{
    $result = $packagist->search( $query, $type, $page );
    if ( $result === false )
    {
        $error = $packagist->error;
    }
}
else if ( $source === 'composer' && $query !== '' )
{
    $list = $manager->search( $query );
    if ( $list === false )
    {
        $error = ezpI18n::tr( 'extension/ezupdate', 'Composer could not search.' );
    }
    else
    {
        $result = array( 'results' => $list, 'total' => count( $list ), 'page' => 1, 'pages' => 1 );
    }
}

$tpl = eZTemplate::factory();
$tpl->setVariable( 'query', $query );
$tpl->setVariable( 'query_string', http_build_query( array( 'q' => $query, 'source' => $source, 'type' => $type ) ) );
$tpl->setVariable( 'source', $source );
$tpl->setVariable( 'type', $type );
$tpl->setVariable( 'types', $types );
$tpl->setVariable( 'result', $result );
$tpl->setVariable( 'error', $error );
$tpl->setVariable( 'installed', $manager->installedPackages() );
$tpl->setVariable( 'packagist_url', $packagist->baseURL() );

$Result = array();
$Result['content'] = $tpl->fetch( 'design:ezupdate/browse.tpl' );
$Result['path']    = array(
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => 'update/dashboard' ),
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Find packages' ), 'url' => false ),
);
