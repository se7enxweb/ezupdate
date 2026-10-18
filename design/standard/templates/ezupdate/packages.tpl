{* Setup > Updates and packages > the packages of a package server (update/packages/<server>): its index.xml, with a
   filter that works in the page (ezupdate.js, data-ezx-filter) and the Fetch buttons. Built from the shared
   components (.a4-notice, .a4-card, .a4-field, .a4-table, .a4-badge, .a4-btn, .a4-empty); the rest is .a4-update-*
   in stylesheets/modules/update.css. No inline CSS or script. Every field and button name of the view is kept. *}
{def $ezx_actions = array( hash( 'url', 'update/servers', 'text', concat( '← ', 'Package servers'|i18n( 'extension/ezupdate' ) ), 'external', false(), 'download', false() ) )}
{if gt( $servers|count, 1 )}{foreach $servers as $other}{if ne( $other.name, $server.name )}{set $ezx_actions = $ezx_actions|append( hash( 'url', concat( 'update/packages/', $other.name ), 'text', $other.name, 'external', false(), 'download', false() ) )}{/if}{/foreach}{/if}
{include uri='design:ezupdate/parts/header.tpl' current='servers' error=$error message=$message
         title='Packages on %server'|i18n( 'extension/ezupdate',, hash( '%server', $server.name ) )
         actions=$ezx_actions}
{undef $ezx_actions}

<p class="a4-update-copyable a4-update-section"><code id="ezupdate-packages-index">{$server.url|wash}/index.xml</code>
    <button type="button" class="a4-btn a4-btn-small a4-update-copy" data-ezx-copy-target="ezupdate-packages-index" data-done="{'Copied'|i18n( 'extension/ezupdate' )|wash}" aria-label="{'Copy'|i18n( 'extension/ezupdate' )|wash}: {$server.url|wash}/index.xml">{'Copy'|i18n( 'extension/ezupdate' )}</button></p>

<div class="a4-notice is-info a4-update-section"><p>{'Fetching puts a package into the local package repository. It is installed from there with the package views of the Setup tab.'|i18n( 'extension/ezupdate' )}</p></div>

<section class="a4-card a4-update-section" aria-labelledby="ezupdate-packages-title">
    <div class="a4-card-head">
        <h2 id="ezupdate-packages-title">{'%count packages'|i18n( 'extension/ezupdate',, hash( '%count', $packages|count ) )}</h2>
        {if $packages|count}
        <div class="a4-card-actions a4-field a4-update-filter">
            <label class="a4-sr-only" for="ezupdate-packages-filter">{'Filter'|i18n( 'extension/ezupdate' )}</label>
            <input type="search" id="ezupdate-packages-filter" placeholder="{'Filter'|i18n( 'extension/ezupdate' )|wash}" data-ezx-filter="#ezx-pkg-rows" data-ezx-search="1" />
        </div>
        {/if}
    </div>
    <div class="a4-card-body">
    {if $packages|count}
        <div class="a4-table-wrap" role="region" aria-labelledby="ezupdate-packages-title" tabindex="0">
        <table class="a4-table">
            <caption class="a4-sr-only">{'%count packages'|i18n( 'extension/ezupdate',, hash( '%count', $packages|count ) )}</caption>
            <thead><tr>
                <th scope="col">{'Package'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Type'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Local copy'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col"><span class="a4-sr-only">{'Actions'|i18n( 'extension/ezupdate' )}</span></th>
            </tr></thead>
            <tbody id="ezx-pkg-rows">
            {foreach $packages as $package}
            <tr data-ezx-text="{concat( $package.name, ' ', $package.summary, ' ', $package.type )|downcase|wash}">
                <td><strong>{$package.name|wash}</strong>{if $package.summary}<span class="a4-meta a4-update-desc">{$package.summary|wash}</span>{/if}</td>
                <td><span class="a4-badge">{$package.type|wash}</span></td>
                <td>{if $package.local_version}<a href={concat( 'package/view/full/', $package.name )|ezurl}><span class="a4-badge is-ok">{$package.local_version|wash}</span></a>{else}<span class="a4-muted">&ndash;</span>{/if}</td>
                <td class="a4-update-actions">
                    {if $can_manage}
                    <form method="post" action={concat( 'update/packages/', $server.name )|ezurl}{if $package.local_version} data-ezupdate-confirm="{'Replace the local copy with the one from the server?'|i18n( 'extension/ezupdate' )|wash}"{/if}>
                        <input type="hidden" name="PackageName" value="{$package.name|wash}" />
                        {if $package.local_version}<input type="hidden" name="Replace" value="1" />{/if}
                        <input class="a4-btn a4-btn-small{if $package.local_version|not} a4-btn-primary{/if}" type="submit" name="FetchPackageButton" value="{if $package.local_version}{'Fetch again'|i18n( 'extension/ezupdate' )}{else}{'Fetch'|i18n( 'extension/ezupdate' )}{/if}" aria-label="{if $package.local_version}{'Fetch again'|i18n( 'extension/ezupdate' )|wash}{else}{'Fetch'|i18n( 'extension/ezupdate' )|wash}{/if}: {$package.name|wash}" data-ezx-busy="{'Fetching...'|i18n( 'extension/ezupdate' )|wash}" />
                    </form>
                    {/if}
                    {if $package.local_version}<a class="a4-btn a4-btn-small" href={concat( 'package/view/full/', $package.name )|ezurl}>{'Open'|i18n( 'extension/ezupdate' )}</a>{/if}
                </td>
            </tr>
            {/foreach}
            </tbody>
        </table>
        </div>
        <p class="a4-empty" data-ezx-none="#ezx-pkg-rows" hidden="hidden">{'Nothing matches.'|i18n( 'extension/ezupdate' )}</p>
    {else}
        <div class="a4-empty"><strong>{'No packages'|i18n( 'extension/ezupdate' )}</strong><p>{'This server lists no packages, or its index.xml could not be read.'|i18n( 'extension/ezupdate' )}</p></div>
    {/if}
    </div>
</section>
{include uri='design:ezupdate/parts/footer.tpl'}
