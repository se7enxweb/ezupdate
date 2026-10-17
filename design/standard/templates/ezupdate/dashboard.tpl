{* Setup > Updates and packages > Overview (update/dashboard).

   The figures (installed, extensions, issues, updates, the last run), the Composer facts, the updates with their
   form (check, dry run, install behind the backup box) and the recent runs. Built from the administration's shared
   components (.a4-figures, .a4-card, .a4-facts, .a4-table, .a4-badge, .a4-btn, .a4-notice, .a4-empty), so it
   follows admin4's light and dark look and reads in the classic admin; what they cannot do is .a4-update-* in
   stylesheets/modules/update.css. No inline CSS or script: ezupdate.js reads the data-* attributes.
   Every field and button name of the view is kept. *}
{include uri='design:ezupdate/parts/header.tpl' current='dashboard' error=$error message=$notice
         title='Overview'|i18n( 'extension/ezupdate' )
         intro='The installation\'s Composer: where it is, what may be run, which packages have a newer release, and the recent runs.'|i18n( 'extension/ezupdate' )}

<section class="a4-update-section" aria-labelledby="ezupdate-summary-title">
    <h2 class="a4-sr-only" id="ezupdate-summary-title">{'Summary'|i18n( 'extension/ezupdate' )}</h2>
    <ul class="a4-figures a4-update-figures">
        <li class="a4-figure"><a href={'update/installed'|ezurl}><strong>{$installed_count}</strong><span>{'Installed by Composer'|i18n( 'extension/ezupdate' )}</span></a></li>
        <li class="a4-figure"><a href={'update/installed#extension'|ezurl}><strong>{$inventory.extension}</strong><span>{'Extensions on disk, %active active in any siteaccess'|i18n( 'extension/ezupdate',, hash( '%active', $inventory.active ) )}</span></a></li>
        <li class="a4-figure{if $inventory.issues} is-warn{else} is-ok{/if}"><a href={'update/installed#issues'|ezurl}><strong>{$inventory.issues}</strong><span>{'Need attention'|i18n( 'extension/ezupdate' )}</span></a></li>
        <li class="a4-figure{if $outdated|is_array}{if $outdated|count} is-warn{else} is-ok{/if}{/if}">
            <strong>{if $outdated|is_array}{$outdated|count}{else}&ndash;{/if}</strong>
            <span>{if $outdated|is_array}{'With a newer release'|i18n( 'extension/ezupdate' )}{else}{'Updates not checked yet'|i18n( 'extension/ezupdate' )}{/if}</span>
        </li>
        <li class="a4-figure"><a href={if $last_job}{concat( 'update/job/', $last_job.id )|ezurl}{else}"#ezx-runs"{/if}>
            <strong>{if $last_job}{include uri='design:ezupdate/parts/status.tpl' status=$last_job.status}{else}&ndash;{/if}</strong>
            <span>{if $last_job}{'Last run %date'|i18n( 'extension/ezupdate',, hash( '%date', $last_job.created|l10n( 'shortdatetime' ) ) )}{else}{'No runs yet'|i18n( 'extension/ezupdate' )}{/if}</span>
        </a></li>
    </ul>
</section>

<section class="a4-card a4-update-section" aria-labelledby="ezupdate-composer-title">
    <div class="a4-card-head"><h2 id="ezupdate-composer-title">{'Composer'|i18n( 'extension/ezupdate' )}</h2></div>
    <div class="a4-card-body">
        <dl class="a4-facts is-rows a4-update-facts">
            <dt>{'Composer'|i18n( 'extension/ezupdate' )}</dt>
            <dd>{if $composer_binary}<code>{$composer_binary|wash}</code>{if $composer_version} <span class="a4-meta">{$composer_version|wash}</span>{/if}
                {if $composer_problem}<span class="a4-badge is-bad">{'Does not start'|i18n( 'extension/ezupdate' )}</span><pre class="a4-pre a4-update-message">{$composer_problem|wash}</pre>{/if}
                {else}<span class="a4-badge is-bad">{'Not found'|i18n( 'extension/ezupdate' )}</span>
                <pre class="a4-pre a4-update-message">{$composer_not_found|wash}</pre>
                {if $can_manage}
                <form method="post" action={'update/dashboard'|ezurl} class="a4-actions a4-update-row">
                    <input class="a4-btn a4-btn-primary" type="submit" name="GetComposerButton" value="{'Get Composer'|i18n( 'extension/ezupdate' )}" data-ezx-busy="{'Downloading...'|i18n( 'extension/ezupdate' )|wash}" />
                </form>
                {/if}{/if}
                {if $composer_trusted}<span class="a4-meta">{'Taken from ezupdate.ini; open_basedir keeps PHP from checking the file.'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
            <dt>{'PHP for Composer'|i18n( 'extension/ezupdate' )}</dt>
            <dd>{if $php_binary}<code>{$php_binary|wash}</code>{else}<span class="a4-badge is-bad">{'Not found'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
            <dt>{'Installation'|i18n( 'extension/ezupdate' )}</dt>
            <dd><code id="ezupdate-project-path">{$project_path|wash}</code>
                <button type="button" class="a4-btn a4-btn-small a4-update-copy" data-ezx-copy-target="ezupdate-project-path" data-done="{'Copied'|i18n( 'extension/ezupdate' )|wash}" aria-label="{'Copy'|i18n( 'extension/ezupdate' )|wash}: {$project_path|wash}">{'Copy'|i18n( 'extension/ezupdate' )}</button>
                {if $has_composer_json}<span class="a4-meta">{'composer.json, %count packages installed'|i18n( 'extension/ezupdate',, hash( '%count', $installed_count ) )}</span>
                    {if $composer_json_writable|not}<span class="a4-badge is-warn">{'composer.json is read-only for the web server'|i18n( 'extension/ezupdate' )}</span>{/if}
                {else}<span class="a4-badge is-bad">{'No composer.json'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
            <dt>{'Package servers'|i18n( 'extension/ezupdate' )}</dt>
            <dd>{if $packagist_enabled}packagist.org{else}<span class="a4-muted">{'packagist.org switched off'|i18n( 'extension/ezupdate' )}</span>{/if}{if $composer_server_count}, {'%count more in composer.json'|i18n( 'extension/ezupdate',, hash( '%count', $composer_server_count ) )}{/if}
                &middot; <a href={'update/servers'|ezurl}>{'Edit'|i18n( 'extension/ezupdate' )}</a></dd>
            <dt>{'Updating'|i18n( 'extension/ezupdate' )}</dt>
            <dd>{if $update_allowed}<span class="a4-badge is-warn">{'Allowed'|i18n( 'extension/ezupdate' )}</span>
                {else}<span class="a4-badge">{'Switched off'|i18n( 'extension/ezupdate' )}</span> <code class="a4-meta">[UpdateSettings] AllowUpdate</code>{/if}</dd>
            <dt>{'Installing new packages'|i18n( 'extension/ezupdate' )}</dt>
            <dd>{if $install_allowed}<span class="a4-badge is-warn">{'Allowed'|i18n( 'extension/ezupdate' )}</span>
                {else}<span class="a4-badge">{'Switched off'|i18n( 'extension/ezupdate' )}</span> <code class="a4-meta">[UpdateSettings] AllowInstall</code>{/if}</dd>
        </dl>
    </div>
</section>

{def $installable = 0}
{if $outdated|is_array}{foreach $outdated as $package}{if $package.installable}{set $installable = $installable|inc}{/if}{/foreach}{/if}
<section class="a4-card a4-update-section" id="ezx-updates" aria-labelledby="ezupdate-updates-title">
    <div class="a4-card-head">
        <h2 id="ezupdate-updates-title">{'Updates'|i18n( 'extension/ezupdate' )}</h2>
        <p>{'Asks the package servers which of the packages composer.json names have a newer release. Nothing is changed.'|i18n( 'extension/ezupdate' )}</p>
    </div>

    {def $show_note = or( $update_allowed|not, and( $outdated|is_array, $installable|not ), $outdated|is_array|not )}
    {if $show_note}
    <div class="a4-notice is-info a4-update-note" id="ezupdate-install-note">
        {if $update_allowed|not}
        <strong class="a4-notice-title">{'Installing updates is switched off.'|i18n( 'extension/ezupdate' )}</strong>
        <p>{'Composer rewrites vendor/ and the files of every package it updates, so this stays off until you choose otherwise. Make a backup of the files and the database first.'|i18n( 'extension/ezupdate' )}
            {'To switch it on, set AllowUpdate=enabled under [UpdateSettings] in settings/override/ezupdate.ini.append.php'|i18n( 'extension/ezupdate' )}{if $can_manage}{', or use the button below.'|i18n( 'extension/ezupdate' )}{else}{'.'|i18n( 'extension/ezupdate' )}{/if}</p>
        {if $can_manage}
        <form method="post" action={'update/dashboard'|ezurl} class="a4-actions a4-update-row">
            <input class="a4-btn" type="submit" name="SwitchUpdatesOnButton" value="{'Switch on updates'|i18n( 'extension/ezupdate' )}" />
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
    <form method="post" action={'update/dashboard'|ezurl} class="a4-actions a4-update-row">
        <span class="a4-meta">{'Installing updates is switched on.'|i18n( 'extension/ezupdate' )}</span>
        <input class="a4-btn a4-btn-small" type="submit" name="SwitchUpdatesOffButton" value="{'Switch off'|i18n( 'extension/ezupdate' )}" />
    </form>
    {/if}

    <form method="post" action={'update/dashboard'|ezurl}>
    <div class="a4-card-body">
    {if $outdated|is_array}
        {if $outdated|count}
        <div class="a4-table-wrap">
        <table class="a4-table">
            <caption class="a4-sr-only">{'Packages with a newer release'|i18n( 'extension/ezupdate' )}</caption>
            <thead><tr>
                <th scope="col"><span class="a4-sr-only">{'Select'|i18n( 'extension/ezupdate' )}</span></th>
                <th scope="col">{'Package'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Installed'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Latest'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Kind'|i18n( 'extension/ezupdate' )}</th>
            </tr></thead>
            <tbody>
            {foreach $outdated as $package}
            <tr>
                <td>{if $package.installable}<input type="checkbox" name="Packages[]" value="{$package.name|wash}" checked="checked" title="{'Install this update'|i18n( 'extension/ezupdate' )|wash}" aria-label="{'Install this update'|i18n( 'extension/ezupdate' )|wash}: {$package.name|wash}" />{/if}</td>
                <td><a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>
                    {if $package.description}<span class="a4-meta a4-update-desc">{$package.description|wash|shorten( 100 )}</span>{/if}</td>
                <td><code>{$package.version|wash}</code></td>
                <td><code>{$package.latest|wash}</code></td>
                <td>{if $package.installable}<span class="a4-badge is-ok">{'Can be installed'|i18n( 'extension/ezupdate' )}</span>
                    {if and( $package.would_install, ne( $package.would_install, $package.latest ) )}<span class="a4-meta a4-update-desc">{'Would install %version'|i18n( 'extension/ezupdate',, hash( '%version', $package.would_install ) )|wash}</span>{/if}
                    {elseif $package.unknown}<span class="a4-badge">{'Could not be checked'|i18n( 'extension/ezupdate' )}</span>
                    {elseif $package.constraint}<span class="a4-badge is-warn">{'Blocked by composer.json (%constraint)'|i18n( 'extension/ezupdate',, hash( '%constraint', $package.constraint ) )|wash}</span>
                    {else}<span class="a4-badge is-warn">{'Blocked by composer.json or another package'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
            </tr>
            {/foreach}
            </tbody>
        </table>
        </div>
        {foreach $lock_mismatch as $name}<input type="hidden" name="Packages[]" value="{$name|wash}" />{/foreach}
        {if $lock_mismatch|count}<p class="a4-help a4-update-row">{'composer.json asks for newer versions than composer.lock holds of: %packages. Composer needs them in the same run, so they are always included.'|i18n( 'extension/ezupdate',, hash( '%packages', $lock_mismatch|implode( ', ' ) ) )|wash}</p>{/if}
        {else}
        <div class="a4-empty"><strong>{'Everything is up to date'|i18n( 'extension/ezupdate' )}</strong><p>{'Every package composer.json names is at its latest release.'|i18n( 'extension/ezupdate' )}</p></div>
        {/if}
    {else}
        <div class="a4-empty"><strong>{'Not checked yet'|i18n( 'extension/ezupdate' )}</strong><p>{'Check for updates to see which packages have a newer release.'|i18n( 'extension/ezupdate' )}</p></div>
    {/if}
    </div>
    <div class="a4-card-foot a4-update-foot">
        <input class="a4-btn" type="submit" name="CheckForUpdatesButton" value="{'Check for updates'|i18n( 'extension/ezupdate' )}" data-ezx-busy="{'Checking...'|i18n( 'extension/ezupdate' )|wash}" />
        {include uri='design:ezupdate/parts/method.tpl' method_id='ezupdate-method-updates'}
        <input class="a4-btn" type="submit" name="DryRunUpdateButton" value="{'Preview (dry run)'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
        {if and( $can_manage, $update_allowed, $installable )}
        <span class="a4-update-confirm">
            <label class="a4-check"><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="InstallUpdatesButton" /> <span>{'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</span></label>
            <input class="a4-btn a4-btn-primary" type="submit" name="InstallUpdatesButton" value="{'Install updates'|i18n( 'extension/ezupdate' )}" disabled="disabled" />
        </span>
        {else}
        <input class="a4-btn a4-btn-primary" type="submit" name="InstallUpdatesButton" value="{'Install updates'|i18n( 'extension/ezupdate' )}" disabled="disabled"{if $show_note} aria-describedby="ezupdate-install-note"{/if} />
        {/if}
    </div>
    </form>
</section>
{undef $installable $show_note}

{if $jobs|count}
<section class="a4-card a4-update-section" id="ezx-runs" aria-labelledby="ezupdate-runs-title">
    <div class="a4-card-head"><h2 id="ezupdate-runs-title">{'Recent runs'|i18n( 'extension/ezupdate' )}</h2></div>
    <div class="a4-card-body">
        <div class="a4-table-wrap">
        <table class="a4-table">
            <caption class="a4-sr-only">{'Recent runs'|i18n( 'extension/ezupdate' )}</caption>
            <thead><tr>
                <th scope="col">{'Run'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'By'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Started'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Status'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col"><span class="a4-sr-only">{'Actions'|i18n( 'extension/ezupdate' )}</span></th>
            </tr></thead>
            <tbody>
            {foreach $jobs as $job}
            <tr>
                <td><a href={concat( 'update/job/', $job.id )|ezurl}>{$job.label|wash}</a></td>
                <td>{$job.user|wash}</td>
                <td class="a4-nowrap"><time datetime="{$job.created|datetime( 'custom', '%Y-%m-%dT%H:%i:%s' )}" data-ezx-ago="{$job.created}">{$job.created|l10n( 'shortdatetime' )}</time></td>
                <td>{include uri='design:ezupdate/parts/status.tpl' status=$job.status}</td>
                <td class="a4-update-actions">
                    {* A dry run runs again from here; a run that changes the installation asks for the backup on its own page. *}
                    {if $job.changes|not}
                    <form method="post" action={concat( 'update/job/', $job.id )|ezurl}>
                        <input class="a4-btn a4-btn-small" type="submit" name="RerunButton" value="{'Run again'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
                    </form>
                    {else}
                    <a class="a4-btn a4-btn-small" href={concat( 'update/job/', $job.id )|ezurl}>{'Run again'|i18n( 'extension/ezupdate' )}&hellip;</a>
                    {/if}
                </td>
            </tr>
            {/foreach}
            </tbody>
        </table>
        </div>
    </div>
</section>
{/if}
{include uri='design:ezupdate/parts/footer.tpl'}
