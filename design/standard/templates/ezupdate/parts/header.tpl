{* The tabs every ezupdate page starts with, and the messages of the request.
   Parameters: current (dashboard|browse|servers), error, message. *}
{ezcss_require( 'ezupdate.css' )}
{ezscript_require( 'ezupdate.js' )}
{if is_set( $error )|not}{def $error = false()}{/if}
{if is_set( $message )|not}{def $message = false()}{/if}

<ul class="ezupdate-tabs">
    <li{if eq( $current, 'dashboard' )} class="selected"{/if}><a href={'update/dashboard'|ezurl}>{'Installed packages'|i18n( 'extension/ezupdate' )}</a></li>
    <li{if eq( $current, 'browse' )} class="selected"{/if}><a href={'update/browse'|ezurl}>{'Find packages'|i18n( 'extension/ezupdate' )}</a></li>
    <li{if eq( $current, 'servers' )} class="selected"{/if}><a href={'update/servers'|ezurl}>{'Package servers'|i18n( 'extension/ezupdate' )}</a></li>
</ul>

{if $error}
<div class="message-error">
    <h2>{'The request could not be completed'|i18n( 'extension/ezupdate' )}</h2>
    <pre class="ezupdate-message">{$error|wash}</pre>
</div>
{/if}

{if $message}
<div class="message-feedback">
    <h2>{$message|wash}</h2>
</div>
{/if}
