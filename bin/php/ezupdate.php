#!/usr/bin/env php
<?php
/**
 * Entry point of extension/ezupdate/bin/php/ezupdate.php
 *
 * @copyright Copyright (C) 1998 - 2026 7x and the Exponential Foundation. All rights reserved.
 * @license GNU General Public License v2.0 (or any later version)
 * @package eZUpdate
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

// The code is in extension/ezupdate/classes/runnable/commands/php_ezupdate.php (#207); this file is the entry point.
\Exponential\Command\Extension\Ezupdate\Ezupdate::main( __FILE__ );
