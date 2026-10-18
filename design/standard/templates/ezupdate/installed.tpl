{* Setup > Updates and packages > Installed packages (update/installed): composer.json, composer.lock, installed.json
   and the extension directories matched up (eZUpdateInventory). The figures and the filter chips choose what is
   shown, the search and the sorting work in the page (ezupdate.js, installedPackages(): it finds its parts by their
   data-* attributes). Built from the shared components (.a4-figures, .a4-toolbar, .a4-field, .a4-chips, .a4-table,
   .a4-tag, .a4-badge, .a4-facts, .a4-btn); the rest is .a4-update-* in stylesheets/modules/update.css. *}
{include uri='design:ezupdate/parts/header.tpl' current='installed'
         title='Installed packages'|i18n( 'extension/ezupdate' )
         intro='What composer.json requires, what composer.lock resolved, what is installed on disk and which extensions the settings switch on, side by side.'|i18n( 'extension/ezupdate' )
         actions=array( hash( 'url', 'update/installed/json', 'text', 'JSON ↓', 'external', false(), 'download', true() ),
                        hash( 'url', 'update/installed/csv', 'text', 'CSV ↓', 'external', false(), 'download', true() ) )}

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

<div data-ezupdate-installed="1">

    <ul class="a4-badges a4-update-section" aria-label="{'Sources'|i18n( 'extension/ezupdate' )|wash}">
        <li class="a4-tag{if $sources.composer_json} is-ok{else} is-bad{/if}"><code>composer.json</code></li>
        <li class="a4-tag{if $sources.composer_lock} is-ok{else} is-bad{/if}"><code>composer.lock</code>{if $sources.lock_age}&nbsp;{$sources.lock_age|l10n( 'shortdatetime' )}{/if}</li>
        <li class="a4-tag{if $sources.installed_json} is-ok{else} is-bad{/if}"><code>installed.json</code>{if $sources.installed_age}&nbsp;{$sources.installed_age|l10n( 'shortdatetime' )}{/if}</li>
        <li class="a4-tag is-ok"><code>{$sources.extension_dir|wash}/</code>&nbsp;{'%count siteaccesses'|i18n( 'extension/ezupdate',, hash( '%count', $sources.siteaccesses|count ) )}</li>
    </ul>

    <section class="a4-update-section" aria-labelledby="ezupdate-installed-summary">
        <h2 class="a4-sr-only" id="ezupdate-installed-summary">{'Summary'|i18n( 'extension/ezupdate' )}</h2>
        <ul class="a4-figures a4-update-figures">
            <li class="a4-figure"><button type="button" data-filter="composer" aria-pressed="false"><strong>{$summary.composer}</strong><span>{'Installed by Composer'|i18n( 'extension/ezupdate' )}</span></button></li>
            <li class="a4-figure"><button type="button" data-filter="required" aria-pressed="false"><strong>{$summary.required}</strong><span>{'Required in composer.json'|i18n( 'extension/ezupdate' )}</span></button></li>
            <li class="a4-figure"><button type="button" data-filter="extension" aria-pressed="false"><strong>{$summary.extension}</strong><span>{'Extensions on disk, %active active in any siteaccess'|i18n( 'extension/ezupdate',, hash( '%active', $summary.active ) )}</span></button></li>
            <li class="a4-figure"><button type="button" data-filter="local" aria-pressed="false"><strong>{$summary.local}</strong><span>{'Extensions not from Composer'|i18n( 'extension/ezupdate' )}</span></button></li>
            <li class="a4-figure{if $summary.issues} is-attention{else} is-ok{/if}"><button type="button" data-filter="issues" aria-pressed="false"><strong>{$summary.issues}</strong><span>{'Need attention'|i18n( 'extension/ezupdate' )}</span></button></li>
        </ul>
    </section>

    <div class="a4-toolbar a4-update-invbar">
        <div class="a4-field a4-update-grow">
            <label for="ezupdate-installed-search">{'Search'|i18n( 'extension/ezupdate' )}</label>
            <input type="search" id="ezupdate-installed-search" placeholder="{'Filter by name, description, extension or path'|i18n( 'extension/ezupdate' )}" data-search="1" aria-keyshortcuts="/" />
        </div>
        <div class="a4-field">
            <label for="ezupdate-installed-sort">{'Sort by'|i18n( 'extension/ezupdate' )}</label>
            <select id="ezupdate-installed-sort" data-sort-select="1">
                <option value="name">{'Name'|i18n( 'extension/ezupdate' )}</option>
                <option value="issues">{'Needs attention first'|i18n( 'extension/ezupdate' )}</option>
                <option value="installed">{'Installed version'|i18n( 'extension/ezupdate' )}</option>
                <option value="extension">{'Extension'|i18n( 'extension/ezupdate' )}</option>
                <option value="kind">{'Kind'|i18n( 'extension/ezupdate' )}</option>
            </select>
        </div>
        <fieldset class="a4-field a4-field-wide a4-update-show">
            <legend>{'Show'|i18n( 'extension/ezupdate' )}</legend>
            <div class="a4-chips">
                {foreach $filters as $filter}
                <label class="a4-chip"><input type="radio" name="ezupdate-installed-show" value="{$filter.id}" data-filter="{$filter.id}"{if eq( $filter.id, 'all' )} checked="checked"{/if} /><span>{$filter.label|wash}{if ne( $filter.id, 'all' )} <span class="a4-update-count">{$summary[$filter.id]}</span>{/if}</span></label>
                {/foreach}
            </div>
        </fieldset>
        <p class="a4-meta a4-update-shown" aria-live="polite"><span data-count="1">{$rows|count}</span> / {$rows|count}</p>
    </div>

    <div class="a4-table-wrap" role="region" aria-label="{'Installed packages'|i18n( 'extension/ezupdate' )|wash}" tabindex="0">
    <table class="a4-table a4-update-inv" data-ezupdate-table="1">
        <caption class="a4-sr-only">{'Installed packages'|i18n( 'extension/ezupdate' )}</caption>
        <thead>
            <tr>
                <th scope="col" aria-sort="ascending"><button type="button" class="a4-link-button" data-sort="name">{'Package'|i18n( 'extension/ezupdate' )}</button></th>
                <th scope="col" aria-sort="none"><button type="button" class="a4-link-button" data-sort="installed">{'Versions'|i18n( 'extension/ezupdate' )}</button></th>
                <th scope="col" aria-sort="none"><button type="button" class="a4-link-button" data-sort="extension">{'Extension'|i18n( 'extension/ezupdate' )}</button></th>
                <th scope="col" aria-sort="none"><button type="button" class="a4-link-button" data-sort="issues">{'Status'|i18n( 'extension/ezupdate' )}</button></th>
                <th scope="col"><span class="a4-sr-only">{'Details'|i18n( 'extension/ezupdate' )}</span></th>
            </tr>
        </thead>
        {foreach $rows as $index => $row}
        <tbody class="a4-update-invrow{if $row.issues} has-issues{/if}" data-ezupdate-row="1"
               data-filters="all {$row.filters|implode( ' ' )}"
               data-name="{$row.name|downcase|wash}" data-kind="{$row.kind|wash}" data-required="{$row.required|wash}"
               data-locked="{$row.locked|wash}" data-installed="{$row.installed|wash}" data-extension="{if $row.extension}{$row.extension|wash}{/if}"
               data-issues="{$row.issues|count}"
               data-text="{concat( $row.name, ' ', $row.description, ' ', $row.extension, ' ', $row.path )|downcase|wash}">
            <tr>
                <td class="a4-update-name">
                    {if $row.composer}{def $parts = $row.name|explode( '/' )}{/if}
                    {if and( $row.composer, $row.installed, $parts|count|eq( 2 ) )}
                        <a href={concat( 'update/package/', $parts[0], '/', $parts[1] )|ezurl}><span class="a4-update-vendor">{$parts[0]|wash}/</span>{$parts[1]|wash}</a>
                    {else}
                        <span>{$row.name|wash}</span>
                    {/if}
                    {if $row.composer}{undef $parts}{/if}
                    <span class="a4-tag{if eq( $row.kind, 'extension' )} is-accent{/if}">{if eq( $row.kind, 'extension' )}{'Extension'|i18n( 'extension/ezupdate' )}{elseif eq( $row.kind, 'plugin' )}{'Plugin'|i18n( 'extension/ezupdate' )}{else}{'Library'|i18n( 'extension/ezupdate' )}{/if}</span>{if $row.dev} <span class="a4-tag is-mono">dev</span>{/if}
                    {if $row.description}<span class="a4-meta a4-update-desc">{$row.description|wash}</span>{/if}
                </td>
                <td>
                    <dl class="a4-update-versions">
                        <dt title="composer.json">json</dt>
                        <dd>{if $row.required}<code>{$row.required|wash}</code>{elseif $row.composer|not}<span class="a4-muted">{'not from Composer'|i18n( 'extension/ezupdate' )}</span>{else}<span class="a4-muted" title="{'Not in composer.json: required by another package'|i18n( 'extension/ezupdate' )}">{'dependency'|i18n( 'extension/ezupdate' )}</span>{/if}</dd>
                        {if $row.composer}
                        <dt title="composer.lock">lock</dt>
                        <dd>{if $row.locked}<code>{$row.locked|wash}</code>{else}<span class="a4-muted">&mdash;</span>{/if}</dd>
                        {/if}
                        <dt title="{'Installed on disk'|i18n( 'extension/ezupdate' )}">{'disk'|i18n( 'extension/ezupdate' )}</dt>
                        <dd>{if $row.installed}<code>{$row.installed|wash}</code>{elseif $row.ext_version}<code>{$row.ext_version|wash}</code>{else}<span class="a4-muted">&mdash;</span>{/if}
                            {if $row.git}<span class="a4-meta a4-update-desc" title="{'Git working copy'|i18n( 'extension/ezupdate' )}">{if $row.git.branch}{$row.git.branch|wash}{else}HEAD{/if}@{$row.git.commit|wash}</span>{/if}</dd>
                    </dl>
                </td>
                <td>{if $row.extension}<span class="a4-badges a4-update-ext">
                        <code>{$row.extension|wash}</code>
                        {if $row.active|count|eq( 0 )}<span class="a4-badge">{'off'|i18n( 'extension/ezupdate' )}</span>
                        {elseif eq( $row.active[0], 'everywhere' )}<span class="a4-badge is-ok">{'active'|i18n( 'extension/ezupdate' )}</span>
                        {else}<span class="a4-badge is-info" title="{$row.active|implode( ', ' )|wash}">{'%count siteaccesses'|i18n( 'extension/ezupdate',, hash( '%count', $row.active|count ) )}</span>{/if}</span>
                    {else}<span class="a4-muted">&mdash;</span>{/if}</td>
                <td><span class="a4-badges">{if $row.issues|count}
                        {foreach $row.issues as $issue}<span class="a4-badge is-{$issue[0]|wash}">{$issue[1]|wash}</span>{/foreach}
                    {else}<span class="a4-badge is-ok">{'OK'|i18n( 'extension/ezupdate' )}</span>{/if}</span></td>
                <td class="a4-update-actions"><button type="button" class="a4-btn a4-btn-small a4-btn-ghost a4-btn-icon a4-update-more" aria-expanded="false" aria-controls="ezupdate-inv-detail-{$index}" title="{'Details'|i18n( 'extension/ezupdate' )|wash}"><span class="a4-icon a4-bi-chevron-down" aria-hidden="true"></span><span class="a4-sr-only">{'Details'|i18n( 'extension/ezupdate' )}: {$row.name|wash}</span></button></td>
            </tr>
            <tr class="a4-update-detail" id="ezupdate-inv-detail-{$index}" hidden="hidden">
                <td colspan="5">
                    <dl class="a4-facts is-rows">
                        <dt>{'Path'|i18n( 'extension/ezupdate' )}</dt>
                        <dd>{if $row.path}<code>{$row.path|wash}</code>{if $row.path_exists|not} <span class="a4-badge is-bad">{'missing'|i18n( 'extension/ezupdate' )}</span>{/if}{else}&mdash;{/if}</dd>
                        {if $row.composer}
                        <dt>{'Installed from'|i18n( 'extension/ezupdate' )}</dt>
                        <dd>{if $row.method}{$row.method|wash}{else}&mdash;{/if}{if $row.installed_ref} <code>{$row.installed_ref|wash}</code>{/if}{if $row.locked_ref} <span class="a4-muted">({'lock'|i18n( 'extension/ezupdate' )} <code>{$row.locked_ref|wash}</code>)</span>{/if}</dd>
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
                        {if $row.ext_version}<dt>{'Extension version'|i18n( 'extension/ezupdate' )}</dt><dd><code>{$row.ext_version|wash}</code> <span class="a4-muted">(extension.xml / ezinfo.php)</span></dd>{/if}
                        {/if}
                    </dl>
                </td>
            </tr>
        </tbody>
        {/foreach}
        <tbody data-ezupdate-empty="1" hidden="hidden"><tr><td colspan="5"><p class="a4-empty">{'Nothing matches.'|i18n( 'extension/ezupdate' )}</p></td></tr></tbody>
    </table>
    </div>
</div>
{undef $filters}
{include uri='design:ezupdate/parts/footer.tpl'}
