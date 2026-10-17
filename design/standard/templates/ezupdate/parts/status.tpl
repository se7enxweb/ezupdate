{* A run's status as a shared badge (.a4-badge), the state in its colour and its text; the job page's script swaps
   it while it follows a run (the same classes, see ezupdate.js). Needs $status. *}
{switch match=$status}
{case match='queued'}<span class="a4-badge a4-update-status">{'Waiting'|i18n( 'extension/ezupdate' )}</span>{/case}
{case match='running'}<span class="a4-badge is-warn a4-update-status is-running">{'Running'|i18n( 'extension/ezupdate' )}</span>{/case}
{case match='finished'}<span class="a4-badge is-ok a4-update-status">{'Finished'|i18n( 'extension/ezupdate' )}</span>{/case}
{case match='stopped'}<span class="a4-badge is-bad a4-update-status">{'Stopped'|i18n( 'extension/ezupdate' )}</span>{/case}
{case}<span class="a4-badge is-bad a4-update-status">{'Failed'|i18n( 'extension/ezupdate' )}</span>{/case}
{/switch}
