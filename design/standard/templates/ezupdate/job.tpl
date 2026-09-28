{include uri='design:ezupdate/parts/header.tpl' current='dashboard'}

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
             data-status-running="{'Running'|i18n( 'extension/ezupdate' )|wash}">{$progress.html}</pre>
    </div>
    <div class="controlbar">
        <a class="button" href={'update/dashboard'|ezurl}>{'Back to installed packages'|i18n( 'extension/ezupdate' )}</a>
    </div>
</div>
