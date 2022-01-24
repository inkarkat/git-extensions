#!/bin/bash source-this-script
[ "${BASH_VERSION:-}" ] || return

# git-init: invalid function name
_git_initAndCloneExtension()
{
    typeset command=$1
    typeset -r gitCommand="$(which hub 2>/dev/null || which git)"
    shift

    "$gitCommand" "$command" "$@" || return $?
    if [ $# -gt 0 ]; then
	eval "typeset repoOrDir=\${$#}"
	typeset dir=${repoOrDir%.git}
	[ -d "$dir" ] || { echo >&2 'Note: Cannot locate working copy'; return 1; }

	# Feature: Automatically chdir into the created repository. That's why this
	# cannot be a script, and must be a function.
	cd "$dir"
    else
	[ -d .git ] || { echo >&2 'Note: No arguments and not in working copy'; return 1; }
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
    typeset -a gitInitArgs=()
    typeset isForce=
    while [ $# -ne 0 ]
    do
	case "$1" in
	    --force|-f)	shift; isForce=t;;
	    -q)		gitInitArgs+=("$1"); shift;;
	    --quiet|--bare)
			gitInitArgs+=("$1"); shift;;
	    --template=*|--separate-git-dir=*|--shared=*)
			gitInitArgs+=("$1"); shift;;
	    --template|--separate-git-dir|--shared)
			gitInitArgs+=("$1" "$2"); shift; shift;;
	    --)		gitInitArgs+=("$1"); shift; break;;
	    *)		break;;
	esac
    done

    if [ $# -eq 1 ] && [ ! -e "$1" ]; then
	# DIRECTORY is passed, and it does not exist yet. If it is inside the
	# current directory, ensure that it won't be created inside a Git repo,
	# as this likely is a user error.
	typeset directory="${1%/}"
	if case "$directory" in
	    ../*)   false;;
	    /*)	    [ "${directory:0:$((${#PWD} + 1))}" = "${PWD}/" ];;
	esac; then
	    typeset existingRepoRootDir
	    if existingRepoRootDir="$(git root 2>/dev/null)"; then
		if [ "$isForce" ]; then
		    printf >&2 'Note: The new Git repository %s lies within the existing %s repo.\n' "${directory%/}" "$existingRepoRootDir"
		else
		    printf >&2 'ERROR: Will not create a Git repository within the existing %s repo; use -f|--force to override.\n' "$existingRepoRootDir"
		    return 1
		fi
	    fi
	fi
    fi

    _git_initAndCloneExtension init "${gitInitArgs[@]}" "$@"
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


# sgitls [DIR ...] [-- SELECTIONs ...]
#			Print selected filespecs that are under source control
#			in the passed / current directory.
# sgitlsr [DIR ...] [-- SELECTIONs ...]
#			Print selected filespecs that are under source control
#			in the passed / current directory and below.
# sgitlll [-r|--recursive] [DIR ...] [-- SELECTIONs ...]
#			Print selected filespecs that are under source control
#			with relative paths [to DIR] from the working copy's
#			root.
alias  sgitls='commandOnSelected --generator "git-ls --only-files" --entries'
alias sgitlsr='commandOnSelected --generator "git-ls --recursive --only-files" --entries'
alias sgitlll='commandOnSelected --generator "git-lll --only-files" --entries'

# ygitls [DIR ...] [-- SELECTIONs ...]
#			Yank selected filespecs that are under source control
#			in the passed / current directory.
# ygitlsr [DIR ...] [-- SELECTIONs ...]
#			Yank selected filespecs that are under source control
#			in the passed / current directory and below.
# ygitlll [-r|--recursive] [DIR ...] [-- SELECTIONs ...]
#			Yank selected filespecs that are under source control
#			with relative paths [to DIR] from the working copy's
#			root.
alias  ygitls='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-ls --only-files" --entries'
alias ygitlsr='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-ls --recursive --only-files" --entries'
alias ygitlll='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-lll --only-files" --entries'

# lgitls [DIR ...] [-- SELECTIONs ...]
#			View selected files that are under source control in the
#			passed / current directory with the pager.
# lgitlsr [DIR ...] [-- SELECTIONs ...]
#			View selected files that are under source control in the
#			passed / current directory and below with the pager.
# lgitlll [-r|--recursive] [DIR ...] [-- SELECTIONs ...]
#			View selected files that are under source control with
#			relative paths [to DIR] from the working copy's root
#			with the pager.
alias  lgitls='commandOnSelected --command "${PAGER:-less}" --generator "git-ls --only-files" --entries'
alias lgitlsr='commandOnSelected --command "${PAGER:-less}" --generator "git-ls --recursive --only-files" --entries'
alias lgitlll='commandOnSelected --command "${PAGER:-less}" --generator "git-lll --only-files" --entries'

# vgitls [DIR ...] [-- SELECTIONs ...]
#			Edit selected files that are under source control in the
#			passed / current directory in GVIM.
# vgitlsr [DIR ...] [-- SELECTIONs ...]
#			Edit selected files that are under source control in the
#			passed / current directory and below in GVIM.
# vgitlll [-r|--recursive] [DIR ...] [-- SELECTIONs ...]
#			Edit selected files that are under source control with
#			relative paths [to DIR] from the working copy's root in
#			GVIM.
alias  vgitls='commandOnSelected --command SendToGVIM --generator "git-ls --only-files" --entries'
alias vgitlsr='commandOnSelected --command SendToGVIM --generator "git-ls --recursive --only-files" --entries'
alias vgitlll='commandOnSelected --command SendToGVIM --generator "git-lll --only-files" --entries'

# vimgitls [DIR ...] [-- SELECTIONs ...]
#			Edit selected files that are under source control in the
#			passed / current directory in Vim.
# vimgitlsr [DIR ...] [-- SELECTIONs ...]
#			Edit selected files that are under source control in the
#			passed / current directory and below in Vim.
# vimgitlll [-r|--recursive] [DIR ...] [-- SELECTIONs ...]
#			Edit selected files that are under source control with
#			relative paths [to DIR] from the working copy's root in
#			Vim.
alias  vimgitls='commandOnSelected --command '"${_aliases_vim}"' --generator "git-ls --only-files" --entries'
alias vimgitlsr='commandOnSelected --command '"${_aliases_vim}"' --generator "git-ls --recursive --only-files" --entries'
alias vimgitlll='commandOnSelected --command '"${_aliases_vim}"' --generator "git-lll --only-files" --entries'



# sgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified in passed commit or
#			commit range.
# sgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by me in my last commit.
# sgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by my team in our last
#			commit.
# sgitbymeshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me.
# sgitbyteamshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# sgitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Print selected filespecs modified in passed commit or
#			commit range where text or /regexp/ was added or
#			removed.
# sgitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Print selected filespecs modified in passed commit or
#			commit range where lines were modified where text or
#			/regexp/ appears.
alias        sgitshowfiles='commandOnSelected --generator "git showfiles" --entries'
alias    sgitshowfilesmine='commandOnSelected --generator "git showfilesmine" --entries'
alias    sgitshowfilesteam='commandOnSelected --generator "git showfilesteam" --entries'
alias    sgitbymeshowfiles='commandOnSelected --generator "git bymeshowfiles" --entries'
alias  sgitbyteamshowfiles='commandOnSelected --generator "git byteamshowfiles" --entries'
alias    sgitshowfilesfind='commandOnSelected --generator "git showfilesfind" --entries'
alias sgitshowfilestouched='commandOnSelected --generator "git showfilestouched" --entries'

# ygitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range.
# ygitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by me in my last commit.
# ygitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by my team in our last
#			commit.
# ygitbymeshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me.
# ygitbyteamshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# ygitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range where text or /regexp/ was added or
#			removed.
# ygitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range where lines were modified where text or
#			/regexp/ appears.
alias        ygitshowfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfiles" --entries'
alias    ygitshowfilesmine='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesmine" --entries'
alias    ygitshowfilesteam='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesteam" --entries'
alias    ygitbymeshowfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git bymeshowfiles" --entries'
alias  ygitbyteamshowfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git byteamshowfiles" --entries'
alias    ygitshowfilesfind='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesfind" --entries'
alias ygitshowfilestouched='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilestouched" --entries'

# lgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			View selected files modified in passed commit or commit
#			range with the pager.
# lgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by me in my last commit
#			with the pager.
# lgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by my team in our last
#			commit with the pager.
# lgitbymeshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me with the pager.
# lgitbyteamshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them with the pager.
# lgitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			View selected files modified in passed commit or commit
#			range where text or /regexp/ was added or removed with
#			the pager.
# lgitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			View selected files modified in passed commit or commit
#			range where lines were modified where text or /regexp/
#			appears with the pager.
alias        lgitshowfiles='commandOnSelected --command "${PAGER:-less}" --generator "git showfiles" --entries'
alias    lgitshowfilesmine='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesmine" --entries'
alias    lgitshowfilesteam='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesteam" --entries'
alias    lgitbymeshowfiles='commandOnSelected --command "${PAGER:-less}" --generator "git bymeshowfiles" --entries'
alias  lgitbyteamshowfiles='commandOnSelected --command "${PAGER:-less}" --generator "git byteamshowfiles" --entries'
alias    lgitshowfilesfind='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesfind" --entries'
alias lgitshowfilestouched='commandOnSelected --command "${PAGER:-less}" --generator "git showfilestouched" --entries'

# vgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in GVIM.
# vgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in my last commit
#			in GVIM.
# vgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in our last
#			commit in GVIM.
# vgitbymeshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me in GVIM.
# vgitbyteamshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them in GVIM.
# vgitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range where text or /regexp/ was added or removed in
#			GVIM.
# vgitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range where lines were modified where text or /regexp/
#			appears in GVIM.
alias        vgitshowfiles='commandOnSelected --command SendToGVIM --generator "git showfiles" --entries'
alias    vgitshowfilesmine='commandOnSelected --command SendToGVIM --generator "git showfilesmine" --entries'
alias    vgitshowfilesteam='commandOnSelected --command SendToGVIM --generator "git showfilesteam" --entries'
alias    vgitbymeshowfiles='commandOnSelected --command SendToGVIM --generator "git bymeshowfiles" --entries'
alias  vgitbyteamshowfiles='commandOnSelected --command SendToGVIM --generator "git byteamshowfiles" --entries'
alias    vgitshowfilesfind='commandOnSelected --command SendToGVIM --generator "git showfilesfind" --entries'
alias vgitshowfilestouched='commandOnSelected --command SendToGVIM --generator "git showfilestouched" --entries'

# vimgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in Vim.
# vimgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in my last commit
#			in Vim.
# vimgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in our last
#			commit in Vim.
# vimgitbymeshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me in Vim.
# vimgitbyteamshowfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them in Vim.
# vimgitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range where text or /regexp/ was added or removed in
#			Vim.
# vimgitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range where lines were modified where text or /regexp/
#			appears in Vim.
alias        vimgitshowfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfiles" --entries'
alias    vimgitshowfilesmine='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesmine" --entries'
alias    vimgitshowfilesfind='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesfind" --entries'
alias vimgitshowfilestouched='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilestouched" --entries'



# sgitconflicts [DIR ...] [-- SELECTIONs ...]
#			Print selected filespecs with conflicts.
alias sgitconflicts='commandOnSelected --generator "git-conflicts" --entries'

# ygitconflicts [DIR ...] [-- SELECTIONs ...]
#			Yank selected filespecs with conflicts.
alias ygitconflicts='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-conflicts" --entries'

# lgitconflicts [DIR ...] [-- SELECTIONs ...]
#			View selected files with conflicts with the pager.
alias lgitconflicts='commandOnSelected --command "${PAGER:-less}" --generator "git-conflicts" --entries'

# vgitconflicts [DIR ...] [-- SELECTIONs ...]
#			Edit selected files with conflicts in GVIM.
alias vgitconflicts='commandOnSelected --command SendToGVIM --generator "git-conflicts" --entries'

# vimgitconflicts [DIR ...] [-- SELECTIONs ...]
#			Edit selected files with conflicts in Vim.
alias vimgitconflicts='commandOnSelected --command '"${_aliases_vim}"' --generator "git-conflicts" --entries'



# sgitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			Print selected filespecs that are under source control
#			in the current directory and below.
alias sgitlsprivate='commandOnSelected --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# ygitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			Yank selected filespecs that are under source control
#			in the current directory and below.
alias ygitlsprivate='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# lgitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			View selected files that are under source control in the
#			current directory and below with the pager.
alias lgitlsprivate='commandOnSelected --command "${PAGER:-less}" --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# vgitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			Edit selected files that are under source control in the
#			current directory and below in GVIM.
alias vgitlsprivate='commandOnSelected --command SendToGVIM --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# vimgitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			Edit selected files that are under source control in the
#			current directory and below in Vim.
alias vimgitlsprivate='commandOnSelected --command '"${_aliases_vim}"'
--generator "git-lsprivate --long --ignore-empty-directories" --entries'



# sgitstfiles [<path>] [-- SELECTIONs ...] Print selected changed filespecs.
alias sgitstfiles='commandOnSelected --generator "git-stfiles" --entries'

# ygitstfiles [<path>] [-- SELECTIONs ...] Yank selected changed filespecs.
alias ygitstfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-stfiles" --entries'

# lgitstfiles [<path>] [-- SELECTIONs ...]
#			View selected changed files with the pager.
alias lgitstfiles='commandOnSelected --command "${PAGER:-less}" --generator "git-stfiles" --entries'

# vgitstfiles [<path>] [-- SELECTIONs ...]
#			Edit selected changed files in GVIM.
alias vgitstfiles='commandOnSelected --command SendToGVIM --generator "git-stfiles" --entries'

# vimgitstfiles [<path>] [-- SELECTIONs ...]
#			Edit selected changed files in Vim.
alias vimgitstfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git-stfiles" --entries'



# sgitstifiles [<path>] [-- SELECTIONs ...]
#			Print selected staged filespecs.
alias sgitstifiles='commandOnSelected --generator "git-stifiles" --entries'

# ygitstifiles [<path>] [-- SELECTIONs ...]
#			Yank selected staged filespecs.
alias ygitstifiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-stifiles" --entries'

# lgitstifiles [<path>] [-- SELECTIONs ...]
#			View selected staged files with the pager.
alias lgitstifiles='commandOnSelected --command "${PAGER:-less}" --generator "git-stifiles" --entries'

# vgitstifiles [<path>] [-- SELECTIONs ...]
#			Edit selected staged files in GVIM.
alias vgitstifiles='commandOnSelected --command SendToGVIM --generator "git-stifiles" --entries'

# vimgitstifiles [<path>] [-- SELECTIONs ...]
#			Edit selected staged files in Vim.
alias vimgitstifiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git-stifiles" --entries'



# sgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs that match PATTERN.
# sgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs that do not match PATTERN.
alias sgitgf='commandOnSelected --generator "git gf" --entries'
alias sgitgF='commandOnSelected --generator "git g-f" --entries'

# ygitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs that match PATTERN.
# ygitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs that do not match PATTERN.
alias ygitgf='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git gf" --entries'
alias ygitgF='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git g-f" --entries'

# lgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			View selected files that match PATTERN with the pager.
# lgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			View selected files that do not match PATTERN with the
#			pager.
alias lgitgf='commandOnSelected --command "${PAGER:-less}" --generator "git gf" --entries'
alias lgitgF='commandOnSelected --command "${PAGER:-less}" --generator "git g-f" --entries'

# vgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			Edit selected files that match PATTERN in GVIM.
# vgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			Edit selected files that do not match PATTERN in GVIM.
alias vgitgf='commandOnSelected --command SendToGVIM --generator "git gf" --entries'
alias vgitgF='commandOnSelected --command SendToGVIM --generator "git g-f" --entries'

# vimgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			Edit selected files that match PATTERN in Vim.
# vimgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<path> ...] [-- SELECTIONs ...]
#			Edit selected files that do not match PATTERN in Vim.
alias vimgitgf='commandOnSelected --command '"${_aliases_vim}"' --generator "git gf" --entries'
alias vimgitgF='commandOnSelected --command '"${_aliases_vim}"' --generator "git g-f" --entries'
