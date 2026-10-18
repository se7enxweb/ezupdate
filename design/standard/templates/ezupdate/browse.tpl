{* Setup > Updates and packages > Find packages (update/browse): the search (packagist.org through its API, or every
   server of composer.json through Composer) and its results with their pages. Built from the shared components
   (.a4-filterbar, .a4-field, .a4-card, .a4-table, .a4-badge, .a4-btn, .a4-empty); the rest is .a4-update-* in
   stylesheets/modules/update.css. No inline CSS or script. The form's field names (q, source, type) are kept. *}
{include uri='design:ezupdate/parts/header.tpl' current='browse' error=$error
         title='Find packages'|i18n( 'extension/ezupdate' )
         intro='packagist.org is asked through its public API; the type applies there only. The servers in composer.json are searched by Composer itself.'|i18n( 'extension/ezupdate' )}

<form method="get" action={'update/browse'|ezurl} class="a4-filterbar a4-update-search" role="search">
    <div class="a4-field a4-update-grow">
        <label for="ezupdate-browse-q">{'Search'|i18n( 'extension/ezupdate' )}</label>
        <input type="search" id="ezupdate-browse-q" name="q" value="{$query|wash}" placeholder="{'Name, keyword or vendor'|i18n( 'extension/ezupdate' )}" autofocus="autofocus" data-ezx-search="1" />
    </div>
    <div class="a4-field">
        <label for="ezupdate-browse-source">{'Where'|i18n( 'extension/ezupdate' )}</label>
        <select id="ezupdate-browse-source" name="source">
            <option value="packagist"{if eq( $source, 'packagist' )} selected="selected"{/if}>packagist.org</option>
            <option value="composer"{if eq( $source, 'composer' )} selected="selected"{/if}>{'Every server in composer.json'|i18n( 'extension/ezupdate' )}</option>
        </select>
    </div>
    <div class="a4-field">
        <label for="ezupdate-browse-type">{'Type'|i18n( 'extension/ezupdate' )}</label>
        <select id="ezupdate-browse-type" name="type">
            {foreach $types as $value => $label}
            <option value="{$value|wash}"{if eq( $type, $value )} selected="selected"{/if}>{$label|wash}</option>
            {/foreach}
        </select>
    </div>
    <div class="a4-actions">
        <input class="a4-btn a4-btn-primary" type="submit" value="{'Search'|i18n( 'extension/ezupdate' )}" data-ezx-busy="{'Searching...'|i18n( 'extension/ezupdate' )|wash}" />
    </div>
</form>

{if $result}
<section class="a4-card a4-update-section" aria-labelledby="ezupdate-browse-results">
    <div class="a4-card-head">
        <h2 id="ezupdate-browse-results">{'%count packages'|i18n( 'extension/ezupdate',, hash( '%count', $result.total ) )}</h2>
        {if gt( $result.pages, 1 )}<div class="a4-card-actions"><span class="a4-meta">{'Page %page of %pages'|i18n( 'extension/ezupdate',, hash( '%page', $result.page, '%pages', $result.pages ) )}</span></div>{/if}
    </div>
    <div class="a4-card-body">
    {if $result.results|count}
        <div class="a4-table-wrap">
        <table class="a4-table">
            <caption class="a4-sr-only">{'%count packages'|i18n( 'extension/ezupdate',, hash( '%count', $result.total ) )}</caption>
            <thead><tr>
                <th scope="col">{'Package'|i18n( 'extension/ezupdate' )}</th>
                {if eq( $source, 'packagist' )}<th scope="col" class="a4-num">{'Downloads'|i18n( 'extension/ezupdate' )}</th><th scope="col" class="a4-num">{'Stars'|i18n( 'extension/ezupdate' )}</th>{/if}
                <th scope="col">{'Installed'|i18n( 'extension/ezupdate' )}</th>
            </tr></thead>
            <tbody>
            {foreach $result.results as $package}
            <tr>
                <td><a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>
                    {if and( is_set( $package.abandoned ), $package.abandoned )}<span class="a4-badge is-bad">{'Abandoned'|i18n( 'extension/ezupdate' )}</span>{/if}
                    {if $package.description}<span class="a4-meta a4-update-desc">{$package.description|wash}</span>{/if}</td>
                {if eq( $source, 'packagist' )}
                <td class="a4-num"><span data-ezx-num="{$package.downloads}">{$package.downloads}</span></td>
                <td class="a4-num"><span data-ezx-num="{$package.favers}">{$package.favers}</span></td>
                {/if}
                <td>{if is_set( $installed[$package.name] )}<span class="a4-badge is-ok">{'Installed %version'|i18n( 'extension/ezupdate',, hash( '%version', $installed[$package.name] ) )|wash}</span>{/if}</td>
            </tr>
            {/foreach}
            </tbody>
        </table>
        </div>
    {else}
        <div class="a4-empty"><strong>{'Nothing found'|i18n( 'extension/ezupdate' )}</strong><p>{'Try another word, or every type.'|i18n( 'extension/ezupdate' )}</p></div>
    {/if}
    </div>
    {if gt( $result.pages, 1 )}
    <nav class="a4-card-foot" aria-label="{'Pages'|i18n( 'extension/ezupdate' )}">
        {if gt( $result.page, 1 )}<a class="a4-btn a4-btn-small" href="{concat( 'update/browse/(page)/', sub( $result.page, 1 ) )|ezurl( 'no' )}?{$query_string|wash}">&larr; {'Previous'|i18n( 'extension/ezupdate' )}</a>{/if}
        <span class="a4-meta">{'Page %page of %pages'|i18n( 'extension/ezupdate',, hash( '%page', $result.page, '%pages', $result.pages ) )}</span>
        {if lt( $result.page, $result.pages )}<a class="a4-btn a4-btn-small" href="{concat( 'update/browse/(page)/', sum( $result.page, 1 ) )|ezurl( 'no' )}?{$query_string|wash}">{'Next'|i18n( 'extension/ezupdate' )} &rarr;</a>{/if}
    </nav>
    {/if}
</section>
{else}
<div class="a4-empty"><strong>{'Search packagist.org or your own servers'|i18n( 'extension/ezupdate' )}</strong><p>{'Exponential extensions are of the type ezpublish-legacy-extension.'|i18n( 'extension/ezupdate' )}</p></div>
{/if}
{include uri='design:ezupdate/parts/footer.tpl'}
