{include uri='design:ezupdate/parts/header.tpl' current='servers' error=$error message=$message}
<div class="ezx-page">

    <div class="ezx-head">
        <div>
            <h1>{'Package servers'|i18n( 'extension/ezupdate' )}</h1>
            <p>{'Where Composer looks for code packages, and where the setup wizard and the package views find .ezpkg packages.'|i18n( 'extension/ezupdate' )}</p>
        </div>
    </div>

    <section class="ezx-panel">
        <header>
            <div>
                <h2>{'Composer servers'|i18n( 'extension/ezupdate' )}</h2>
                <p>{'Where Composer looks for code packages: the "repositories" of composer.json, changed here with composer config. The command line and Composer read the same list.'|i18n( 'extension/ezupdate' )}</p>
            </div>
            <span class="ezupdate-badge">{sum( $composer_servers|count, 1 )}</span>
        </header>
        {if $composer_json_writable|not}
        <div class="ezx-panel-body"><div class="ezx-alert ezx-alert-warn"><div>{'composer.json cannot be written by the web server, so this list can only be read here.'|i18n( 'extension/ezupdate' )}</div></div></div>
        {/if}
        <div class="ezx-panel-body ezx-panel-flush">
            <table class="ezx-table">
                <thead><tr>
                    <th>{'Name'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Type'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Address'|i18n( 'extension/ezupdate' )}</th>
                    <th><span class="hide">{'Actions'|i18n( 'extension/ezupdate' )}</span></th>
                </tr></thead>
                <tbody>
                <tr>
                    <td class="ezx-title-cell"><strong>packagist.org</strong> {if $packagist_enabled}<span class="ezupdate-badge ezupdate-good">{'On'|i18n( 'extension/ezupdate' )}</span>{else}<span class="ezupdate-badge">{'Off'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                    <td data-label="{'Type'|i18n( 'extension/ezupdate' )}">composer</td>
                    <td data-label="{'Address'|i18n( 'extension/ezupdate' )}"><code>https://repo.packagist.org</code></td>
                    <td class="ezx-actions">
                        <form method="post" action={'update/servers'|ezurl}>
                            {if $packagist_enabled}
                            <input class="button ezx-btn-s" type="submit" name="PackagistOffButton" value="{'Switch off'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                            {else}
                            <input class="button ezx-btn-s" type="submit" name="PackagistOnButton" value="{'Switch on'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                            {/if}
                        </form>
                    </td>
                </tr>
                {foreach $composer_servers as $server}
                <tr>
                    <td class="ezx-title-cell"><strong>{$server.name|wash}</strong></td>
                    <td data-label="{'Type'|i18n( 'extension/ezupdate' )}">{$server.type|wash}</td>
                    <td data-label="{'Address'|i18n( 'extension/ezupdate' )}"><code data-ezx-copy="1">{$server.url|wash}</code></td>
                    <td class="ezx-actions">
                        {if $server.removable}
                        <form method="post" action={'update/servers'|ezurl} data-ezupdate-confirm="{'Remove this server from composer.json?'|i18n( 'extension/ezupdate' )|wash}">
                            <input type="hidden" name="ServerName" value="{$server.name|wash}" />
                            <input class="button ezx-btn-s ezx-btn-danger" type="submit" name="RemoveComposerServerButton" value="{'Remove'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                        </form>
                        {else}
                        <span class="ezupdate-muted">{'unnamed, edit composer.json'|i18n( 'extension/ezupdate' )}</span>
                        {/if}
                    </td>
                </tr>
                {/foreach}
                </tbody>
            </table>
        </div>
        <footer>
            <form method="post" action={'update/servers'|ezurl} class="ezx-form">
                <label class="ezx-field"><span>{'Name'|i18n( 'extension/ezupdate' )}</span>
                    <input type="text" name="ServerName" placeholder="my-satis" size="14" required="required" pattern="[A-Za-z0-9][A-Za-z0-9_.\-]*" /></label>
                <label class="ezx-field"><span>{'Type'|i18n( 'extension/ezupdate' )}</span>
                    <select name="ServerType">
                        {foreach $composer_types as $type}<option value="{$type}">{$type}</option>{/foreach}
                    </select></label>
                <label class="ezx-field ezx-field-grow"><span>{'Address'|i18n( 'extension/ezupdate' )}</span>
                    <input type="url" name="ServerURL" placeholder="https://" size="40" required="required" pattern="https://.*" /></label>
                <input class="defaultbutton" type="submit" name="AddComposerServerButton" value="{'Add Composer server'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
            </form>
        </footer>
    </section>

    <section class="ezx-panel">
        <header>
            <div>
                <h2>{'Exponential package servers'|i18n( 'extension/ezupdate' )}</h2>
                <p>{'Servers of .ezpkg packages (site designs, content classes, demo content), in the index.xml format the setup wizard reads. Added servers are kept in %file.'|i18n( 'extension/ezupdate',, hash( '%file', $override_file ) )}</p>
            </div>
            <span class="ezupdate-badge">{$package_servers|count}</span>
        </header>
        <div class="ezx-panel-body ezx-panel-flush">
            {if $package_servers|count}
            <table class="ezx-table">
                <thead><tr>
                    <th>{'Name'|i18n( 'extension/ezupdate' )}</th>
                    <th>{'Address'|i18n( 'extension/ezupdate' )}</th>
                    <th><span class="hide">{'Actions'|i18n( 'extension/ezupdate' )}</span></th>
                </tr></thead>
                <tbody>
                {foreach $package_servers as $server}
                <tr>
                    <td class="ezx-title-cell"><a href={concat( 'update/packages/', $server.name )|ezurl}>{$server.name|wash}</a>{if $server.builtin} <span class="ezupdate-badge" title="package.ini">{'built in'|i18n( 'extension/ezupdate' )}</span>{/if}</td>
                    <td data-label="{'Address'|i18n( 'extension/ezupdate' )}"><code data-ezx-copy="1">{$server.url|wash}</code></td>
                    <td class="ezx-actions">
                        <a class="button ezx-btn-s" href={concat( 'update/packages/', $server.name )|ezurl}>{'Packages'|i18n( 'extension/ezupdate' )} &rarr;</a>
                        {if $server.builtin|not}
                        <form method="post" action={'update/servers'|ezurl} data-ezupdate-confirm="{'Remove this package server?'|i18n( 'extension/ezupdate' )|wash}">
                            <input type="hidden" name="ServerName" value="{$server.name|wash}" />
                            <input class="button ezx-btn-s ezx-btn-danger" type="submit" name="RemovePackageServerButton" value="{'Remove'|i18n( 'extension/ezupdate' )}" />
                        </form>
                        {/if}
                    </td>
                </tr>
                {/foreach}
                </tbody>
            </table>
            {else}
            <div class="ezx-empty"><strong>{'No package servers'|i18n( 'extension/ezupdate' )}</strong>{'Add one below.'|i18n( 'extension/ezupdate' )}</div>
            {/if}
        </div>
        <footer>
            <form method="post" action={'update/servers'|ezurl} class="ezx-form">
                <label class="ezx-field"><span>{'Name'|i18n( 'extension/ezupdate' )}</span>
                    <input type="text" name="ServerName" placeholder="my-packages" size="14" required="required" pattern="[A-Za-z0-9][A-Za-z0-9_.\-]*" /></label>
                <label class="ezx-field ezx-field-grow"><span>{'Address'|i18n( 'extension/ezupdate' )}</span>
                    <input type="url" name="ServerURL" placeholder="https://" size="50" required="required" pattern="https://.*" /></label>
                <input class="defaultbutton" type="submit" name="AddPackageServerButton" value="{'Add package server'|i18n( 'extension/ezupdate' )}" />
            </form>
        </footer>
    </section>
</div>
{include uri='design:ezupdate/parts/footer.tpl'}
