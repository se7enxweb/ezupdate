{* Setup > Updates and packages > Package servers (update/servers): the Composer servers of composer.json and the
   servers of .ezpkg packages, each with its add form. Built from the shared components (.a4-card, .a4-table,
   .a4-badge, .a4-btn, .a4-field, .a4-notice, .a4-empty); the rest is .a4-update-* in stylesheets/modules/update.css.
   No inline CSS or script: a form with data-ezupdate-confirm asks first (ezupdate.js). Every field and button name
   of the view is kept. *}
{include uri='design:ezupdate/parts/header.tpl' current='servers' error=$error message=$message
         title='Package servers'|i18n( 'extension/ezupdate' )
         intro='Where Composer looks for code packages, and where the setup wizard and the package views find .ezpkg packages.'|i18n( 'extension/ezupdate' )}

<section class="a4-card a4-update-section" aria-labelledby="ezupdate-composer-servers">
    <div class="a4-card-head">
        <div>
            <h2 id="ezupdate-composer-servers">{'Composer servers'|i18n( 'extension/ezupdate' )}</h2>
            <p>{'Where Composer looks for code packages: the "repositories" of composer.json, changed here with composer config. The command line and Composer read the same list.'|i18n( 'extension/ezupdate' )}</p>
        </div>
        <div class="a4-card-actions"><span class="a4-badge">{sum( $composer_servers|count, 1 )}</span></div>
    </div>
    <div class="a4-card-body">
        {if $composer_json_writable|not}
        <div class="a4-notice is-warn a4-update-note-top"><p>{'composer.json cannot be written by the web server, so this list can only be read here.'|i18n( 'extension/ezupdate' )}</p></div>
        {/if}
        <div class="a4-table-wrap">
        <table class="a4-table">
            <caption class="a4-sr-only">{'Composer servers'|i18n( 'extension/ezupdate' )}</caption>
            <thead><tr>
                <th scope="col">{'Name'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Type'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Address'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col"><span class="a4-sr-only">{'Actions'|i18n( 'extension/ezupdate' )}</span></th>
            </tr></thead>
            <tbody>
            <tr>
                <td><strong>packagist.org</strong> {if $packagist_enabled}<span class="a4-badge is-ok">{'On'|i18n( 'extension/ezupdate' )}</span>{else}<span class="a4-badge">{'Off'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                <td>composer</td>
                <td><code>https://repo.packagist.org</code></td>
                <td class="a4-update-actions">
                    <form method="post" action={'update/servers'|ezurl}>
                        {if $packagist_enabled}
                        <input class="a4-btn a4-btn-small" type="submit" name="PackagistOffButton" value="{'Switch off'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                        {else}
                        <input class="a4-btn a4-btn-small" type="submit" name="PackagistOnButton" value="{'Switch on'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                        {/if}
                    </form>
                </td>
            </tr>
            {foreach $composer_servers as $index => $server}
            <tr>
                <td><strong>{$server.name|wash}</strong></td>
                <td>{$server.type|wash}</td>
                <td><span class="a4-update-copyable"><code id="ezupdate-composer-server-{$index}">{$server.url|wash}</code>
                    <button type="button" class="a4-btn a4-btn-small a4-update-copy" data-ezx-copy-target="ezupdate-composer-server-{$index}" data-done="{'Copied'|i18n( 'extension/ezupdate' )|wash}" aria-label="{'Copy'|i18n( 'extension/ezupdate' )|wash}: {$server.url|wash}">{'Copy'|i18n( 'extension/ezupdate' )}</button></span></td>
                <td class="a4-update-actions">
                    {if $server.removable}
                    <form method="post" action={'update/servers'|ezurl} data-ezupdate-confirm="{'Remove this server from composer.json?'|i18n( 'extension/ezupdate' )|wash}">
                        <input type="hidden" name="ServerName" value="{$server.name|wash}" />
                        <input class="a4-btn a4-btn-small a4-btn-outline-danger" type="submit" name="RemoveComposerServerButton" value="{'Remove'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                    </form>
                    {else}
                    <span class="a4-meta">{'unnamed, edit composer.json'|i18n( 'extension/ezupdate' )}</span>
                    {/if}
                </td>
            </tr>
            {/foreach}
            </tbody>
        </table>
        </div>
    </div>
    <form method="post" action={'update/servers'|ezurl} class="a4-card-foot a4-update-form" aria-label="{'Add Composer server'|i18n( 'extension/ezupdate' )|wash}">
        <div class="a4-field">
            <label for="ezupdate-composer-name">{'Name'|i18n( 'extension/ezupdate' )}</label>
            <input type="text" id="ezupdate-composer-name" name="ServerName" placeholder="my-satis" size="14" required="required" pattern="[A-Za-z0-9][A-Za-z0-9_.\-]*" />
        </div>
        <div class="a4-field">
            <label for="ezupdate-composer-type">{'Type'|i18n( 'extension/ezupdate' )}</label>
            <select id="ezupdate-composer-type" name="ServerType">
                {foreach $composer_types as $type}<option value="{$type}">{$type}</option>{/foreach}
            </select>
        </div>
        <div class="a4-field a4-update-grow">
            <label for="ezupdate-composer-url">{'Address'|i18n( 'extension/ezupdate' )}</label>
            <input type="url" id="ezupdate-composer-url" name="ServerURL" placeholder="https://" size="40" required="required" pattern="https://.*" />
        </div>
        <input class="a4-btn a4-btn-primary" type="submit" name="AddComposerServerButton" value="{'Add Composer server'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
    </form>
</section>

<section class="a4-card a4-update-section" aria-labelledby="ezupdate-package-servers">
    <div class="a4-card-head">
        <div>
            <h2 id="ezupdate-package-servers">{'Exponential package servers'|i18n( 'extension/ezupdate' )}</h2>
            <p>{'Servers of .ezpkg packages (site designs, content classes, demo content), in the index.xml format the setup wizard reads. Added servers are kept in %file.'|i18n( 'extension/ezupdate',, hash( '%file', $override_file ) )}</p>
        </div>
        <div class="a4-card-actions"><span class="a4-badge">{$package_servers|count}</span></div>
    </div>
    <div class="a4-card-body">
        {if $package_servers|count}
        <div class="a4-table-wrap">
        <table class="a4-table">
            <caption class="a4-sr-only">{'Exponential package servers'|i18n( 'extension/ezupdate' )}</caption>
            <thead><tr>
                <th scope="col">{'Name'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col">{'Address'|i18n( 'extension/ezupdate' )}</th>
                <th scope="col"><span class="a4-sr-only">{'Actions'|i18n( 'extension/ezupdate' )}</span></th>
            </tr></thead>
            <tbody>
            {foreach $package_servers as $index => $server}
            <tr>
                <td><a href={concat( 'update/packages/', $server.name )|ezurl}>{$server.name|wash}</a>{if $server.builtin} <span class="a4-badge" title="package.ini">{'built in'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                <td><span class="a4-update-copyable"><code id="ezupdate-package-server-{$index|wash}">{$server.url|wash}</code>
                    <button type="button" class="a4-btn a4-btn-small a4-update-copy" data-ezx-copy-target="ezupdate-package-server-{$index|wash}" data-done="{'Copied'|i18n( 'extension/ezupdate' )|wash}" aria-label="{'Copy'|i18n( 'extension/ezupdate' )|wash}: {$server.url|wash}">{'Copy'|i18n( 'extension/ezupdate' )}</button></span></td>
                <td class="a4-update-actions">
                    <a class="a4-btn a4-btn-small" href={concat( 'update/packages/', $server.name )|ezurl}>{'Packages'|i18n( 'extension/ezupdate' )} &rarr;</a>
                    {if $server.builtin|not}
                    <form method="post" action={'update/servers'|ezurl} data-ezupdate-confirm="{'Remove this package server?'|i18n( 'extension/ezupdate' )|wash}">
                        <input type="hidden" name="ServerName" value="{$server.name|wash}" />
                        <input class="a4-btn a4-btn-small a4-btn-outline-danger" type="submit" name="RemovePackageServerButton" value="{'Remove'|i18n( 'extension/ezupdate' )}" />
                    </form>
                    {/if}
                </td>
            </tr>
            {/foreach}
            </tbody>
        </table>
        </div>
        {else}
        <div class="a4-empty"><strong>{'No package servers'|i18n( 'extension/ezupdate' )}</strong><p>{'Add one below.'|i18n( 'extension/ezupdate' )}</p></div>
        {/if}
    </div>
    <form method="post" action={'update/servers'|ezurl} class="a4-card-foot a4-update-form" aria-label="{'Add package server'|i18n( 'extension/ezupdate' )|wash}">
        <div class="a4-field">
            <label for="ezupdate-package-name">{'Name'|i18n( 'extension/ezupdate' )}</label>
            <input type="text" id="ezupdate-package-name" name="ServerName" placeholder="my-packages" size="14" required="required" pattern="[A-Za-z0-9][A-Za-z0-9_.\-]*" />
        </div>
        <div class="a4-field a4-update-grow">
            <label for="ezupdate-package-url">{'Address'|i18n( 'extension/ezupdate' )}</label>
            <input type="url" id="ezupdate-package-url" name="ServerURL" placeholder="https://" size="50" required="required" pattern="https://.*" />
        </div>
        <input class="a4-btn a4-btn-primary" type="submit" name="AddPackageServerButton" value="{'Add package server'|i18n( 'extension/ezupdate' )}" />
    </form>
</section>
{include uri='design:ezupdate/parts/footer.tpl'}
