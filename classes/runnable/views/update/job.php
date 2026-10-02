<?php
/**
 * The code of extension/ezupdate/modules/update/job.php, moved into a class (#207 stage 1). The file extension/ezupdate/modules/update/job.php is one call to it.
 * Guide: doc/bc/6.0/cli_cronjob_view_abstractions.md
 */
/*
 * The original header of extension/ezupdate/modules/update/job.php:
 *
 *
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * A background Composer run: update/job/<id> shows it, update/job/<id>/json is
 * what the page polls for the output while the run is going on. A finished run
 * can be started again, and a dry run can be run for real.
 *
 */

namespace Exponential\View\Extension\Ezupdate\Update
{

class Job extends \Exponential\Runnable\ModuleView
{
    public function run( array $scope )
    {
        // the including function's variables ($Params, $Module, $cli, ...)
        foreach ( array_keys( $scope ) as $__name )
            if ( $__name !== 'this' && $__name !== 'scope' )
                ${$__name} = &$scope[$__name];
        unset( $__name );

        require_once $this->scriptDir() . '/classes.php';

        $module = $Params['Module'];
        $job    = \eZUpdateJob::fetch( (string)$Params['JobID'] );

        if ( !$job )
        {
            return $this->viewResult( isset( $Result ) ? $Result : null,  $module->handleError( \eZError::KERNEL_NOT_FOUND, 'kernel' ) );
        }

        $manager   = \eZUpdateManager::getInstance();
        $user      = \eZUser::currentUser();
        $access    = $user->hasAccessTo( 'update', 'manage' );
        $canManage = $access['accessWord'] !== 'no';
        $error     = null;

        // Run again, or run a dry run for real: the same checks as the dashboard and
        // the package page, and a new job built from what this one did.
        if ( $module->isCurrentAction( 'Rerun' ) || $module->isCurrentAction( 'RunForReal' ) )
        {
            $plan = $job->rerunPlan( $module->isCurrentAction( 'RunForReal' ) );
            if ( is_string( $plan ) )
            {
                $error = $plan;
            }
            else if ( $plan['changes'] && strpos( $plan['kind'], 'update' ) === 0 && ( !$canManage || !$manager->isUpdateAllowed() ) )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Updating is switched off ([UpdateSettings] AllowUpdate in ezupdate.ini).' );
            }
            else if ( $plan['changes'] && strpos( $plan['kind'], 'require' ) === 0 && ( !$canManage || !$manager->isInstallAllowed() ) )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Installing is switched off ([UpdateSettings] AllowInstall in ezupdate.ini).' );
            }
            else if ( $plan['changes'] && !$module->hasActionParameter( 'ConfirmBackup' ) )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Confirm that a backup exists before this run.' );
            }
            else
            {
                $new = \eZUpdateJob::start( $plan['kind'], $plan['arguments'], $plan['label'] );
                if ( $new instanceof \eZUpdateJob )
                {
                    return $this->viewResult( isset( $Result ) ? $Result : null,  $module->redirectTo( 'update/job/' . $new->data['id'] ) );
                }
                $error = $new;
            }
        }

        $progress = $job->progress();

        if ( $Params['Format'] === 'json' )
        {
            header( 'Content-Type: application/json; charset=utf-8' );
            header( 'Cache-Control: no-store' );
            echo json_encode( $progress );
            \eZExecution::cleanExit();
        }

        $kind = (string)$job->data['kind'];
        $plan = $job->rerunPlan( false );

        $tpl = \eZTemplate::factory();
        $tpl->setVariable( 'job', $job->data );
        $tpl->setVariable( 'progress', $progress );
        $tpl->setVariable( 'error', $error );
        $tpl->setVariable( 'job_running', \eZUpdateJob::isRunning() );
        $tpl->setVariable( 'can_rerun', is_array( $plan ) );
        $tpl->setVariable( 'rerun_changes', is_array( $plan ) && $plan['changes'] );
        $tpl->setVariable( 'is_dry_run', substr( $kind, -8 ) === '-dry-run' );
        $tpl->setVariable( 'can_change', $canManage && ( strpos( $kind, 'update' ) === 0 ? $manager->isUpdateAllowed() : $manager->isInstallAllowed() ) );

        $Result = array();
        $Result['content'] = $tpl->fetch( 'design:ezupdate/job.tpl' );
        $Result['path']    = array(
            array( 'text' => \ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => 'update/dashboard' ),
            array( 'text' => $job->data['label'], 'url' => false ),
        );

        return $this->viewResult( isset( $Result ) ? $Result : null, null );
    }
}

}
