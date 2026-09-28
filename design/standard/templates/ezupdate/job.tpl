{include uri='design:ezupdate/parts/header.tpl' current='dashboard' error=$error}
{def $ended = or( eq( $progress.status, 'finished' ), eq( $progress.status, 'failed' ), eq( $progress.status, 'stopped' ) )}

<div class="context-block ezupdate">
    <div class="box-header">
        <h1 class="context-title">{$job.label|wash}</h1>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <p>
            <span id="ezupdate-job-status">{include uri='design:ezupdate/parts/status.tpl' status=$progress.status}</span>
            <span class="ezupdate-muted">{'Started by %user on %date'|i18n( 'extension/ezupdate',, hash( '%user', $job.user|wash, '%date', $job.created|l10n( 'shortdatetime' ) ) )}</span>
        </p>
        {* The output is HTML made by eZUpdateManager::ansiToHtml(), which escapes it first. *}
        <pre class="ezupdate-terminal" id="ezupdate-job-output"
             data-ezupdate-job="{concat( 'update/job/', $job.id, '/json' )|ezurl( 'no' )}"
             data-ezupdate-done="{if or( eq( $progress.status, 'finished' ), eq( $progress.status, 'failed' ), eq( $progress.status, 'stopped' ) )}1{else}0{/if}"
             data-status-finished="{'Finished'|i18n( 'extension/ezupdate' )|wash}"
             data-status-failed="{'Failed'|i18n( 'extension/ezupdate' )|wash}"
             data-status-stopped="{'Stopped'|i18n( 'extension/ezupdate' )|wash}"
             data-status-running="{'Running'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-signedout="{'You are no longer signed in, so the output cannot be followed. Sign in again and reload this page: the run goes on on the server.'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-refused="{'The server refused to show this run (HTTP 403). The update/job policy is needed to follow it.'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-server="{'The server answered with an error (HTTP %status). Trying again...'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-noanswer="{'No answer from the server. Trying again...'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-gaveup="{'Contact with this run was lost after %count attempts. It goes on on the server: reload this page to follow it.'|i18n( 'extension/ezupdate' )|wash}">{$progress.html}</pre>
        <p class="ezupdate-notice" id="ezupdate-job-notice" role="status" aria-live="polite" hidden="hidden"></p>
    </div>
    <div class="controlbar">
        <form method="post" action={concat( 'update/job/', $job.id )|ezurl} class="ezupdate-bar">
            <a class="button" href={'update/dashboard'|ezurl}>{'Back to installed packages'|i18n( 'extension/ezupdate' )}</a>
            {if $can_rerun}
                {* Buttons wait for this run to end; ezupdate.js enables them then. *}
                {if $rerun_changes|not}
                <input class="button" type="submit" name="RerunButton" value="{'Run again'|i18n( 'extension/ezupdate' )}" data-ezupdate-when-done="1"{if or( $ended|not, $job_running )} disabled="disabled"{/if} />
                {/if}
                {if or( $rerun_changes, $is_dry_run )}
                    {if $can_change}
                    <span class="ezupdate-confirm">
                        <label><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="{if $rerun_changes}RerunButton{else}RunForRealButton{/if}" /> {'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</label>
                        {if $rerun_changes}
                        <input class="defaultbutton" type="submit" name="RerunButton" value="{'Run again'|i18n( 'extension/ezupdate' )}" disabled="disabled" />
                        {else}
                        <input class="defaultbutton" type="submit" name="RunForRealButton" value="{'Run it for real'|i18n( 'extension/ezupdate' )}" disabled="disabled" />
                        {/if}
                    </span>
                    {elseif $rerun_changes}
                    <span class="ezupdate-muted">{'Running this again is switched off (AllowUpdate / AllowInstall in ezupdate.ini).'|i18n( 'extension/ezupdate' )}</span>
                    {/if}
                {/if}
            {/if}
        </form>
    </div>
</div>
