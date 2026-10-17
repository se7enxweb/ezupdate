{* The top of every ezupdate page: the page header, the app's tabs and the messages of the request. Opens the page's
   root, <div class="context-block a4-page ezx">, which parts/footer.tpl closes (.a4-page, the shared reset, only
   for a view that passes its title: the older views keep their own spacing).

   Built from the administration's shared components (design:stylesheets/components.css: .a4-pagehead, .a4-tabs,
   .a4-notice, .a4-btn), so it follows the light and the dark look of admin4 and reads in the classic admin too.
   The module's own rules are .a4-update-* in stylesheets/modules/update.css (design.ini BackendCSSFileList). The
   other views' bodies still use the older .ezx-* rules of ezupdate.css, loaded here for them.

   Parameters: current (dashboard|installed|browse|servers|fund), error, message; optional title and intro: with a
   title the header draws the page's h1 (the view then has none of its own). *}
{ezcss_require( 'ezupdate.css' )}
{ezscript_require( 'ezupdate.js' )}
{* the views pass error and message even when they have none (an empty value): first_set, not a def behind is_set(),
   which warned "already defined" for a passed empty value *}
{def $ezx_error = first_set( $error, false() )
     $ezx_message = first_set( $message, false() )
     $ezx_title = first_set( $title, false() )
     $ezx_intro = first_set( $intro, false() )
     $ezx_tabs = array( hash( 'id', 'dashboard', 'url', 'update/dashboard', 'text', 'Overview'|i18n( 'extension/ezupdate' ) ),
                        hash( 'id', 'installed', 'url', 'update/installed', 'text', 'Installed packages'|i18n( 'extension/ezupdate' ) ),
                        hash( 'id', 'browse', 'url', 'update/browse', 'text', 'Find packages'|i18n( 'extension/ezupdate' ) ),
                        hash( 'id', 'servers', 'url', 'update/servers', 'text', 'Package servers'|i18n( 'extension/ezupdate' ) ),
                        hash( 'id', 'fund', 'url', 'update/fund', 'text', 'Funding'|i18n( 'extension/ezupdate' ) ) )}
<div class="context-block{if $ezx_title} a4-page{/if} ezx a4-update" data-ezupdate-copy="{'Copy'|i18n( 'extension/ezupdate' )|wash}" data-ezupdate-copied="{'Copied'|i18n( 'extension/ezupdate' )|wash}">
<div class="a4-update-head">
    <div class="a4-pagehead">
        <div class="a4-pagehead-main">
            {if $ezx_title}
            <p class="a4-pagehead-pre">{'Updates and packages'|i18n( 'extension/ezupdate' )}</p>
            <h1 class="a4-pagehead-title">{$ezx_title|wash}</h1>
            {if $ezx_intro}<p class="a4-pagehead-sub">{$ezx_intro|wash}</p>{/if}
            {else}
            <p class="a4-pagehead-pre">{'Updates and packages'|i18n( 'extension/ezupdate' )}</p>
            <p class="a4-pagehead-sub">{'Composer, extensions and package servers'|i18n( 'extension/ezupdate' )}</p>
            {/if}
        </div>
    </div>
    <nav aria-label="{'Updates and packages'|i18n( 'extension/ezupdate' )}">
    <ul class="a4-tabs a4-update-tabs">
        {foreach $ezx_tabs as $ezx_tab}
        <li>{if eq( $current, $ezx_tab.id )}<a class="is-current" href={$ezx_tab.url|ezurl} aria-current="page">{$ezx_tab.text|wash}</a>{else}<a href={$ezx_tab.url|ezurl}>{$ezx_tab.text|wash}</a>{/if}</li>
        {/foreach}
    </ul>
    </nav>

    {if $ezx_error}
    <div class="a4-notice is-bad" role="alert">
        <strong class="a4-notice-title">{'The request could not be completed'|i18n( 'extension/ezupdate' )}</strong>
        <pre class="a4-pre a4-update-message">{$ezx_error|wash}</pre>
    </div>
    {/if}

    {if $ezx_message}
    <div class="a4-notice is-ok a4-update-dismissable" role="status" data-ezx-dismiss="1" data-ezx-autoclose="1">
        <strong class="a4-notice-title">{$ezx_message|wash}</strong>
        <button type="button" class="a4-btn a4-btn-ghost a4-btn-icon a4-update-dismiss ezx-dismiss" title="{'Close'|i18n( 'extension/ezupdate' )|wash}" aria-label="{'Close'|i18n( 'extension/ezupdate' )|wash}">&times;</button>
    </div>
    {/if}
</div>
{undef $ezx_error $ezx_message $ezx_title $ezx_intro $ezx_tabs}
