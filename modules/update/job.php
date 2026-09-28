<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * A background Composer run: update/job/<id> shows it, update/job/<id>/json is
 * what the page polls for the output while the run is going on.
 **/

require_once __DIR__ . '/classes.php';

$module = $Params['Module'];
$job    = eZUpdateJob::fetch( (string)$Params['JobID'] );

if ( !$job )
{
    return $module->handleError( eZError::KERNEL_NOT_FOUND, 'kernel' );
}

$progress = $job->progress();

if ( $Params['Format'] === 'json' )
{
    header( 'Content-Type: application/json; charset=utf-8' );
    header( 'Cache-Control: no-store' );
    echo json_encode( $progress );
    eZExecution::cleanExit();
}

$tpl = eZTemplate::factory();
$tpl->setVariable( 'job', $job->data );
$tpl->setVariable( 'progress', $progress );

$Result = array();
$Result['content'] = $tpl->fetch( 'design:ezupdate/job.tpl' );
$Result['path']    = array(
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => 'update/dashboard' ),
    array( 'text' => $job->data['label'], 'url' => false ),
);
