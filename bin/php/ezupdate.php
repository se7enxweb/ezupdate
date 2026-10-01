#!/usr/bin/env php
<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 *
 * The command line of ezupdate: the same classes, settings and server lists as
 * the admin pages. Run it from the installation root:
 *
 *   php extension/ezupdate/bin/php/ezupdate.php <command> [arguments] [options]
 */

// A detached job worker (run-job, started by the admin) first moves its own
// streams off the pipe its starter has already closed: stdout to /dev/null,
// stderr into the job's log. The lowest free descriptors are reused, so the
// order of the fopen() calls is what puts each one at 0, 1 and 2.
if ( isset( $argv[1], $argv[2] ) && $argv[1] === 'run-job' && preg_match( '#^[a-f0-9]{16}$#', $argv[2] ) )
{
    fclose( STDIN );
    fclose( STDOUT );
    fclose( STDERR );
    $ezupdateStdin  = fopen( '/dev/null', 'r' );
    $ezupdateStdout = fopen( '/dev/null', 'w' );
    $ezupdateStderr = fopen( getcwd() . '/var/ezupdate/jobs/' . $argv[2] . '.log', 'a' );
}

require 'autoload.php';

$cli = eZCLI::instance();
$script = eZScript::instance( array(
    'description'    => "ezupdate: Composer updates and packages, Exponential package servers.\n\n" .
        "Commands:\n" .
        "  status                                 where Composer is, what may be run\n" .
        "  installed [--issues] [--json]          composer.json, the lock, installed.json and the extension\n" .
        "                                         directories matched up, and which extensions are active\n" .
        "  outdated [--all]                       packages with a newer release (--all: dependencies too)\n" .
        "  search <words> [--type=<type>]         search packagist.org\n" .
        "  search <words> --composer              search every server in composer.json with Composer\n" .
        "  show <vendor/name>                     a package on packagist.org, and as installed\n" .
        "  servers                                the Composer and the Exponential package servers\n" .
        "  server-add composer <name> <composer|vcs|git> <https url>\n" .
        "  server-add ezpkg <name> <https url>\n" .
        "  server-remove composer|ezpkg <name>\n" .
        "  packagist on|off                       use packagist.org or not (composer.json)\n" .
        "  packages [<server>]                    the .ezpkg packages a server offers\n" .
        "  fetch <server> <package> [--replace]   download a .ezpkg into the local package repository\n" .
        "  require <vendor/name> [<constraint>] [--dry-run] [--prefer=dist|source]   install a package\n" .
        "  update [--dry-run] [--prefer=dist|source]   update the packages composer.json names\n" .
        "  jobs                                   the recent runs, from here and from the admin\n" .
        "  fund [--direct] [--json]               who the installed packages ask to be funded by, as composer fund\n",
    'use-session'    => false,
    'use-modules'    => true,
    'use-extensions' => true,
) );
$script->startup();
$options = $script->getOptions( '[all][type:][composer][replace][dry-run][prefer:][direct][json][issues]', '', array(
    'all'      => 'outdated: dependencies too, not only what composer.json names',
    'type'     => 'search: the package type on packagist.org (empty: any)',
    'composer' => 'search: ask Composer (every server in composer.json) instead of packagist.org',
    'replace'  => 'fetch: replace a package already in the local repository',
    'dry-run'  => 'require, update: show what would change, change nothing',
    'prefer'   => 'require, update: dist (archives), source (git clones with history) or auto; default [UpdateSettings] PreferredInstall',
    'direct'   => 'fund: only the packages composer.json requires itself',
    'json'     => 'fund, installed: print JSON instead of text',
    'issues'   => 'installed: only what needs attention',
) );
$script->initialize();

$arguments = array_values( $options['arguments'] );
$command   = isset( $arguments[0] ) ? $arguments[0] : 'status';
$manager   = eZUpdateManager::getInstance();
$exit      = 0;

$fail = function ( $text ) use ( $cli, $script )
{
    $cli->error( $text );
    $script->shutdown( 1 );
};
$composerResult = function ( $result ) use ( $cli, $fail )
{
    if ( is_string( $result ) )
    {
        $fail( $result );
    }
    if ( $result['output'] !== '' )
    {
        $cli->output( $result['output'] );
    }
    if ( $result['exit'] !== 0 )
    {
        $fail( 'composer exit ' . $result['exit'] );
    }
};

switch ( $command )
{
    case 'status':
        $servers = new eZUpdateComposerServers( $manager );
        $cli->output( 'Composer:     ' . ( $manager->composerBinary() ? $manager->composerBinary() : 'not found' ) );
        if ( $manager->composerBinary() )
        {
            $cli->output( '              ' . $manager->composerVersion() );
        }
        $cli->output( 'PHP:          ' . ( $manager->phpBinary() ? $manager->phpBinary() : 'not found' ) );
        $cli->output( 'Installation: ' . $manager->projectPath() . ( $manager->hasComposerJson() ? '' : ' (no composer.json)' ) );
        $cli->output( 'Installed:    ' . count( $manager->installedPackages() ) . ' packages' );
        $cli->output( 'Servers:      ' . ( $servers->packagistEnabled() ? 'packagist.org' : 'packagist.org off' ) . ', ' . count( $servers->servers() ) . ' in composer.json' );
        $cli->output( 'Update:       ' . ( $manager->isUpdateAllowed() ? 'allowed' : 'switched off ([UpdateSettings] AllowUpdate)' ) );
        $cli->output( 'Install:      ' . ( $manager->isInstallAllowed() ? 'allowed' : 'switched off ([UpdateSettings] AllowInstall)' ) );
        break;

    case 'installed':
        if ( !class_exists( 'eZUpdateInventory' ) )
            require_once __DIR__ . '/../../classes/ezupdateinventory.php';
        $inventory = ( new eZUpdateInventory( $manager ) )->build();
        $rows = $inventory['rows'];
        if ( !empty( $options['issues'] ) )
            $rows = array_values( array_filter( $rows, function ( $row ) { return (bool)$row['issues']; } ) );
        if ( !empty( $options['json'] ) )
        {
            $cli->output( json_encode( array( 'summary' => $inventory['summary'], 'packages' => $rows ), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ) );
            break;
        }
        $sum = $inventory['summary'];
        $cli->output( sprintf( '%d rows: %d installed by Composer, %d required in composer.json, %d extensions (%d active), %d not from Composer, %d need attention',
                               $sum['all'], $sum['composer'], $sum['required'], $sum['extension'], $sum['active'], $sum['local'], $sum['issues'] ) );
        $cli->output( '' );
        $cli->output( sprintf( '%-44s %-9s %-12s %-12s %-14s %s', 'PACKAGE', 'KIND', 'JSON', 'LOCK', 'INSTALLED', 'EXTENSION' ) );
        foreach ( $rows as $row )
        {
            $installedVersion = $row['installed'] !== '' ? $row['installed'] : ( $row['ext_version'] !== '' ? $row['ext_version'] : '-' );
            if ( $row['git'] )
                $installedVersion .= ' (' . trim( $row['git']['branch'] . '@' . $row['git']['commit'], '@' ) . ')';
            $where = $row['extension'] ? $row['extension'] . ' ' . ( $row['active'] ? '[' . implode( ',', $row['active'] ) . ']' : '[off]' ) : '';
            $cli->output( sprintf( '%-44s %-9s %-12s %-12s %-14s %s', $row['name'], $row['kind'], $row['required'] !== '' ? $row['required'] : ( $row['composer'] ? 'dependency' : '-' ),
                                   $row['locked'] !== '' ? $row['locked'] : '-', $installedVersion, $where ) );
            foreach ( $row['issues'] as $issue )
                $cli->output( '    ' . ( $issue[0] === 'bad' ? '!! ' : ' ! ' ) . $issue[1] );
        }
        break;

    case 'fund':
        if ( !class_exists( 'eZUpdateFunding' ) )
            require_once __DIR__ . '/../../classes/ezupdatefunding.php';
        $funding = new eZUpdateFunding( $manager );
        $direct = !empty( $options['direct'] );
        if ( !empty( $options['json'] ) )
        {
            $cli->output( json_encode( array( 'summary' => $funding->summary( $direct ), 'vendors' => array_values( $funding->byVendor( $direct ) ) ),
                                       JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ) );
            break;
        }
        $summary = $funding->summary( $direct );
        $cli->output( sprintf( '%d of %d packages ask for funding, %d vendors, %d links:', $summary['funded'], $summary['packages'], $summary['vendors'], $summary['links'] ) );
        $cli->output( '' );
        $cli->output( $funding->asText( $direct ) );
        break;

    case 'outdated':
        $list = $manager->outdatedPackages( !$options['all'] );
        if ( $list === false )
        {
            $fail( "Composer could not check for updates.\n" . $manager->lastOutput() );
        }
        foreach ( $list as $package )
        {
            $cli->output( sprintf( '%-50s %-16s -> %-16s %s', $package['name'], $package['version'], $package['latest'],
                                   $package['status'] === 'semver-safe-update' ? 'within the constraint' : 'needs a new constraint' ) );
        }
        $cli->output( count( $list ) . ' with a newer release' );
        break;

    case 'search':
        $words = implode( ' ', array_slice( $arguments, 1 ) );
        if ( $options['composer'] )
        {
            $list = $manager->search( $words );
            if ( $list === false )
            {
                $fail( 'Composer could not search.' );
            }
            foreach ( $list as $package )
            {
                $cli->output( sprintf( '%-50s %s', $package['name'], $package['description'] ) );
            }
            break;
        }
        $packagist = new eZUpdatePackagist();
        $result = $packagist->search( $words, $options['type'] !== null ? $options['type'] : '' );
        if ( $result === false )
        {
            $fail( $packagist->error );
        }
        foreach ( $result['results'] as $package )
        {
            $cli->output( sprintf( '%-50s %10d  %s', $package['name'], $package['downloads'], $package['description'] ) );
        }
        $cli->output( $result['total'] . ' packages' . ( $result['pages'] > 1 ? ', first page shown' : '' ) );
        break;

    case 'show':
        $name = isset( $arguments[1] ) ? strtolower( $arguments[1] ) : '';
        if ( !eZUpdateManager::isPackageName( $name ) )
        {
            $fail( 'Usage: show <vendor/name>' );
        }
        $packagist = new eZUpdatePackagist();
        $package = $packagist->package( $name );
        if ( $package )
        {
            $cli->output( $package['name'] . ' ' . $package['latest'] . ' (' . $package['type'] . ', ' . $package['license'] . ')' );
            $cli->output( $package['description'] );
            $cli->output( 'Source:    ' . $package['repository'] );
            $cli->output( 'Downloads: ' . $package['downloads']['total'] . ', ' . $package['downloads']['monthly'] . ' this month' );
            foreach ( $package['require'] as $dependency => $constraint )
            {
                $cli->output( '  requires ' . $dependency . ' ' . $constraint );
            }
        }
        else
        {
            $cli->warning( 'packagist.org: ' . $packagist->error );
        }
        if ( $package && $package['source'] )
        {
            $cli->output( 'Git:       ' . $package['source']['url'] . ' ' . $package['source']['short'] );
        }
        $installed = $manager->installedPackageInfo( $name );
        if ( !$installed )
        {
            $cli->output( 'Installed: no' );
            break;
        }
        $cli->output( 'Installed: ' . $installed['version'] . ', from ' . $installed['method'] . ( $installed['path'] ? ', in ' . $installed['path'] : '' ) );
        if ( $installed['git'] )
        {
            $git = $installed['git'];
            $cli->output( '           git ' . $git['branch'] . ' ' . $git['commit'] . ( $git['tag'] ? ' (' . $git['tag'] . ')' : '' )
                          . ( $git['changed'] ? ', local changes' : '' ) . ': ' . $git['subject'] );
        }
        else if ( $installed['method'] === 'dist' )
        {
            $cli->output( '           no git working copy (an archive); require it again with --prefer=source for the history' );
        }
        break;

    case 'servers':
        $composer = new eZUpdateComposerServers( $manager );
        $cli->output( 'Composer servers (composer.json):' );
        $cli->output( sprintf( '  %-24s %-9s %s', 'packagist.org', 'composer', $composer->packagistEnabled() ? 'on' : 'off' ) );
        foreach ( $composer->servers() as $server )
        {
            $cli->output( sprintf( '  %-24s %-9s %s', $server['name'], $server['type'], $server['url'] ) );
        }
        $ezpkg = new eZUpdatePackageServers();
        $cli->output( 'Exponential package servers:' );
        foreach ( $ezpkg->servers() as $server )
        {
            $cli->output( sprintf( '  %-24s %s%s', $server['name'], $server['url'], $server['builtin'] ? ' (package.ini)' : '' ) );
        }
        break;

    case 'server-add':
    case 'server-remove':
        $kind = isset( $arguments[1] ) ? $arguments[1] : '';
        $name = isset( $arguments[2] ) ? $arguments[2] : '';
        if ( $kind === 'composer' )
        {
            $composer = new eZUpdateComposerServers( $manager );
            $composerResult( $command === 'server-add'
                ? $composer->add( $name, isset( $arguments[3] ) ? $arguments[3] : '', isset( $arguments[4] ) ? $arguments[4] : '' )
                : $composer->remove( $name ) );
        }
        else if ( $kind === 'ezpkg' )
        {
            $ezpkg = new eZUpdatePackageServers();
            $ok = $command === 'server-add' ? $ezpkg->add( $name, isset( $arguments[3] ) ? $arguments[3] : '' ) : $ezpkg->remove( $name );
            if ( !$ok )
            {
                $fail( $ezpkg->error );
            }
        }
        else
        {
            $fail( 'Usage: ' . $command . ' composer|ezpkg <name> ...' );
        }
        $cli->output( 'Done.' );
        break;

    case 'packagist':
        $state = isset( $arguments[1] ) ? $arguments[1] : '';
        if ( $state !== 'on' && $state !== 'off' )
        {
            $fail( 'Usage: packagist on|off' );
        }
        $composer = new eZUpdateComposerServers( $manager );
        $composerResult( $composer->setPackagistEnabled( $state === 'on' ) );
        break;

    case 'packages':
        $ezpkg = new eZUpdatePackageServers();
        $servers = $ezpkg->servers();
        $server = isset( $arguments[1] ) ? $arguments[1] : (string)key( $servers );
        $list = $ezpkg->packages( $server );
        if ( $list === false )
        {
            $fail( $ezpkg->error );
        }
        foreach ( $list as $package )
        {
            $cli->output( sprintf( '%-40s %-14s %s', $package['name'], $package['type'], $package['local_version'] !== false ? 'local ' . $package['local_version'] : '' ) );
        }
        break;

    case 'fetch':
        $ezpkg = new eZUpdatePackageServers();
        $package = $ezpkg->fetchPackage( isset( $arguments[1] ) ? $arguments[1] : '', isset( $arguments[2] ) ? $arguments[2] : '', (bool)$options['replace'] );
        if ( !$package )
        {
            $fail( $ezpkg->error );
        }
        $cli->output( $package->attribute( 'name' ) . ' ' . $package->getVersion() . ' is in the local package repository.' );
        break;

    case 'require':
    case 'update':
        $dryRun = (bool)$options['dry-run'];
        if ( $command === 'require' )
        {
            $name = isset( $arguments[1] ) ? strtolower( $arguments[1] ) : '';
            $constraint = isset( $arguments[2] ) ? $arguments[2] : '';
            $composerArguments = $manager->requireArguments( $name, $constraint, $dryRun, $options['prefer'] );
            if ( $composerArguments === false )
            {
                $fail( 'Usage: require <vendor/name> [<constraint>] [--dry-run]' );
            }
            if ( !$dryRun && !$manager->isInstallAllowed() )
            {
                $fail( 'Installing is switched off ([UpdateSettings] AllowInstall in ezupdate.ini).' );
            }
            $label = 'Install ' . $name . ( $constraint !== '' ? ':' . $constraint : '' ) . ( $dryRun ? ', dry run' : '' );
        }
        else
        {
            if ( !$dryRun && !$manager->isUpdateAllowed() )
            {
                $fail( 'Updating is switched off ([UpdateSettings] AllowUpdate in ezupdate.ini).' );
            }
            $composerArguments = $manager->updateArguments( $dryRun, $options['prefer'] );
            $label = 'Update' . ( $dryRun ? ', dry run' : '' );
        }
        $job = eZUpdateJob::start( $command . ( $dryRun ? '-dry-run' : '' ), $composerArguments, $label, false );
        if ( !$job instanceof eZUpdateJob )
        {
            $fail( $job );
        }
        $exit = $job->data['exit'] === 0 ? 0 : 1;
        break;

    case 'jobs':
        foreach ( eZUpdateJob::fetchList( 20 ) as $job )
        {
            $cli->output( sprintf( '%s  %s  %-9s %-12s %s', $job['id'], date( 'Y-m-d H:i', $job['created'] ), $job['status'], $job['user'], $job['label'] ) );
        }
        break;

    case 'run-job':
        // Started by the admin (detached); not meant to be typed.
        $exit = eZUpdateJob::runJob( isset( $arguments[1] ) ? $arguments[1] : '' ) === 0 ? 0 : 1;
        break;

    default:
        $fail( 'Unknown command "' . $command . '". Run with --help for the list.' );
}

$script->shutdown( $exit );
