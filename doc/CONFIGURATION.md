Configuration
=============

Every setting lives in `ezupdate.ini`. The extension ships its defaults in
`extension/ezupdate/settings/ezupdate.ini.append`; change them in
`settings/override/ezupdate.ini.append.php` (or a siteaccess's own
`ezupdate.ini.append.php`, usually the admin's):

```ini
<?php /* #?ini charset="utf-8"?

[UpdateSettings]
AllowUpdate=enabled

*/ ?>
```

After changing a setting, clear the INI cache:
`php bin/php/ezcache.php --clear-tag=ini`.

[ComposerSettings] — finding and running Composer
-------------------------------------------------

| Setting | Default | Meaning |
|---|---|---|
| `Path` | *(empty)* | Directory of the Composer binary. Empty: each directory of `SearchPath` is tried. |
| `Binary` | *(empty)* | File name in that directory. Empty: each name of `BinaryNames` is tried. |
| `SearchPath[]` | `/usr/local/bin/`, `/usr/bin/`, `/opt/cpanel/composer/bin/` | Where to look when `Path` is empty. |
| `BinaryNames[]` | `composer`, `composer.phar` | Names to look for. |
| `PHPBinary` | *(empty)* | The PHP command line binary that runs a `composer.phar` and the background runs. Empty: the `php` next to the running PHP (`PHP_BINDIR`), then `/usr/local/bin/php`, `/usr/bin/php`. Set it when the web server's PHP is not a command line PHP (PHP-FPM). |
| `Timeout` | `900` | Seconds a Composer run may take before it is stopped. |
| `ComposerHome` | `var/ezupdate/composer` | `COMPOSER_HOME` when the web server passes none, relative to the installation root. Each system account gets its own directory below it (`…/composer/<user>`), so the web server and root never lock each other out of Composer's cache. |

Example: Composer installed in a home directory, PHP 8.5 from a control panel:

```ini
[ComposerSettings]
Path=/home/deploy/bin/
Binary=composer.phar
PHPBinary=/opt/plesk/php/8.5/bin/php
```

[UpdateSettings] — what the admin may change
--------------------------------------------

| Setting | Default | Meaning |
|---|---|---|
| `AllowUpdate` | `disabled` | `enabled`: the admin may run `composer update`. `disabled`: only the check for updates and the dry run. |
| `AllowInstall` | `disabled` | `enabled`: the admin may install packages and change their versions (`composer require`). |
| `PreferredInstall` | `auto` | How packages are fetched by default: `dist` (release archives, fast), `source` (git clones, each package keeps its `.git` so its history, branch and commit can be read and worked on) or `auto` (source for development versions, dist for releases). The forms and `--prefer` choose per run. |
| `UpdateArguments[]` | `--ansi`, `--no-progress` | Extra arguments of every `composer update`. |
| `RequireArguments[]` | `--ansi`, `--no-progress` | Extra arguments of every `composer require`. |

Composer rewrites `vendor/` and every package it manages, so switch
`AllowUpdate` and `AllowInstall` on only where that is wanted, and keep
backups. Even then every real run asks for the backup confirmation.

A common setup: allowed on development and staging, `disabled` on production
(which is updated by its deployment), with `update/ezupdate` for developers so
they can still look and dry-run.

[JobSettings] — background runs
-------------------------------

| Setting | Default | Meaning |
|---|---|---|
| `AfterRunCommands[]` | `bin/php/ezpgenerateautoloads.php --extension`, `bin/php/ezcache.php --clear-tag=ini,template,content` | PHP scripts of the installation run after a successful update or install, each with its arguments. Only PHP scripts inside the installation are accepted. |
| `KeepJobs` | `20` | How many finished runs (log and status) are kept in `var/ezupdate/jobs/`. |

Add your own step, for example a cache warmer:

```ini
[JobSettings]
AfterRunCommands[]=bin/php/ezcache.php --clear-tag=ini,template,content
AfterRunCommands[]=bin/php/ezpgenerateautoloads.php --extension
AfterRunCommands[]=extension/mysite/bin/warm-cache.php
```

[PackagistSettings] — packagist.org
-----------------------------------

| Setting | Default | Meaning |
|---|---|---|
| `URL` | `https://packagist.org` | The packagist.org API, or a compatible mirror. |
| `PerPage` | `25` | Search results per page. |
| `CacheTime` | `900` | Seconds a packagist.org answer is reused. |
| `Types[]` | `ezpublish-legacy-extension=Extensions`, `ezpublish-legacy=Kernel`, `library=Libraries`, `=Any type` | The package types offered in the search form, `type=label`; an empty type means any. The first is the default. |

[PackageServerSettings] — Exponential .ezpkg servers
----------------------------------------------------

| Setting | Meaning |
|---|---|
| `Servers[<name>]=<https URL>` | Package servers added in the admin (or by hand). The admin writes them to `settings/override/ezupdate.ini.append.php`. The server of `package.ini [RepositorySettings]` is always listed first and cannot be removed here. |

```ini
[PackageServerSettings]
Servers[]
Servers[agency]=https://packages.example.com/exponential/6.0
```

Settings that live elsewhere
----------------------------

| What | Where | Changed from |
|---|---|---|
| Composer servers, packagist.org on/off | `composer.json` `repositories` | Package servers tab, or `composer config` |
| Which extensions run | `site.ini [ExtensionSettings] ActiveExtensions`, a siteaccess's `ActiveAccessExtensions` | your settings files (shown, never changed, by eZ Update) |
| The setup wizard's package server | `package.ini [RepositorySettings]` | your settings files |
| Who may use it | the `update/ezupdate` and `update/manage` policies | Roles and policies |

Files eZ Update writes
----------------------

| Path | What |
|---|---|
| `var/ezupdate/jobs/<id>.json`, `<id>.log` | a run's status and output (pruned to `KeepJobs`) |
| `var/ezupdate/composer/<user>/` | Composer's home and cache per system account |
| `composer.json`, `composer.lock`, `vendor/`, package directories | through Composer, only in runs you started |
| `settings/override/ezupdate.ini.append.php` | package servers you added |
| the local package repository (`var/storage/packages/` by default) | `.ezpkg` packages you fetched, through the kernel's `eZPackage::import` |
