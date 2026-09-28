{include uri='design:ezupdate/parts/header.tpl' current='browse' error=$error}

<div class="context-block ezupdate">
    <div class="box-header">
        <h1 class="context-title">{$name|wash}
            {if $installed_version}<span class="ezupdate-badge ezupdate-good">{'Installed %version'|i18n( 'extension/ezupdate',, hash( '%version', $installed_version|wash ) )}</span>{/if}
            {if and( $package, $package.abandoned )}<span class="ezupdate-badge ezupdate-bad">{'Abandoned'|i18n( 'extension/ezupdate' )}</span>{/if}
        </h1>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        {if $package}
        <p class="ezupdate-lead">{$package.description|wash}</p>
        <table class="list ezupdate-facts" cellspacing="0">
            <tr><th>{'Latest release'|i18n( 'extension/ezupdate' )}</th><td><code>{$package.latest|wash}</code></td></tr>
            <tr><th>{'Type'|i18n( 'extension/ezupdate' )}</th><td>{$package.type|wash}</td></tr>
            <tr><th>{'License'|i18n( 'extension/ezupdate' )}</th><td>{$package.license|wash}</td></tr>
            <tr><th>{'Maintainers'|i18n( 'extension/ezupdate' )}</th><td>{$package.maintainers|implode( ', ' )|wash}</td></tr>
            <tr><th>{'Downloads'|i18n( 'extension/ezupdate' )}</th><td>{'%total in all, %monthly this month, %daily today'|i18n( 'extension/ezupdate',, hash( '%total', $package.downloads.total, '%monthly', $package.downloads.monthly, '%daily', $package.downloads.daily ) )}</td></tr>
            <tr><th>{'Stars'|i18n( 'extension/ezupdate' )}</th><td>{$package.favers}</td></tr>
            {if $package.repository}<tr><th>{'Source'|i18n( 'extension/ezupdate' )}</th><td><a href="{$package.repository|wash}" target="_blank" rel="noopener noreferrer">{$package.repository|wash}</a></td></tr>{/if}
            {if $package.homepage}<tr><th>{'Website'|i18n( 'extension/ezupdate' )}</th><td><a href="{$package.homepage|wash}" target="_blank" rel="noopener noreferrer">{$package.homepage|wash}</a></td></tr>{/if}
            <tr><th>packagist.org</th><td><a href="{$package.url|wash}" target="_blank" rel="noopener noreferrer">{$package.url|wash}</a></td></tr>
            {if $package.source}<tr><th>{'source (git)'|i18n( 'extension/ezupdate' )}</th><td><code>{$package.source.url|wash}</code> <span class="ezupdate-muted">{$package.source.type|wash} {'commit'|i18n( 'extension/ezupdate' )} <code>{$package.source.short|wash}</code></span></td></tr>{/if}
            {if $package.dist}<tr><th>{'dist (archive)'|i18n( 'extension/ezupdate' )}</th><td><code>{$package.dist.url|wash}</code> <span class="ezupdate-muted">{$package.dist.type|wash}</span></td></tr>{/if}
        </table>

        {if $package.require|count}
        <h3>{'Requires (latest release)'|i18n( 'extension/ezupdate' )}</h3>
        <ul class="ezupdate-requires">
            {foreach $package.require as $dependency => $constraint}
            <li>{if $dependency|contains( '/' )}<a href={concat( 'update/package/', $dependency )|ezurl}>{$dependency|wash}</a>{else}<code>{$dependency|wash}</code>{/if} <code>{$constraint|wash}</code></li>
            {/foreach}
        </ul>
        {/if}
        {else}
        <div class="message-warning">
            <h2>{'packagist.org has no information about this package'|i18n( 'extension/ezupdate' )}</h2>
            <p>{$packagist_error|wash} {'It may come from another server in composer.json.'|i18n( 'extension/ezupdate' )}</p>
        </div>
        {/if}
    </div>
    <div class="controlbar">
        <form method="post" action={concat( 'update/package/', $name )|ezurl} class="ezupdate-bar">
            <label>{'Version'|i18n( 'extension/ezupdate' )}
                <input type="text" name="Constraint" value="{$constraint|wash}" size="14" list="ezupdate-versions" placeholder="{if $package}^{$package.latest|explode( 'v' )|implode( '' )|wash}{/if}" />
            </label>
            {if $package}
            <datalist id="ezupdate-versions">
                {foreach $package.versions as $version max 30}<option value="{$version.version|wash}"></option>{/foreach}
            </datalist>
            {/if}
            {include uri='design:ezupdate/parts/method.tpl'}
            <input class="button" type="submit" name="DryRunInstallButton" value="{'Install, dry run'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
            {if and( $can_manage, $install_allowed )}
            <span class="ezupdate-confirm">
                <label><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="InstallButton" /> {'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</label>
                <input class="defaultbutton" type="submit" name="InstallButton" value="{if $installed_version}{'Change version'|i18n( 'extension/ezupdate' )}{else}{'Install'|i18n( 'extension/ezupdate' )}{/if}" disabled="disabled" />
            </span>
            {else}
            <span class="ezupdate-muted">{'Installing is switched off ([UpdateSettings] AllowInstall in ezupdate.ini).'|i18n( 'extension/ezupdate' )}</span>
            {/if}
        </form>
    </div>
</div>

{if $package.versions|count}
<div class="context-block ezupdate">
    <div class="box-header">
        <h2 class="context-title">{'Versions'|i18n( 'extension/ezupdate' )}</h2>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <table class="list" cellspacing="0">
            <tr>
                <th>{'Version'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Released'|i18n( 'extension/ezupdate' )}</th>
                <th>{'License'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Requires'|i18n( 'extension/ezupdate' )}</th>
            </tr>
            {foreach $package.versions as $version max 40 sequence array( 'bglight', 'bgdark' ) as $style}
            <tr class="{$style}">
                <td><code>{$version.version|wash}</code>{if $version.stable|not} <span class="ezupdate-muted">{'development'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                <td>{if $version.time}{$version.time|l10n( 'shortdate' )}{/if}</td>
                <td>{$version.license|wash}</td>
                <td class="ezupdate-muted">{foreach $version.require as $dependency => $constraint}{$dependency|wash} {$constraint|wash}{delimiter}, {/delimiter}{/foreach}</td>
            </tr>
            {/foreach}
        </table>
    </div>
</div>
{/if}

{if or( $details, $installed_info )}
<div class="context-block ezupdate">
    <div class="box-header">
        <h2 class="context-title">{'As installed'|i18n( 'extension/ezupdate' )}</h2>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        {if $installed_info}
        <table class="list ezupdate-facts" cellspacing="0">
            <tr><th>{'Version'|i18n( 'extension/ezupdate' )}</th><td><code>{$installed_info.version|wash}</code></td></tr>
            <tr><th>{'Fetched from'|i18n( 'extension/ezupdate' )}</th><td>{if eq( $installed_info.method, 'source' )}{'source (git, with history)'|i18n( 'extension/ezupdate' )}{elseif eq( $installed_info.method, 'dist' )}{'dist (archives)'|i18n( 'extension/ezupdate' )}{else}{$installed_info.method|wash}{/if}</td></tr>
            {if $installed_info.path}<tr><th>{'Directory'|i18n( 'extension/ezupdate' )}</th><td><code>{$installed_info.path|wash}</code></td></tr>{/if}
            {if $installed_info.source}<tr><th>{'source (git)'|i18n( 'extension/ezupdate' )}</th><td><code>{$installed_info.source.url|wash}</code> <span class="ezupdate-muted">{'commit'|i18n( 'extension/ezupdate' )} <code>{$installed_info.source.reference|wash}</code></span></td></tr>{/if}
            {if $installed_info.git}
            <tr><th>{'Git working copy'|i18n( 'extension/ezupdate' )}</th><td>
                {'branch'|i18n( 'extension/ezupdate' )} <code>{$installed_info.git.branch|wash}</code>,
                {'commit'|i18n( 'extension/ezupdate' )} <code>{$installed_info.git.commit|wash}</code>
                {if $installed_info.git.tag}(<code>{$installed_info.git.tag|wash}</code>){/if}
                {if $installed_info.git.changed}<span class="ezupdate-badge ezupdate-warn">{'local changes'|i18n( 'extension/ezupdate' )}</span>{/if}
                <div class="ezupdate-muted">{$installed_info.git.subject|wash}</div>
                {if $installed_info.git.remote}<div class="ezupdate-muted">origin <code>{$installed_info.git.remote|wash}</code></div>{/if}
            </td></tr>
            {elseif eq( $installed_info.method, 'dist' )}
            <tr><th>{'Git working copy'|i18n( 'extension/ezupdate' )}</th><td class="ezupdate-muted">{'none: fetched as an archive. Install again from source to get the git history.'|i18n( 'extension/ezupdate' )}</td></tr>
            {/if}
        </table>
        {/if}
        {if $details}
        {* HTML from eZUpdateManager::ansiToHtml(), which escapes first. *}
        <pre class="ezupdate-terminal">{$details}</pre>
        {/if}
    </div>
</div>
{/if}
