{include uri='design:ezupdate/parts/header.tpl' current='fund'}

<div class="context-block ezupdate ezupdate-fund">
    <div class="box-header">
        <h1 class="context-title">{'Funding'|i18n( 'extension/ezupdate' )}</h1>
        <div class="header-mainline"></div>
    </div>
    <div class="box-content">
        <p class="ezupdate-lead">{'The people and organisations behind the installed packages, and how to support them. This is the list "composer fund" prints, read from the installed packages\' metadata and their .github/FUNDING.yml, without running Composer.'|i18n( 'extension/ezupdate' )}</p>

        <ul class="ezupdate-fund-summary">
            <li><strong>{$summary.funded}</strong> {'of %count packages ask for funding'|i18n( 'extension/ezupdate',, hash( '%count', $summary.packages ) )}</li>
            <li><strong>{$summary.vendors}</strong> {'vendors'|i18n( 'extension/ezupdate' )}</li>
            <li><strong>{$summary.links}</strong> {'funding links'|i18n( 'extension/ezupdate' )}</li>
        </ul>

        <div class="ezupdate-fund-bar">
            <span class="ezupdate-fund-scope">
                {if $direct}
                    <a href={'update/fund'|ezurl}>{'All installed packages'|i18n( 'extension/ezupdate' )}</a>
                    <strong>{'Required by composer.json'|i18n( 'extension/ezupdate' )}</strong>
                {else}
                    <strong>{'All installed packages'|i18n( 'extension/ezupdate' )}</strong>
                    <a href={'update/fund/(direct)/1'|ezurl}>{'Required by composer.json'|i18n( 'extension/ezupdate' )}</a>
                {/if}
            </span>
            <span class="ezupdate-fund-downloads">
                {'Download'|i18n( 'extension/ezupdate' )}:
                <a href={concat( 'update/fund/json', cond( $direct, '/(direct)/1', '' ) )|ezurl}>JSON</a>
                <a href={concat( 'update/fund/text', cond( $direct, '/(direct)/1', '' ) )|ezurl}>{'Text'|i18n( 'extension/ezupdate' )}</a>
            </span>
            <label class="ezupdate-fund-filter">{'Filter'|i18n( 'extension/ezupdate' )}
                <input type="search" id="ezupdate-fund-filter" placeholder="{'Vendor, package or link'|i18n( 'extension/ezupdate' )|wash}" /></label>
        </div>

        {if $vendors|count}
        <div class="ezupdate-fund-vendors" id="ezupdate-fund-vendors">
        {foreach $vendors as $vendor}
            <section class="ezupdate-fund-vendor" data-search="{$vendor.vendor|wash}{foreach $vendor.links as $link} {$link.url|wash}{foreach $link.packages as $name} {$name|wash}{/foreach}{/foreach}">
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
        <p class="ezupdate-muted" id="ezupdate-fund-none" hidden="hidden">{'No vendor matches the filter.'|i18n( 'extension/ezupdate' )}</p>
        {else}
        <p>{'None of these packages asks for funding.'|i18n( 'extension/ezupdate' )}</p>
        {/if}

        {if $unfunded|count}
        <details class="ezupdate-fund-unfunded">
            <summary>{'%count packages declare no funding'|i18n( 'extension/ezupdate',, hash( '%count', $unfunded|count ) )}</summary>
            <p>{foreach $unfunded as $package}<a href={concat( 'update/package/', $package.name )|ezurl}>{$package.name|wash}</a>{delimiter}, {/delimiter}{/foreach}</p>
        </details>
        {/if}

        <p class="ezupdate-muted">{'On the command line: php extension/ezupdate/bin/php/ezupdate.php fund [--direct] [--json]'|i18n( 'extension/ezupdate' )}</p>
    </div>
</div>

{literal}
<script type="text/javascript">
(function () {
    var input = document.getElementById('ezupdate-fund-filter');
    var list = document.getElementById('ezupdate-fund-vendors');
    var none = document.getElementById('ezupdate-fund-none');
    if (!input || !list) { return; }
    input.addEventListener('input', function () {
        var q = this.value.replace(/^\s+|\s+$/g, '').toLowerCase(), shown = 0;
        Array.prototype.forEach.call(list.querySelectorAll('.ezupdate-fund-vendor'), function (section) {
            var match = q === '' || section.getAttribute('data-search').toLowerCase().indexOf(q) !== -1;
            section.hidden = !match;
            if (match) { shown++; }
        });
        if (none) { none.hidden = shown !== 0; }
    });
})();
</script>
{/literal}
