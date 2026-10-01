{switch match=$status}
{case match='queued'}<span class="ezupdate-badge">{'Waiting'|i18n( 'extension/ezupdate' )}</span>{/case}
{case match='running'}<span class="ezupdate-badge ezupdate-warn ezupdate-running">{'Running'|i18n( 'extension/ezupdate' )}</span>{/case}
{case match='finished'}<span class="ezupdate-badge ezupdate-good">{'Finished'|i18n( 'extension/ezupdate' )}</span>{/case}
{case match='stopped'}<span class="ezupdate-badge ezupdate-bad">{'Stopped'|i18n( 'extension/ezupdate' )}</span>{/case}
{case}<span class="ezupdate-badge ezupdate-bad">{'Failed'|i18n( 'extension/ezupdate' )}</span>{/case}
{/switch}
