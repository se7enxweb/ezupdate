<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * Loads the extension's classes for the module views when the autoload array
 * does not know them yet: a web server that keeps PHP alive across requests
 * keeps the autoload array it started with, so an extension updated while it
 * runs would otherwise answer "class not found" until it restarts.
 **/

foreach ( array(
    'eZUpdateManager'         => 'ezupdatemanager.php',
    'eZUpdateComposerServers' => 'ezupdatecomposerservers.php',
    'eZUpdatePackageServers'  => 'ezupdatepackageservers.php',
    'eZUpdatePackagist'       => 'ezupdatepackagist.php',
    'eZUpdateJob'             => 'ezupdatejob.php',
    'eZUpdateFunding'         => 'ezupdatefunding.php',
    'eZUpdateInventory'       => 'ezupdateinventory.php',
) as $ezupdateClass => $ezupdateFile )
{
    if ( !class_exists( $ezupdateClass ) )
    {
        require_once __DIR__ . '/../../classes/' . $ezupdateFile;
    }
}
unset( $ezupdateClass, $ezupdateFile );
