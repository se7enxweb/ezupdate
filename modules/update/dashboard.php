<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * The installation's Composer state: where Composer is, what may be run, the
 * packages that have a newer release, and the recent runs. No function or class
 * is declared here, so the view can run many times in one PHP process.
 **/

require_once __DIR__ . '/classes.php';

$module  = $Params['Module'];
$manager = eZUpdateManager::getInstance();
$user    = eZUser::currentUser();
$access  = $user->hasAccessTo( 'update', 'manage' );
$canManage = $access['accessWord'] !== 'no';
$error   = null;
$outdated = null;
$method  = $manager->installMethod( $module->hasActionParameter( 'InstallMethod' ) ? (string)$module->actionParameter( 'InstallMethod' ) : null );

if ( $module->isCurrentAction( 'CheckForUpdates' ) )
{
    $outdated = $manager->outdatedPackages( true );
    if ( $outdated === false )
    {
        $error = ezpI18n::tr( 'extension/ezupdate', 'Composer could not check for updates.' ) . "\n" . $manager->lastOutput();
    }
}
else if ( $module->isCurrentAction( 'DryRunUpdate' ) || $module->isCurrentAction( 'Update' ) )
{
    $dryRun = $module->isCurrentAction( 'DryRunUpdate' );
    if ( !$dryRun && ( !$canManage || !$manager->isUpdateAllowed() ) )
    {
        $error = ezpI18n::tr( 'extension/ezupdate', 'Updating is switched off ([UpdateSettings] AllowUpdate in ezupdate.ini).' );
    }
    else if ( !$dryRun && !$module->hasActionParameter( 'ConfirmBackup' ) )
    {
        $error = ezpI18n::tr( 'extension/ezupdate', 'Confirm that a backup exists before updating.' );
    }
    else
    {
        $job = eZUpdateJob::start(
            $dryRun ? 'update-dry-run' : 'update',
            $manager->updateArguments( $dryRun, $method ),
            ( $dryRun ? ezpI18n::tr( 'extension/ezupdate', 'Update, dry run' ) : ezpI18n::tr( 'extension/ezupdate', 'Update' ) ) . ' (' . $method . ')'
        );
        if ( $job instanceof eZUpdateJob )
        {
            return $module->redirectTo( 'update/job/' . $job->data['id'] );
        }
        $error = $job;
    }
}

$composerServers = new eZUpdateComposerServers( $manager );

$tpl = eZTemplate::factory();
$tpl->setVariable( 'error', $error );
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
$tpl->setVariable( 'install_method', $method );
$tpl->setVariable( 'install_methods', eZUpdateManager::$installMethods );
$tpl->setVariable( 'jobs', eZUpdateJob::fetchList( 10 ) );
$tpl->setVariable( 'job_running', eZUpdateJob::isRunning() );

$Result = array();
$Result['content'] = $tpl->fetch( 'design:ezupdate/dashboard.tpl' );
$Result['path']    = array(
    array( 'text' => ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => false ),
);
