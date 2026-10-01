{* The package page's install form: version, how to fetch, dry run, and the real run behind the backup box. *}
<form method="post" action={concat( 'update/package/', $name )|ezurl} class="ezupdate-bar">
    <label class="ezx-field"><span>{'Version'|i18n( 'extension/ezupdate' )}</span>
        <input type="text" name="Constraint" value="{$constraint|wash}" size="14" list="ezupdate-versions" placeholder="{if $package}^{$package.latest|explode( 'v' )|implode( '' )|wash}{/if}" />
    </label>
    {if $package}
    <datalist id="ezupdate-versions">
        {foreach $package.versions as $version max 30}<option value="{$version.version|wash}"></option>{/foreach}
    </datalist>
    {/if}
    {include uri='design:ezupdate/parts/method.tpl'}
    <input class="button" type="submit" name="DryRunInstallButton" value="{'Install, dry run'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
    {if and( $can_manage, $install_allowed )}
    <span class="ezupdate-confirm">
        <label><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="InstallButton" /> {'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</label>
        <input class="defaultbutton" type="submit" name="InstallButton" value="{if $installed_version}{'Change version'|i18n( 'extension/ezupdate' )}{else}{'Install'|i18n( 'extension/ezupdate' )}{/if}" disabled="disabled" />
    </span>
    {else}
    <span class="ezupdate-muted">{'Installing is switched off ([UpdateSettings] AllowInstall in ezupdate.ini).'|i18n( 'extension/ezupdate' )}</span>
    {/if}
</form>
