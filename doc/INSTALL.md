Installation
============

This guide takes an Exponential installation from "no eZ Update" to "updating
packages from the admin", one step at a time. Every command runs from the
installation root, the directory that holds `index.php` and `composer.json`.

1. Requirements
---------------

| Need | Why | Check |
|---|---|---|
| Exponential 6 | the admin, the settings, the module system | `/ezinfo/about` in the admin |
| PHP 7.4 or later | the extension's code (tested up to PHP 8.5) | `php -v` |
| `proc_open` allowed | Composer and the background runs are started with it | `php -r 'var_dump(function_exists("proc_open"));'` |
| `curl` | packagist.org, package servers, page fetching | `php -m \| grep curl` |
| Composer 2 | the work itself | `composer --version` |
| A writable `var/` | runs, logs and Composer's cache live in `var/ezupdate/` | |

Composer is found on its own in `/usr/local/bin`, `/usr/bin` and
`/opt/cpanel/composer/bin` (as `composer` or `composer.phar`). Somewhere else?
Set `[ComposerSettings] Path` (see [CONFIGURATION.md](CONFIGURATION.md)).

eZ Update does not need root, a daemon or a database table.

2. Install the package
----------------------

```sh
composer require se7enxweb/ezupdate
```

Composer puts it in `extension/ezupdate/` (it is an
`ezpublish-legacy-extension` package). Prefer a git checkout you can work on?

```sh
composer require se7enxweb/ezupdate --prefer-source
```

Without Composer, download a release from
[GitHub](https://github.com/se7enxweb/ezupdate/releases) and unpack it as
`extension/ezupdate/`.

3. Switch it on
---------------

In `settings/override/site.ini.append.php`:

```ini
[ExtensionSettings]
ActiveExtensions[]=ezupdate
```

Then refresh the autoload array and the caches:

```sh
php bin/php/ezpgenerateautoloads.php --extension
php bin/php/ezcache.php --clear-all
```

On a persistent-worker server (Exponential Velocity, RoadRunner and the like)
restart its workers too, so they load the new classes. eZ Update loads its own
classes when the autoload array does not know them yet, so a page keeps working
in between.

4. Open it
----------

Admin, **Setup** tab, **Updates and packages** in the left menu, or straight at
`/update/dashboard` on the admin siteaccess. The tabs:

- **Overview** (`update/dashboard`) — Composer, the check for updates, runs
- **Installed packages** (`update/installed`) — the inventory
- **Find packages** (`update/browse`) — packagist.org and your servers
- **Package servers** (`update/servers`) — Composer and `.ezpkg` servers
- **Funding** (`update/fund`) — who to support

If the Overview says *Composer: Not found*, set `[ComposerSettings] Path`. If it
says *Does not start*, the message under it is Composer's own: usually a PHP
binary it cannot use (set `PHPBinary`) or a `COMPOSER_HOME` it cannot write.

5. Permissions
--------------

The module is `update`, with two functions:

| Policy | Allows |
|---|---|
| `update/ezupdate` | every page; the check for updates; dry runs; following runs; the JSON and CSV downloads |
| `update/manage` | updating, installing, fetching `.ezpkg` packages, adding and removing servers, switching packagist.org on and off |

The Administrator role has both. For a developer who should see everything but
change nothing, give `update/ezupdate` only.

6. Allow changes (when you want them)
-------------------------------------

Out of the box eZ Update only looks: you can check for updates and run dry runs,
but not update or install. That is on purpose: Composer rewrites `vendor/` and
every package it manages.

When you want the admin to be able to change packages, in
`settings/override/ezupdate.ini.append.php`:

```ini
<?php /* #?ini charset="utf-8"?

[UpdateSettings]
AllowUpdate=enabled
AllowInstall=enabled

*/ ?>
```

Each real run still asks you to tick *A backup of files and database exists*.

7. The web server's user
------------------------

The admin runs Composer as the web server's user (often `www-data`, `apache` or
the site's own account). That user must be able to write what Composer writes:
`composer.json`, `composer.lock`, `vendor/` and the package directories
(`extension/...`). The Overview warns when `composer.json` is read-only for it.

Composer's cache and settings for each system account live in
`var/ezupdate/composer/<user>/`, so the web server and an administrator at the
shell never fight over one cache.

8. Upgrading eZ Update
----------------------

From the admin (Find packages, `se7enxweb/ezupdate`, *Change version*) or:

```sh
composer update se7enxweb/ezupdate
php bin/php/ezpgenerateautoloads.php --extension
php bin/php/ezcache.php --clear-tag=template,ini
```

Read [CHANGELOG.md](CHANGELOG.md) first: settings that changed are named there.

9. Removing it
--------------

```sh
# switch it off: remove ActiveExtensions[]=ezupdate, then
composer remove se7enxweb/ezupdate
php bin/php/ezpgenerateautoloads.php --extension
php bin/php/ezcache.php --clear-all
```

Its runs and Composer cache stay in `var/ezupdate/`; delete that directory when
you no longer need the logs. Package servers it added stay in
`settings/override/ezupdate.ini.append.php` and `composer.json`.
