FAQ
===

### Is it safe to install on a production site?

Yes. Out of the box it only looks: updating and installing are off
(`[UpdateSettings] AllowUpdate`, `AllowInstall`) until you switch them on in a
settings file. The check for updates, dry runs and the Installed packages view
change nothing. See [SECURITY.md](SECURITY.md).

### Does it replace the command line?

No, it sits next to it. Everything it does, `composer` and its own command line
tool can do; it adds a view of the whole installation, guard rails, and a
history of runs that both sides share.

### The Overview says "Composer: Not found".

Composer is looked for first inside the installation (`var/ezupdate/`, `bin/`, the
root, `vendor/bin/`), then in `/usr/local/bin`, `/usr/bin` and
`/opt/cpanel/composer/bin`. On a default Plesk host PHP runs with `open_basedir`,
which hides the system folders from the search (and the Plesk `composer` there is
a wrapper that starts an older PHP). Press **Get Composer** on the Overview: it
downloads the official `composer.phar` into `var/ezupdate/` and verifies it against
the published SHA-256 (needs the *manage* permission). Or set
`[ComposerSettings] Path`, `Binary` and `PHPBinary` in
`settings/override/ezupdate.ini.append.php`: a path you set yourself is used even
when `open_basedir` keeps PHP from checking it. The message on the Overview lists
everywhere that was looked at.

### It says "Does not start".

The text under it is Composer's own. The usual causes: the web server's PHP is
PHP-FPM, which cannot run Composer (set `[ComposerSettings] PHPBinary` to a
command line PHP), or `COMPOSER_HOME` is not writable (it is
`var/ezupdate/composer/<user>` unless the web server passes one).

### A run says "Another Composer run is still in progress".

One run at a time, on purpose. Wait for it (its page shows its output), or, if
it was killed, the next request notices and marks it *Stopped*.

### The run page says I am no longer signed in.

The admin session ended while the page was following the run. The run goes on
on the server; sign in again and open the run from *Recent runs*.

### Why do so many packages "need attention"?

Usually because `composer.json` was raised but `composer update` was not run
(*Lock older than composer.json*), or because the lock changed and
`composer install` was not run (*Locked X, installed Y*). Each status is
explained in [INSTALLED_PACKAGES.md](INSTALLED_PACKAGES.md#what-needs-attention-means).
A dry run on the Overview shows what an update would do about it.

### What is "Git clone of a dist install"?

Composer installed a release archive into that directory, but the directory is a
git clone (someone cloned over it to work on it). The next `composer update`
replaces it with an archive again. Install that package from *source* to keep a
clone Composer knows about.

### dist or source?

*dist* downloads release archives: fast, small, nothing to commit by accident.
*source* clones each package with its git history: you can see its branch and
commit, switch branches and send changes upstream. *auto* lets Composer choose
(source for development versions). Choose per run, default
`[UpdateSettings] PreferredInstall`.

### Can I use my own package repository?

Yes: add it on *Package servers* (a Composer repository such as Satis or Private
Packagist, or a single `vcs`/`git` repository), and switch packagist.org off if
every package must come from you. It is written to `composer.json`, so the
command line uses it too.

### What are "Exponential package servers"?

Servers of `.ezpkg` packages: site designs, content classes and demo content in
the format the setup wizard installs. eZ Update lists them, shows their
packages and fetches one into the local package repository.

### It works in admin2, but looks plain.

It is designed for admin3. In admin2 everything works and reads well; the look
is simpler.

### Does it work behind a persistent-worker server?

Yes (Exponential Velocity and similar). Its view scripts declare nothing, its
classes load themselves when the autoload array is older than the extension, and
runs are separate processes.

### Can I get the list into a spreadsheet?

*Installed packages* → *CSV*, or `/update/installed/csv`. JSON for scripts:
`/update/installed/json` or `ezupdate.php installed --json`.

### How do I translate it?

Copy `translations/untranslated/translation.ts` to
`translations/<locale>/translation.ts`, fill in the `<translation>`s, clear the
translation cache. Pull requests with a new language are very welcome.
