{* How Composer fetches packages: dist (release archives) or source (git clones,
   each package with its .git: history, branch and commit can be read and worked
   on), or auto. A shared field (.a4-field) with its help under it, so the
   explanation is read out and not only in a tooltip. Needs $install_method and
   $install_methods; the optional $method_id keeps the ids unique on a page. *}
{def $ezx_method_id = first_set( $method_id, 'ezupdate-method' )}
<div class="a4-field a4-update-method">
    <label for="{$ezx_method_id}">{'Fetch from'|i18n( 'extension/ezupdate' )}</label>
    <select id="{$ezx_method_id}" name="InstallMethod" aria-describedby="{$ezx_method_id}-help">
        {foreach $install_methods as $method}
        <option value="{$method}"{if eq( $method, $install_method )} selected="selected"{/if}>{switch match=$method}{case match='dist'}{'dist (archives)'|i18n( 'extension/ezupdate' )}{/case}{case match='source'}{'source (git, with history)'|i18n( 'extension/ezupdate' )}{/case}{case}{'auto'|i18n( 'extension/ezupdate' )}{/case}{/switch}</option>
        {/foreach}
    </select>
    <span class="a4-sr-only" id="{$ezx_method_id}-help">{'dist: release archives, fast. source: git clones with their history, so the branch and commit of each package can be read and worked on. auto: source for development versions, dist for releases.'|i18n( 'extension/ezupdate' )}</span>
</div>
{undef $ezx_method_id}
