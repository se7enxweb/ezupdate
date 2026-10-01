{include uri='design:ezupdate/parts/header.tpl' current='browse' error=$error}
<div class="ezx-page">

    <div class="ezx-head">
        <div>
            <h1>{'Find packages'|i18n( 'extension/ezupdate' )}</h1>
            <p>{'packagist.org is asked through its public API; the type applies there only. The servers in composer.json are searched by Composer itself.'|i18n( 'extension/ezupdate' )}</p>
        </div>
    </div>

    <section class="ezx-panel">
        <div class="ezx-panel-body">
            <form method="get" action={'update/browse'|ezurl} class="ezx-form" role="search">
                <label class="ezx-field ezx-field-grow"><span>{'Search'|i18n( 'extension/ezupdate' )}</span>
                    <input type="search" name="q" value="{$query|wash}" placeholder="{'Name, keyword or vendor'|i18n( 'extension/ezupdate' )}" autofocus="autofocus" data-ezx-search="1" /></label>
                <label class="ezx-field"><span>{'Where'|i18n( 'extension/ezupdate' )}</span>
                    <select name="source">
                        <option value="packagist"{if eq( $source, 'packagist' )} selected="selected"{/if}>packagist.org</option>
                        <option value="composer"{if eq( $source, 'composer' )} selected="selected"{/if}>{'Every server in composer.json'|i18n( 'extension/ezupdate' )}</option>
                    </select></label>
                <label class="ezx-field"><span>{'Type'|i18n( 'extension/ezupdate' )}</span>
                    <select name="type">
                        {foreach $types as $value => $label}
                        <option value="{$value|wash}"{if eq( $type, $value )} selected="selected"{/if}>{$label|wash}</option>
                        {/foreach}
                    </select></label>
                <input class="defaultbutton" type="submit" value="{'Search'|i18n( 'extension/ezupdate' )}" data-ezx-busy="{'Searching...'|i18n( 'extension/ezupdate' )|wash}" />
            </form>
        </div>
    </section>

    {if $result}
    <section class="ezx-panel">
        <header><h2>{'%count packages'|i18n( 'extension/ezupdate',, hash( '%count', $result.total ) )}</h2>
            {if gt( $result.pages, 1 )}<span class="ezupdate-muted">{'Page %page of %pages'|i18n( 'extension/ezupdate',, hash( '%page', $result.page, '%pages', $result.pages ) )}</span>{/if}</header>
        <div class="ezx-panel-body{if $result.results|count} ezx-panel-flush{/if}">
        {if $result.results|count}
            <table class="ezx-table">
                <thead><tr>
                    <th>{'Package'|i18n( 'extension/ezupdate' )}</th>
                    {if eq( $source, 'packagist' )}<th class="ezx-num">{'Downloads'|i18n( 'extension/ezupdate' )}</th><th class="ezx-num">{'Stars'|i18n( 'extension/ezupdate' )}</th>{/if}
                    <th>{'Installed'|i18n( 'extension/ezupdate' )}</th>
                </tr></thead>
                <tbody>
                {foreach $result.results as $package}
                <tr>
                    <td class="ezx-title-cell"><a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>
                        {if and( is_set( $package.abandoned ), $package.abandoned )}<span class="ezupdate-badge ezupdate-bad">{'Abandoned'|i18n( 'extension/ezupdate' )}</span>{/if}
                        <small>{$package.description|wash}</small></td>
                    {if eq( $source, 'packagist' )}
                    <td class="ezx-num" data-label="{'Downloads'|i18n( 'extension/ezupdate' )}"><span data-ezx-num="{$package.downloads}">{$package.downloads}</span></td>
                    <td class="ezx-num" data-label="{'Stars'|i18n( 'extension/ezupdate' )}"><span data-ezx-num="{$package.favers}">{$package.favers}</span></td>
                    {/if}
                    <td>{if is_set( $installed[$package.name] )}<span class="ezupdate-badge ezupdate-good">{'Installed %version'|i18n( 'extension/ezupdate',, hash( '%version', $installed[$package.name] ) )|wash}</span>{/if}</td>
                </tr>
                {/foreach}
                </tbody>
            </table>
        {else}
            <div class="ezx-empty"><strong>{'Nothing found'|i18n( 'extension/ezupdate' )}</strong>{'Try another word, or every type.'|i18n( 'extension/ezupdate' )}</div>
        {/if}
        </div>
        {if gt( $result.pages, 1 )}
        <footer>
            <nav class="ezupdate-pages" aria-label="{'Pages'|i18n( 'extension/ezupdate' )}">
                {if gt( $result.page, 1 )}<a class="button ezx-btn-s" href="{concat( 'update/browse/(page)/', sub( $result.page, 1 ) )|ezurl( 'no' )}?{$query_string|wash}">&larr; {'Previous'|i18n( 'extension/ezupdate' )}</a>{/if}
                <span class="ezupdate-muted">{'Page %page of %pages'|i18n( 'extension/ezupdate',, hash( '%page', $result.page, '%pages', $result.pages ) )}</span>
                {if lt( $result.page, $result.pages )}<a class="button ezx-btn-s" href="{concat( 'update/browse/(page)/', sum( $result.page, 1 ) )|ezurl( 'no' )}?{$query_string|wash}">{'Next'|i18n( 'extension/ezupdate' )} &rarr;</a>{/if}
            </nav>
        </footer>
        {/if}
    </section>
    {else}
    <div class="ezx-empty"><strong>{'Search packagist.org or your own servers'|i18n( 'extension/ezupdate' )}</strong>{'Exponential extensions are of the type ezpublish-legacy-extension.'|i18n( 'extension/ezupdate' )}</div>
    {/if}
</div>
{include uri='design:ezupdate/parts/footer.tpl'}
