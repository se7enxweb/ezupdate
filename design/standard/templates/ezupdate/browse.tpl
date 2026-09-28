{include uri='design:ezupdate/parts/header.tpl' current='browse' error=$error}

<div class="context-block ezupdate">
    <div class="box-header">
        <h1 class="context-title">{'Find packages'|i18n( 'extension/ezupdate' )}</h1>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <form method="get" action={'update/browse'|ezurl} class="ezupdate-search">
            <input type="search" name="q" value="{$query|wash}" placeholder="{'Name, keyword or vendor'|i18n( 'extension/ezupdate' )}" autofocus="autofocus" />
            <select name="source">
                <option value="packagist"{if eq( $source, 'packagist' )} selected="selected"{/if}>packagist.org</option>
                <option value="composer"{if eq( $source, 'composer' )} selected="selected"{/if}>{'Every server in composer.json'|i18n( 'extension/ezupdate' )}</option>
            </select>
            <select name="type">
                {foreach $types as $value => $label}
                <option value="{$value|wash}"{if eq( $type, $value )} selected="selected"{/if}>{$label|wash}</option>
                {/foreach}
            </select>
            <input class="defaultbutton" type="submit" value="{'Search'|i18n( 'extension/ezupdate' )}" />
        </form>
        <p class="ezupdate-muted">{'packagist.org is asked through its public API; the type applies there only. The servers in composer.json are searched by Composer itself.'|i18n( 'extension/ezupdate' )}</p>

        {if $result}
            <p>{'%count packages'|i18n( 'extension/ezupdate',, hash( '%count', $result.total ) )}</p>
            {if $result.results|count}
            <table class="list" cellspacing="0">
                <tr>
                    <th>{'Package'|i18n( 'extension/ezupdate' )}</th>
                    {if eq( $source, 'packagist' )}<th class="ezupdate-number">{'Downloads'|i18n( 'extension/ezupdate' )}</th><th class="ezupdate-number">{'Stars'|i18n( 'extension/ezupdate' )}</th>{/if}
                    <th>{'Installed'|i18n( 'extension/ezupdate' )}</th>
                </tr>
                {foreach $result.results as $package sequence array( 'bglight', 'bgdark' ) as $style}
                <tr class="{$style}">
                    <td><a href={concat( 'update/package/', $package.name )|ezurl}><strong>{$package.name|wash}</strong></a>
                        {if and( is_set( $package.abandoned ), $package.abandoned )}<span class="ezupdate-badge ezupdate-bad">{'Abandoned'|i18n( 'extension/ezupdate' )}</span>{/if}
                        <div class="ezupdate-muted">{$package.description|wash}</div></td>
                    {if eq( $source, 'packagist' )}
                    <td class="ezupdate-number">{$package.downloads}</td>
                    <td class="ezupdate-number">{$package.favers}</td>
                    {/if}
                    <td>{if is_set( $installed[$package.name] )}<code>{$installed[$package.name]|wash}</code>{/if}</td>
                </tr>
                {/foreach}
            </table>

            {if gt( $result.pages, 1 )}
            <div class="ezupdate-pages">
                {if gt( $result.page, 1 )}<a href="{concat( 'update/browse/(page)/', sub( $result.page, 1 ) )|ezurl( 'no' )}?{$query_string|wash}">&laquo; {'Previous'|i18n( 'extension/ezupdate' )}</a>{/if}
                <span>{'Page %page of %pages'|i18n( 'extension/ezupdate',, hash( '%page', $result.page, '%pages', $result.pages ) )}</span>
                {if lt( $result.page, $result.pages )}<a href="{concat( 'update/browse/(page)/', sum( $result.page, 1 ) )|ezurl( 'no' )}?{$query_string|wash}">{'Next'|i18n( 'extension/ezupdate' )} &raquo;</a>{/if}
            </div>
            {/if}
            {/if}
        {/if}
    </div>
</div>
