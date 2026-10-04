<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 **/

$Module = array(
    'name'      => 'Update',
    'functions' => array()
);

$ViewList = array(
    'dashboard' => array(
        'script'                  => 'dashboard.php',
        'functions'               => array( 'ezupdate' ),
        'params'                  => array(),
        'default_navigation_part' => 'ezsetupnavigationpart',
        'single_post_actions'     => array(
            'CheckForUpdatesButton' => 'CheckForUpdates',
            'DryRunUpdateButton'    => 'DryRunUpdate',
            'UpdateButton'          => 'Update',
            'InstallUpdatesButton'  => 'InstallUpdates',
            'SwitchUpdatesOnButton'  => 'SwitchUpdatesOn',
            'SwitchUpdatesOffButton' => 'SwitchUpdatesOff',
            'GetComposerButton'     => 'GetComposer',
        ),
        'post_action_parameters'  => array(
            'DryRunUpdate'   => array( 'InstallMethod' => 'InstallMethod', 'Packages' => 'Packages' ),
            'Update'         => array( 'ConfirmBackup' => 'ConfirmBackup', 'InstallMethod' => 'InstallMethod' ),
            'InstallUpdates' => array( 'ConfirmBackup' => 'ConfirmBackup', 'InstallMethod' => 'InstallMethod', 'Packages' => 'Packages' ),
        ),
    ),
    // composer.json, composer.lock, installed.json and the extension directories, matched up (read only)
    'installed' => array(
        'script'                  => 'installed.php',
        'functions'               => array( 'ezupdate' ),
        'params'                  => array( 'Format' ),
        'default_navigation_part' => 'ezsetupnavigationpart',
    ),
    'browse' => array(
        'script'                  => 'browse.php',
        'functions'               => array( 'ezupdate' ),
        'params'                  => array(),
        'unordered_params'        => array( 'page' => 'Page' ),
        'default_navigation_part' => 'ezsetupnavigationpart',
    ),
    'package' => array(
        'script'                  => 'package.php',
        'functions'               => array( 'ezupdate' ),
        'params'                  => array( 'Vendor', 'Name' ),
        'default_navigation_part' => 'ezsetupnavigationpart',
        'single_post_actions'     => array(
            'DryRunInstallButton' => 'DryRunInstall',
            'InstallButton'       => 'Install',
        ),
        'post_action_parameters'  => array(
            'DryRunInstall' => array( 'Constraint' => 'Constraint', 'InstallMethod' => 'InstallMethod' ),
            'Install'       => array( 'Constraint' => 'Constraint', 'ConfirmBackup' => 'ConfirmBackup', 'InstallMethod' => 'InstallMethod' ),
        ),
    ),
    'servers' => array(
        'script'                  => 'servers.php',
        'functions'               => array( 'manage' ),
        'params'                  => array(),
        'default_navigation_part' => 'ezsetupnavigationpart',
        'single_post_actions'     => array(
            'AddComposerServerButton'    => 'AddComposerServer',
            'RemoveComposerServerButton' => 'RemoveComposerServer',
            'PackagistOnButton'          => 'PackagistOn',
            'PackagistOffButton'         => 'PackagistOff',
            'AddPackageServerButton'     => 'AddPackageServer',
            'RemovePackageServerButton'  => 'RemovePackageServer',
        ),
    ),
    'packages' => array(
        'script'                  => 'packages.php',
        'functions'               => array( 'ezupdate' ),
        'params'                  => array( 'Server' ),
        'default_navigation_part' => 'ezsetupnavigationpart',
        'single_post_actions'     => array(
            'FetchPackageButton' => 'FetchPackage',
        ),
    ),
    // Who the installed packages ask to be funded by, as "composer fund".
    'fund' => array(
        'script'                  => 'fund.php',
        'functions'               => array( 'ezupdate' ),
        'params'                  => array( 'Format' ),
        'unordered_params'        => array( 'direct' => 'Direct' ),
        'default_navigation_part' => 'ezsetupnavigationpart',
    ),
    'job' => array(
        'script'                  => 'job.php',
        'functions'               => array( 'ezupdate' ),
        'params'                  => array( 'JobID', 'Format' ),
        'default_navigation_part' => 'ezsetupnavigationpart',
        'single_post_actions'     => array(
            'RerunButton'      => 'Rerun',
            'RunForRealButton' => 'RunForReal',
        ),
        'post_action_parameters'  => array(
            'Rerun'      => array( 'ConfirmBackup' => 'ConfirmBackup' ),
            'RunForReal' => array( 'ConfirmBackup' => 'ConfirmBackup' ),
        ),
    ),
);

$FunctionList = array(
    // See installed packages, check for updates, dry runs, browse packagist.org.
    'ezupdate' => array(),
    // Update, install, fetch .ezpkg packages, edit the package servers.
    'manage'   => array(),
);
