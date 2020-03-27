#!/bin/bash source-this-script
[ "${BASH_VERSION:-}" ] || return

# git-init: invalid function name
_git_initAndCloneExtension()
{
    typeset command=$1
    typeset -r gitCommand="$(which hub || which git)"
    shift

    "$gitCommand" "$command" "$@" || return $?
    if [ $# -gt 0 ]; then
	eval typeset repoOrDir=\${$#}
	typeset dir=${repoOrDir%.git}
	dir=${dir##*/}
	[ -d "$dir" ] || { echo >&2 "Cannot locate working copy; quitting"; return 1; }

	# Feature: Automatically chdir into the created repository. That's why this
	# cannot be a script, and must be a function.
	cd "$dir"
    else
	[ -d .git ] || { echo >&2 "No arguments and not in working copy; quitting"; return 1; }
    fi

    if "$gitCommand" config --system --get core.filemode >/dev/null; then
	# XXX: On init and clone, Git automatically detects if chmod(2) is
	# supported on the current file system and sets the repo-local
	# core.filemode to the corresponding value. Because Cygwin emulates
	# chmod(), git sets core.filemode to true, thereby overturning our
	# system-wide setting done by git-system-setup.
	# Let's fix this by undoing the local config when a system-wide one
	# exists.
	"$gitCommand" config --unset core.filemode
    fi
}
git-init()
{
    _git_initAndCloneExtension init "$@"
}
git-clone()
{
    _git_initAndCloneExtension clone "$@"
}
# Avoids "git remote rename origin upstream".
git-uclone()
{
    _git_initAndCloneExtension clone --origin upstream "$@"
}

git-cd()
{
    typeset root; root="$(git rev-parse --show-toplevel)" || return $?
    cd "${root}/$1"
}
