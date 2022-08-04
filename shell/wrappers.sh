#!/bin/sh source-this-script

# Git supports aliases defined in .gitconfig, but you cannot override Git
# builtins (e.g. "git log") by putting an executable "git-log" somewhere in the
# PATH. Also, git aliases are case-insensitive, but case can be useful to create
# a negated command (gf = grep --files-with-matches; gF = grep
# --files-without-match). As a workaround, translate "X" to "-x".
# Add support for the "hub" extension. As this messes with the completion for
# git, anyway, follow their advice and alias git=hub (adapted to my wrapper).
git()
{
    typeset gitSubAlias="git-$1-$2"
    typeset gitAlias="git-$1"
    typeset gitCommand="$(which hub 2>/dev/null || which git)"
    if [ $# -eq 0 ]; then
	command git ${GIT_DEFAULT_COMMAND:-str}
    elif type ${BASH_VERSION:+-t} "$gitSubAlias" >/dev/null 2>&1; then
	shift; shift
	$gitSubAlias "$@"
    elif type ${BASH_VERSION:+-t} "$gitAlias" >/dev/null 2>&1; then
	shift
	$gitAlias "$@"
    else
	case "$1" in
	    [!-]*[A-Z]*)
		# Translate "X" to "-x" to enable aliases with uppercase letters.
		typeset translatedAlias="$(echo "$1" | sed -e 's/[[:upper:]]/-\l\0/g')"
		shift
		"$gitCommand" "$translatedAlias" "$@"
		;;
	    *)
		"$gitCommand" "$@";;
	esac
    fi
}

which hub >/dev/null 2>&1 || return
hub()
{
    typeset hubSubAlias="hub-$1-$2"
    typeset hubAlias="hub-$1"
    if [ $# -eq 0 ]; then
	HUB=t command hub ${HUB_DEFAULT_COMMAND:-str}
    elif type ${BASH_VERSION:+-t} "$hubSubAlias" >/dev/null 2>&1; then
	shift; shift
	HUB=t $hubSubAlias "$@"
    elif type ${BASH_VERSION:+-t} "$hubAlias" >/dev/null 2>&1; then
	shift
	HUB=t $hubAlias "$@"
    else
	HUB=t command hub "$@"
    fi
}
