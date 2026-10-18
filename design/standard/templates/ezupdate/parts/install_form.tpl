{* The package page's install form: version, how to fetch, dry run, and the real run behind the backup box. Drawn in
   the foot of a card (.a4-card-foot) from the shared fields and buttons; the field and button names are kept. *}
<form method="post" action={concat( 'update/package/', $name )|ezurl} class="a4-update-bar a4-update-installform">
    <div class="a4-field">
        <label for="ezupdate-install-version">{'Version'|i18n( 'extension/ezupdate' )}</label>
        <input type="text" id="ezupdate-install-version" name="Constraint" value="{$constraint|wash}" size="14" list="ezupdate-versions" placeholder="{if $package}^{$package.latest|explode( 'v' )|implode( '' )|wash}{/if}" />
    </div>
    {if $package}
    <datalist id="ezupdate-versions">
        {foreach $package.versions as $version max 30}<option value="{$version.version|wash}"></option>{/foreach}
    </datalist>
    {/if}
    {include uri='design:ezupdate/parts/method.tpl'}
    <input class="a4-btn" type="submit" name="DryRunInstallButton" value="{'Install, dry run'|i18n( 'extension/ezupdate' )}"{if $job_running} disabled="disabled"{/if} />
    {if and( $can_manage, $install_allowed )}
    <span class="a4-update-confirm">
        <label class="a4-check"><input type="checkbox" name="ConfirmBackup" value="1" data-ezupdate-enables="InstallButton" /> <span>{'A backup of files and database exists'|i18n( 'extension/ezupdate' )}</span></label>
        <input class="a4-btn a4-btn-primary" type="submit" name="InstallButton" value="{if $installed_version}{'Change version'|i18n( 'extension/ezupdate' )}{else}{'Install'|i18n( 'extension/ezupdate' )}{/if}" disabled="disabled" />
    </span>
    {else}
    <span class="a4-meta">{'Installing is switched off ([UpdateSettings] AllowInstall in ezupdate.ini).'|i18n( 'extension/ezupdate' )}</span>
    {/if}
</form>
