{include uri='design:ezupdate/parts/header.tpl' current='browse' error=$error}
<div class="ezx-page">

    <div class="ezx-head">
        <div>
            <h1>{$name|wash}</h1>
            <p>{if $package}{$package.description|wash}{else}{'Not on packagist.org'|i18n( 'extension/ezupdate' )}{/if}</p>
        </div>
        <div class="ezx-head-actions">
            {if $installed_version}<span class="ezupdate-badge ezupdate-good">{'Installed %version'|i18n( 'extension/ezupdate',, hash( '%version', $installed_version ) )|wash}</span>{/if}
            {if and( $package, $package.latest )}<span class="ezupdate-badge">{'Latest %version'|i18n( 'extension/ezupdate',, hash( '%version', $package.latest ) )|wash}</span>{/if}
            {if and( $package, $package.abandoned )}<span class="ezupdate-badge ezupdate-bad">{'Abandoned'|i18n( 'extension/ezupdate' )}</span>{/if}
            {if and( $package, $package.url )}<a class="button ezx-btn-s" href="{$package.url|wash}" target="_blank" rel="noopener noreferrer">packagist.org &#8599;</a>{/if}
        </div>
    </div>

    {if $package}
    <section class="ezx-panel">
        <header><h2>{'About'|i18n( 'extension/ezupdate' )}</h2></header>
        <div class="ezx-panel-body">
            <dl class="ezx-facts">
                <dt>{'Latest release'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$package.latest|wash}</code></dd>
                <dt>{'Type'|i18n( 'extension/ezupdate' )}</dt><dd>{$package.type|wash}</dd>
                <dt>{'License'|i18n( 'extension/ezupdate' )}</dt><dd>{$package.license|wash}</dd>
                <dt>{'Maintainers'|i18n( 'extension/ezupdate' )}</dt><dd>{$package.maintainers|implode( ', ' )|wash}</dd>
                <dt>{'Downloads'|i18n( 'extension/ezupdate' )}</dt><dd>{'%total in all, %monthly this month, %daily today'|i18n( 'extension/ezupdate',, hash( '%total', $package.downloads.total, '%monthly', $package.downloads.monthly, '%daily', $package.downloads.daily ) )}</dd>
                <dt>{'Stars'|i18n( 'extension/ezupdate' )}</dt><dd>{$package.favers}</dd>
                {if $package.repository}<dt>{'Source'|i18n( 'extension/ezupdate' )}</dt><dd><a href="{$package.repository|wash}" target="_blank" rel="noopener noreferrer">{$package.repository|wash}</a></dd>{/if}
                {if $package.homepage}<dt>{'Website'|i18n( 'extension/ezupdate' )}</dt><dd><a href="{$package.homepage|wash}" target="_blank" rel="noopener noreferrer">{$package.homepage|wash}</a></dd>{/if}
                {if $package.source}<dt>{'source (git)'|i18n( 'extension/ezupdate' )}</dt><dd><code data-ezx-copy="1">{$package.source.url|wash}</code> <span class="ezupdate-muted">{$package.source.type|wash} {'commit'|i18n( 'extension/ezupdate' )} <code>{$package.source.short|wash}</code></span></dd>{/if}
                {if $package.dist}<dt>{'dist (archive)'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$package.dist.url|wash}</code> <span class="ezupdate-muted">{$package.dist.type|wash}</span></dd>{/if}
                {if $package.require|count}
                <dt>{'Requires (latest release)'|i18n( 'extension/ezupdate' )}</dt>
                <dd><ul class="ezx-chips">
                    {foreach $package.require as $dependency => $constraint}
                    <li>{if $dependency|contains( '/' )}<a href={concat( 'update/package/', $dependency )|ezurl}>{$dependency|wash}</a>{else}{$dependency|wash}{/if} <code>{$constraint|wash}</code></li>
                    {/foreach}
                </ul></dd>
                {/if}
            </dl>
        </div>
        <footer>
            {include uri='design:ezupdate/parts/install_form.tpl'}
        </footer>
    </section>
    {else}
    <div class="ezx-alert ezx-alert-warn">
        <div>
            <h2>{'packagist.org has no information about this package'|i18n( 'extension/ezupdate' )}</h2>
            <p>{$packagist_error|wash} {'It may come from another server in composer.json.'|i18n( 'extension/ezupdate' )}</p>
        </div>
    </div>
    <section class="ezx-panel">
        <header><h2>{'Install'|i18n( 'extension/ezupdate' )}</h2></header>
        <footer>
            {include uri='design:ezupdate/parts/install_form.tpl'}
        </footer>
    </section>
    {/if}

    {if or( $details, $installed_info )}
    <section class="ezx-panel">
        <header><h2>{'As installed'|i18n( 'extension/ezupdate' )}</h2></header>
        <div class="ezx-panel-body">
            {if $installed_info}
            <dl class="ezx-facts">
                <dt>{'Version'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$installed_info.version|wash}</code></dd>
                <dt>{'Fetched from'|i18n( 'extension/ezupdate' )}</dt><dd>{if eq( $installed_info.method, 'source' )}{'source (git, with history)'|i18n( 'extension/ezupdate' )}{elseif eq( $installed_info.method, 'dist' )}{'dist (archives)'|i18n( 'extension/ezupdate' )}{else}{$installed_info.method|wash}{/if}</dd>
                {if $installed_info.path}<dt>{'Directory'|i18n( 'extension/ezupdate' )}</dt><dd><code data-ezx-copy="1">{$installed_info.path|wash}</code></dd>{/if}
                {if $installed_info.source}<dt>{'source (git)'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$installed_info.source.url|wash}</code> <span class="ezupdate-muted">{'commit'|i18n( 'extension/ezupdate' )} <code>{$installed_info.source.reference|wash}</code></span></dd>{/if}
                {if $installed_info.git}
                <dt>{'Git working copy'|i18n( 'extension/ezupdate' )}</dt>
                <dd>{'branch'|i18n( 'extension/ezupdate' )} <code>{$installed_info.git.branch|wash}</code>,
                    {'commit'|i18n( 'extension/ezupdate' )} <code>{$installed_info.git.commit|wash}</code>
                    {if $installed_info.git.tag}(<code>{$installed_info.git.tag|wash}</code>){/if}
                    {if $installed_info.git.changed}<span class="ezupdate-badge ezupdate-warn">{'local changes'|i18n( 'extension/ezupdate' )}</span>{/if}
                    <div class="ezupdate-muted">{$installed_info.git.subject|wash}</div>
                    {if $installed_info.git.remote}<div class="ezupdate-muted">origin <code>{$installed_info.git.remote|wash}</code></div>{/if}</dd>
                {elseif eq( $installed_info.method, 'dist' )}
                <dt>{'Git working copy'|i18n( 'extension/ezupdate' )}</dt><dd class="ezupdate-muted">{'none: fetched as an archive. Install again from source to get the git history.'|i18n( 'extension/ezupdate' )}</dd>
                {/if}
                <dt>{'Funding'|i18n( 'extension/ezupdate' )}</dt>
                <dd>{if $funding|count}
                        {foreach $funding as $link}<div><a class="ezupdate-fund-link" href="{$link.url|wash}" target="_blank" rel="noopener noreferrer nofollow"><span class="ezupdate-badge ezupdate-fund-type ezupdate-fund-type-{$link.type|wash}">{$link.label|wash}</span> <span class="ezupdate-fund-url">{$link.url|wash}</span></a></div>{/foreach}
                        <div class="ezupdate-muted"><a href={'update/fund'|ezurl}>{'Funding of all installed packages'|i18n( 'extension/ezupdate' )}</a></div>
                    {else}<span class="ezupdate-muted">{'This package declares no funding.'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
            </dl>
            {/if}
            {if $details}
            <div class="ezx-term" style="margin-top: 1em">
                <div class="ezx-term-bar"><span class="ezx-dots" aria-hidden="true"><i></i><i></i><i></i></span><span class="ezx-term-title">composer show {$name|wash}</span></div>
                {* HTML from eZUpdateManager::ansiToHtml(), which escapes first. *}
                <pre class="ezupdate-terminal">{$details}</pre>
            </div>
            {/if}
        </div>
    </section>
    {/if}

    {if and( $package, $package.versions|count )}
    <section class="ezx-panel" data-ezx-versions="1">
        <header>
            <h2>{'Versions'|i18n( 'extension/ezupdate' )}</h2>
            <label class="ezupdate-method"><input type="checkbox" data-ezx-stable-only="1" /> {'Releases only'|i18n( 'extension/ezupdate' )}</label>
        </header>
        <div class="ezx-panel-body ezx-panel-flush">
            <table class="ezx-table">
                <thead><tr>
                    <th>{'Version'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Released'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'License'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Requires'|i18n( 'extension/ezupdate' )}</th>
                </tr></thead>
                <tbody>
                {foreach $package.versions as $version max 40}
                <tr{if $version.stable|not} data-ezx-dev="1"{/if}>
                    <td class="ezx-title-cell"><code>{$version.version|wash}</code>{if $version.stable|not} <span class="ezupdate-badge">{'development'|i18n( 'extension/ezupdate' )}</span>{/if}
                        {if eq( $version.version, $installed_version )} <span class="ezupdate-badge ezupdate-good">{'installed'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                    <td data-label="{'Released'|i18n( 'extension/ezupdate' )}">{if $version.time}<time data-ezx-ago="{$version.time}">{$version.time|l10n( 'shortdate' )}</time>{/if}</td>
                    <td data-label="{'License'|i18n( 'extension/ezupdate' )}">{$version.license|wash}</td>
                    <td class="ezupdate-muted">{foreach $version.require as $dependency => $constraint}{$dependency|wash} {$constraint|wash}{delimiter}, {/delimiter}{/foreach}</td>
                </tr>
                {/foreach}
                </tbody>
            </table>
        </div>
    </section>
    {/if}
</div>
{include uri='design:ezupdate/parts/footer.tpl'}
