#!/bin/sh source-this-script

if type ${BASH_VERSION:+-t} __git_ps1 >/dev/null 2>&1; then
    # Git's GIT_PS1_DESCRIBE_STYLE='branch' will print a tag even if a
    # corresponding branch exists. Let's patch the function (as it's too
    # large and complex to reimplement) to use my git-brname instead.
    # Note: Use --raw because the function will wrap in (...) if necessary
    # on its own.
    functionmodify -e 's#git describe --contains --all HEAD#git-brname --detached-effective-branch --include-remote-branches --raw HEAD#' __git_ps1

    _PS1RCS_Git()
    {
	# XXX: __git_ps1 (in Ubuntu 16.04 LTS) references ZSH_VERSION; this causes errors with "set -u". As setting this also affects escaping (% is doubled as %%), only enable the workaround if necessary.
	case "$-" in
	    *u*)  : ${ZSH_VERSION=};;
	esac

	# Configuration. Cp. /usr/lib/git-core/git-sh-prompt
	# `*`: unstaged changes
	# `+`: staged changes
	# `$`: something is stashed
	# `%`: untracked files
	# `<`: you are behind
	# `>`: you are ahead
	# `<>`:you have diverged
	# `=`: you are up-to-date; is no difference
	typeset GIT_PS1_DESCRIBE_STYLE='branch'	# show detached checkout as relative to newer tag or branch (master~4)
	typeset GIT_PS1_SHOWDIRTYSTATE=t		# unstaged (*) and staged (+) changes will be shown
	typeset GIT_PS1_SHOWSTASHSTATE=t		# if something is stashed, then a '$' will be shown next to the branch name
	typeset GIT_PS1_SHOWUNTRACKEDFILES=t	# a '%' will be shown next to the branch name
	typeset GIT_PS1_SHOWUPSTREAM='auto git'	# A "<" indicates you are behind, ">" indicates you are ahead, "<>" indicates you have diverged and "=" indicates that there is no difference.

	__git_ps1 'git:%s' 2>/dev/null
    }
fi

_PS1GitRepoChange()
{
    typeset gitRoot="$(git root 2>/dev/null)"
    if [ "${_PS1GitRoot:-}" != "$gitRoot" ]; then
	[ -n "${_PS1GitRoot:-}" ] && _PS1PreviousGitRoot="$_PS1GitRoot" || unset _PS1PreviousGitRoot
	if [ "$gitRoot" ]; then
	    export _PS1GitRoot="$gitRoot"
	    eval "${_PS1OnGitRepoEnter:-}"	# Triggered when entering a (different) Git repo.
	    if [ -z "${_PS1PreviousExistingGitRoot+t}" ] || [ "$_PS1PreviousExistingGitRoot" != "$gitRoot" ]; then
		eval "${_PS1OnGitRepoChange:-}" # Triggered when moving into the first and then to another Git repo, ignores changes to non-Git paths.
		_PS1PreviousExistingGitRoot="$gitRoot"
	    fi
	else
	    unset _PS1GitRoot
	    eval "${_PS1OnGitRepoLeave:-}"	# Triggered when leaving a Git repo for a non-Git path.
	fi
	unset _PS1PreviousGitRoot
    fi
}
commandSequenceMunge _PS1OnChangeDirectory _PS1GitRepoChange

_PS1GitUpdateDate()
{
    typeset gitUpdateDate; gitUpdateDate="$(git-syncdate --verbose origin upstream 2>/dev/null)" || return
    _PS1Message "${gitUpdateDate}"
}
commandSequenceMunge _PS1OnGitRepoChange _PS1GitUpdateDate
