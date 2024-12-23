# Git CLI extensions

_Additions and tweaks to the Git CLI._

These are some personal aliases, shortcuts, and extensions that make (my) work with the [Git distributed version control tool](https://git-scm.com/) easier and faster. Some of them may be specific to my environment and workflow, and especially the advanced commands often rely on other (potentially unpublished) scripts, but maybe someone finds a valuable nugget in there.

### Installation

Download all / some selected extensions (note that some have dependencies, though) and put them somewhere in your `PATH`, or just add the `./bin` subdirectory to `PATH`. You can then invoke them via `git-SUBCOMMAND`; those commands that don't override built-in ones or have case differences can also be invoked via `git SUBCOMMAND` (space instead of hyphen!).

Additionally, the `gitconfig` supplies many aliases and shortcuts. You can mix and match those within your own `.gitconfig`, or import all of it (beware this is highly personal and still very much in flux!) via the following fragment in there:

    [include]
            path = PATH/TO/git-extensions/gitconfig

To use system-local configuration (like `.gitconfig`, but in a separate file, so you can still share or synchronize the former), add this as well:

    [include]
            path = .local/.gitconfig

This is used by the `git customtool` command.

It is recommended to also use the (Bash, but should also work in Korn shell and Dash) shell functions (e.g. in your `.bashrc`) found at [shell/wrappers.sh](shell/wrappers.sh) to transparently invoke the extensions in the same way as the built-in Git commands, via `git SUBCOMMAND`. It also supports the [hub](https://github.com/github/hub) extension.

The [shell/aliases.sh](shell/aliases.sh) script (also meant to be sourced in `.bashrc`) defines additional (Bash-only) aliases for stuff that cannot be done by an extension script (like automatically changing your current directory). [shell/completions.sh](shell/completions.sh) set up Bash completion for commands that take shell commands.

The [profile/aliases.sh](profile/aliases.sh) sets up system-specific Git aliases, which will be persisted in the system-local configuration; these only need to be sourced once, e.g. from your `.profile`.

The [etc/hooks/](etc/hooks/) directory contains Git hooks; these can be globally installed via

    [core]
            hooksPath = path/to/git-extensions/etc/hooks

Additional hooks can be placed into the `etc/hooks/<hook-name>.d/` subdirectories, allowing for composition of hooks. A working copy hook is still executed first; each hook can abort the execution of further hooks by exiting with `99`.

## See also

* [tj/git-extras](https://github.com/tj/git-extras) has native packages for many distributions, man pages, and shell completions; likely the most popular Git utility collection. Still mixes general-purpose commands with specific (e.g. GitHub, GitLab-related) and questionable (e.g. file locking) ones, and has some quirks (like running PHP linting in an SCP file copy) and strange, underdocumented commands (e.g. `psykorebase`).
* [unixorn/git-extra-commands](https://github.com/unixorn/git-extra-commands) has a hodgepodge of scripts (sometimes duplicate ones for the same purpose) collected from various sources, and therefore having confusing names, different implementation styles (some are undocumented one-liners, in others the boilerplate code for debugging and dependency checks vastly outnumbers the implementation) and languages, and little reuse. Despite these shortcomings, it has a lot of stars and contributors.
* [jwiegley/git-scripts](https://github.com/jwiegley/git-scripts) has both self-written scripts (some very specific to his system and used tools) and collected Git helpers. A lot of stars and contributors, likely also because of its old age.
* _Brooke Kuhlmann_ has developed an astoundingly similar [set of shell functions](https://github.com/bkuhlmann/dotfiles/blob/d93297201cb31531078aa7308e920bc4a0faab24/lib/templates/.config/bash/functions-public.sh.tt#L435) in his dotfiles. I recognize some ranges (this month, yesterday, until last tag), various commit summary functions, and shortcuts for fixups and rebasing. Some of the functions are referenced in his [Alchemists articles](https://alchemists.io/articles), but they way they are stored (along with other customizations) makes them a showcase of personal preferences rather than a reusable library.
