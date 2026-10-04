{include uri='design:ezupdate/parts/header.tpl' current='dashboard' error=$error}
{def $ended = or( eq( $progress.status, 'finished' ), eq( $progress.status, 'failed' ), eq( $progress.status, 'stopped' ) )}
<div class="ezx-page">

    {* The result of the run: filled in by ezupdate.js when the run ends while this page is open. *}
    <div id="ezupdate-job-result" class="ezx-alert ezx-alert-{if $progress.message_state|eq( '' )}ok{else}{$progress.message_state}{/if}" role="status" aria-live="polite"{if $progress.message|eq( '' )} hidden="hidden"{/if}>
        <div><h2>{$progress.message|wash}</h2></div>
    </div>

    <div class="ezx-head">
        <div>
            <h1>{$job.label|wash}</h1>
            <div class="ezx-run">
                <span id="ezupdate-job-status">{include uri='design:ezupdate/parts/status.tpl' status=$progress.status}</span>
                <span class="ezx-run-meta">
                    <span>{'Started by'|i18n( 'extension/ezupdate' )} <b>{$job.user|wash}</b></span>
                    <span><time data-ezx-ago="{$job.created}">{$job.created|l10n( 'shortdatetime' )}</time></span>
                    <span>{'Took'|i18n( 'extension/ezupdate' )} <b data-ezx-elapsed="1" data-started="{if $progress.started}{$progress.started}{else}{$job.created}{/if}" data-finished="{if $progress.finished}{$progress.finished}{/if}">&ndash;</b></span>
                    {if and( $ended, is_set( $progress.exit ), $progress.exit|ne( '' ) )}<span>{'Exit code'|i18n( 'extension/ezupdate' )} <b>{$progress.exit|wash}</b></span>{/if}
                </span>
            </div>
        </div>
        <div class="ezx-head-actions">
            <a class="button ezx-btn-s" href={'update/dashboard'|ezurl}>&larr; {'Overview'|i18n( 'extension/ezupdate' )}</a>
        </div>
    </div>

    <div class="ezx-term" data-ezx-term="1">
        <div class="ezx-term-bar">
            <span class="ezx-dots" aria-hidden="true"><i></i><i></i><i></i></span>
            <span class="ezx-term-title">composer &middot; {$job.label|wash}</span>
            <label title="{'Keep the newest output in view'|i18n( 'extension/ezupdate' )}"><input type="checkbox" data-ezx-follow="1" checked="checked" /> {'Follow'|i18n( 'extension/ezupdate' )}</label>
            <label><input type="checkbox" data-ezx-wrap="1" checked="checked" /> {'Wrap lines'|i18n( 'extension/ezupdate' )}</label>
            <button type="button" data-ezx-copy-target="ezupdate-job-output" data-done="{'Copied'|i18n( 'extension/ezupdate' )|wash}">{'Copy'|i18n( 'extension/ezupdate' )}</button>
        </div>
        {* The output is HTML made by eZUpdateManager::ansiToHtml(), which escapes it first. *}
        <pre class="ezupdate-terminal" id="ezupdate-job-output"
             data-ezupdate-job="{concat( 'update/job/', $job.id, '/json' )|ezurl( 'no' )}"
             data-ezupdate-done="{if $ended}1{else}0{/if}"
             data-status-finished="{'Finished'|i18n( 'extension/ezupdate' )|wash}"
             data-status-failed="{'Failed'|i18n( 'extension/ezupdate' )|wash}"
             data-status-stopped="{'Stopped'|i18n( 'extension/ezupdate' )|wash}"
             data-status-running="{'Running'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-signedout="{'You are no longer signed in, so the output cannot be followed. Sign in again and reload this page: the run goes on on the server.'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-refused="{'The server refused to show this run (HTTP 403). The update/job policy is needed to follow it.'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-server="{'The server answered with an error (HTTP %status). Trying again...'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-noanswer="{'No answer from the server. Trying again...'|i18n( 'extension/ezupdate' )|wash}"
             data-notice-gaveup="{'Contact with this run was lost after %count attempts. It goes on on the server: reload this page to follow it.'|i18n( 'extension/ezupdate' )|wash}">{$progress.html}</pre>
    </div>
    <p class="ezupdate-notice" id="ezupdate-job-notice" role="status" aria-live="polite" hidden="hidden"></p>

    {if $can_rerun}
    <section class="ezx-panel">
        <header><h2>{'Run again'|i18n( 'extension/ezupdate' )}</h2></header>
        <footer>
        <form method="post" action={concat( 'update/job/', $job.id )|ezurl} class="ezupdate-bar">
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
        </form>
        </footer>
    </section>
    {/if}
</div>
{undef $ended}
{include uri='design:ezupdate/parts/footer.tpl'}
