Architecture
============

eZ Update is an ordinary Exponential extension: one module (`update`), a few
classes, templates in `design/standard`, one stylesheet, one script and a
command line tool. No database tables, no daemon.

```
extension/ezupdate/
├── bin/php/ezupdate.php          the command line, and the background run worker (run-job)
├── classes/
│   ├── ezupdatemanager.php       finding Composer and PHP, running Composer, installed.json, git info
│   ├── ezupdateinventory.php     the Installed packages inventory (files only)
│   ├── ezupdatejob.php           background runs: start, detach, follow, rerun, prune
│   ├── ezupdatepackagist.php     the packagist.org API (search, package), cached
│   ├── ezupdatecomposerservers.php  composer.json repositories, via composer config
│   ├── ezupdatepackageservers.php   .ezpkg servers, index.xml, fetching into the package repository
│   └── ezupdatefunding.php       composer fund, from metadata and .github/FUNDING.yml
├── modules/update/
│   ├── module.php                views, post actions, the two policy functions
│   ├── classes.php               loads the classes when the autoload array does not know them yet
│   └── dashboard.php installed.php browse.php package.php servers.php packages.php job.php fund.php
├── design/standard/
│   ├── templates/ezupdate/       one template per view, parts/ (header, footer, status, method, install form)
│   ├── stylesheets/ezupdate.css  the design system (all under .ezx)
│   └── javascript/ezupdate.js    plain JavaScript, no library
├── settings/                     ezupdate.ini, menu (Setup), module, design, site
└── translations/                 eng-US, ger-DE, untranslated
```

The classes
-----------

**eZUpdateManager** (singleton) is the only place Composer is started. It finds
the binary (`[ComposerSettings]`), the PHP that runs a `.phar` and the workers,
builds argument lists for each kind of run (`updateArguments()`,
`requireArguments()`), and runs them with `proc_open` in the installation root:
no shell, an environment with `COMPOSER_HOME` per system account, a time limit,
and the output captured. It also reads `vendor/composer/installed.json`
(`installedPackages()`, `installedPackageInfo()`), reads a working copy with
read-only git calls (`gitInfo()`), and turns ANSI colours into HTML after
escaping (`ansiToHtml()`).

**eZUpdateInventory** builds the Installed packages view from four sources,
without running anything: `composer.json`, `composer.lock`, `installed.json`,
the extension directories and the settings (`ActiveExtensions`, each
siteaccess's `ActiveAccessExtensions` through `eZSiteAccess::getIni()`). A
working copy's branch and commit are read straight from `.git` (`gitHead()`).
`build()` returns the rows, a summary and the sources' state; `issues()` and
`filters()` decide what each row says and which filters it answers to.

**eZUpdateJob** runs Composer in the background. `start()` writes the run's
JSON (`var/ezupdate/jobs/<id>.json`) and starts
`php extension/ezupdate/bin/php/ezupdate.php run-job <id>` detached, so the web
request ends at once; only one run at a time (`isRunning()`). The worker moves
its streams off the closed pipe, runs Composer with the output going to
`<id>.log`, records the exit code, then runs `[JobSettings] AfterRunCommands`.
`progress()` is what the run page polls (`update/job/<id>/json`); `rerunPlan()`
repeats a run, or turns a dry run into the real one.

**eZUpdatePackagist** asks packagist.org's API (`search.json`,
`/packages/<name>.json`), caches answers for `[PackagistSettings] CacheTime`.
**eZUpdateComposerServers** reads and changes `composer.json`'s `repositories`
with `composer config`, so Composer's own rules apply. **eZUpdatePackageServers**
lists `.ezpkg` servers (the wizard's own from `package.ini`, added ones from
`ezupdate.ini`), reads their `index.xml`, and fetches a package into the local
repository with `eZPackage::import()`. **eZUpdateFunding** collects funding
links from `installed.json` and each package's `.github/FUNDING.yml`.

Views
-----

| View | Script | Template | Needs |
|---|---|---|---|
| `update/dashboard` | dashboard.php | dashboard.tpl | ezupdate (changes: manage) |
| `update/installed[/json\|/csv]` | installed.php | installed.tpl | ezupdate |
| `update/browse` | browse.php | browse.tpl | ezupdate |
| `update/package/<vendor>/<name>` | package.php | package.tpl | ezupdate (install: manage) |
| `update/servers` | servers.php | servers.tpl | manage |
| `update/packages/<server>` | packages.php | packages.tpl | ezupdate (fetch: manage) |
| `update/job/<id>[/json]` | job.php | job.tpl | ezupdate |
| `update/fund[/json\|/text]` | fund.php | fund.tpl | ezupdate |

The view scripts declare no functions or classes, so they can run many times in
one PHP process (persistent-worker servers).

The front end
-------------

Every page starts with `parts/header.tpl` (title, tabs, messages; it opens the
page root `<div class="ezx">`) and ends with `parts/footer.tpl`. The stylesheet
is a small design system, every rule under `.ezx`, so the rest of the admin is
untouched:

| Component | Classes |
|---|---|
| tokens | CSS custom properties on `.ezx` (`--x-ink`, `--x-accent`, `--x-line`, …) |
| page | `.ezx-page`, `.ezx-head`, `.ezx-head-actions` |
| panel | `.ezx-panel` with `header`, `.ezx-panel-body` (`.ezx-panel-flush`), `footer` |
| cards | `.ezx-stats`, `.ezx-stat` (`is-ok`, `is-warn`, `is-bad`) |
| facts | `.ezx-facts` (a `dl`) |
| table | `.ezx-table`, `.ezx-title-cell`, `.ezx-num`, `.ezx-actions`; cells with `data-label` |
| forms | `.ezx-form`, `.ezx-field`, `.ezx-field-grow`, `.ezupdate-bar`, `.ezupdate-confirm` |
| badges | `.ezupdate-badge` (`ezupdate-good`, `-warn`, `-bad`, `-running`) |
| alerts | `.ezx-alert` (`-ok`, `-warn`, `-bad`, `-info`), `data-ezx-dismiss` |
| terminal | `.ezx-term`, `.ezx-term-bar`, `.ezupdate-terminal` |

The layout follows the width of the page's own box, not the window
(`container: ezx / inline-size` and `@container` rules), because the admin's
side panels leave a narrow column even on wide screens: below 720px tables
become cards.

`ezupdate.js` is plain JavaScript; each feature does nothing on a page without
its markup:

| Attribute | Feature |
|---|---|
| `data-ezupdate-enables` | a checkbox that enables a button (the backup confirmation) |
| `data-ezupdate-confirm` | a form that asks before submitting |
| `#ezupdate-job-output` | follows a run (polls `…/json`, handles signed-out, 403, errors) |
| `data-ezupdate-installed` | the Installed packages filters, search, sort, details, address state |
| `data-ezx-filter` / `data-ezx-text` / `data-ezx-none` | filtering a list as you type |
| `data-ezx-copy`, `data-ezx-copy-target` | copy buttons |
| `data-ezx-num`, `data-ezx-ago`, `data-ezx-elapsed` | compact numbers, relative times, a run's duration |
| `data-ezx-follow`, `data-ezx-wrap` | the terminal's switches |
| `data-ezx-stable-only` | hiding development versions |
| `data-ezx-busy` | a busy label on slow submits |
| `data-ezx-search` | the field `/` jumps to |

Extending it
------------

- **A new view**: add it to `modules/update/module.php`, write the script (no
  declarations), the template between `parts/header.tpl` and `parts/footer.tpl`,
  and a tab in `parts/header.tpl` if it belongs there. Use the components above.
- **A new inventory check**: add it to `eZUpdateInventory::issues()` (with
  `warn` or `bad`) and its text to the translations; it shows on the page, in
  the downloads and on the command line at once.
- **A new command**: a `case` in `bin/php/ezupdate.php`, its line in the help,
  its options in `getOptions()`.
- **A new language**: copy `translations/untranslated/translation.ts` to
  `translations/<locale>/translation.ts` and fill in the translations.
- **Run something after every update**: `[JobSettings] AfterRunCommands[]`.
