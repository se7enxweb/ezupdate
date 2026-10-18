{* Setup > Updates and packages > a package (update/package/<vendor>/<name>): what packagist.org says about it, the
   install form (parts/install_form.tpl), how it is installed here and its versions. Built from the shared
   components (.a4-badges, .a4-card, .a4-facts, .a4-table, .a4-tag, .a4-badge, .a4-pre, .a4-check, .a4-notice); the
   rest is .a4-update-* in stylesheets/modules/update.css. No inline CSS or script. *}
{def $ezx_actions = array()
     $ezx_intro = 'Not on packagist.org'|i18n( 'extension/ezupdate' )}
{if $package}{set $ezx_intro = $package.description}{/if}
{if and( $package, $package.url )}{set $ezx_actions = array( hash( 'url', $package.url, 'text', 'packagist.org ↗', 'external', true(), 'download', false() ) )}{/if}
{include uri='design:ezupdate/parts/header.tpl' current='browse' error=$error
         title=$name
         intro=$ezx_intro
         actions=$ezx_actions}
{undef $ezx_actions $ezx_intro}

{if or( $installed_version, and( $package, $package.latest ), and( $package, $package.abandoned ) )}
<p class="a4-badges a4-update-section">
    {if $installed_version}<span class="a4-badge is-ok">{'Installed %version'|i18n( 'extension/ezupdate',, hash( '%version', $installed_version ) )|wash}</span>{/if}
    {if and( $package, $package.latest )}<span class="a4-badge">{'Latest %version'|i18n( 'extension/ezupdate',, hash( '%version', $package.latest ) )|wash}</span>{/if}
    {if and( $package, $package.abandoned )}<span class="a4-badge is-bad">{'Abandoned'|i18n( 'extension/ezupdate' )}</span>{/if}
</p>
{/if}

{if $package}
<section class="a4-card a4-update-section" aria-labelledby="ezupdate-package-about">
    <div class="a4-card-head"><h2 id="ezupdate-package-about">{'About'|i18n( 'extension/ezupdate' )}</h2></div>
    <div class="a4-card-body">
        <dl class="a4-facts is-rows a4-update-facts">
            <dt>{'Latest release'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$package.latest|wash}</code></dd>
            <dt>{'Type'|i18n( 'extension/ezupdate' )}</dt><dd>{$package.type|wash}</dd>
            <dt>{'License'|i18n( 'extension/ezupdate' )}</dt><dd>{$package.license|wash}</dd>
            <dt>{'Maintainers'|i18n( 'extension/ezupdate' )}</dt><dd>{$package.maintainers|implode( ', ' )|wash}</dd>
            <dt>{'Downloads'|i18n( 'extension/ezupdate' )}</dt><dd>{'%total in all, %monthly this month, %daily today'|i18n( 'extension/ezupdate',, hash( '%total', $package.downloads.total, '%monthly', $package.downloads.monthly, '%daily', $package.downloads.daily ) )}</dd>
            <dt>{'Stars'|i18n( 'extension/ezupdate' )}</dt><dd>{$package.favers}</dd>
            {if $package.repository}<dt>{'Source'|i18n( 'extension/ezupdate' )}</dt><dd><a href="{$package.repository|wash}" target="_blank" rel="noopener noreferrer">{$package.repository|wash}</a></dd>{/if}
            {if $package.homepage}<dt>{'Website'|i18n( 'extension/ezupdate' )}</dt><dd><a href="{$package.homepage|wash}" target="_blank" rel="noopener noreferrer">{$package.homepage|wash}</a></dd>{/if}
            {if $package.source}<dt>{'source (git)'|i18n( 'extension/ezupdate' )}</dt>
                <dd><code id="ezupdate-package-source">{$package.source.url|wash}</code>
                    <button type="button" class="a4-btn a4-btn-small a4-update-copy" data-ezx-copy-target="ezupdate-package-source" data-done="{'Copied'|i18n( 'extension/ezupdate' )|wash}" aria-label="{'Copy'|i18n( 'extension/ezupdate' )|wash}: {$package.source.url|wash}">{'Copy'|i18n( 'extension/ezupdate' )}</button>
                    <span class="a4-meta">{$package.source.type|wash} {'commit'|i18n( 'extension/ezupdate' )} <code>{$package.source.short|wash}</code></span></dd>{/if}
            {if $package.dist}<dt>{'dist (archive)'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$package.dist.url|wash}</code> <span class="a4-meta">{$package.dist.type|wash}</span></dd>{/if}
            {if $package.require|count}
            <dt>{'Requires (latest release)'|i18n( 'extension/ezupdate' )}</dt>
            <dd><ul class="a4-badges">
                {foreach $package.require as $dependency => $constraint}
                <li class="a4-tag">{if $dependency|contains( '/' )}<a href={concat( 'update/package/', $dependency )|ezurl}>{$dependency|wash}</a>{else}{$dependency|wash}{/if}&nbsp;<code>{$constraint|wash}</code></li>
                {/foreach}
            </ul></dd>
            {/if}
        </dl>
    </div>
    <div class="a4-card-foot">
        {include uri='design:ezupdate/parts/install_form.tpl'}
    </div>
</section>
{else}
<div class="a4-notice is-warn a4-update-section">
    <strong class="a4-notice-title">{'packagist.org has no information about this package'|i18n( 'extension/ezupdate' )}</strong>
    <p>{$packagist_error|wash} {'It may come from another server in composer.json.'|i18n( 'extension/ezupdate' )}</p>
</div>
<section class="a4-card a4-update-section" aria-labelledby="ezupdate-package-install">
    <div class="a4-card-head"><h2 id="ezupdate-package-install">{'Install'|i18n( 'extension/ezupdate' )}</h2></div>
    <div class="a4-card-foot">
        {include uri='design:ezupdate/parts/install_form.tpl'}
    </div>
</section>
{/if}

{if or( $details, $installed_info )}
<section class="a4-card a4-update-section" aria-labelledby="ezupdate-package-installed">
    <div class="a4-card-head"><h2 id="ezupdate-package-installed">{'As installed'|i18n( 'extension/ezupdate' )}</h2></div>
    <div class="a4-card-body">
        {if $installed_info}
        <dl class="a4-facts is-rows a4-update-facts">
            <dt>{'Version'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$installed_info.version|wash}</code></dd>
            <dt>{'Fetched from'|i18n( 'extension/ezupdate' )}</dt><dd>{if eq( $installed_info.method, 'source' )}{'source (git, with history)'|i18n( 'extension/ezupdate' )}{elseif eq( $installed_info.method, 'dist' )}{'dist (archives)'|i18n( 'extension/ezupdate' )}{else}{$installed_info.method|wash}{/if}</dd>
            {if $installed_info.path}<dt>{'Directory'|i18n( 'extension/ezupdate' )}</dt>
                <dd><code id="ezupdate-package-path">{$installed_info.path|wash}</code>
                    <button type="button" class="a4-btn a4-btn-small a4-update-copy" data-ezx-copy-target="ezupdate-package-path" data-done="{'Copied'|i18n( 'extension/ezupdate' )|wash}" aria-label="{'Copy'|i18n( 'extension/ezupdate' )|wash}: {$installed_info.path|wash}">{'Copy'|i18n( 'extension/ezupdate' )}</button></dd>{/if}
            {if $installed_info.source}<dt>{'source (git)'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$installed_info.source.url|wash}</code> <span class="a4-meta">{'commit'|i18n( 'extension/ezupdate' )} <code>{$installed_info.source.reference|wash}</code></span></dd>{/if}
            {if $installed_info.git}
            <dt>{'Git working copy'|i18n( 'extension/ezupdate' )}</dt>
            <dd>{'branch'|i18n( 'extension/ezupdate' )} <code>{$installed_info.git.branch|wash}</code>,
                {'commit'|i18n( 'extension/ezupdate' )} <code>{$installed_info.git.commit|wash}</code>
                {if $installed_info.git.tag}(<code>{$installed_info.git.tag|wash}</code>){/if}
                {if $installed_info.git.changed}<span class="a4-badge is-warn">{'local changes'|i18n( 'extension/ezupdate' )}</span>{/if}
                <span class="a4-meta">{$installed_info.git.subject|wash}</span>
                {if $installed_info.git.remote}<span class="a4-meta">origin <code>{$installed_info.git.remote|wash}</code></span>{/if}</dd>
            {elseif eq( $installed_info.method, 'dist' )}
            <dt>{'Git working copy'|i18n( 'extension/ezupdate' )}</dt><dd><span class="a4-muted">{'none: fetched as an archive. Install again from source to get the git history.'|i18n( 'extension/ezupdate' )}</span></dd>
            {/if}
            <dt>{'Funding'|i18n( 'extension/ezupdate' )}</dt>
            <dd>{if $funding|count}
                    <ul class="a4-update-links">
                    {foreach $funding as $link}<li><a class="a4-update-fund-link" href="{$link.url|wash}" target="_blank" rel="noopener noreferrer nofollow"><span class="a4-badge{if eq( $link.type, 'custom' )} is-ok{elseif ne( $link.type, 'github' )} is-info{/if}">{$link.label|wash}</span> <span class="a4-update-url">{$link.url|wash}</span></a></li>{/foreach}
                    </ul>
                    <span class="a4-meta"><a href={'update/fund'|ezurl}>{'Funding of all installed packages'|i18n( 'extension/ezupdate' )}</a></span>
                {else}<span class="a4-muted">{'This package declares no funding.'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
        </dl>
        {/if}
        {if $details}
        <h3 class="a4-h3 a4-update-term-title a4-update-show-title" id="ezupdate-package-show">composer show {$name|wash}</h3>
        {* HTML from eZUpdateManager::ansiToHtml(), which escapes first. *}
        <pre class="a4-pre a4-update-terminal" tabindex="0" role="region" aria-labelledby="ezupdate-package-show">{$details}</pre>
        {/if}
    </div>
</section>
{/if}

{if and( $package, $package.versions|count )}
<section class="a4-card a4-update-section" data-ezx-versions="1" aria-labelledby="ezupdate-package-versions">
    <div class="a4-card-head">
        <h2 id="ezupdate-package-versions">{'Versions'|i18n( 'extension/ezupdate' )}</h2>
        <div class="a4-card-actions"><label class="a4-check"><input type="checkbox" data-ezx-stable-only="1" /> <span>{'Releases only'|i18n( 'extension/ezupdate' )}</span></label></div>
    </div>
    <div class="a4-card-body">
        <div class="a4-table-wrap" role="region" aria-labelledby="ezupdate-package-versions" tabindex="0">
        <table class="a4-table">
            <caption class="a4-sr-only">{'Versions'|i18n( 'extension/ezupdate' )}</caption>
            <thead><tr>
                <th scope="col">{'Version'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Released'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'License'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Requires'|i18n( 'extension/ezupdate' )}</th>
            </tr></thead>
            <tbody>
            {foreach $package.versions as $version max 40}
            <tr{if $version.stable|not} data-ezx-dev="1"{/if}>
                <td class="a4-nowrap"><code>{$version.version|wash}</code>{if $version.stable|not} <span class="a4-badge">{'development'|i18n( 'extension/ezupdate' )}</span>{/if}
                    {if eq( $version.version, $installed_version )} <span class="a4-badge is-ok">{'installed'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                <td class="a4-nowrap">{if $version.time}<time data-ezx-ago="{$version.time}">{$version.time|l10n( 'shortdate' )}</time>{/if}</td>
                <td>{$version.license|wash}</td>
                <td class="a4-meta">{foreach $version.require as $dependency => $constraint}{$dependency|wash} {$constraint|wash}{delimiter}, {/delimiter}{/foreach}</td>
            </tr>
            {/foreach}
            </tbody>
        </table>
        </div>
    </div>
</section>
{/if}
{include uri='design:ezupdate/parts/footer.tpl'}
