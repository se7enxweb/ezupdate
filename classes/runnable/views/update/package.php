<?php
/**
 * The code of extension/ezupdate/modules/update/package.php, moved into a class (#207 stage 1). The file extension/ezupdate/modules/update/package.php is one call to it.
 * Guide: doc/bc/6.0/cli_cronjob_view_abstractions.md
 */
/*
 * The original header of extension/ezupdate/modules/update/package.php:
 *
 *
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * One Composer package: what packagist.org says about it (versions, requirements,
 * license, downloads), what is installed, and a guarded install.
 *
 */

namespace Exponential\View\Extension\Ezupdate\Update
{

class Package extends \Exponential\Runnable\ModuleView
{
    public function run( array $scope )
    {
        // the including function's variables ($Params, $Module, $cli, ...)
        foreach ( array_keys( $scope ) as $__name )
            if ( $__name !== 'this' && $__name !== 'scope' )
                ${$__name} = &$scope[$__name];
        unset( $__name );

        require_once $this->scriptDir() . '/classes.php';

        $module    = $Params['Module'];
        $name      = strtolower( $Params['Vendor'] . '/' . $Params['Name'] );
        $manager   = \eZUpdateManager::getInstance();
        $packagist = new \eZUpdatePackagist();
        $user      = \eZUser::currentUser();
        $access    = $user->hasAccessTo( 'update', 'manage' );
        $canManage = $access['accessWord'] !== 'no';
        $error     = null;

        if ( !\eZUpdateManager::isPackageName( $name ) )
        {
            return $this->viewResult( isset( $Result ) ? $Result : null,  $module->handleError( \eZError::KERNEL_NOT_FOUND, 'kernel' ) );
        }

        $constraint = $module->hasActionParameter( 'Constraint' ) ? trim( (string)$module->actionParameter( 'Constraint' ) ) : '';
        $method     = $manager->installMethod( $module->hasActionParameter( 'InstallMethod' ) ? (string)$module->actionParameter( 'InstallMethod' ) : null );

        if ( $module->isCurrentAction( 'DryRunInstall' ) || $module->isCurrentAction( 'Install' ) )
        {
            $dryRun = $module->isCurrentAction( 'DryRunInstall' );
            $arguments = $manager->requireArguments( $name, $constraint, $dryRun, $method );
            if ( $arguments === false )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'The version constraint is not valid.' );
            }
            else if ( !$dryRun && ( !$canManage || !$manager->isInstallAllowed() ) )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Installing is switched off ([UpdateSettings] AllowInstall in ezupdate.ini).' );
            }
            else if ( !$dryRun && !$module->hasActionParameter( 'ConfirmBackup' ) )
            {
                $error = \ezpI18n::tr( 'extension/ezupdate', 'Confirm that a backup exists before installing.' );
            }
            else
            {
                $label = $name . ( $constraint !== '' ? ':' . $constraint : '' ) . ' (' . $method . ')';
                $job = \eZUpdateJob::start(
                    $dryRun ? 'require-dry-run' : 'require',
                    $arguments,
                    $dryRun ? \ezpI18n::tr( 'extension/ezupdate', 'Install %package, dry run', null, array( '%package' => $label ) )
                            : \ezpI18n::tr( 'extension/ezupdate', 'Install %package', null, array( '%package' => $label ) )
                );
                if ( $job instanceof \eZUpdateJob )
                {
                    return $this->viewResult( isset( $Result ) ? $Result : null,  $module->redirectTo( 'update/job/' . $job->data['id'] ) );
                }
                $error = $job;
            }
        }

        $package = $packagist->package( $name );
        $installedVersion = $manager->installedVersion( $name );
        $details = null;
        if ( $installedVersion !== false )
        {
            $info = $manager->packageInfo( $name );
            $details = $info && $info['exit'] === 0 ? \eZUpdateManager::ansiToHtml( $info['output'] ) : null;
        }

        $tpl = \eZTemplate::factory();
        $tpl->setVariable( 'name', $name );
        $tpl->setVariable( 'package', $package );
        $tpl->setVariable( 'packagist_error', $package === false ? $packagist->error : null );
        $tpl->setVariable( 'installed_version', $installedVersion );
        $tpl->setVariable( 'installed_info', $installedVersion !== false ? $manager->installedPackageInfo( $name ) : false );
        $funding = new \eZUpdateFunding( $manager );
        $tpl->setVariable( 'funding', $installedVersion !== false ? $funding->forPackage( $name ) : array() );
        $tpl->setVariable( 'install_method', $method );
        $tpl->setVariable( 'install_methods', \eZUpdateManager::$installMethods );
        $tpl->setVariable( 'details', $details );
        $tpl->setVariable( 'constraint', $constraint );
        $tpl->setVariable( 'error', $error );
        $tpl->setVariable( 'can_manage', $canManage );
        $tpl->setVariable( 'install_allowed', $manager->isInstallAllowed() );
        $tpl->setVariable( 'job_running', \eZUpdateJob::isRunning() );

        $Result = array();
        $Result['content'] = $tpl->fetch( 'design:ezupdate/package.tpl' );
        $Result['path']    = array(
            array( 'text' => \ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => 'update/dashboard' ),
            array( 'text' => \ezpI18n::tr( 'extension/ezupdate', 'Find packages' ), 'url' => 'update/browse' ),
            array( 'text' => $name, 'url' => false ),
        );

        return $this->viewResult( isset( $Result ) ? $Result : null, null );
    }
}

}
