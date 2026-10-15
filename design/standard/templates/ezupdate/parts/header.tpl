{* The top of every ezupdate page: the app's title, its tabs and the messages of the request. Opens <div class="ezx">,
   the page's root (tokens and the container the layout follows); parts/footer.tpl closes it.
   Parameters: current (dashboard|installed|browse|servers|fund), error, message. *}
{ezcss_require( 'ezupdate.css' )}
{ezscript_require( 'ezupdate.js' )}
{* the views pass error and message even when they have none (an empty value): first_set, not a def behind is_set(),
   which warned "already defined" for a passed empty value *}
{def $ezx_error = first_set( $error, false() )
     $ezx_message = first_set( $message, false() )}
<div class="ezx">
<div class="ezx-app">
    <div class="ezx-app-title">
        <span class="ezx-logo" aria-hidden="true">&#8593;</span>
        <strong>{'Updates and packages'|i18n( 'extension/ezupdate' )}</strong>
        <span>{'Composer, extensions and package servers'|i18n( 'extension/ezupdate' )}</span>
    </div>
    <nav aria-label="{'Updates and packages'|i18n( 'extension/ezupdate' )}">
    <ul class="ezupdate-tabs">
        <li{if eq( $current, 'dashboard' )} class="selected"{/if}><a href={'update/dashboard'|ezurl}{if eq( $current, 'dashboard' )} aria-current="page"{/if}>{'Overview'|i18n( 'extension/ezupdate' )}</a></li>
        <li{if eq( $current, 'installed' )} class="selected"{/if}><a href={'update/installed'|ezurl}{if eq( $current, 'installed' )} aria-current="page"{/if}>{'Installed packages'|i18n( 'extension/ezupdate' )}</a></li>
        <li{if eq( $current, 'browse' )} class="selected"{/if}><a href={'update/browse'|ezurl}{if eq( $current, 'browse' )} aria-current="page"{/if}>{'Find packages'|i18n( 'extension/ezupdate' )}</a></li>
        <li{if eq( $current, 'servers' )} class="selected"{/if}><a href={'update/servers'|ezurl}{if eq( $current, 'servers' )} aria-current="page"{/if}>{'Package servers'|i18n( 'extension/ezupdate' )}</a></li>
        <li{if eq( $current, 'fund' )} class="selected"{/if}><a href={'update/fund'|ezurl}{if eq( $current, 'fund' )} aria-current="page"{/if}>{'Funding'|i18n( 'extension/ezupdate' )}</a></li>
    </ul>
    </nav>

    {if $ezx_error}
    <div class="ezx-alert ezx-alert-bad" role="alert">
        <div>
            <h2>{'The request could not be completed'|i18n( 'extension/ezupdate' )}</h2>
            <pre class="ezupdate-message">{$ezx_error|wash}</pre>
        </div>
    </div>
    {/if}

    {if $ezx_message}
    <div class="ezx-alert ezx-alert-ok" role="status" data-ezx-dismiss="1">
        <div><h2>{$ezx_message|wash}</h2></div>
        <button type="button" class="ezx-dismiss" title="{'Close'|i18n( 'extension/ezupdate' )}" aria-label="{'Close'|i18n( 'extension/ezupdate' )}">&times;</button>
    </div>
    {/if}
</div>
{undef $ezx_error $ezx_message}
