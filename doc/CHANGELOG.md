Changelog
=========

All notable changes. Versions follow the tags of
[github.com/se7enxweb/ezupdate](https://github.com/se7enxweb/ezupdate/releases).

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
