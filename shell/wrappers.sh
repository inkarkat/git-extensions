#!/bin/sh source-this-script

[ "${BASH_VERSION:-}" -o "${KSH_VERSION:-}" ] || return

: ${GIT_DEFAULT_COMMAND=str}
: ${HUB_DEFAULT_COMMAND=$GIT_DEFAULT_COMMAND}

# Git supports aliases defined in .gitconfig, but you cannot override Git
# builtins (e.g. "git log") by putting an executable "git-log" somewhere in the
# PATH. Also, git aliases are case-insensitive, but case can be useful to create
# a negated command (gf = grep --files-with-matches; gF = grep
# --files-without-match). As a workaround, translate "X" to "-x".
# Add support for the "hub" extension. As this messes with the completion for
# git, anyway, follow their advice and alias git=hub (adapted to my wrapper).
git()
{
    typeset -a gitConfigArgs=()
    while [ $# -ne 0 ]
    do
	case "$1" in
	    -c) gitConfigArgs+=("$1" "$2"); shift; shift;;
	    *)  break;;
	esac
    done
    # If there's no alias we can simply pass gitConfigArgs directly after the "git"
    # command. Aliases however need to do this on their own (if their Git command(s)
    # need to react to config overrides). We can just pass the arguments along here.
    GIT_CONFIG_ARGS=; [ ${#gitConfigArgs[@]} -gt 0 ] && printf -v GIT_CONFIG_ARGS '%q ' "${gitConfigArgs[@]}"; export GIT_CONFIG_ARGS

    typeset gitSubAlias="git-$1-$2"
    typeset gitAlias="git-$1"
    typeset gitCommand="$(which hub 2>/dev/null || which git)"
    if [ $# -eq 0 -a -n "$GIT_DEFAULT_COMMAND" ]; then
	eval "git \"\${gitConfigArgs[@]}\" $GIT_DEFAULT_COMMAND"
    elif type ${BASH_VERSION:+-t} "$gitSubAlias" >/dev/null 2>&1; then
	shift; shift
	eval $gitSubAlias '"$@"'	# Need eval for shell aliases.
    elif type ${BASH_VERSION:+-t} "$gitAlias" >/dev/null 2>&1; then
	shift
	eval $gitAlias '"$@"'	# Need eval for shell aliases.
    else
	case "$1" in
	    [!-]*[A-Z]*)
		# Translate "X" to "-x" to enable aliases with uppercase letters.
		typeset translatedAlias="$(echo "$1" | sed -e 's/[[:upper:]]/-\l\0/g')"
		shift
		"$gitCommand" "${gitConfigArgs[@]}" "$translatedAlias" "$@"
		;;
	    *)
		"$gitCommand" "${gitConfigArgs[@]}" "$@";;
	esac
    fi
}

which hub >/dev/null 2>&1 && \
hub()
{
    typeset -a gitConfigArgs=()
    while [ $# -ne 0 ]
    do
	case "$1" in
	    -c) gitConfigArgs+=("$1" "$2"); shift; shift;;
	    *)  break;;
	esac
    done
    # If there's no alias we can simply pass gitConfigArgs directly after the "git"
    # command. Aliases however need to do this on their own (if their Git command(s)
    # need to react to config overrides). We can just pass the arguments along here.
    GIT_CONFIG_ARGS=; [ ${#gitConfigArgs[@]} -gt 0 ] && printf -v GIT_CONFIG_ARGS '%q ' "${gitConfigArgs[@]}"; export GIT_CONFIG_ARGS

    typeset hubSubAlias="hub-$1-$2"
    typeset hubAlias="hub-$1"
    typeset gitSubAlias="git-$1-$2"
    typeset gitAlias="git-$1"
    if [ $# -eq 0 ]; then
	HUB=t eval "hub \"\${gitConfigArgs[@]}\" $HUB_DEFAULT_COMMAND"
    elif type ${BASH_VERSION:+-t} "$hubSubAlias" >/dev/null 2>&1; then
	shift; shift
	HUB=t eval $hubSubAlias '"$@"'	# Need eval for shell aliases.
    elif type ${BASH_VERSION:+-t} "$hubAlias" >/dev/null 2>&1; then
	shift
	HUB=t eval $hubAlias '"$@"'	# Need eval for shell aliases.
    elif contains "$1" am apply checkout cherry-pick clone fetch init merge push remote submodule alias api browse ci-status compare create delete fork gist issue pr pull-request release sync; then
	# Built-in hub commands need to have precedence over git-alias with the same name (e.g. "hub browse" over git-browse).
	HUB=t command hub "${gitConfigArgs[@]}" "$@"
    elif type ${BASH_VERSION:+-t} "$gitSubAlias" >/dev/null 2>&1; then
	shift; shift
	HUB=t $gitSubAlias "$@"
    elif type ${BASH_VERSION:+-t} "$gitAlias" >/dev/null 2>&1; then
	shift
	HUB=t eval $gitAlias '"$@"'	# Need eval for shell aliases.
    else
	HUB=t command hub "${gitConfigArgs[@]}" "$@"
    fi
}

which gh >/dev/null 2>&1 && \
gh()
{
    typeset ghSubAlias="gh-$1-$2"
    typeset ghAlias="gh-$1"
    if [ $# -eq 0 ]; then
	gh ${GH_DEFAULT_COMMAND:-}
    elif type ${BASH_VERSION:+-t} "$ghSubAlias" >/dev/null; then
	shift; shift
	$ghSubAlias "$@"
    elif type ${BASH_VERSION:+-t} "$ghAlias" >/dev/null; then
	shift
	$ghAlias "$@"
    else
	command gh "$@"
    fi
}
