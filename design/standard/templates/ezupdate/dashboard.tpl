{include uri='design:ezupdate/parts/header.tpl' current='dashboard' error=$error}

<div class="context-block ezupdate">
    <div class="box-header">
        <h1 class="context-title">{'Composer'|i18n( 'extension/ezupdate' )}</h1>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <table class="list ezupdate-facts" cellspacing="0">
            <tr>
                <th>{'Composer'|i18n( 'extension/ezupdate' )}</th>
                <td>{if $composer_binary}<code>{$composer_binary|wash}</code>{if $composer_version} <span class="ezupdate-muted">{$composer_version|wash}</span>{/if}
                    {if $composer_problem}<span class="ezupdate-badge ezupdate-bad">{'Does not start'|i18n( 'extension/ezupdate' )}</span><pre class="ezupdate-message">{$composer_problem|wash}</pre>{/if}
                    {else}<span class="ezupdate-badge ezupdate-bad">{'Not found'|i18n( 'extension/ezupdate' )}</span> {'Set [ComposerSettings] Path in ezupdate.ini.'|i18n( 'extension/ezupdate' )}{/if}</td>
            </tr>
            <tr>
                <th>{'PHP for Composer'|i18n( 'extension/ezupdate' )}</th>
                <td>{if $php_binary}<code>{$php_binary|wash}</code>{else}<span class="ezupdate-badge ezupdate-bad">{'Not found'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
            </tr>
            <tr>
                <th>{'Installation'|i18n( 'extension/ezupdate' )}</th>
                <td><code>{$project_path|wash}</code>
                    {if $has_composer_json}<span class="ezupdate-muted">{'composer.json, %count packages installed'|i18n( 'extension/ezupdate',, hash( '%count', $installed_count ) )}</span>
                        {if $composer_json_writable|not}<span class="ezupdate-badge ezupdate-warn">{'composer.json is read-only for the web server'|i18n( 'extension/ezupdate' )}</span>{/if}
                    {else}<span class="ezupdate-badge ezupdate-bad">{'No composer.json'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
            </tr>
            <tr>
                <th>{'Package servers'|i18n( 'extension/ezupdate' )}</th>
                <td>{if $packagist_enabled}packagist.org{else}<span class="ezupdate-muted">{'packagist.org switched off'|i18n( 'extension/ezupdate' )}</span>{/if}
                    {if $composer_server_count}, {'%count more in composer.json'|i18n( 'extension/ezupdate',, hash( '%count', $composer_server_count ) )}{/if}
                    &middot; <a href={'update/servers'|ezurl}>{'Edit'|i18n( 'extension/ezupdate' )}</a></td>
            </tr>
            <tr>
                <th>{'Updating'|i18n( 'extension/ezupdate' )}</th>
                <td>{if $update_allowed}<span class="ezupdate-badge ezupdate-warn">{'Allowed'|i18n( 'extension/ezupdate' )}</span>
                    {else}<span class="ezupdate-badge">{'Switched off'|i18n( 'extension/ezupdate' )}</span> <span class="ezupdate-muted">[UpdateSettings] AllowUpdate</span>{/if}</td>
            </tr>
            <tr>
                <th>{'Installing'|i18n( 'extension/ezupdate' )}</th>
                <td>{if $install_allowed}<span class="ezupdate-badge ezupdate-warn">{'Allowed'|i18n( 'extension/ezupdate' )}</span>
                    {else}<span class="ezupdate-badge">{'Switched off'|i18n( 'extension/ezupdate' )}</span> <span class="ezupdate-muted">[UpdateSettings] AllowInstall</span>{/if}</td>
            </tr>
        </table>
    </div>
</div>

<div class="context-block ezupdate">
    <div class="box-header">
        <h2 class="context-title">{'Updates'|i18n( 'extension/ezupdate' )}</h2>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        {if $outdated|is_array}
            {if $outdated|count}
            <table class="list" cellspacing="0">
                <tr>
                    <th>{'Package'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Installed'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Latest'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Kind'|i18n( 'extension/ezupdate' )}</th>
                </tr>
                {foreach $outdated as $package sequence array( 'bglight', 'bgdark' ) as $style}
                <tr class="{$style}">
                    <td><a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>
                        <div class="ezupdate-muted">{$package.description|wash|shorten( 100 )}</div></td>
                    <td><code>{$package.version|wash}</code></td>
                    <td><code>{$package.latest|wash}</code></td>
                    <td>{if eq( $package.status, 'semver-safe-update' )}<span class="ezupdate-badge ezupdate-good">{'Within the constraint'|i18n( 'extension/ezupdate' )}</span>
                        {else}<span class="ezupdate-badge ezupdate-warn">{'Needs a new constraint'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                </tr>
                {/foreach}
            </table>
            {else}
            <p>{'Every package composer.json names is at its latest release.'|i18n( 'extension/ezupdate' )}</p>
            {/if}
        {else}
            <p>{'Asks the package servers which of the packages composer.json names have a newer release. Nothing is changed.'|i18n( 'extension/ezupdate' )}</p>
        {/if}
    </div>
    <div class="controlbar">
        <form method="post" action={'update/dashboard'|ezurl} class="ezupdate-bar">
            <input class="defaultbutton" type="submit" name="CheckForUpdatesButton" value="{'Check for updates'|i18n( 'extension/ezupdate' )}" />
            {include uri='design:ezupdate/parts/method.tpl'}
            <input class="button" type="submit" name="DryRunUpdateButton" value="{'Update, dry run'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
            {if and( $can_manage, $update_allowed )}
            <span class="ezupdate-confirm">
                <label><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="UpdateButton" /> {'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</label>
                <input class="button" type="submit" name="UpdateButton" value="{'Update'|i18n( 'extension/ezupdate' )}" disabled="disabled" />
            </span>
            {/if}
        </form>
    </div>
</div>

{if $jobs|count}
<div class="context-block ezupdate">
    <div class="box-header">
        <h2 class="context-title">{'Recent runs'|i18n( 'extension/ezupdate' )}</h2>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <table class="list" cellspacing="0">
            <tr>
                <th>{'Run'|i18n( 'extension/ezupdate' )}</th>
                <th>{'By'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Started'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Status'|i18n( 'extension/ezupdate' )}</th>
            </tr>
            {foreach $jobs as $job sequence array( 'bglight', 'bgdark' ) as $style}
            <tr class="{$style}">
                <td><a href={concat( 'update/job/', $job.id )|ezurl}>{$job.label|wash}</a></td>
                <td>{$job.user|wash}</td>
                <td>{$job.created|l10n( 'shortdatetime' )}</td>
                <td>{include uri='design:ezupdate/parts/status.tpl' status=$job.status}</td>
            </tr>
            {/foreach}
        </table>
    </div>
</div>
{/if}
