Command line
============

Everything the admin pages do, the command line does too: the same classes,
settings and server lists, and the same run history. Run it from the
installation root:

```sh
php extension/ezupdate/bin/php/ezupdate.php <command> [arguments] [options]
```

Without a command it prints `status`. `--help` lists the commands and options.
Every Exponential script option works too (`-s <siteaccess>`, `--debug`, …).

Commands
--------

| Command | Does |
|---|---|
| [`status`](#status) | where Composer is, what may be run |
| [`installed`](#installed) | the inventory of the Installed packages view |
| [`outdated`](#outdated) | packages with a newer release |
| [`search`](#search) | search packagist.org or your servers |
| [`show`](#show) | a package on packagist.org, and as installed |
| [`servers`](#servers-server-add-server-remove-packagist) | the Composer and Exponential package servers |
| `server-add`, `server-remove`, `packagist` | change them |
| [`packages`, `fetch`](#packages-fetch) | `.ezpkg` packages of a server, and downloading one |
| [`require`, `update`](#require-update) | install or update, with `--dry-run` |
| [`jobs`](#jobs) | the recent runs, from here and from the admin |
| [`fund`](#fund) | who the installed packages ask to be funded by |

### status

```
$ php extension/ezupdate/bin/php/ezupdate.php status
Composer:     /usr/local/bin/composer
              Composer version 2.8.12 2025-09-19 13:41:59
PHP:          /usr/bin/php
Installation: /var/www/example.com
Installed:    105 packages
Servers:      packagist.org, 0 in composer.json
Update:       switched off ([UpdateSettings] AllowUpdate)
Install:      switched off ([UpdateSettings] AllowInstall)
```

### installed

```sh
php extension/ezupdate/bin/php/ezupdate.php installed           # every row
php extension/ezupdate/bin/php/ezupdate.php installed --issues  # only what needs attention
php extension/ezupdate/bin/php/ezupdate.php installed --json    # the rows and the summary, as JSON
```

```
127 rows: 105 installed by Composer, 81 required in composer.json, 75 extensions (51 active), 19 not from Composer, 58 need attention

PACKAGE                                      KIND      JSON         LOCK         INSTALLED      EXTENSION
se7enxweb/bccie                              extension ~1.1.9       v1.1.4       v1.1.3         bccie [everywhere]
     ! Locked v1.1.4, installed v1.1.3
     ! Lock older than composer.json (~1.1.9)
se7enxweb/birthday                           extension ~1.3.1       1.3.1        1.3.0          birthday [off]
     ! Locked 1.3.1, installed 1.3.0
```

`[everywhere]` is `ActiveExtensions`; a list of siteaccesses is their
`ActiveAccessExtensions`; `[off]` is neither. `!!` marks what is broken, `!`
what is out of step. What each status means:
[INSTALLED_PACKAGES.md](INSTALLED_PACKAGES.md#what-needs-attention-means).

### outdated

```sh
php extension/ezupdate/bin/php/ezupdate.php outdated        # what composer.json names
php extension/ezupdate/bin/php/ezupdate.php outdated --all  # dependencies too
```

Asks the package servers (`composer outdated`); changes nothing.

### search

```sh
php extension/ezupdate/bin/php/ezupdate.php search tags                          # packagist.org, extensions
php extension/ezupdate/bin/php/ezupdate.php search tags --type=                  # any type
php extension/ezupdate/bin/php/ezupdate.php search cache --type=library
php extension/ezupdate/bin/php/ezupdate.php search newsletter --composer         # every server in composer.json
```

### show

```sh
php extension/ezupdate/bin/php/ezupdate.php show se7enxweb/eztags
```

The package on packagist.org (latest release, versions, requirements, source)
and, when installed, how it was installed and the state of its git working copy.

### servers, server-add, server-remove, packagist

```
$ php extension/ezupdate/bin/php/ezupdate.php servers
Composer servers (composer.json):
  packagist.org            composer  on
Exponential package servers:
  exponential              https://packages.example.com/exponential/6.0 (package.ini)
```

```sh
php extension/ezupdate/bin/php/ezupdate.php server-add composer agency composer https://satis.example.com
php extension/ezupdate/bin/php/ezupdate.php server-add composer mylib vcs https://github.com/example/mylib
php extension/ezupdate/bin/php/ezupdate.php server-add ezpkg agency https://packages.example.com/exponential/6.0
php extension/ezupdate/bin/php/ezupdate.php server-remove composer agency
php extension/ezupdate/bin/php/ezupdate.php packagist off
```

Composer servers are written to `composer.json` with `composer config`;
`.ezpkg` servers to `settings/override/ezupdate.ini.append.php`. Addresses
must be `https://`; names letters, digits, `.`, `-` and `_`.

### packages, fetch

```sh
php extension/ezupdate/bin/php/ezupdate.php packages                 # the first server's packages
php extension/ezupdate/bin/php/ezupdate.php packages agency
php extension/ezupdate/bin/php/ezupdate.php fetch agency mysite_design
php extension/ezupdate/bin/php/ezupdate.php fetch agency mysite_design --replace
```

`fetch` puts the `.ezpkg` into the local package repository; install it from
there with the kernel's package tools.

### require, update

```sh
php extension/ezupdate/bin/php/ezupdate.php require se7enxweb/eztags --dry-run
php extension/ezupdate/bin/php/ezupdate.php require se7enxweb/eztags "^2.4" --prefer=source
php extension/ezupdate/bin/php/ezupdate.php update --dry-run
php extension/ezupdate/bin/php/ezupdate.php update --prefer=dist
```

- `--dry-run`: show what would change, change nothing.
- `--prefer=dist|source|auto`: how to fetch (default
  `[UpdateSettings] PreferredInstall`).

The run is recorded like an admin run, with its output, so it shows in the
admin's *Recent runs*. The same switches apply as in the admin: a real `update`
needs `[UpdateSettings] AllowUpdate=enabled`, a real `require`
`AllowInstall=enabled`; dry runs always work. After a successful run the
`[JobSettings] AfterRunCommands` run.

### jobs

```
$ php extension/ezupdate/bin/php/ezupdate.php jobs
cb234d60b813e4a0  2026-09-29 00:36  finished  cli:deploy   Update, dry run (auto)
07deba8d17395a4d  2026-09-28 03:40  finished  admin        Update, dry run (auto)
```

Runs started on the command line are by `cli:<system user>`; from the admin by
the admin user. Each has a page in the admin, `update/job/<id>`.

### fund

```sh
php extension/ezupdate/bin/php/ezupdate.php fund            # every installed package
php extension/ezupdate/bin/php/ezupdate.php fund --direct   # only what composer.json requires
php extension/ezupdate/bin/php/ezupdate.php fund --json
```

In scripts and cron
-------------------

The commands exit with `0` on success and `1` on failure (Composer's own exit
code is printed), so they fit in scripts:

```sh
#!/bin/sh
# Nightly: mail the list of what needs attention, if anything does.
cd /var/www/example.com || exit 1
out=$(php extension/ezupdate/bin/php/ezupdate.php installed --issues)
echo "$out" | grep -q '^ *!' && echo "$out" | mail -s "Packages need attention" ops@example.com
```

```sh
# CI: fail the build when composer.json was raised but the lock was not updated
php extension/ezupdate/bin/php/ezupdate.php installed --json \
  | php -r '$d = json_decode(stream_get_contents(STDIN), true);
            foreach ($d["packages"] as $p) foreach ($p["issues"] as $i)
              if (strpos($i[1], "Lock older") === 0) { echo $p["name"], ": ", $i[1], "\n"; $bad = 1; }
            exit(empty($bad) ? 0 : 1);'
```

Run it as the user that owns the installation's files, so what Composer writes
belongs to the right account. Each account gets its own `COMPOSER_HOME` under
`var/ezupdate/composer/`.
