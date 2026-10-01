{include uri='design:ezupdate/parts/header.tpl' current='servers' error=$error message=$message}
<div class="ezx-page">

    <div class="ezx-head">
        <div>
            <h1>{'Packages on %server'|i18n( 'extension/ezupdate',, hash( '%server', $server.name|wash ) )}</h1>
            <p><code data-ezx-copy="1">{$server.url|wash}/index.xml</code></p>
        </div>
        <div class="ezx-head-actions">
            <a class="button ezx-btn-s" href={'update/servers'|ezurl}>&larr; {'Package servers'|i18n( 'extension/ezupdate' )}</a>
            {if gt( $servers|count, 1 )}
                {foreach $servers as $other}{if ne( $other.name, $server.name )}<a class="button ezx-btn-s" href={concat( 'update/packages/', $other.name )|ezurl}>{$other.name|wash}</a>{/if}{/foreach}
            {/if}
        </div>
    </div>

    <div class="ezx-alert ezx-alert-info"><div>{'Fetching puts a package into the local package repository. It is installed from there with the package views of the Setup tab.'|i18n( 'extension/ezupdate' )}</div></div>

    <section class="ezx-panel">
        <header>
            <h2>{'%count packages'|i18n( 'extension/ezupdate',, hash( '%count', $packages|count ) )}</h2>
            {if $packages|count}<input type="search" placeholder="{'Filter'|i18n( 'extension/ezupdate' )}" data-ezx-filter="#ezx-pkg-rows" data-ezx-search="1" />{/if}
        </header>
        <div class="ezx-panel-body ezx-panel-flush">
        {if $packages|count}
            <table class="ezx-table">
                <thead><tr>
                    <th>{'Package'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Type'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Local copy'|i18n( 'extension/ezupdate' )}</th>
                    <th><span class="hide">{'Actions'|i18n( 'extension/ezupdate' )}</span></th>
                </tr></thead>
                <tbody id="ezx-pkg-rows">
                {foreach $packages as $package}
                <tr data-ezx-text="{concat( $package.name, ' ', $package.summary, ' ', $package.type )|downcase|wash}">
                    <td class="ezx-title-cell"><strong>{$package.name|wash}</strong>{if $package.summary}<small>{$package.summary|wash}</small>{/if}</td>
                    <td data-label="{'Type'|i18n( 'extension/ezupdate' )}"><span class="ezupdate-badge">{$package.type|wash}</span></td>
                    <td data-label="{'Local copy'|i18n( 'extension/ezupdate' )}">{if $package.local_version}<a href={concat( 'package/view/full/', $package.name )|ezurl}><span class="ezupdate-badge ezupdate-good">{$package.local_version|wash}</span></a>{else}<span class="ezupdate-muted">&ndash;</span>{/if}</td>
                    <td class="ezx-actions">
                        {if $can_manage}
                        <form method="post" action={concat( 'update/packages/', $server.name )|ezurl}{if $package.local_version} data-ezupdate-confirm="{'Replace the local copy with the one from the server?'|i18n( 'extension/ezupdate' )|wash}"{/if}>
                            <input type="hidden" name="PackageName" value="{$package.name|wash}" />
                            {if $package.local_version}<input type="hidden" name="Replace" value="1" />{/if}
                            <input class="{if $package.local_version}button{else}defaultbutton{/if} ezx-btn-s" type="submit" name="FetchPackageButton" value="{if $package.local_version}{'Fetch again'|i18n( 'extension/ezupdate' )}{else}{'Fetch'|i18n( 'extension/ezupdate' )}{/if}" data-ezx-busy="{'Fetching...'|i18n( 'extension/ezupdate' )|wash}" />
                        </form>
                        {/if}
                        {if $package.local_version}<a class="button ezx-btn-s" href={concat( 'package/view/full/', $package.name )|ezurl}>{'Open'|i18n( 'extension/ezupdate' )}</a>{/if}
                    </td>
                </tr>
                {/foreach}
                </tbody>
            </table>
            <div class="ezx-empty" data-ezx-none="#ezx-pkg-rows" hidden="hidden">{'Nothing matches.'|i18n( 'extension/ezupdate' )}</div>
        {else}
            <div class="ezx-empty"><strong>{'No packages'|i18n( 'extension/ezupdate' )}</strong>{'This server lists no packages, or its index.xml could not be read.'|i18n( 'extension/ezupdate' )}</div>
        {/if}
        </div>
    </section>
</div>
{include uri='design:ezupdate/parts/footer.tpl'}
