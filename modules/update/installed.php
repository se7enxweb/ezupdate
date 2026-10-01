<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    01 Oct 2026
 *
 * Installed packages: composer.json, composer.lock, vendor/composer/installed.json
 * and the extension directories matched up, with which extensions the settings
 * switch on (eZUpdateInventory). Read only. No function or class is declared
 * here, so the view can run many times in one PHP process.
 **/

require_once __DIR__ . '/classes.php';

$manager = eZUpdateManager::getInstance();
$inventory = new eZUpdateInventory( $manager );
$data = $inventory->build();

// update/installed/json and update/installed/csv: the same rows as a download
$format = isset( $Params['Format'] ) ? (string)$Params['Format'] : '';
if ( $format === 'json' || $format === 'csv' )
{
    $file = 'installed-packages-' . date( 'Ymd-His' ) . '.' . $format;
    $rows = array();
    foreach ( $data['rows'] as $row )
    {
        $rows[] = array(
            'name'      => $row['name'],
            'kind'      => $row['kind'],
            'composer'  => $row['composer'],
            'required'  => $row['required'],
            'dev'       => $row['dev'],
            'locked'    => $row['locked'],
            'installed' => $row['installed'] !== '' ? $row['installed'] : $row['ext_version'],
            'method'    => $row['method'],
            'path'      => $row['path'],
            'extension' => $row['extension'] ? $row['extension'] : '',
            'active'    => implode( ' ', $row['active'] ),
            'git'       => $row['git'] ? trim( $row['git']['branch'] . '@' . $row['git']['commit'], '@' ) : '',
            'issues'    => implode( '; ', array_map( function ( $issue ) { return $issue[1]; }, $row['issues'] ) ),
        );
    }
    while ( @ob_end_clean() );
    header( 'Content-Disposition: attachment; filename="' . $file . '"' );
    if ( $format === 'json' )
    {
        header( 'Content-Type: application/json; charset=utf-8' );
        echo json_encode( array( 'generated' => date( DATE_ATOM ), 'summary' => $data['summary'], 'packages' => $rows ),
                          JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ), "\n";
    }
    else
    {
        header( 'Content-Type: text/csv; charset=utf-8' );
        $out = fopen( 'php://output', 'w' );
        fputcsv( $out, array_keys( reset( $rows ) ?: array( 'name' => '' ) ), ',', '"', '\\' );
        foreach ( $rows as $row )
        {
            $row['composer'] = $row['composer'] ? 'yes' : 'no';
            $row['dev'] = $row['dev'] ? 'yes' : 'no';
            fputcsv( $out, $row, ',', '"', '\\' );
        }
        fclose( $out );
    }
    eZExecution::cleanExit();
}

$tpl = eZTemplate::factory();
$tpl->setVariable( 'rows', $data['rows'] );
$tpl->setVariable( 'summary', $data['summary'] );
$tpl->setVariable( 'sources', $data['sources'] );
$tpl->setVariable( 'project_path', $manager->projectPath() );
$tpl->setVariable( 'has_composer_json', $manager->hasComposerJson() );

$Result = array();
$Result['content'] = $tpl->fetch( 'design:ezupdate/installed.tpl' );
$Result['path']    = array(
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => 'update/dashboard' ),
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Installed packages' ), 'url' => false ),
);
