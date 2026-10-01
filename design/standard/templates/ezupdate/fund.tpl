{include uri='design:ezupdate/parts/header.tpl' current='fund'}
<div class="ezx-page ezupdate-fund">

    <div class="ezx-head">
        <div>
            <h1>{'Funding'|i18n( 'extension/ezupdate' )}</h1>
            <p>{'The people and organisations behind the installed packages, and how to support them. This is the list "composer fund" prints, read from the installed packages\' metadata and their .github/FUNDING.yml, without running Composer.'|i18n( 'extension/ezupdate' )}</p>
        </div>
        <div class="ezx-head-actions ezupdate-fund-downloads">
            <a class="button ezx-btn-s" href={concat( 'update/fund/json', cond( $direct, '/(direct)/1', '' ) )|ezurl}>JSON &darr;</a>
            <a class="button ezx-btn-s" href={concat( 'update/fund/text', cond( $direct, '/(direct)/1', '' ) )|ezurl}>{'Text'|i18n( 'extension/ezupdate' )} &darr;</a>
        </div>
    </div>

    <div class="ezx-stats">
        <div class="ezx-stat"><strong>{$summary.funded}</strong><span>{'of %count packages ask for funding'|i18n( 'extension/ezupdate',, hash( '%count', $summary.packages ) )}</span></div>
        <div class="ezx-stat"><strong>{$summary.vendors}</strong><span>{'vendors'|i18n( 'extension/ezupdate' )}</span></div>
        <div class="ezx-stat"><strong>{$summary.links}</strong><span>{'funding links'|i18n( 'extension/ezupdate' )}</span></div>
    </div>

    <section class="ezx-panel">
        <header class="ezupdate-fund-bar">
            <span class="ezupdate-fund-scope">
                {if $direct}
                    <a href={'update/fund'|ezurl}>{'All installed packages'|i18n( 'extension/ezupdate' )}</a>
                    <strong>{'Required by composer.json'|i18n( 'extension/ezupdate' )}</strong>
                {else}
                    <strong>{'All installed packages'|i18n( 'extension/ezupdate' )}</strong>
                    <a href={'update/fund/(direct)/1'|ezurl}>{'Required by composer.json'|i18n( 'extension/ezupdate' )}</a>
                {/if}
            </span>
            <label class="ezupdate-fund-filter"><span class="hide">{'Filter'|i18n( 'extension/ezupdate' )}</span>
                <input type="search" id="ezupdate-fund-filter" placeholder="{'Vendor, package or link'|i18n( 'extension/ezupdate' )|wash}" data-ezx-filter="#ezupdate-fund-vendors" data-ezx-search="1" /></label>
        </header>
        <div class="ezx-panel-body">
        {if $vendors|count}
            <div class="ezupdate-fund-vendors" id="ezupdate-fund-vendors">
            {foreach $vendors as $vendor}
                <section class="ezupdate-fund-vendor" data-ezx-text="{concat( $vendor.vendor, ' ' )|downcase|wash}{foreach $vendor.links as $link} {$link.url|downcase|wash}{foreach $link.packages as $name} {$name|downcase|wash}{/foreach}{/foreach}">
                    <h2>{$vendor.vendor|wash}</h2>
                    <ul class="ezupdate-fund-links">
                    {foreach $vendor.links as $link}
                        <li>
                            <a class="ezupdate-fund-link" href="{$link.url|wash}" target="_blank" rel="noopener noreferrer nofollow">
                                <span class="ezupdate-badge ezupdate-fund-type ezupdate-fund-type-{$link.type|wash}">{$link.label|wash}</span>
                                <span class="ezupdate-fund-url">{$link.url|wash}</span>
                            </a>
                            <details class="ezupdate-fund-packages">
                                <summary>{if eq( $link.packages|count, 1 )}{'Supports 1 package'|i18n( 'extension/ezupdate' )}{else}{'Supports %count packages'|i18n( 'extension/ezupdate',, hash( '%count', $link.packages|count ) )}{/if}
                                    <span class="ezupdate-muted">&middot; {'from %source'|i18n( 'extension/ezupdate',, hash( '%source', $link.from ) )|wash}</span></summary>
                                <p>{foreach $link.packages as $name}<a href={concat( 'update/package/', $name )|ezurl}>{$name|wash}</a>{delimiter}, {/delimiter}{/foreach}</p>
                            </details>
                        </li>
                    {/foreach}
                    </ul>
                </section>
            {/foreach}
            </div>
            <div class="ezx-empty" data-ezx-none="#ezupdate-fund-vendors" hidden="hidden">{'No vendor matches the filter.'|i18n( 'extension/ezupdate' )}</div>
        {else}
            <div class="ezx-empty"><strong>{'None of these packages asks for funding.'|i18n( 'extension/ezupdate' )}</strong></div>
        {/if}

        {if $unfunded|count}
            <details class="ezupdate-fund-unfunded">
                <summary>{'%count packages declare no funding'|i18n( 'extension/ezupdate',, hash( '%count', $unfunded|count ) )}</summary>
                <p>{foreach $unfunded as $package}<a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>{delimiter}, {/delimiter}{/foreach}</p>
            </details>
        {/if}
        </div>
        <footer><span class="ezupdate-muted">{'On the command line: php extension/ezupdate/bin/php/ezupdate.php fund [--direct] [--json]'|i18n( 'extension/ezupdate' )}</span></footer>
    </section>
</div>
{include uri='design:ezupdate/parts/footer.tpl'}
