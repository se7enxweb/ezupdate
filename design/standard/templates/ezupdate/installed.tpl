{* Installed packages: composer.json, composer.lock, installed.json and the extension directories matched up
   (eZUpdateInventory). The filters, the search and the sorting work in the page (ezupdate.js, ezupdateInstalled). *}
{include uri='design:ezupdate/parts/header.tpl' current='installed'}

{def $filters = array(
        hash( 'id', 'all',       'label', 'All'|i18n( 'extension/ezupdate' ) ),
        hash( 'id', 'required',  'label', 'In composer.json'|i18n( 'extension/ezupdate' ) ),
        hash( 'id', 'extension', 'label', 'Extensions'|i18n( 'extension/ezupdate' ) ),
        hash( 'id', 'library',   'label', 'Libraries'|i18n( 'extension/ezupdate' ) ),
        hash( 'id', 'active',    'label', 'Active'|i18n( 'extension/ezupdate' ) ),
        hash( 'id', 'inactive',  'label', 'Not active'|i18n( 'extension/ezupdate' ) ),
        hash( 'id', 'local',     'label', 'Not from Composer'|i18n( 'extension/ezupdate' ) ),
        hash( 'id', 'git',       'label', 'Git clones'|i18n( 'extension/ezupdate' ) ),
        hash( 'id', 'issues',    'label', 'Needs attention'|i18n( 'extension/ezupdate' ) ) )}

<div class="ezupdate ezupdate-inv" data-ezupdate-installed="1">

    <div class="ezupdate-inv-head">
        <div>
            <h1>{'Installed packages'|i18n( 'extension/ezupdate' )}</h1>
            <p class="ezupdate-muted">
                {'What composer.json requires, what composer.lock resolved, what is installed on disk and which extensions the settings switch on, side by side.'|i18n( 'extension/ezupdate' )}
            </p>
        </div>
        <div class="ezx-head-actions">
            <a class="button ezx-btn-s" href={'update/installed/json'|ezurl} download>JSON &darr;</a>
            <a class="button ezx-btn-s" href={'update/installed/csv'|ezurl} download>CSV &darr;</a>
        </div>
        <ul class="ezupdate-inv-sources">
            <li class="{if $sources.composer_json}is-ok{else}is-bad{/if}"><code>composer.json</code></li>
            <li class="{if $sources.composer_lock}is-ok{else}is-bad{/if}"><code>composer.lock</code>{if $sources.lock_age} <span>{$sources.lock_age|l10n( 'shortdatetime' )}</span>{/if}</li>
            <li class="{if $sources.installed_json}is-ok{else}is-bad{/if}"><code>installed.json</code>{if $sources.installed_age} <span>{$sources.installed_age|l10n( 'shortdatetime' )}</span>{/if}</li>
            <li class="is-ok"><code>{$sources.extension_dir|wash}/</code> <span>{'%count siteaccesses'|i18n( 'extension/ezupdate',, hash( '%count', $sources.siteaccesses|count ) )}</span></li>
        </ul>
    </div>

    <div class="ezupdate-inv-cards">
        <button type="button" class="ezupdate-inv-card" data-filter="composer"><strong>{$summary.composer}</strong><span>{'Installed by Composer'|i18n( 'extension/ezupdate' )}</span></button>
        <button type="button" class="ezupdate-inv-card" data-filter="required"><strong>{$summary.required}</strong><span>{'Required in composer.json'|i18n( 'extension/ezupdate' )}</span></button>
        <button type="button" class="ezupdate-inv-card" data-filter="extension"><strong>{$summary.extension}</strong><span>{'Extensions, %active active'|i18n( 'extension/ezupdate',, hash( '%active', $summary.active ) )}</span></button>
        <button type="button" class="ezupdate-inv-card" data-filter="local"><strong>{$summary.local}</strong><span>{'Extensions not from Composer'|i18n( 'extension/ezupdate' )}</span></button>
        <button type="button" class="ezupdate-inv-card{if $summary.issues} is-warn{/if}" data-filter="issues"><strong>{$summary.issues}</strong><span>{'Need attention'|i18n( 'extension/ezupdate' )}</span></button>
    </div>

    <div class="ezupdate-inv-toolbar">
        <label class="ezupdate-inv-search">
            <span class="hide">{'Search'|i18n( 'extension/ezupdate' )}</span>
            <input type="search" placeholder="{'Filter by name, description, extension or path'|i18n( 'extension/ezupdate' )}" data-search="1" aria-keyshortcuts="/" />
        </label>
        <div class="ezupdate-inv-chips" role="group" aria-label="{'Show'|i18n( 'extension/ezupdate' )}">
            {foreach $filters as $filter}
            <button type="button" class="ezupdate-inv-chip{if eq( $filter.id, 'all' )} is-on{/if}" data-filter="{$filter.id}" aria-pressed="{if eq( $filter.id, 'all' )}true{else}false{/if}">{$filter.label|wash}{if ne( $filter.id, 'all' )} <span>{$summary[$filter.id]}</span>{/if}</button>
            {/foreach}
        </div>
        <label class="ezupdate-inv-sort">{'Sort by'|i18n( 'extension/ezupdate' )}
            <select data-sort-select="1">
                <option value="name">{'Name'|i18n( 'extension/ezupdate' )}</option>
                <option value="issues">{'Needs attention first'|i18n( 'extension/ezupdate' )}</option>
                <option value="installed">{'Installed version'|i18n( 'extension/ezupdate' )}</option>
                <option value="extension">{'Extension'|i18n( 'extension/ezupdate' )}</option>
                <option value="kind">{'Kind'|i18n( 'extension/ezupdate' )}</option>
            </select>
        </label>
        <p class="ezupdate-inv-count" aria-live="polite"><span data-count="1">{$rows|count}</span> / {$rows|count}</p>
    </div>

    <div class="ezupdate-inv-tablewrap">
    <table class="ezupdate-inv-table">
        <thead>
            <tr>
                <th><button type="button" data-sort="name">{'Package'|i18n( 'extension/ezupdate' )}</button></th>
                <th><button type="button" data-sort="installed">{'Versions'|i18n( 'extension/ezupdate' )}</button></th>
                <th><button type="button" data-sort="extension">{'Extension'|i18n( 'extension/ezupdate' )}</button></th>
                <th><button type="button" data-sort="issues">{'Status'|i18n( 'extension/ezupdate' )}</button></th>
                <th><span class="hide">{'Details'|i18n( 'extension/ezupdate' )}</span></th>
            </tr>
        </thead>
        {foreach $rows as $index => $row}
        <tbody class="ezupdate-inv-row{if $row.issues} has-issues{/if}"
               data-filters="all {$row.filters|implode( ' ' )}"
               data-name="{$row.name|downcase|wash}" data-kind="{$row.kind|wash}" data-required="{$row.required|wash}"
               data-locked="{$row.locked|wash}" data-installed="{$row.installed|wash}" data-extension="{if $row.extension}{$row.extension|wash}{/if}"
               data-issues="{$row.issues|count}"
               data-text="{concat( $row.name, ' ', $row.description, ' ', $row.extension, ' ', $row.path )|downcase|wash}">
            <tr>
                <td class="ezupdate-inv-name">
                    {if $row.composer}{def $parts = $row.name|explode( '/' )}{/if}
                    {if and( $row.composer, $row.installed, $parts|count|eq( 2 ) )}
                        <a href={concat( 'update/package/', $parts[0], '/', $parts[1] )|ezurl}><span class="ezupdate-inv-vendor">{$parts[0]|wash}/</span>{$parts[1]|wash}</a>
                    {else}
                        <span>{$row.name|wash}</span>
                    {/if}
                    {if $row.composer}{undef $parts}{/if}
                    <span class="ezupdate-inv-kind ezupdate-inv-kind-{$row.kind|wash}">{if eq( $row.kind, 'extension' )}{'Extension'|i18n( 'extension/ezupdate' )}{elseif eq( $row.kind, 'plugin' )}{'Plugin'|i18n( 'extension/ezupdate' )}{else}{'Library'|i18n( 'extension/ezupdate' )}{/if}</span>{if $row.dev}<span class="ezupdate-inv-tag">dev</span>{/if}
                    {if $row.description}<small>{$row.description|wash}</small>{/if}
                </td>
                <td class="ezupdate-inv-vcell">
                    <dl class="ezupdate-inv-versions">
                        <dt title="composer.json">json</dt>
                        <dd>{if $row.required}<code>{$row.required|wash}</code>{elseif $row.composer|not}<span class="ezupdate-inv-none">{'not from Composer'|i18n( 'extension/ezupdate' )}</span>{else}<span class="ezupdate-inv-none" title="{'Not in composer.json: required by another package'|i18n( 'extension/ezupdate' )}">{'dependency'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
                        {if $row.composer}
                        <dt title="composer.lock">lock</dt>
                        <dd>{if $row.locked}<code>{$row.locked|wash}</code>{else}<span class="ezupdate-inv-none">&mdash;</span>{/if}</dd>
                        {/if}
                        <dt title="{'Installed on disk'|i18n( 'extension/ezupdate' )}">{'disk'|i18n( 'extension/ezupdate' )}</dt>
                        <dd>{if $row.installed}<code>{$row.installed|wash}</code>{elseif $row.ext_version}<code>{$row.ext_version|wash}</code>{else}<span class="ezupdate-inv-none">&mdash;</span>{/if}
                            {if $row.git}<span class="ezupdate-inv-git" title="{'Git working copy'|i18n( 'extension/ezupdate' )}">{if $row.git.branch}{$row.git.branch|wash}{else}HEAD{/if}@{$row.git.commit|wash}</span>{/if}</dd>
                    </dl>
                </td>
                <td>{if $row.extension}
                        <code>{$row.extension|wash}</code>
                        {if $row.active|count|eq( 0 )}<span class="ezupdate-inv-pill is-off">{'off'|i18n( 'extension/ezupdate' )}</span>
                        {elseif eq( $row.active[0], 'everywhere' )}<span class="ezupdate-inv-pill is-on">{'active'|i18n( 'extension/ezupdate' )}</span>
                        {else}<span class="ezupdate-inv-pill is-access" title="{$row.active|implode( ', ' )|wash}">{'%count siteaccesses'|i18n( 'extension/ezupdate',, hash( '%count', $row.active|count ) )}</span>{/if}
                    {else}<span class="ezupdate-inv-none">&mdash;</span>{/if}</td>
                <td>{if $row.issues|count}
                        {foreach $row.issues as $issue}<span class="ezupdate-inv-issue is-{$issue[0]|wash}">{$issue[1]|wash}</span>{/foreach}
                    {else}<span class="ezupdate-inv-issue is-ok">{'OK'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                <td class="ezupdate-inv-more"><button type="button" aria-expanded="false" aria-controls="ezupdate-inv-detail-{$index}" title="{'Details'|i18n( 'extension/ezupdate' )}"><span class="hide">{'Details'|i18n( 'extension/ezupdate' )}</span></button></td>
            </tr>
            <tr class="ezupdate-inv-detail" id="ezupdate-inv-detail-{$index}" hidden="hidden">
                <td colspan="5">
                    <dl>
                        <dt>{'Path'|i18n( 'extension/ezupdate' )}</dt>
                        <dd>{if $row.path}<code>{$row.path|wash}</code>{if $row.path_exists|not} <span class="ezupdate-inv-issue is-bad">{'missing'|i18n( 'extension/ezupdate' )}</span>{/if}{else}&mdash;{/if}</dd>
                        {if $row.composer}
                        <dt>{'Installed from'|i18n( 'extension/ezupdate' )}</dt>
                        <dd>{if $row.method}{$row.method|wash}{else}&mdash;{/if}{if $row.installed_ref} <code>{$row.installed_ref|wash}</code>{/if}{if $row.locked_ref} <span class="ezupdate-muted">({'lock'|i18n( 'extension/ezupdate' )} <code>{$row.locked_ref|wash}</code>)</span>{/if}</dd>
                        {if $row.source_url}<dt>{'Source'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$row.source_url|wash}</code></dd>{/if}
                        {if $row.homepage}<dt>{'Website'|i18n( 'extension/ezupdate' )}</dt><dd><a href="{$row.homepage|wash}" rel="noopener" target="_blank">{$row.homepage|wash}</a></dd>{/if}
                        {if $row.license}<dt>{'License'|i18n( 'extension/ezupdate' )}</dt><dd>{$row.license|wash}</dd>{/if}
                        {/if}
                        {if $row.git}
                        <dt>Git</dt>
                        <dd>{if $row.git.branch}{'branch %branch'|i18n( 'extension/ezupdate',, hash( '%branch', $row.git.branch ) )|wash}{else}{'detached'|i18n( 'extension/ezupdate' )}{/if}, <code>{$row.git.commit|wash}</code></dd>
                        {/if}
                        {if $row.extension}
                        <dt>{'Switched on'|i18n( 'extension/ezupdate' )}</dt>
                        <dd>{if $row.active|count|eq( 0 )}{'Not in ActiveExtensions or any ActiveAccessExtensions'|i18n( 'extension/ezupdate' )}
                            {elseif eq( $row.active[0], 'everywhere' )}{'Everywhere (ActiveExtensions)'|i18n( 'extension/ezupdate' )}
                            {else}{'ActiveAccessExtensions of %list'|i18n( 'extension/ezupdate',, hash( '%list', $row.active|implode( ', ' ) ) )|wash}{/if}</dd>
                        {if $row.ext_version}<dt>{'Extension version'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$row.ext_version|wash}</code> <span class="ezupdate-muted">(extension.xml / ezinfo.php)</span></dd>{/if}
                        {/if}
                    </dl>
                </td>
            </tr>
        </tbody>
        {/foreach}
        <tbody class="ezupdate-inv-empty" hidden="hidden"><tr><td colspan="5">{'Nothing matches.'|i18n( 'extension/ezupdate' )}</td></tr></tbody>
    </table>
    </div>
</div>
{undef $filters}
{include uri='design:ezupdate/parts/footer.tpl'}
