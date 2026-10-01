Contributing to eZ Update
=========================

Thank you for helping. eZ Update is free software (GPL v2 or later) and lives at
[github.com/se7enxweb/ezupdate](https://github.com/se7enxweb/ezupdate).

Ways to help
------------

- **Report a problem** — [open an issue](https://github.com/se7enxweb/ezupdate/issues)
  with your Exponential, PHP and Composer versions (the Overview shows them), what
  you did, what you expected and what happened. For a run, paste its output
  (*Copy* on the run page). Security problems: see [doc/SECURITY.md](doc/SECURITY.md),
  not a public issue.
- **Suggest a feature** — an issue that says what you want to get done, not only
  how; it helps us find the simplest way.
- **Translate** — copy `translations/untranslated/translation.ts` to
  `translations/<locale>/translation.ts` (for example `fre-FR`, `nor-NO`), fill
  in the translations, send a pull request.
- **Improve the documentation** — everything in `doc/` and this file.
- **Write code** — see below.

Working on the code
-------------------

```sh
# in an Exponential installation
composer require se7enxweb/ezupdate --prefer-source
cd extension/ezupdate        # a git clone: branch, commit, push
```

Activate it, regenerate the autoloads, and open *Setup > Updates and packages*.
[doc/ARCHITECTURE.md](doc/ARCHITECTURE.md) explains the classes, views,
templates, styles and scripts, and how to add a view, a check, a command or a
language.

Guidelines:

- **PHP**: the style of the files around you (Exponential's: spaces inside
  parentheses, braces on their own lines, `eZ`-prefixed classes). PHP 7.4
  compatible. `php -l` every file you touch.
- **View scripts** declare no functions or classes (they may run many times in
  one process).
- **Composer** is only ever started through `eZUpdateManager` (argument lists,
  no shell). Check every value that comes from a form before it gets there.
- **Templates**: every visible text through `i18n( 'extension/ezupdate' )`, every
  value `|wash`ed. Use the design system's components (`.ezx-*`) rather than new
  one-off styles; keep every new rule under `.ezx`.
- **JavaScript**: plain, no library; a feature does nothing on a page without
  its markup.
- **Translations**: add new texts to `translations/untranslated`, `eng-US` and,
  if you can, `ger-DE`.
- Test in the admin3 design at a wide and a narrow width (the content column
  between the admin's side panels), and with JavaScript off for the forms.

Commits and pull requests
-------------------------

One change per commit, with a message that starts with what kind of change it
is and says what it does for the user:

```
Added: Installed packages names a lock older than composer.json
Updated: The run page follows Composer's output after a sign-in
Removed: The unused packagist.org mirror setting
Renamed: The dashboard tab is Overview
```

The body says why, when that is not obvious. Open the pull request against
`main`; describe what you changed and how you tested it.

By contributing you agree that your work is published under the GNU General
Public License v2.0 or any later version.
