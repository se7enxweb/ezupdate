{* Setup > Updates and packages > a run (update/job/<id>): its result, status and times, the live output of Composer
   (ezupdate.js polls update/job/<id>/json until the run ends) and the form to run it again. Built from the shared
   components (.a4-notice, .a4-badge, .a4-card, .a4-pre, .a4-check, .a4-btn); the rest is .a4-update-* in
   stylesheets/modules/update.css. No inline CSS or script; the output's colours are classes
   (eZUpdateManager::ansiToHtml()). Every field and button name of the view is kept. *}
{def $ended = or( eq( $progress.status, 'finished' ), eq( $progress.status, 'failed' ), eq( $progress.status, 'stopped' ) )}
{include uri='design:ezupdate/parts/header.tpl' current='dashboard' error=$error
         title=$job.label
         actions=array( hash( 'url', 'update/dashboard', 'text', concat( '← ', 'Overview'|i18n( 'extension/ezupdate' ) ), 'external', false(), 'download', false() ) )}

{* The result of the run: filled in by ezupdate.js when the run ends while this page is open. *}
<div id="ezupdate-job-result" class="a4-notice is-{if $progress.message_state|eq( '' )}ok{else}{$progress.message_state|wash}{/if} a4-update-section" role="status" aria-live="polite"{if $progress.message|eq( '' )} hidden="hidden"{/if}>
    <strong class="a4-notice-title">{$progress.message|wash}</strong>
</div>

<div class="a4-update-run a4-update-section">
    <span id="ezupdate-job-status">{include uri='design:ezupdate/parts/status.tpl' status=$progress.status}</span>
    <span class="a4-meta">{'Started by'|i18n( 'extension/ezupdate' )} <strong>{$job.user|wash}</strong></span>
    <span class="a4-meta"><time data-ezx-ago="{$job.created}">{$job.created|l10n( 'shortdatetime' )}</time></span>
    <span class="a4-meta">{'Took'|i18n( 'extension/ezupdate' )} <strong data-ezx-elapsed="1" data-started="{if $progress.started}{$progress.started}{else}{$job.created}{/if}" data-finished="{if $progress.finished}{$progress.finished}{/if}">&ndash;</strong></span>
    {if and( $ended, is_set( $progress.exit ), $progress.exit|ne( '' ) )}<span class="a4-meta">{'Exit code'|i18n( 'extension/ezupdate' )} <strong>{$progress.exit|wash}</strong></span>{/if}
</div>

<section class="a4-card a4-update-section a4-update-term" data-ezx-term="1" aria-labelledby="ezupdate-job-output-title">
    <div class="a4-card-head">
        <h2 id="ezupdate-job-output-title" class="a4-update-term-title">composer &middot; {$job.label|wash}</h2>
        <div class="a4-card-actions">
            <label class="a4-check" title="{'Keep the newest output in view'|i18n( 'extension/ezupdate' )|wash}"><input type="checkbox" data-ezx-follow="1" checked="checked" /> <span>{'Follow'|i18n( 'extension/ezupdate' )}</span></label>
            <label class="a4-check"><input type="checkbox" data-ezx-wrap="1" checked="checked" /> <span>{'Wrap lines'|i18n( 'extension/ezupdate' )}</span></label>
            <button type="button" class="a4-btn a4-btn-small a4-update-copy" data-ezx-copy-target="ezupdate-job-output" data-done="{'Copied'|i18n( 'extension/ezupdate' )|wash}">{'Copy'|i18n( 'extension/ezupdate' )}</button>
        </div>
    </div>
    <div class="a4-card-body">
        {* The output is HTML made by eZUpdateManager::ansiToHtml(), which escapes it first. *}
        <pre class="a4-pre is-tall a4-update-terminal" id="ezupdate-job-output" tabindex="0" role="region" aria-labelledby="ezupdate-job-output-title"
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
        <p class="a4-notice is-warn a4-update-note" id="ezupdate-job-notice" role="status" aria-live="polite" hidden="hidden"></p>
    </div>
</section>

{if $can_rerun}
<section class="a4-card a4-update-section" aria-labelledby="ezupdate-job-rerun">
    <div class="a4-card-head"><h2 id="ezupdate-job-rerun">{'Run again'|i18n( 'extension/ezupdate' )}</h2></div>
    <form method="post" action={concat( 'update/job/', $job.id )|ezurl} class="a4-card-foot a4-update-foot">
        {* Buttons wait for this run to end; ezupdate.js enables them then. *}
        {if $rerun_changes|not}
        <input class="a4-btn" type="submit" name="RerunButton" value="{'Run again'|i18n( 'extension/ezupdate' )}" data-ezupdate-when-done="1"{if or( $ended|not, $job_running )} disabled="disabled"{/if} />
        {/if}
        {if or( $rerun_changes, $is_dry_run )}
            {if $can_change}
            <span class="a4-update-confirm">
                <label class="a4-check"><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="{if $rerun_changes}RerunButton{else}RunForRealButton{/if}" /> <span>{'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</span></label>
                {if $rerun_changes}
                <input class="a4-btn a4-btn-primary" type="submit" name="RerunButton" value="{'Run again'|i18n( 'extension/ezupdate' )}" disabled="disabled" />
                {else}
                <input class="a4-btn a4-btn-primary" type="submit" name="RunForRealButton" value="{'Run it for real'|i18n( 'extension/ezupdate' )}" disabled="disabled" />
                {/if}
            </span>
            {elseif $rerun_changes}
            <span class="a4-meta">{'Running this again is switched off (AllowUpdate / AllowInstall in ezupdate.ini).'|i18n( 'extension/ezupdate' )}</span>
            {/if}
        {/if}
    </form>
</section>
{/if}
{undef $ended}
{include uri='design:ezupdate/parts/footer.tpl'}
