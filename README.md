# Git CLI extensions

These are some personal aliases, shortcuts, and extensions that make (my) work with the [Git distributed version control tool](https://git-scm.com/) easier and faster. Some of them may be specific to my environment and workflow, but maybe someone finds a valuable nugget in there.

Use the following (Bash) shell function to invoke the extensions in the same way as the built-in Git commands, via `git SUBCOMMAND`:

    # Git supports aliases defined in .gitconfig, but you cannot override Git
    # builtins (e.g. "git log") by putting an executable "git-log" somewhere in the
    # PATH. Also, git aliases are case-insensitive, but case can be useful to create
    # a negated command (gf = grep --files-with-matches; gF = grep
    # --files-without-match). As a workaround, translate "X" to "-x".
    exists git && git() {
        typeset -r gitAlias="git-$1"
        typeset -r gitCommand="$(which git)"
        if [ $# -eq 0 ]; then
            git ${GIT_DEFAULT_COMMAND:-st}
        elif type -t "$gitAlias" >/dev/null; then
            shift
            eval $gitAlias '"$@"'
        elif [ "$1" = "${1#-}" ] && expr "$1" : '.*[[:upper:]]' >/dev/null; then
            # Translate "X" to "-x" to enable aliases with uppercase letters.
            translatedAlias=$(echo "$1" | sed -e 's/[[:upper:]]/-\l\0/g')
            shift
            "$gitCommand" "$translatedAlias" "$@"
        else
            "$gitCommand" "$@"
        fi
    }

Here is a variant that also adds support for the [hub](https://github.com/github/hub) extension:

    # Git supports aliases defined in .gitconfig, but you cannot override Git
    # builtins (e.g. "git log") by putting an executable "git-log" somewhere in the
    # PATH. Also, git aliases are case-insensitive, but case can be useful to create
    # a negated command (gf = grep --files-with-matches; gF = grep
    # --files-without-match). As a workaround, translate "X" to "-x".
    # Add support for the "hub" extension. As this messes with the completion for
    # git, anyway, follow their advice and alias git=hub (adapted to my wrapper).
    exists git && git() {
        typeset -r gitAlias="git-$1"
        typeset -r gitCommand="$(which hub || which git)"
        if [ $# -eq 0 ]; then
            git ${GIT_DEFAULT_COMMAND:-st}
        elif type -t "$gitAlias" >/dev/null; then
            shift
            eval $gitAlias '"$@"'
        elif [ "$1" = "${1#-}" ] && expr "$1" : '.*[[:upper:]]' >/dev/null; then
            # Translate "X" to "-x" to enable aliases with uppercase letters.
            translatedAlias=$(echo "$1" | sed -e 's/[[:upper:]]/-\l\0/g')
            shift
            "$gitCommand" "$translatedAlias" "$@"
        else
            "$gitCommand" "$@"
        fi
}

The following function also allows extending the `hub` command (in a different way than what the forwarded-to `git` command would offer, e.g. to have both `git-cheat` and `hub-cheat`):

    exists hub && hub() {
        typeset -r hubAlias="hub-$1"
        if [ $# -eq 0 ]; then
            hub ${HUB_DEFAULT_COMMAND:-st}
        elif type -t "$hubAlias" >/dev/null; then
            shift
            eval $hubAlias '"$@"'
        else
            command hub "$@"
        fi
    }
