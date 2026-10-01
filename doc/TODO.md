Roadmap
=======

Ideas for the next releases. Want one of them, or something else? Say so in an
[issue](https://github.com/se7enxweb/ezupdate/issues); pull requests welcome
(see [CONTRIBUTING.md](../CONTRIBUTING.md)).

Next
----

- **Activate and deactivate extensions** from *Installed packages*, writing
  `ActiveExtensions` the way the kernel's own extension view does.
- **Fix it buttons** for the inventory's findings: a dry run of
  `composer update <package>` for *Lock older than composer.json*, of
  `composer install` for *Locked X, installed Y*.
- **Security advisories**: `composer audit` on the Overview, with the affected
  packages marked in *Installed packages*.
- **Scheduled checks**: a cronjob part that checks for updates and mails a
  summary.

Later
-----

- Diff of `composer.lock` between two runs.
- A changelog link per update, from the package's releases.
- More languages (French, Norwegian, Spanish …) — translations welcome.

Done
----

See [CHANGELOG.md](CHANGELOG.md).
