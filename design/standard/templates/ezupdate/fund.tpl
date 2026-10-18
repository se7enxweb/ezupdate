{* Setup > Updates and packages > Funding (update/fund): the list "composer fund" prints, by vendor, with the
   downloads (JSON, text), the scope (all installed packages or those composer.json requires) and a filter that
   works in the page (ezupdate.js, data-ezx-filter). Built from the shared components (.a4-figures, .a4-card,
   .a4-cards, .a4-tabs, .a4-field, .a4-badge, .a4-fold, .a4-empty); the rest is .a4-update-* in
   stylesheets/modules/update.css. No inline CSS or script. *}
{def $ezx_scope = cond( $direct, '/(direct)/1', '' )}
{include uri='design:ezupdate/parts/header.tpl' current='fund'
         title='Funding'|i18n( 'extension/ezupdate' )
         intro='The people and organisations behind the installed packages, and how to support them. This is the list "composer fund" prints, read from the installed packages\' metadata and their .github/FUNDING.yml, without running Composer.'|i18n( 'extension/ezupdate' )
         actions=array( hash( 'url', concat( 'update/fund/json', $ezx_scope ), 'text', 'JSON ↓', 'external', false(), 'download', false() ),
                        hash( 'url', concat( 'update/fund/text', $ezx_scope ), 'text', concat( 'Text'|i18n( 'extension/ezupdate' ), ' ↓' ), 'external', false(), 'download', false() ) )}
{undef $ezx_scope}

<section class="a4-update-section" aria-labelledby="ezupdate-fund-summary">
    <h2 class="a4-sr-only" id="ezupdate-fund-summary">{'Summary'|i18n( 'extension/ezupdate' )}</h2>
    <ul class="a4-figures">
        <li class="a4-figure"><strong>{$summary.funded}</strong><span>{'of %count packages ask for funding'|i18n( 'extension/ezupdate',, hash( '%count', $summary.packages ) )}</span></li>
        <li class="a4-figure"><strong>{$summary.vendors}</strong><span>{'vendors'|i18n( 'extension/ezupdate' )}</span></li>
        <li class="a4-figure"><strong>{$summary.links}</strong><span>{'funding links'|i18n( 'extension/ezupdate' )}</span></li>
    </ul>
</section>

<section class="a4-card a4-update-section" aria-labelledby="ezupdate-fund-title">
    <div class="a4-card-head">
        <h2 id="ezupdate-fund-title">{'Funding links'|i18n( 'extension/ezupdate' )}</h2>
    </div>
    <div class="a4-card-body">
        <div class="a4-update-bar">
            <nav aria-label="{'Packages'|i18n( 'extension/ezupdate' )}">
            <ul class="a4-tabs a4-update-scope">
                {if $direct}
                <li><a href={'update/fund'|ezurl}>{'All installed packages'|i18n( 'extension/ezupdate' )}</a></li>
                <li><a class="is-current" href={'update/fund/(direct)/1'|ezurl} aria-current="page">{'Required by composer.json'|i18n( 'extension/ezupdate' )}</a></li>
                {else}
                <li><a class="is-current" href={'update/fund'|ezurl} aria-current="page">{'All installed packages'|i18n( 'extension/ezupdate' )}</a></li>
                <li><a href={'update/fund/(direct)/1'|ezurl}>{'Required by composer.json'|i18n( 'extension/ezupdate' )}</a></li>
                {/if}
            </ul>
            </nav>
            {if $vendors|count}
            <div class="a4-field a4-update-filter">
                <label for="ezupdate-fund-filter">{'Filter'|i18n( 'extension/ezupdate' )}</label>
                <input type="search" id="ezupdate-fund-filter" placeholder="{'Vendor, package or link'|i18n( 'extension/ezupdate' )|wash}" data-ezx-filter="#ezupdate-fund-vendors" data-ezx-search="1" />
            </div>
            {/if}
        </div>

        {if $vendors|count}
        <ul class="a4-cards a4-update-vendors" id="ezupdate-fund-vendors">
            {foreach $vendors as $vendor}
            <li class="a4-card" data-ezx-text="{concat( $vendor.vendor, ' ' )|downcase|wash}{foreach $vendor.links as $link} {$link.url|downcase|wash}{foreach $link.packages as $name} {$name|downcase|wash}{/foreach}{/foreach}">
                <div class="a4-card-head"><h3 class="a4-card-title">{$vendor.vendor|wash}</h3></div>
                <ul class="a4-card-body a4-update-links">
                {foreach $vendor.links as $link}
                    <li>
                        <a class="a4-update-fund-link" href="{$link.url|wash}" target="_blank" rel="noopener noreferrer nofollow">
                            <span class="a4-badge{if eq( $link.type, 'custom' )} is-ok{elseif ne( $link.type, 'github' )} is-info{/if}">{$link.label|wash}</span>
                            <span class="a4-update-url">{$link.url|wash}</span>
                        </a>
                        <details class="a4-update-supports">
                            <summary>{if eq( $link.packages|count, 1 )}{'Supports 1 package'|i18n( 'extension/ezupdate' )}{else}{'Supports %count packages'|i18n( 'extension/ezupdate',, hash( '%count', $link.packages|count ) )}{/if}
                                <span class="a4-meta">&middot; {'from %source'|i18n( 'extension/ezupdate',, hash( '%source', $link.from ) )|wash}</span></summary>
                            <p>{foreach $link.packages as $name}<a href={concat( 'update/package/', $name )|ezurl}>{$name|wash}</a>{delimiter}, {/delimiter}{/foreach}</p>
                        </details>
                    </li>
                {/foreach}
                </ul>
            </li>
            {/foreach}
        </ul>
        <p class="a4-empty" data-ezx-none="#ezupdate-fund-vendors" hidden="hidden">{'No vendor matches the filter.'|i18n( 'extension/ezupdate' )}</p>
        {else}
        <div class="a4-empty"><strong>{'None of these packages asks for funding.'|i18n( 'extension/ezupdate' )}</strong></div>
        {/if}

        {if $unfunded|count}
        <details class="a4-fold a4-update-section-top">
            <summary>{'%count packages declare no funding'|i18n( 'extension/ezupdate',, hash( '%count', $unfunded|count ) )}</summary>
            <div class="a4-fold-body"><p>{foreach $unfunded as $package}<a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>{delimiter}, {/delimiter}{/foreach}</p></div>
        </details>
        {/if}
    </div>
    <div class="a4-card-foot">
        <span class="a4-meta">{'On the command line: php extension/ezupdate/bin/php/ezupdate.php fund [--direct] [--json]'|i18n( 'extension/ezupdate' )}</span>
    </div>
</section>
{include uri='design:ezupdate/parts/footer.tpl'}
