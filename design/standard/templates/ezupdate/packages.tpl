{include uri='design:ezupdate/parts/header.tpl' current='servers' error=$error message=$message}

<div class="context-block ezupdate">
    <div class="box-header">
        <h1 class="context-title">{'Packages on %server'|i18n( 'extension/ezupdate',, hash( '%server', $server.name|wash ) )}</h1>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <p class="ezupdate-muted"><code>{$server.url|wash}/index.xml</code>
            {if gt( $servers|count, 1 )}&middot; {'Other servers:'|i18n( 'extension/ezupdate' )}
            {foreach $servers as $other}{if ne( $other.name, $server.name )}<a href={concat( 'update/packages/', $other.name )|ezurl}>{$other.name|wash}</a> {/if}{/foreach}{/if}</p>
        <p class="ezupdate-muted">{'Fetching puts a package into the local package repository. It is installed from there with the package views of the Setup tab.'|i18n( 'extension/ezupdate' )}</p>

        {if $packages|count}
        <table class="list" cellspacing="0">
            <tr>
                <th>{'Package'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Type'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Local copy'|i18n( 'extension/ezupdate' )}</th>
                <th></th>
            </tr>
            {foreach $packages as $package sequence array( 'bglight', 'bgdark' ) as $style}
            <tr class="{$style}">
                <td><strong>{$package.name|wash}</strong>{if $package.summary}<div class="ezupdate-muted">{$package.summary|wash}</div>{/if}</td>
                <td>{$package.type|wash}</td>
                <td>{if $package.local_version}<a href={concat( 'package/view/full/', $package.name )|ezurl}>{$package.local_version|wash}</a>{else}<span class="ezupdate-muted">&ndash;</span>{/if}</td>
                <td class="ezupdate-actions">
                    {if $can_manage}
                    <form method="post" action={concat( 'update/packages/', $server.name )|ezurl}{if $package.local_version} data-ezupdate-confirm="{'Replace the local copy with the one from the server?'|i18n( 'extension/ezupdate' )|wash}"{/if}>
                        <input type="hidden" name="PackageName" value="{$package.name|wash}" />
                        {if $package.local_version}<input type="hidden" name="Replace" value="1" />{/if}
                        <input class="button" type="submit" name="FetchPackageButton" value="{if $package.local_version}{'Fetch again'|i18n( 'extension/ezupdate' )}{else}{'Fetch'|i18n( 'extension/ezupdate' )}{/if}" />
                    </form>
                    {/if}
                    {if $package.local_version}<a class="button" href={concat( 'package/view/full/', $package.name )|ezurl}>{'Open'|i18n( 'extension/ezupdate' )}</a>{/if}
                </td>
            </tr>
            {/foreach}
        </table>
        {/if}
    </div>
</div>
