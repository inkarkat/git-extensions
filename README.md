# Git CLI extensions

These are some personal aliases, shortcuts, and extensions that make (my) work with the [Git distributed version control tool](https://git-scm.com/) easier and faster. Some of them may be specific to my environment and workflow, but maybe someone finds a valuable nugget in there.

### Installation

Download all / some selected extensions (note that some have dependencies, though) and put them somewhere in your `PATH`. You can then invoke them via `git-SUBCOMMAND`; those commands that don't override built-in ones or have case differences can also be invoked via `git SUBCOMMAND` (space instead of hyphen!).

Additionally, the `gitconfig` supplies many aliases and shortcuts. You can mix and match those within your own `.gitconfig`, or import all of it via the following fragment in there:

    [include]
            path = PATH/TO/git-extensions/gitconfig

It is recommended to also use the (Bash, but should also work in Korn shell and Dash) shell functions (e.g. in your `.bashrc`) found at [shell/wrappers.sh](shell/wrappers.sh) to transparently invoke the extensions in the same way as the built-in Git commands, via `git SUBCOMMAND`. It also supports the [hub](https://github.com/github/hub) extension.

The [shell/aliases.sh](shell/aliases.sh) script (also meant to be sourced in `.bashrc`) defined additional (Bash-only) aliases for stuff that cannot be done by an extension script (like automatically changing your current directory).
