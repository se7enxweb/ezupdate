<?php
/**
 * @package eZUpdate
 * @class   eZUpdateJob
 * @author  7x <info@se7enx.com>
 * @date    28 Sep 2026
 **/

/**
 * A Composer run in the background, so a long update or install neither holds
 * a web request open nor hits its time limit, and the page can show the output
 * while it is written.
 *
 * Each job is <id>.json (what to run, status, exit code) and <id>.log (the
 * output) in var/ezupdate/jobs of the installation. The web request writes the job and starts
 * `php extension/ezupdate/bin/php/ezupdate.php run-job <id>` detached with
 * setsid; that process runs Composer and then the [JobSettings]
 * AfterRunCommands (autoloads, caches). One job runs at a time: the worker holds
 * an exclusive lock on var/ezupdate/jobs/.lock while it runs.
 */
class eZUpdateJob
{
    const ID_PATTERN = '#^[a-f0-9]{16}$#';

    /** Job kinds and whether they change the installation. */
    public static $kinds = array(
        'update-dry-run'  => false,
        'update'          => true,
        'require-dry-run' => false,
        'require'         => true,
    );

    /** @var array */
    public $data;

    private function __construct( array $data )
    {
        $this->data = $data;
    }

    /**
     * One place for the whole installation, whichever siteaccess (and so
     * whichever VarDir) started the run: Composer changes all of them.
     */
    public static function directory()
    {
        return eZSys::rootDir() . '/var/ezupdate/jobs';
    }

    private static function jsonFile( $id )
    {
        return self::directory() . '/' . $id . '.json';
    }

    public static function logFile( $id )
    {
        return self::directory() . '/' . $id . '.log';
    }

    /**
     * @return eZUpdateJob|false
     */
    public static function fetch( $id )
    {
        if ( !is_string( $id ) || !preg_match( self::ID_PATTERN, $id ) || !is_file( self::jsonFile( $id ) ) )
        {
            return false;
        }
        $data = json_decode( (string)file_get_contents( self::jsonFile( $id ) ), true );
        return is_array( $data ) ? new self( $data ) : false;
    }

    /**
     * The newest jobs first.
     */
    public static function fetchList( $limit = 10 )
    {
        $files = glob( self::directory() . '/*.json' );
        if ( !$files )
        {
            return array();
        }
        usort( $files, function ( $a, $b ) { return filemtime( $b ) - filemtime( $a ); } );
        $jobs = array();
        foreach ( array_slice( $files, 0, $limit ) as $file )
        {
            $job = self::fetch( basename( $file, '.json' ) );
            if ( $job )
            {
                $jobs[] = $job->data;
            }
        }
        return $jobs;
    }

    /**
     * True while a worker holds the lock.
     */
    public static function isRunning()
    {
        $dir = self::directory();
        if ( !is_file( $dir . '/.lock' ) )
        {
            return false;
        }
        $handle = fopen( $dir . '/.lock', 'c' );
        if ( !$handle )
        {
            return false;
        }
        $free = flock( $handle, LOCK_EX | LOCK_NB );
        if ( $free )
        {
            flock( $handle, LOCK_UN );
        }
        fclose( $handle );
        return !$free;
    }

    /**
     * Writes a job and starts its worker.
     *
     * @param string $kind      one of self::$kinds
     * @param array  $arguments the Composer arguments (from eZUpdateManager)
     * @param string $label     what the job does, for the list
     * @return eZUpdateJob|string the job, or an error text
     */
    public static function start( $kind, array $arguments, $label, $detach = true )
    {
        if ( !isset( self::$kinds[$kind] ) )
        {
            return 'Unknown job kind';
        }
        if ( self::isRunning() )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'Another Composer run is still in progress.' );
        }
        $dir = self::directory();
        if ( !is_dir( $dir ) && !eZDir::mkdir( $dir, false, true ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'Could not write %file.', null, array( '%file' => $dir ) );
        }
        self::prune();

        $id = bin2hex( random_bytes( 8 ) );
        if ( PHP_SAPI === 'cli' )
        {
            // The command line: the system account that ran it.
            $info = function_exists( 'posix_getpwuid' ) ? posix_getpwuid( posix_geteuid() ) : false;
            $userName = 'cli:' . ( $info ? $info['name'] : get_current_user() );
        }
        else
        {
            $user = eZUser::currentUser();
            $userName = $user ? $user->attribute( 'login' ) : '';
        }
        $job = new self( array(
            'id'        => $id,
            'kind'      => $kind,
            'changes'   => self::$kinds[$kind],
            'arguments' => array_values( $arguments ),
            'label'     => (string)$label,
            'status'    => 'queued',
            'exit'      => null,
            'created'   => time(),
            'started'   => null,
            'finished'  => null,
            'user'      => $userName,
            'siteaccess' => isset( $GLOBALS['eZCurrentAccess']['name'] ) ? $GLOBALS['eZCurrentAccess']['name'] : '',
        ) );
        $job->store();
        file_put_contents( self::logFile( $id ), '' );

        // The command line runs it in the foreground ($detach false); a web
        // request detaches it, or runs it within the request where it cannot.
        if ( !$detach || !$job->launch() )
        {
            self::runJob( $id, !$detach );
        }
        return self::fetch( $id );
    }

    private function store()
    {
        $file = self::jsonFile( $this->data['id'] );
        file_put_contents( $file . '.tmp', json_encode( $this->data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES ) );
        rename( $file . '.tmp', $file );
    }

    /**
     * Starts the worker detached (setsid -f), so it outlives the web request.
     */
    private function launch()
    {
        $setsid = is_executable( '/usr/bin/setsid' ) ? '/usr/bin/setsid' : ( is_executable( '/bin/setsid' ) ? '/bin/setsid' : false );
        $php = eZUpdateManager::getInstance()->phpBinary();
        if ( !$setsid || !$php || !function_exists( 'proc_open' ) )
        {
            return false;
        }
        $command = array( $setsid, '-f', $php, eZExtension::baseDirectory() . '/ezupdate/bin/php/ezupdate.php', 'run-job', $this->data['id'] );
        if ( $this->data['siteaccess'] !== '' )
        {
            $command[] = '-s';
            $command[] = $this->data['siteaccess'];
        }
        if ( function_exists( 'posix_geteuid' ) && posix_geteuid() === 0 )
        {
            $command[] = '--allow-root-user';
        }
        // setsid -f forks the worker and returns at once. The worker moves its
        // own stdout to /dev/null and stderr into the job's log before anything
        // else (bin/php/ezupdate.php run-job), so the pipe closed here is never
        // written to.
        $spawned = eZUpdateManager::spawn( $command, eZSys::rootDir() );
        if ( !$spawned )
        {
            return false;
        }
        list( $process, $stdout ) = $spawned;
        fclose( $stdout );
        return proc_close( $process ) === 0;
    }

    /**
     * Runs a job (called by the worker). Returns the exit code.
     */
    public static function runJob( $id, $echo = false )
    {
        $job = self::fetch( $id );
        if ( !$job || $job->data['status'] !== 'queued' )
        {
            return 1;
        }
        $log = fopen( self::logFile( $id ), 'a' );
        $lock = fopen( self::directory() . '/.lock', 'c' );
        if ( !$lock || !flock( $lock, LOCK_EX | LOCK_NB ) )
        {
            fwrite( $log, ezpI18n::tr( 'extension/ezupdate', 'Another Composer run is still in progress.' ) . "\n" );
            $job->data['status'] = 'failed';
            $job->data['finished'] = time();
            $job->store();
            return 1;
        }

        $job->data['status'] = 'running';
        $job->data['started'] = time();
        $job->data['pid'] = getmypid();
        $job->store();

        $write = function ( $chunk ) use ( $log, $echo )
        {
            fwrite( $log, $chunk );
            fflush( $log );
            if ( $echo )
            {
                echo $chunk;
            }
        };

        $manager = eZUpdateManager::getInstance();
        $write( "\x1b[1m$ composer " . implode( ' ', $job->data['arguments'] ) . "\x1b[0m\n" );
        $result = $manager->run( $job->data['arguments'], null, $write );
        $exit = $result['exit'];
        $write( "\n" );

        if ( $exit === 0 && $job->data['changes'] )
        {
            $exit = self::afterRun( $write );
        }

        $write( "\n\x1b[1m" . ( $exit === 0
            ? ezpI18n::tr( 'extension/ezupdate', 'Finished.' )
            : ezpI18n::tr( 'extension/ezupdate', 'Failed with exit code %code.', null, array( '%code' => $exit ) ) ) . "\x1b[0m\n" );

        $job->data['status'] = $exit === 0 ? 'finished' : 'failed';
        $job->data['exit'] = $exit;
        $outcome = self::outcomeOf( (string)@file_get_contents( self::logFile( $id ) ), $exit );
        $job->data['outcome'] = $outcome['state'];
        $job->data['counts'] = $outcome['counts'];
        $job->data['finished'] = time();
        $job->store();

        flock( $lock, LOCK_UN );
        fclose( $lock );
        fclose( $log );
        return $exit;
    }

    /**
     * Runs [JobSettings] AfterRunCommands[] (each a PHP script of the
     * installation plus its arguments) after a run that changed packages.
     */
    private static function afterRun( $write )
    {
        $ini = eZINI::instance( 'ezupdate.ini' );
        if ( !$ini->hasVariable( 'JobSettings', 'AfterRunCommands' ) )
        {
            return 0;
        }
        $php = eZUpdateManager::getInstance()->phpBinary();
        $root = eZSys::rootDir();
        foreach ( (array)$ini->variable( 'JobSettings', 'AfterRunCommands' ) as $line )
        {
            $parts = preg_split( '/\s+/', trim( (string)$line ), -1, PREG_SPLIT_NO_EMPTY );
            if ( !$parts )
            {
                continue;
            }
            $script = $parts[0];
            // Only scripts inside the installation, given by a relative path.
            if ( $script[0] === '/' || strpos( $script, '..' ) !== false || substr( $script, -4 ) !== '.php' || !is_file( $root . '/' . $script ) )
            {
                $write( ezpI18n::tr( 'extension/ezupdate', 'Skipped %command: not a PHP script of this installation.', null, array( '%command' => $line ) ) . "\n" );
                continue;
            }
            if ( function_exists( 'posix_geteuid' ) && posix_geteuid() === 0
                 && strpos( (string)file_get_contents( $root . '/' . $script ), 'eZScript::instance' ) !== false )
            {
                $parts[] = '--allow-root-user';
            }
            $write( "\x1b[1m$ php " . implode( ' ', $parts ) . "\x1b[0m\n" );

            $spawned = eZUpdateManager::spawn( array_merge( array( $php ), $parts ), $root );
            if ( !$spawned )
            {
                return -1;
            }
            list( $process, $stdout ) = $spawned;
            while ( !feof( $stdout ) )
            {
                $chunk = fread( $stdout, 8192 );
                if ( $chunk !== false && $chunk !== '' )
                {
                    $write( $chunk );
                }
            }
            fclose( $stdout );
            $exit = proc_close( $process );
            if ( $exit !== 0 )
            {
                return $exit;
            }
        }
        return 0;
    }

    /**
     * Keeps the newest [JobSettings] KeepJobs jobs.
     */
    private static function prune()
    {
        $keep = (int)eZINI::instance( 'ezupdate.ini' )->variable( 'JobSettings', 'KeepJobs' );
        $files = glob( self::directory() . '/*.json' );
        if ( $keep < 1 || !$files || count( $files ) < $keep )
        {
            return;
        }
        usort( $files, function ( $a, $b ) { return filemtime( $b ) - filemtime( $a ); } );
        foreach ( array_slice( $files, $keep - 1 ) as $file )
        {
            $id = basename( $file, '.json' );
            @unlink( $file );
            @unlink( self::logFile( $id ) );
        }
    }

    /**
     * What a new run of this job would be: the same update or install again, or
     * with $forReal a dry run done for real. The Composer arguments are built
     * again by eZUpdateManager from what the job did (package, version
     * constraint, dist or source), never taken over from the stored file.
     *
     * @return array|string hash kind, arguments, label, changes; or an error text
     */
    public function rerunPlan( $forReal = false )
    {
        $manager = eZUpdateManager::getInstance();
        $kind = (string)$this->data['kind'];
        $arguments = (array)$this->data['arguments'];
        if ( !isset( self::$kinds[$kind] ) )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'This run cannot be started again.' );
        }
        $dryRun = substr( $kind, -8 ) === '-dry-run' && !$forReal;
        $method = in_array( '--prefer-source', $arguments, true ) ? 'source'
                : ( in_array( '--prefer-dist', $arguments, true ) ? 'dist' : 'auto' );

        if ( strpos( $kind, 'update' ) === 0 )
        {
            return array(
                'kind'      => $dryRun ? 'update-dry-run' : 'update',
                'arguments' => $manager->updateArguments( $dryRun, $method ),
                'label'     => ( $dryRun ? ezpI18n::tr( 'extension/ezupdate', 'Update, dry run' ) : ezpI18n::tr( 'extension/ezupdate', 'Update' ) ) . ' (' . $method . ')',
                'changes'   => !$dryRun,
            );
        }

        // require: the first argument after "require" that is not an option.
        $spec = '';
        foreach ( array_slice( $arguments, 1 ) as $argument )
        {
            if ( $argument !== '' && $argument[0] !== '-' )
            {
                $spec = $argument;
                break;
            }
        }
        $parts = explode( ':', $spec, 2 );
        $name = $parts[0];
        $constraint = isset( $parts[1] ) ? $parts[1] : '';
        $newArguments = $manager->requireArguments( $name, $constraint, $dryRun, $method );
        if ( $newArguments === false )
        {
            return ezpI18n::tr( 'extension/ezupdate', 'This run cannot be started again.' );
        }
        $label = $name . ( $constraint !== '' ? ':' . $constraint : '' ) . ' (' . $method . ')';
        return array(
            'kind'      => $dryRun ? 'require-dry-run' : 'require',
            'arguments' => $newArguments,
            'label'     => $dryRun ? ezpI18n::tr( 'extension/ezupdate', 'Install %package, dry run', null, array( '%package' => $label ) )
                                   : ezpI18n::tr( 'extension/ezupdate', 'Install %package', null, array( '%package' => $label ) ),
            'changes'   => !$dryRun,
        );
    }

    /**
     * What a finished run came to, read from Composer's output: 'failed' (exit code
     * other than 0), 'uptodate' (nothing to install, update or remove) or 'changed'
     * (with the counts of installs, updates and removals when Composer printed them).
     *
     * @param string $log  the run's output, with or without colour codes
     * @param int    $exit the exit code
     * @return array hash state, counts (hash installs, updates, removals)
     */
    public static function outcomeOf( $log, $exit )
    {
        $counts = array( 'installs' => 0, 'updates' => 0, 'removals' => 0 );
        if ( (int)$exit !== 0 )
        {
            return array( 'state' => 'failed', 'counts' => $counts );
        }
        $text = preg_replace( '/\x1b\[[0-9;]*m/', '', (string)$log );
        // "Package operations: ..." is the real run, "Lock file operations: ..." the lock only; the last one wins.
        if ( preg_match_all( '/^(?:Package|Lock file) operations: (\d+) installs?, (\d+) updates?, (\d+) removals?/m', $text, $all, PREG_SET_ORDER ) )
        {
            $last = end( $all );
            $counts = array( 'installs' => (int)$last[1], 'updates' => (int)$last[2], 'removals' => (int)$last[3] );
            $state = array_sum( $counts ) > 0 ? 'changed' : 'uptodate';
        }
        else if ( preg_match( '/^Nothing to (?:install, update or remove|modify in lock file)/m', $text ) )
        {
            $state = 'uptodate';
        }
        else
        {
            $state = 'changed';
        }
        return array( 'state' => $state, 'counts' => $counts );
    }

    /**
     * The sentence the user is shown when the run has ended.
     *
     * @return array hash state (ok|bad|info), text
     */
    public function resultMessage( $status, $exit, $log )
    {
        if ( $status === 'failed' )
        {
            return array( 'state' => 'bad', 'text' => ezpI18n::tr( 'extension/ezupdate', 'Failed with exit code %code.', null, array( '%code' => $exit ) ) );
        }
        if ( $status === 'stopped' )
        {
            return array( 'state' => 'bad', 'text' => ezpI18n::tr( 'extension/ezupdate', 'The run stopped before it finished.' ) );
        }
        if ( $status !== 'finished' )
        {
            return array( 'state' => '', 'text' => '' );
        }
        $outcome = self::outcomeOf( $log, 0 );
        if ( $outcome['state'] === 'uptodate' )
        {
            return array( 'state' => 'ok', 'text' => ezpI18n::tr( 'extension/ezupdate', 'The installation is up to date! Update again soon to remain secure.' ) );
        }
        $parts = array();
        $c = $outcome['counts'];
        if ( $c['installs'] ) $parts[] = ezpI18n::tr( 'extension/ezupdate', '%count installed', null, array( '%count' => $c['installs'] ) );
        if ( $c['updates'] )  $parts[] = ezpI18n::tr( 'extension/ezupdate', '%count updated', null, array( '%count' => $c['updates'] ) );
        if ( $c['removals'] ) $parts[] = ezpI18n::tr( 'extension/ezupdate', '%count removed', null, array( '%count' => $c['removals'] ) );
        $summary = implode( ', ', $parts );
        if ( substr( (string)$this->data['kind'], -8 ) === '-dry-run' )
        {
            return array( 'state' => 'info', 'text' => $summary !== ''
                ? ezpI18n::tr( 'extension/ezupdate', 'Dry run finished. It would change: %summary. Nothing was changed.', null, array( '%summary' => $summary ) )
                : ezpI18n::tr( 'extension/ezupdate', 'Dry run finished. Nothing was changed.' ) );
        }
        return array( 'state' => 'ok', 'text' => $summary !== ''
            ? ezpI18n::tr( 'extension/ezupdate', 'Finished. Changed: %summary.', null, array( '%summary' => $summary ) )
            : ezpI18n::tr( 'extension/ezupdate', 'Finished.' ) );
    }

    /**
     * The status and the whole output as HTML, for the progress page.
     */
    public function progress()
    {
        $log = is_file( self::logFile( $this->data['id'] ) ) ? (string)file_get_contents( self::logFile( $this->data['id'] ) ) : '';
        // A worker that died leaves "running" behind without holding the lock.
        if ( $this->data['status'] === 'running' && !self::isRunning() )
        {
            clearstatcache();
            $fresh = self::fetch( $this->data['id'] );
            if ( $fresh && $fresh->data['status'] === 'running' )
            {
                $this->data['status'] = 'stopped';
            }
            else if ( $fresh )
            {
                $this->data = $fresh->data;
            }
        }
        $message = $this->resultMessage( $this->data['status'], $this->data['exit'], $log );
        return array(
            'message'  => $message['text'],
            'message_state' => $message['state'],
            'id'       => $this->data['id'],
            'status'   => $this->data['status'],
            'exit'     => $this->data['exit'],
            'label'    => $this->data['label'],
            'started'  => $this->data['started'],
            'finished' => $this->data['finished'],
            'html'     => eZUpdateManager::ansiToHtml( $log ),
            'bytes'    => strlen( $log ),
        );
    }
}
