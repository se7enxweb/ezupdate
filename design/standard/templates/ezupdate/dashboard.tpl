{include uri='design:ezupdate/parts/header.tpl' current='dashboard' error=$error message=$notice}
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
                    {else}<span class="ezupdate-badge ezupdate-bad">{'Not found'|i18n( 'extension/ezupdate' )}</span>
                    <pre class="ezupdate-message">{$composer_not_found|wash}</pre>
                    {if $can_manage}
                    <form method="post" action={'update/dashboard'|ezurl} class="ezupdate-bar">
                        <input class="defaultbutton" type="submit" name="GetComposerButton" value="{'Get Composer'|i18n( 'extension/ezupdate' )}" data-ezx-busy="{'Downloading...'|i18n( 'extension/ezupdate' )|wash}" />
                    </form>
                    {/if}{/if}
                    {if $composer_trusted}<span class="ezupdate-muted">{'Taken from ezupdate.ini; open_basedir keeps PHP from checking the file.'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
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
                <dt>{'Installing new packages'|i18n( 'extension/ezupdate' )}</dt>
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
        {def $installable = 0}
        {if $outdated|is_array}{foreach $outdated as $package}{if $package.installable}{set $installable = $installable|inc}{/if}{/foreach}{/if}
        <form method="post" action={'update/dashboard'|ezurl}>
        <div class="ezx-panel-body{if and( $outdated|is_array, $outdated|count )} ezx-panel-flush{/if}">
        {if $outdated|is_array}
            {if $outdated|count}
            <table class="ezx-table">
                <thead><tr>
                    <th><span class="hide">{'Select'|i18n( 'extension/ezupdate' )}</span></th>
                    <th>{'Package'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Installed'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Latest'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Kind'|i18n( 'extension/ezupdate' )}</th>
                </tr></thead>
                <tbody>
                {foreach $outdated as $package}
                <tr>
                    <td>{if $package.installable}<input type="checkbox" name="Packages[]" value="{$package.name|wash}" checked="checked" title="{'Install this update'|i18n( 'extension/ezupdate' )|wash}" />{/if}</td>
                    <td class="ezx-title-cell"><a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>
                        <small>{$package.description|wash|shorten( 100 )}</small></td>
                    <td data-label="{'Installed'|i18n( 'extension/ezupdate' )}"><code>{$package.version|wash}</code></td>
                    <td data-label="{'Latest'|i18n( 'extension/ezupdate' )}"><code>{$package.latest|wash}</code></td>
                    <td>{if $package.installable}<span class="ezupdate-badge ezupdate-good">{'Can be installed'|i18n( 'extension/ezupdate' )}</span>
                        {if and( $package.would_install, ne( $package.would_install, $package.latest ) )}<small>{'Would install %version'|i18n( 'extension/ezupdate',, hash( '%version', $package.would_install ) )|wash}</small>{/if}
                        {elseif $package.unknown}<span class="ezupdate-badge">{'Could not be checked'|i18n( 'extension/ezupdate' )}</span>
                        {elseif $package.constraint}<span class="ezupdate-badge ezupdate-warn">{'Blocked by composer.json (%constraint)'|i18n( 'extension/ezupdate',, hash( '%constraint', $package.constraint ) )|wash}</span>
                        {else}<span class="ezupdate-badge ezupdate-warn">{'Blocked by composer.json or another package'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                </tr>
                {/foreach}
                </tbody>
            </table>
            {foreach $lock_mismatch as $name}<input type="hidden" name="Packages[]" value="{$name|wash}" />{/foreach}
            {if $lock_mismatch|count}<p class="ezupdate-muted ezupdate-lockmismatch">{'composer.json asks for newer versions than composer.lock holds of: %packages. Composer needs them in the same run, so they are always included.'|i18n( 'extension/ezupdate',, hash( '%packages', $lock_mismatch|implode( ', ' ) ) )|wash}</p>{/if}
            {else}
            <div class="ezx-empty"><strong>{'Everything is up to date'|i18n( 'extension/ezupdate' )}</strong>{'Every package composer.json names is at its latest release.'|i18n( 'extension/ezupdate' )}</div>
            {/if}
        {else}
            <div class="ezx-empty"><strong>{'Not checked yet'|i18n( 'extension/ezupdate' )}</strong>{'Check for updates to see which packages have a newer release.'|i18n( 'extension/ezupdate' )}</div>
        {/if}
        </div>
        <footer>
            <div class="ezupdate-bar">
                <input class="button" type="submit" name="CheckForUpdatesButton" value="{'Check for updates'|i18n( 'extension/ezupdate' )}" data-ezx-busy="{'Checking...'|i18n( 'extension/ezupdate' )|wash}" />
                {include uri='design:ezupdate/parts/method.tpl'}
                <input class="button" type="submit" name="DryRunUpdateButton" value="{'Preview (dry run)'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
                {if and( $can_manage, $update_allowed, $installable )}
                <span class="ezupdate-confirm">
                    <label><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="InstallUpdatesButton" /> {'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</label>
                    <input class="defaultbutton ezupdate-primary" type="submit" name="InstallUpdatesButton" value="{'Install updates'|i18n( 'extension/ezupdate' )}" disabled="disabled" />
                </span>
                {else}
                <input class="defaultbutton ezupdate-primary" type="submit" name="InstallUpdatesButton" value="{'Install updates'|i18n( 'extension/ezupdate' )}" disabled="disabled" aria-describedby="ezupdate-install-note" />
                {/if}
            </div>
        </footer>
        </form>
        <div class="ezupdate-after">
        {if or( $update_allowed|not, and( $outdated|is_array, $installable|not ), $outdated|is_array|not )}
        <div class="ezupdate-install-note" id="ezupdate-install-note">
            {if $update_allowed|not}
            <p><strong>{'Installing updates is switched off.'|i18n( 'extension/ezupdate' )}</strong>
                {'Composer rewrites vendor/ and the files of every package it updates, so this stays off until you choose otherwise. Make a backup of the files and the database first.'|i18n( 'extension/ezupdate' )}
                {'To switch it on, set AllowUpdate=enabled under [UpdateSettings] in settings/override/ezupdate.ini.append.php'|i18n( 'extension/ezupdate' )}{if $can_manage}{', or use the button below.'|i18n( 'extension/ezupdate' )}{else}{'.'|i18n( 'extension/ezupdate' )}{/if}</p>
            {if $can_manage}
            <form method="post" action={'update/dashboard'|ezurl}>
                <input class="button" type="submit" name="SwitchUpdatesOnButton" value="{'Switch on updates'|i18n( 'extension/ezupdate' )}" />
            </form>
            {/if}
            {elseif $outdated|is_array|not}
            <p>{'Check for updates first: then the packages that can be installed are listed and ticked here.'|i18n( 'extension/ezupdate' )}</p>
            {elseif $installable|not}
            <p>{'No package on this list can be installed by an update: composer.json blocks them. Raise their constraints in composer.json first.'|i18n( 'extension/ezupdate' )}</p>
            {/if}
        </div>
        {/if}
        {if and( $update_allowed, $can_manage )}
        <form method="post" action={'update/dashboard'|ezurl} class="ezupdate-switch">
            <span class="ezupdate-muted">{'Installing updates is switched on.'|i18n( 'extension/ezupdate' )}</span>
            <input class="button ezx-btn-s" type="submit" name="SwitchUpdatesOffButton" value="{'Switch off'|i18n( 'extension/ezupdate' )}" />
        </form>
        {/if}
        </div>
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
