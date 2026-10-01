{include uri='design:ezupdate/parts/header.tpl' current='dashboard' error=$error}
<div class="ezx-page">

    <div class="ezx-head">
        <div>
            <h1>{'Overview'|i18n( 'extension/ezupdate' )}</h1>
            <p>{'The installation\'s Composer: where it is, what may be run, which packages have a newer release, and the recent runs.'|i18n( 'extension/ezupdate' )}</p>
        </div>
    </div>

    <div class="ezx-stats">
        <a class="ezx-stat" href={'update/installed'|ezurl}><strong>{$installed_count}</strong><span>{'Installed by Composer'|i18n( 'extension/ezupdate' )}</span></a>
        <a class="ezx-stat" href={'update/installed#extension'|ezurl}><strong>{$inventory.extension}</strong><span>{'Extensions, %active active'|i18n( 'extension/ezupdate',, hash( '%active', $inventory.active ) )}</span></a>
        <a class="ezx-stat{if $inventory.issues} is-warn{else} is-ok{/if}" href={'update/installed#issues'|ezurl}><strong>{$inventory.issues}</strong><span>{'Need attention'|i18n( 'extension/ezupdate' )}</span></a>
        <div class="ezx-stat{if $outdated|is_array}{if $outdated|count} is-warn{else} is-ok{/if}{/if}">
            <strong>{if $outdated|is_array}{$outdated|count}{else}&ndash;{/if}</strong>
            <span>{if $outdated|is_array}{'With a newer release'|i18n( 'extension/ezupdate' )}{else}{'Updates not checked yet'|i18n( 'extension/ezupdate' )}{/if}</span>
        </div>
        <a class="ezx-stat" href={if $last_job}{concat( 'update/job/', $last_job.id )|ezurl}{else}"#ezx-runs"{/if}>
            <strong>{if $last_job}{include uri='design:ezupdate/parts/status.tpl' status=$last_job.status}{else}&ndash;{/if}</strong>
            <span>{if $last_job}{'Last run %date'|i18n( 'extension/ezupdate',, hash( '%date', $last_job.created|l10n( 'shortdatetime' ) ) )}{else}{'No runs yet'|i18n( 'extension/ezupdate' )}{/if}</span>
        </a>
    </div>

    <section class="ezx-panel">
        <header><h2>{'Composer'|i18n( 'extension/ezupdate' )}</h2></header>
        <div class="ezx-panel-body">
            <dl class="ezx-facts">
                <dt>{'Composer'|i18n( 'extension/ezupdate' )}</dt>
                <dd>{if $composer_binary}<code>{$composer_binary|wash}</code>{if $composer_version} <span class="ezupdate-muted">{$composer_version|wash}</span>{/if}
                    {if $composer_problem}<span class="ezupdate-badge ezupdate-bad">{'Does not start'|i18n( 'extension/ezupdate' )}</span><pre class="ezupdate-message">{$composer_problem|wash}</pre>{/if}
                    {else}<span class="ezupdate-badge ezupdate-bad">{'Not found'|i18n( 'extension/ezupdate' )}</span> {'Set [ComposerSettings] Path in ezupdate.ini.'|i18n( 'extension/ezupdate' )}{/if}</dd>
                <dt>{'PHP for Composer'|i18n( 'extension/ezupdate' )}</dt>
                <dd>{if $php_binary}<code>{$php_binary|wash}</code>{else}<span class="ezupdate-badge ezupdate-bad">{'Not found'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
                <dt>{'Installation'|i18n( 'extension/ezupdate' )}</dt>
                <dd><code data-ezx-copy="1">{$project_path|wash}</code>
                    {if $has_composer_json}<span class="ezupdate-muted">{'composer.json, %count packages installed'|i18n( 'extension/ezupdate',, hash( '%count', $installed_count ) )}</span>
                        {if $composer_json_writable|not}<span class="ezupdate-badge ezupdate-warn">{'composer.json is read-only for the web server'|i18n( 'extension/ezupdate' )}</span>{/if}
                    {else}<span class="ezupdate-badge ezupdate-bad">{'No composer.json'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
                <dt>{'Package servers'|i18n( 'extension/ezupdate' )}</dt>
                <dd>{if $packagist_enabled}packagist.org{else}<span class="ezupdate-muted">{'packagist.org switched off'|i18n( 'extension/ezupdate' )}</span>{/if}
                    {if $composer_server_count}, {'%count more in composer.json'|i18n( 'extension/ezupdate',, hash( '%count', $composer_server_count ) )}{/if}
                    &middot; <a href={'update/servers'|ezurl}>{'Edit'|i18n( 'extension/ezupdate' )}</a></dd>
                <dt>{'Updating'|i18n( 'extension/ezupdate' )}</dt>
                <dd>{if $update_allowed}<span class="ezupdate-badge ezupdate-warn">{'Allowed'|i18n( 'extension/ezupdate' )}</span>
                    {else}<span class="ezupdate-badge">{'Switched off'|i18n( 'extension/ezupdate' )}</span> <span class="ezupdate-muted">[UpdateSettings] AllowUpdate</span>{/if}</dd>
                <dt>{'Installing'|i18n( 'extension/ezupdate' )}</dt>
                <dd>{if $install_allowed}<span class="ezupdate-badge ezupdate-warn">{'Allowed'|i18n( 'extension/ezupdate' )}</span>
                    {else}<span class="ezupdate-badge">{'Switched off'|i18n( 'extension/ezupdate' )}</span> <span class="ezupdate-muted">[UpdateSettings] AllowInstall</span>{/if}</dd>
            </dl>
        </div>
    </section>

    <section class="ezx-panel" id="ezx-updates">
        <header>
            <div>
                <h2>{'Updates'|i18n( 'extension/ezupdate' )}</h2>
                <p>{'Asks the package servers which of the packages composer.json names have a newer release. Nothing is changed.'|i18n( 'extension/ezupdate' )}</p>
            </div>
        </header>
        <div class="ezx-panel-body{if and( $outdated|is_array, $outdated|count )} ezx-panel-flush{/if}">
        {if $outdated|is_array}
            {if $outdated|count}
            <table class="ezx-table">
                <thead><tr>
                    <th>{'Package'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Installed'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Latest'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Kind'|i18n( 'extension/ezupdate' )}</th>
                </tr></thead>
                <tbody>
                {foreach $outdated as $package}
                <tr>
                    <td class="ezx-title-cell"><a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>
                        <small>{$package.description|wash|shorten( 100 )}</small></td>
                    <td data-label="{'Installed'|i18n( 'extension/ezupdate' )}"><code>{$package.version|wash}</code></td>
                    <td data-label="{'Latest'|i18n( 'extension/ezupdate' )}"><code>{$package.latest|wash}</code></td>
                    <td>{if eq( $package.status, 'semver-safe-update' )}<span class="ezupdate-badge ezupdate-good">{'Within the constraint'|i18n( 'extension/ezupdate' )}</span>
                        {else}<span class="ezupdate-badge ezupdate-warn">{'Needs a new constraint'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                </tr>
                {/foreach}
                </tbody>
            </table>
            {else}
            <div class="ezx-empty"><strong>{'Everything is up to date'|i18n( 'extension/ezupdate' )}</strong>{'Every package composer.json names is at its latest release.'|i18n( 'extension/ezupdate' )}</div>
            {/if}
        {else}
            <div class="ezx-empty"><strong>{'Not checked yet'|i18n( 'extension/ezupdate' )}</strong>{'Check for updates to see which packages have a newer release.'|i18n( 'extension/ezupdate' )}</div>
        {/if}
        </div>
        <footer>
            <form method="post" action={'update/dashboard'|ezurl} class="ezupdate-bar">
                <input class="defaultbutton" type="submit" name="CheckForUpdatesButton" value="{'Check for updates'|i18n( 'extension/ezupdate' )}" data-ezx-busy="{'Checking...'|i18n( 'extension/ezupdate' )|wash}" />
                {include uri='design:ezupdate/parts/method.tpl'}
                <input class="button" type="submit" name="DryRunUpdateButton" value="{'Update, dry run'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
                {if and( $can_manage, $update_allowed )}
                <span class="ezupdate-confirm">
                    <label><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="UpdateButton" /> {'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</label>
                    <input class="button" type="submit" name="UpdateButton" value="{'Update'|i18n( 'extension/ezupdate' )}" disabled="disabled" />
                </span>
                {/if}
            </form>
        </footer>
    </section>

    {if $jobs|count}
    <section class="ezx-panel" id="ezx-runs">
        <header><h2>{'Recent runs'|i18n( 'extension/ezupdate' )}</h2></header>
        <div class="ezx-panel-body ezx-panel-flush">
            <table class="ezx-table">
                <thead><tr>
                    <th>{'Run'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'By'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Started'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Status'|i18n( 'extension/ezupdate' )}</th>
                    <th><span class="hide">{'Actions'|i18n( 'extension/ezupdate' )}</span></th>
                </tr></thead>
                <tbody>
                {foreach $jobs as $job}
                <tr>
                    <td class="ezx-title-cell"><a href={concat( 'update/job/', $job.id )|ezurl}>{$job.label|wash}</a></td>
                    <td data-label="{'By'|i18n( 'extension/ezupdate' )}">{$job.user|wash}</td>
                    <td data-label="{'Started'|i18n( 'extension/ezupdate' )}"><time datetime="{$job.created|datetime( 'custom', '%Y-%m-%dT%H:%i:%s' )}" data-ezx-ago="{$job.created}">{$job.created|l10n( 'shortdatetime' )}</time></td>
                    <td>{include uri='design:ezupdate/parts/status.tpl' status=$job.status}</td>
                    <td class="ezx-actions">
                        {* A dry run runs again from here; a run that changes the installation asks for the backup on its own page. *}
                        {if $job.changes|not}
                        <form method="post" action={concat( 'update/job/', $job.id )|ezurl}>
                            <input class="button ezx-btn-s" type="submit" name="RerunButton" value="{'Run again'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
                        </form>
                        {else}
                        <a class="button ezx-btn-s" href={concat( 'update/job/', $job.id )|ezurl}>{'Run again'|i18n( 'extension/ezupdate' )}&hellip;</a>
                        {/if}
                    </td>
                </tr>
                {/foreach}
                </tbody>
            </table>
        </div>
    </section>
    {/if}
</div>
{include uri='design:ezupdate/parts/footer.tpl'}
