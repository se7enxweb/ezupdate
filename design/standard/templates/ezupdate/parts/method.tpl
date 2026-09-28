{* How Composer fetches packages: dist (release archives) or source (git clones,
   each package with its .git: history, branch and commit can be read and worked
   on), or auto. Needs $install_method and $install_methods. *}
<label class="ezupdate-method" title="{'dist: release archives, fast. source: git clones with their history, so the branch and commit of each package can be read and worked on. auto: source for development versions, dist for releases.'|i18n( 'extension/ezupdate' )|wash}">
    {'Fetch from'|i18n( 'extension/ezupdate' )}
    <select name="InstallMethod">
        {foreach $install_methods as $method}
        <option value="{$method}"{if eq( $method, $install_method )} selected="selected"{/if}>{switch match=$method}{case match='dist'}{'dist (archives)'|i18n( 'extension/ezupdate' )}{/case}{case match='source'}{'source (git, with history)'|i18n( 'extension/ezupdate' )}{/case}{case}{'auto'|i18n( 'extension/ezupdate' )}{/case}{/switch}</option>
        {/foreach}
    </select>
</label>
