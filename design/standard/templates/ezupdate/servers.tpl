{include uri='design:ezupdate/parts/header.tpl' current='servers' error=$error message=$message}

<div class="context-block ezupdate">
    <div class="box-header">
        <h1 class="context-title">{'Composer servers'|i18n( 'extension/ezupdate' )}</h1>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <p class="ezupdate-muted">{'Where Composer looks for code packages: the "repositories" of composer.json, changed here with composer config. The command line and Composer read the same list.'|i18n( 'extension/ezupdate' )}</p>
        {if $composer_json_writable|not}
        <div class="message-warning"><h2>{'composer.json cannot be written by the web server, so this list can only be read here.'|i18n( 'extension/ezupdate' )}</h2></div>
        {/if}
        <table class="list" cellspacing="0">
            <tr>
                <th>{'Name'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Type'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Address'|i18n( 'extension/ezupdate' )}</th>
                <th></th>
            </tr>
            <tr class="bglight">
                <td>packagist.org</td>
                <td>composer</td>
                <td>https://repo.packagist.org</td>
                <td class="ezupdate-actions">
                    <form method="post" action={'update/servers'|ezurl}>
                        {if $packagist_enabled}
                        <span class="ezupdate-badge ezupdate-good">{'On'|i18n( 'extension/ezupdate' )}</span>
                        <input class="button" type="submit" name="PackagistOffButton" value="{'Switch off'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                        {else}
                        <span class="ezupdate-badge">{'Off'|i18n( 'extension/ezupdate' )}</span>
                        <input class="button" type="submit" name="PackagistOnButton" value="{'Switch on'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                        {/if}
                    </form>
                </td>
            </tr>
            {foreach $composer_servers as $server sequence array( 'bgdark', 'bglight' ) as $style}
            <tr class="{$style}">
                <td>{$server.name|wash}</td>
                <td>{$server.type|wash}</td>
                <td><code>{$server.url|wash}</code></td>
                <td class="ezupdate-actions">
                    {if $server.removable}
                    <form method="post" action={'update/servers'|ezurl} data-ezupdate-confirm="{'Remove this server from composer.json?'|i18n( 'extension/ezupdate' )|wash}">
                        <input type="hidden" name="ServerName" value="{$server.name|wash}" />
                        <input class="button" type="submit" name="RemoveComposerServerButton" value="{'Remove'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
                    </form>
                    {else}
                    <span class="ezupdate-muted">{'unnamed, edit composer.json'|i18n( 'extension/ezupdate' )}</span>
                    {/if}
                </td>
            </tr>
            {/foreach}
        </table>
    </div>
    <div class="controlbar">
        <form method="post" action={'update/servers'|ezurl} class="ezupdate-bar">
            <input type="text" name="ServerName" placeholder="{'Name'|i18n( 'extension/ezupdate' )}" size="14" required="required" pattern="[A-Za-z0-9][A-Za-z0-9_.\-]*" />
            <select name="ServerType">
                {foreach $composer_types as $type}<option value="{$type}">{$type}</option>{/foreach}
            </select>
            <input type="url" name="ServerURL" placeholder="https://" size="40" required="required" pattern="https://.*" />
            <input class="button" type="submit" name="AddComposerServerButton" value="{'Add Composer server'|i18n( 'extension/ezupdate' )}"{if $composer_json_writable|not} disabled="disabled"{/if} />
        </form>
    </div>
</div>

<div class="context-block ezupdate">
    <div class="box-header">
        <h2 class="context-title">{'Exponential package servers'|i18n( 'extension/ezupdate' )}</h2>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <p class="ezupdate-muted">{'Servers of .ezpkg packages (site designs, content classes, demo content), in the index.xml format the setup wizard reads. Added servers are kept in %file.'|i18n( 'extension/ezupdate',, hash( '%file', $override_file ) )}</p>
        <table class="list" cellspacing="0">
            <tr>
                <th>{'Name'|i18n( 'extension/ezupdate' )}</th>
                <th>{'Address'|i18n( 'extension/ezupdate' )}</th>
                <th></th>
            </tr>
            {foreach $package_servers as $server sequence array( 'bglight', 'bgdark' ) as $style}
            <tr class="{$style}">
                <td><a href={concat( 'update/packages/', $server.name )|ezurl}>{$server.name|wash}</a></td>
                <td><code>{$server.url|wash}</code></td>
                <td class="ezupdate-actions">
                    <a class="button" href={concat( 'update/packages/', $server.name )|ezurl}>{'Packages'|i18n( 'extension/ezupdate' )}</a>
                    {if $server.builtin}
                    <span class="ezupdate-muted">package.ini</span>
                    {else}
                    <form method="post" action={'update/servers'|ezurl} data-ezupdate-confirm="{'Remove this package server?'|i18n( 'extension/ezupdate' )|wash}">
                        <input type="hidden" name="ServerName" value="{$server.name|wash}" />
                        <input class="button" type="submit" name="RemovePackageServerButton" value="{'Remove'|i18n( 'extension/ezupdate' )}" />
                    </form>
                    {/if}
                </td>
            </tr>
            {/foreach}
        </table>
    </div>
    <div class="controlbar">
        <form method="post" action={'update/servers'|ezurl} class="ezupdate-bar">
            <input type="text" name="ServerName" placeholder="{'Name'|i18n( 'extension/ezupdate' )}" size="14" required="required" pattern="[A-Za-z0-9][A-Za-z0-9_.\-]*" />
            <input type="url" name="ServerURL" placeholder="https://" size="50" required="required" pattern="https://.*" />
            <input class="button" type="submit" name="AddPackageServerButton" value="{'Add package server'|i18n( 'extension/ezupdate' )}" />
        </form>
    </div>
</div>
