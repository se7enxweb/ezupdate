<?php
/**
 * The code of extension/ezupdate/modules/update/fund.php, moved into a class (#207 stage 1). The file extension/ezupdate/modules/update/fund.php is one call to it.
 * Guide: doc/bc/6.0/cli_cronjob_view_abstractions.md
 */
/*
 * The original header of extension/ezupdate/modules/update/fund.php:
 *
 *
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * Funding: who the installed packages ask to be funded by, the list
 * "composer fund" prints, read from vendor/composer/installed.json and the
 * packages' .github/FUNDING.yml without running Composer.
 *
 *   update/fund                  every installed package
 *   update/fund/(direct)/1       only the ones composer.json requires itself
 *   update/fund/json | text      the same as a download
 *
 */

namespace Exponential\View\Extension\Ezupdate\Update
{

class Fund extends \Exponential\Runnable\ModuleView
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
        $format  = isset( $Params['Format'] ) ? (string)$Params['Format'] : '';
        $direct  = isset( $Params['Direct'] ) && $Params['Direct'] === '1';
        $funding = new \eZUpdateFunding( \eZUpdateManager::getInstance() );

        if ( $format === 'json' || $format === 'text' )
        {
            $name = 'funding' . ( $direct ? '-direct' : '' ) . '.' . ( $format === 'json' ? 'json' : 'txt' );
            header( 'Content-Type: ' . ( $format === 'json' ? 'application/json' : 'text/plain' ) . '; charset=utf-8' );
            header( 'Content-Disposition: attachment; filename="' . $name . '"' );
            header( 'Cache-Control: no-store' );
            if ( $format === 'json' )
            {
                echo json_encode( array( 'summary' => $funding->summary( $direct ), 'vendors' => array_values( $funding->byVendor( $direct ) ) ),
                                  JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ), "\n";
            }
            else
            {
                echo $funding->asText( $direct );
            }
            \eZExecution::cleanExit();
        }
        else if ( $format !== '' )
        {
            return $this->viewResult( isset( $Result ) ? $Result : null,  $module->handleError( \eZError::KERNEL_NOT_FOUND, 'kernel' ) );
        }

        $unfunded = array();
        foreach ( $funding->packages() as $package )
        {
            if ( !$package['links'] && ( !$direct || $package['direct'] ) )
                $unfunded[] = $package;
        }

        $tpl = \eZTemplate::factory();
        $tpl->setVariable( 'vendors', array_values( $funding->byVendor( $direct ) ) );
        $tpl->setVariable( 'summary', $funding->summary( $direct ) );
        $tpl->setVariable( 'unfunded', $unfunded );
        $tpl->setVariable( 'direct', $direct );

        $Result = array();
        $Result['content'] = $tpl->fetch( 'design:ezupdate/fund.tpl' );
        $Result['path']    = array(
            array( 'text' => \ezpI18n::tr( 'extension/ezupdate', 'Updates and packages' ), 'url' => 'update/dashboard' ),
            array( 'text' => \ezpI18n::tr( 'extension/ezupdate', 'Funding' ), 'url' => false ),
        );

        return $this->viewResult( isset( $Result ) ? $Result : null, null );
    }
}

}
