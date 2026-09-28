eZ Update
=========

The package manager of an Exponential installation, in the admin (Setup tab,
"Updates and packages") and on the command line.

- **Installed packages**: where Composer is, which PHP runs it, how many
  packages are installed, whether updating and installing are allowed; a check
  for updates (`composer outdated`) that changes nothing; an update dry run; and
  a guarded update.
- **Find packages**: search packagist.org through its public API, filtered by
  package type (Exponential extensions by default), or every server in
  `composer.json` through `composer search`. A package page shows its
  description, versions, requirements, license, downloads, source repository,
  the git URL and commit of each version, and, when it is installed, how it was
  fetched and the branch and commit of its git working copy. It is installed
  from there: a dry run first, then the install.
- **dist or source**: packages come as release archives (dist, fast) or as git
  clones with their history (source), so the branch and commit of a package can
  be read and worked on; or Composer chooses (auto: source for development
  versions). Chosen per run, default `[UpdateSettings] PreferredInstall`.
- **Package servers**: two lists, each kept where the tools that use it read it,
  so the admin, the command line and those tools never disagree:
  - Composer servers are the `repositories` of `composer.json` (added and
    removed with `composer config`); packagist.org can be switched off there.
  - Exponential package servers serve `.ezpkg` packages (site designs, content
    classes, demo content) in the `index.xml` format the setup wizard reads. The
    wizard's own server (`package.ini [RepositorySettings]`) is always listed;
    added servers are kept in `settings/override/ezupdate.ini.append.php`. A
    package is fetched into the local package repository and installed from
    there with the kernel's package views.
- **Live output**: an update or install runs in the background (one at a time),
  so it neither holds a web request open nor hits its time limit; the page shows
  Composer's output as it is written, in colour. The last runs are listed with
  who started them and how they ended.

Safety
------

- Updating and installing are **off by default**
  (`[UpdateSettings] AllowUpdate` and `AllowInstall`). Composer rewrites
  `vendor/` and every package it manages, so switch them on only where that is
  wanted. Each run asks to confirm that a backup exists, and a dry run is
  always offered first.
- Viewing, checking and dry runs need the `update/ezupdate` policy; updating,
  installing, fetching and changing servers need `update/manage`. Every form is
  protected by the form token.
- Composer is started without a shell (an argument list), in the installation
  root, with a time limit (`[ComposerSettings] Timeout`). Package names and
  version constraints are checked before they reach it; server addresses must
  be `https://`.
- Composer's output is escaped before its colours are turned into HTML.
- Each system account gets its own `COMPOSER_HOME` under
  `var/ezupdate/composer/`, so the web server's user and root never lock each
  other out of Composer's cache. Runs are kept in `var/ezupdate/jobs/`.
- After a successful update or install, `[JobSettings] AfterRunCommands` run
  (autoloads, caches); only PHP scripts of the installation are accepted there.

Command line
------------

Run from the installation root:

```
php extension/ezupdate/bin/php/ezupdate.php status
php extension/ezupdate/bin/php/ezupdate.php outdated [--all]
php extension/ezupdate/bin/php/ezupdate.php search <words> [--type=<type>] [--composer]
php extension/ezupdate/bin/php/ezupdate.php show <vendor/name>
php extension/ezupdate/bin/php/ezupdate.php servers
php extension/ezupdate/bin/php/ezupdate.php server-add composer <name> <composer|vcs|git> <https url>
php extension/ezupdate/bin/php/ezupdate.php server-add ezpkg <name> <https url>
php extension/ezupdate/bin/php/ezupdate.php server-remove composer|ezpkg <name>
php extension/ezupdate/bin/php/ezupdate.php packagist on|off
php extension/ezupdate/bin/php/ezupdate.php packages [<server>]
php extension/ezupdate/bin/php/ezupdate.php fetch <server> <package> [--replace]
php extension/ezupdate/bin/php/ezupdate.php require <vendor/name> [<constraint>] [--dry-run] [--prefer=dist|source|auto]
php extension/ezupdate/bin/php/ezupdate.php update [--dry-run] [--prefer=dist|source|auto]
php extension/ezupdate/bin/php/ezupdate.php jobs
```

Runs started here are listed in the admin too.

Settings
--------

All in `settings/ezupdate.ini.append` (override in
`settings/override/ezupdate.ini.append.php`):

- `[ComposerSettings]`: `Path` and `Binary` of Composer (empty: `SearchPath` and
  `BinaryNames` are tried), `PHPBinary`, `Timeout`, `ComposerHome`.
- `[UpdateSettings]`: `AllowUpdate`, `AllowInstall`, `PreferredInstall`,
  `UpdateArguments`, `RequireArguments`.
- `[JobSettings]`: `AfterRunCommands`, `KeepJobs`.
- `[PackagistSettings]`: `URL`, `PerPage`, `CacheTime`, `Types`.
- `[PackageServerSettings]`: `Servers[<name>]=<https url>`.

Requirements
------------

- Exponential 6 (the extension also runs on the legacy kernel it grew from).
- PHP 7.4 or later with `proc_open` and curl; Composer on the server.
- `setsid` (util-linux) to run jobs in the background; without it a run
  happens within the request.
- Works under PHP-FPM and under Exponential Velocity.

Version
-------

- 1.1.3, September 28, 2026.

Copyright and license
---------------------

eZ Update is copyright 1998 - 2026 7x. It is licensed under the GNU General
Public License v2.0 (or any later version); see `LICENSE` and `doc/LICENSE`.

Issues: https://github.com/se7enxweb/ezupdate/issues
