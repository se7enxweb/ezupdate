<?php
/**
 * The code of extension/ezupdate/modules/update/dashboard.php, moved into a class (#207 stage 1). The file extension/ezupdate/modules/update/dashboard.php is one call to it.
 * Guide: doc/bc/6.0/cli_cronjob_view_abstractions.md
 */
/*
 * The original header of extension/ezupdate/modules/update/dashboard.php:
 *
 *
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * The installation's Composer state: where Composer is, what may be run, the
 * packages that have a newer release, and the recent runs. No function or class
 * is declared here, so the view can run many times in one PHP process.
 *
 */

namespace Exponential\View\Extension\Ezupdate\Update
{

class Dashboard extends \Exponential\Runnable\ModuleView
{
    public function run( array $scope )
    {
        // the including function's variables ($Params, $Module, $cli, ...)
        foreach ( array_keys( $scope ) as $__name )
            if ( $__name !== 'this' && $__name !== 'scope' )
                ${$__name} = &$scope[$__name];
        unset( $__name );

        require_once $this->scriptDir() . '/classes.php';

        $module  = $Params['Module'];
        $manager = \eZUpdateManager::getInstance();
        $user    = \eZUser::currentUser();
        $access  = $user->hasAccessTo( 'update', 'manage' );
        $canManage = $access['accessWord'] !== 'no';
        $error   = null;
        $outdated = null;
        $method  = $manager->installMethod( $module->hasActionParameter( 'InstallMethod' ) ? (string)$module->actionParameter( 'InstallMethod' ) : null );

        $notice  = null;

        if ( $module->isCurrentAction( 'GetComposer' ) )
        {
            if ( !$canManage )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'You do not have permission to download Composer.' );
            }
            else
            {
                $result = $manager->downloadComposer();
                if ( $result === true )
                {
                    \eZAudit::writeAudit( 'ezupdate-get-composer', array( 'Composer file' => $manager->localComposerFile(), 'Comment' => 'composer.phar downloaded and verified against its SHA-256' ) );
                    $manager = \eZUpdateManager::getInstance();
                    $notice = \ezpI18n::tr( 'extension/ezupdate', 'Composer was downloaded to %file and verified against its SHA-256 checksum.', null, array( '%file' => $manager->localComposerFile() ) );
                }
                else
                {
                    $error = $result;
                }
            }
        }
        else if ( $module->isCurrentAction( 'CheckForUpdates' ) )
        {
            $outdated = $manager->outdatedWithInstallability( true );
            if ( $outdated === false )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Composer could not check for updates.' ) . "\n" . $manager->lastOutput();
            }
            else if ( !$outdated )
            {
                $notice = \ezpI18n::tr( 'extension/ezupdate', 'The installation is up to date! Update again soon to remain secure.' );
            }
        }
        else if ( $module->isCurrentAction( 'SwitchUpdatesOn' ) || $module->isCurrentAction( 'SwitchUpdatesOff' ) )
        {
            $on = $module->isCurrentAction( 'SwitchUpdatesOn' );
            if ( !$canManage )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'You do not have permission to change this setting.' );
            }
            else
            {
                // password again when [AuditConsoleSettings] ReauthForManage is on
                $gate = class_exists( 'expAuditReauth' )
                    ? \expAuditReauth::gate( $module, $on ? 'SwitchUpdatesOnButton' : 'SwitchUpdatesOffButton', 'update/dashboard', $on ? 'Switch on updates' : 'Switch off updates' )
                    : null;
                if ( $gate !== null )
                {
                    return $this->viewResult( isset( $Result ) ? $Result : null, $gate );
                }
                $written = $manager->setUpdateAllowed( $on );
                if ( $written === true )
                {
                    \eZAudit::writeAudit( 'ezupdate-switch-updates', array( 'Setting' => '[UpdateSettings] AllowUpdate', 'Value' => $on ? 'enabled' : 'disabled', 'File' => 'settings/override/ezupdate.ini.append.php' ) );
                    \eZCache::clearByTag( 'ini' );
                    return $this->viewResult( isset( $Result ) ? $Result : null, $module->redirectTo( 'update/dashboard' ) );
                }
                $error = $written;
            }
        }
        else if ( $module->isCurrentAction( 'DryRunUpdate' ) || $module->isCurrentAction( 'Update' ) || $module->isCurrentAction( 'InstallUpdates' ) )
        {
            $dryRun = $module->isCurrentAction( 'DryRunUpdate' );
            $packages = array();
            if ( $module->hasActionParameter( 'Packages' ) )
            {
                $packages = array_values( array_filter( (array)$module->actionParameter( 'Packages' ), 'is_string' ) );
            }
            if ( $module->isCurrentAction( 'InstallUpdates' ) && !$packages )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Tick at least one package to install.' );
            }
            else if ( !$dryRun && ( !$canManage || !$manager->isUpdateAllowed() ) )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Updating is switched off ([UpdateSettings] AllowUpdate in ezupdate.ini).' );
            }
            else if ( !$dryRun && !$module->hasActionParameter( 'ConfirmBackup' ) )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Confirm that a backup exists before updating.' );
            }
            else
            {
                $job = \eZUpdateJob::start(
                    $dryRun ? 'update-dry-run' : 'update',
                    $manager->updateArguments( $dryRun, $method, $packages ),
                    ( $dryRun ? \ezpI18n::tr( 'extension/ezupdate', 'Update, dry run' ) : \ezpI18n::tr( 'extension/ezupdate', 'Update' ) ) . ' (' . $method . ')' . ( $packages ? ', ' . count( $packages ) . ' ' . \ezpI18n::tr( 'extension/ezupdate', 'packages' ) : '' )
                );
                if ( $job instanceof \eZUpdateJob )
                {
                    return $this->viewResult( isset( $Result ) ? $Result : null,  $module->redirectTo( 'update/job/' . $job->data['id'] ) );
                }
                $error = $job;
            }
        }

        $composerServers = new \eZUpdateComposerServers( $manager );

        $tpl = \eZTemplate::factory();
        $tpl->setVariable( 'error', $error );
        $tpl->setVariable( 'notice', $notice );
        $tpl->setVariable( 'composer_not_found', $manager->composerBinary() ? '' : $manager->notFoundMessage() );
        $tpl->setVariable( 'composer_trusted', $manager->composerBinary() && $manager->isTrusted() );
        $tpl->setVariable( 'can_manage', $canManage );
        $tpl->setVariable( 'composer_binary', $manager->composerBinary() );
        $composerVersion = $manager->composerBinary() ? $manager->composerVersion() : false;
        $tpl->setVariable( 'composer_version', $composerVersion );
        // When Composer is there but does not start, say why.
        $tpl->setVariable( 'composer_problem', $manager->composerBinary() && $composerVersion === false ? $manager->lastOutput() : '' );
        $tpl->setVariable( 'php_binary', $manager->phpBinary() );
        $tpl->setVariable( 'project_path', $manager->projectPath() );
        $tpl->setVariable( 'has_composer_json', $manager->hasComposerJson() );
        $tpl->setVariable( 'composer_json_writable', is_writable( $manager->projectPath() . '/composer.json' ) );
        $tpl->setVariable( 'update_allowed', $manager->isUpdateAllowed() );
        $tpl->setVariable( 'install_allowed', $manager->isInstallAllowed() );
        $tpl->setVariable( 'installed_count', count( $manager->installedPackages() ) );
        $tpl->setVariable( 'composer_server_count', count( $composerServers->servers() ) );
        $tpl->setVariable( 'packagist_enabled', $composerServers->packagistEnabled() );
        $tpl->setVariable( 'outdated', $outdated );
        $tpl->setVariable( 'lock_mismatch', $manager->lockMismatch() );
        $tpl->setVariable( 'install_method', $method );
        $tpl->setVariable( 'install_methods', \eZUpdateManager::$installMethods );
        $jobs = \eZUpdateJob::fetchList( 10 );
        $tpl->setVariable( 'jobs', $jobs );
        $tpl->setVariable( 'last_job', $jobs ? reset( $jobs ) : false );
        // the Overview's cards: what the installed packages view finds (files only, no Composer run)
        $inventory = new \eZUpdateInventory( $manager );
        $inventoryData = $inventory->build();
        $tpl->setVariable( 'inventory', $inventoryData['summary'] );
        $tpl->setVariable( 'job_running', \eZUpdateJob::isRunning() );

        $Result = array();
        $Result['content'] = $tpl->fetch( 'design:ezupdate/dashboard.tpl' );
        $Result['path']    = array(
            array( 'text' => \ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => false ),
        );

        return $this->viewResult( isset( $Result ) ? $Result : null, null );
    }
}

}
