Changelog
=========

All notable changes. Versions follow the tags of
[github.com/se7enxweb/ezupdate](https://github.com/se7enxweb/ezupdate/releases).

1.1.17 (2026-10-08)
-------------------

**composer.phar keeps to the mode limits of Exponential.** The downloaded `composer.phar` is made executable
through `eZFile::executableMode()`, so `EZP_DIR_MODE_MAX` in `config.php` narrows its 0755 (0750 under 0750 or 0770).
Without the limit, or on a kernel without the helper, it is 0755 as before.

1.1.16 (2026-10-07)
-------------------

**No deprecation entries on PHP 8.5.** The package server and the update checks call `curl_close()` only on PHP
versions before 8.0, where it still had an effect; PHP 8.5 deprecates it.

1.1.15 (2026-10-04)
-------------------

**Install updates works under open_basedir.** On a host that confines PHP to its site directory,
`is_executable('/usr/bin/setsid')` answers no although the program exists and `proc_open` may run it, so
Install updates said it could not start. setsid is now found by the kernel helper `expProcessTools` when the
kernel has one, and otherwise by running `setsid --version`.

1.1.14 (2026-10-04)
-------------------

**Clearer wording.** The Overview's status line for adding packages reads "Installing new packages"
(German: "Neue Pakete installieren") instead of "Installing", so it is not mistaken for updates.

1.1.13 (2026-10-03)
-------------------

**Install updates from the Overview.**

Added
- *Install updates*: after *Check for updates* each package that can be installed has a tick box
  (all ticked) and the button runs `composer update` for the ticked ones. It is always shown;
  disabled with an explanation while `[UpdateSettings] AllowUpdate` is `disabled`.
- *Switch on updates* / *Switch off* for users with `update/manage`: writes `AllowUpdate` to
  `settings/override/ezupdate.ini.append.php` through the kernel INI editor, asks for the
  password again when `ReauthForManage` is on, records an audit event, clears the INI cache.
- English and German strings; tests of the labelling with fixtures.

Updated
- *Kind* is decided by Composer: one `composer update --dry-run` over the outdated packages,
  parsed per package. *Can be installed*, or *Blocked by composer.json (constraint)*.
  Before, "semver-safe-update" was shown as "Within the constraint", which composer.json
  could contradict (phpunit 13.0.0 pinned, 13.4.0 out).
- *Update, dry run* is now *Preview (dry run)*; *Run again* keeps the package list.
- Packages whose composer.json version is newer than composer.lock are added to the run
  (Composer refuses a partial update otherwise).

1.1.12 (2026-10-03)
-------------------

**Every finished run says how it ended.**

Added
- A notice box at the top of the run's page (and on the Overview after *Check for
  updates*): *The installation is up to date! Update again soon to remain secure.* when
  Composer had nothing to install, update or remove; what changed (installed, updated,
  removed) after a run that did something; the exit code after a failure. It appears
  when the run ends while the page is open, too. German translation included.

1.1.11 (2026-10-03)
-------------------

**Works on hosts with open_basedir.**

Added
- *Get Composer* on the Overview: downloads the official `composer.phar` into
  `var/ezupdate/`, verified against the published SHA-256.
- Installation-local places (`var/ezupdate/`, `bin/`, root, `vendor/bin/`) are
  searched before the system ones; `PHPSearchPath[]`, `DownloadURL`, `ChecksumURL`.

Updated
- A Composer or PHP path set in `ezupdate.ini` is used although `open_basedir`
  hides it; the PHP next to the running PHP is used and its major.minor checked.
- The *Composer was not found* message lists where it looked and says what
  `open_basedir` hides.

1.1.8 (2026-10-01)
------------------

**Installed packages and a new look for every page.**

Added
- *Installed packages* (`update/installed`): `composer.json`, `composer.lock`,
  `installed.json` and the extension directories matched up, with which
  extensions `ActiveExtensions` and each siteaccess's `ActiveAccessExtensions`
  switch on. Names what does not agree: required but not installed, not in the
  lock, locked and installed versions apart, a lock older than the constraint,
  another commit than the lock, missing on disk, active but not on disk, a git
  clone where Composer installed an archive. Filters, search, sort, row details,
  the view in the address (`#issues`), JSON and CSV downloads.
- `ezupdate.php installed [--issues] [--json]` on the command line.
- The Overview's cards: installed packages, extensions, what needs attention,
  newer releases, the last run.
- Copy buttons for paths and addresses; relative times; compact download
  counts; a run's elapsed time; the terminal's *Follow*, *Wrap lines* and
  *Copy*; *Releases only* in a package's versions; `/` to search; busy states on
  slow buttons; success messages that close themselves.
- Documentation: installation, user guide, installed packages, configuration,
  command line, security, architecture, FAQ, this changelog, contributing.

Changed
- The first tab is now *Overview* (`update/dashboard`, unchanged); *Installed
  packages* opens the new view.
- Every page in one design made for admin3: panels, cards, tables that become
  cards when the content column is narrow (a container query, so it follows the
  column between the admin's side panels, not the window).
- A package's install form shows for packages packagist.org does not know too.
- All new texts in English and German.
- The license texts are Markdown (`LICENSE.md`, `doc/LICENSE.md`).

1.1.7 (2026-09-30)
------------------
- German texts for the navigation part and the Setup menu entry.

1.1.6 (2026-09-29)
------------------
- Funding: the list `composer fund` prints, in the admin and on the command
  line (`fund [--direct] [--json]`), read from the packages' metadata and their
  `.github/FUNDING.yml`.

1.1.5 (2026-09-28)
------------------
- The run page says why it cannot follow a run: signed out, refused, a server
  error, no answer; it retries what can get better.

1.1.4 (2026-09-28)
------------------
- Run again, and run a dry run for real, from a run's page and the recent runs.

1.1.3 (2026-09-28)
------------------
- A package manager: packagist.org browsing, guarded installs from dist or
  source, Composer and Exponential package servers, live output of background
  runs.

1.1.2 (2026-09-28)
------------------
- Every visible text is a translation string, with German.

1.1.1 (2026-09-28)
------------------
- The license named as GNU General Public License v2.0 (or any later version).

1.1.0 (2026-09-22)
------------------
- Runs under a persistent-worker web server.

1.0.2 (2026-09-14) and 1.0.1 (2024-11-02)
-----------------------------------------
- The first releases: Composer updates from the admin.
