Security
========

A tool that runs Composer from a web page can change every line of code an
installation runs. eZ Update is built so that it only does so when an
administrator has deliberately allowed it, chosen it and confirmed a backup,
and so that nothing a visitor or a package server sends can make it do more.

What it does, and what it never does
------------------------------------

| It does | It never does |
|---|---|
| read `composer.json`, `composer.lock`, `installed.json`, the settings and the extension directories | write settings other than its own package servers |
| run Composer (`outdated`, `show`, `search`, `require`, `update`, `config`) in the installation root | run a shell, or any program other than Composer, PHP and git (read-only `git` calls on the package page) |
| run the PHP scripts named in `[JobSettings] AfterRunCommands` after a successful run | run a script outside the installation, or anything not ending in `.php` |
| talk to packagist.org and to the servers you list | send data anywhere else; there is no telemetry |
| write runs and Composer's cache under `var/ezupdate/` | keep passwords or tokens of its own |

Layers
------

**1. Off by default.** `[UpdateSettings] AllowUpdate` and `AllowInstall` are
`disabled`. Until they are switched on in the settings (a file, not a form), the
admin can look, check and dry-run, and that is all.

**2. Policies.** Every page needs `update/ezupdate`; every change needs
`update/manage`: updating, installing, fetching `.ezpkg` packages, adding or
removing servers, switching packagist.org. Checked on every request, in the
view, not only by hiding buttons.

**3. Confirmation.** Every real update or install asks *A backup of files and
database exists*; the button stays disabled until the box is ticked, and the
server refuses the run without it. A dry run is always offered first, and the
page that shows a dry run can turn it into the real run only with the same
confirmation.

**4. Form tokens.** Every form carries the kernel's form token (ezformtoken), so
another site cannot make an administrator's browser submit one.

**5. No shell, checked arguments.** Composer is started with `proc_open` and an
argument list, never through a shell, so nothing in a value is ever interpreted
as a command. Before anything reaches Composer:

- package names must look like `vendor/name`;
- version constraints may only use the characters of Composer constraints;
- server names letters, digits, `.`, `-`, `_`; `packagist.org` is reserved;
- server addresses must be `https://` URLs;
- the fetch method is one of `dist`, `source`, `auto`.

**6. Limits.** Each run has a time limit (`[ComposerSettings] Timeout`), only
one runs at a time, and downloads of `.ezpkg` packages have a size limit.

**7. Separate homes.** Each system account gets its own `COMPOSER_HOME` under
`var/ezupdate/composer/<user>/`, so the web server's user and root never share
(or lock) a cache, and Composer's auth settings of one account are not read by
another.

**8. Escaped output.** Composer's output is HTML-escaped first; only then are
its ANSI colours turned into `<span>`s. Package metadata from packagist.org and
servers (names, descriptions, URLs) is escaped in every template; links to
outside sites open with `rel="noopener noreferrer"`.

**9. Read-only views stay read-only.** The Installed packages view and its
downloads, the Overview's cards and the Funding page only read files. They run
nothing and need no network.

Recommendations
---------------

- Leave `AllowUpdate` and `AllowInstall` off on production, and update it with
  your deployment; use eZ Update there to look and to dry-run.
- Give `update/manage` to as few people as you would give shell access to.
- Keep `composer.json` and `vendor/` writable only by the account that should
  change them. If that is not the web server's user, the admin can still show
  everything and run dry runs.
- Keep backups that do not live on the same server.
- Use your own Composer server and switch packagist.org off where every
  package must be vetted.

Reporting a vulnerability
-------------------------

Please do not open a public issue. Write to **info@se7enx.com** with the
details and how to reproduce it; we answer within a few days and credit you in
the release notes unless you prefer otherwise.
