#!/bin/bash source-this-script
[ "${BASH_VERSION:-}" ] || return

# git-init: invalid function name
_git_initAndCloneExtension()
{
    typeset command="$1"
    typeset -r gitCommand="$(which hub 2>/dev/null || which git)"
    shift

    "$gitCommand" "$command" "$@" || return $?
    if [ $# -gt 0 ]; then
	typeset repoOrDir="${!#}"
	typeset dir=${repoOrDir%.git}
	[ -d "$dir" ] || \
	    { dir="${dir##*/}"; [ -d "$dir" ]; } || \
	    { echo >&2 'Note: Cannot locate working copy'; return 1; }

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
git-oclone()
{
    if [ $# -eq 0 ]; then
	echo >&2 'ERROR: No REPO-NAME passed.'
	return 2
    fi
    local repoName="$1"; shift
    local me; me="$(git me-in-github)" || return $?
    _git_initAndCloneExtension clone "git@github.com:${me}/${repoName}" "$@"
}
# Avoids "git remote rename origin upstream" and automatically makes upstream
# read-only.
git-uclone()
{
    _git_initAndCloneExtension clone --origin upstream "$@" \
	&& git-remote-setreadonly upstream
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
# sgitbymefiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me.
# sgitbyteamfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# sgitloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitwherelastloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitwherelastchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitwherelasttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitwherefirstloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitwherefirstchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitwherefirsttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   sgitshowfiles='commandOnSelected --generator "git showfiles" --entries'
alias               sgitshowfilesmine='commandOnSelected --generator "git showfilesmine" --entries'
alias               sgitshowfilesteam='commandOnSelected --generator "git showfilesteam" --entries'
alias                   sgitbymefiles='commandOnSelected --generator "git bymefiles" --entries'
alias                 sgitbyteamfiles='commandOnSelected --generator "git byteamfiles" --entries'
alias                   sgitloggfiles='commandOnSelected --generator "git loggfiles" --entries'
alias                sgitchangedfiles='commandOnSelected --generator "git changedfiles" --entries'
alias                sgittouchedfiles='commandOnSelected --generator "git touchedfiles" --entries'
alias          sgitwherelastloggfiles='commandOnSelected --generator "git wherelastloggfiles" --entries'
alias       sgitwherelastchangedfiles='commandOnSelected --generator "git wherelastchangedfiles" --entries'
alias       sgitwherelasttouchedfiles='commandOnSelected --generator "git wherelasttouchedfiles" --entries'
alias         sgitwherefirstloggfiles='commandOnSelected --generator "git wherefirstloggfiles" --entries'
alias      sgitwherefirstchangedfiles='commandOnSelected --generator "git wherefirstchangedfiles" --entries'
alias      sgitwherefirsttouchedfiles='commandOnSelected --generator "git wherefirsttouchedfiles" --entries'

# ygitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range.
# ygitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by me in my last commit.
# ygitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by my team in our last
#			commit.
# ygitbymefiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me.
# ygitbyteamfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# ygitloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitwherelastloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitwherelastchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitwherelasttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitwherefirstloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitwherefirstchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitwherefirsttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   ygitshowfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfiles" --entries'
alias               ygitshowfilesmine='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesmine" --entries'
alias               ygitshowfilesteam='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesteam" --entries'
alias                   ygitbymefiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git bymefiles" --entries'
alias                 ygitbyteamfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git byteamfiles" --entries'
alias              ygitwherelastfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git wherelastfiles" --entries'
alias                   sgitloggfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git loggfiles" --entries'
alias                sgitchangedfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git changedfiles" --entries'
alias                sgittouchedfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git touchedfiles" --entries'
alias          sgitwherelastloggfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git wherelastloggfiles" --entries'
alias       sgitwherelastchangedfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git wherelastchangedfiles" --entries'
alias       sgitwherelasttouchedfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git wherelasttouchedfiles" --entries'
alias         sgitwherefirstloggfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git wherefirstloggfiles" --entries'
alias      sgitwherefirstchangedfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git wherefirstchangedfiles" --entries'
alias      sgitwherefirsttouchedfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git wherefirsttouchedfiles" --entries'

# lgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			View selected files modified in passed commit or commit
#			range with the pager.
# lgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by me in my last commit
#			with the pager.
# lgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by my team in our last
#			commit with the pager.
# lgitbymefiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me with the pager.
# lgitbyteamfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them with the pager.
# lgitloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitwherelastloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitwherelastchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitwherelasttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitwherefirstloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitwherefirstchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitwherefirsttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   lgitshowfiles='commandOnSelected --command "${PAGER:-less}" --generator "git showfiles" --entries'
alias               lgitshowfilesmine='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesmine" --entries'
alias               lgitshowfilesteam='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesteam" --entries'
alias                   lgitbymefiles='commandOnSelected --command "${PAGER:-less}" --generator "git bymefiles" --entries'
alias                 lgitbyteamfiles='commandOnSelected --command "${PAGER:-less}" --generator "git byteamfiles" --entries'
alias                   lgitloggfiles='commandOnSelected --command "${PAGER:-less}" --generator "git loggfiles" --entries'
alias                lgitchangedfiles='commandOnSelected --command "${PAGER:-less}" --generator "git changedfiles" --entries'
alias                lgittouchedfiles='commandOnSelected --command "${PAGER:-less}" --generator "git touchedfiles" --entries'
alias          lgitwherelastloggfiles='commandOnSelected --command "${PAGER:-less}" --generator "git wherelastloggfiles" --entries'
alias       lgitwherelastchangedfiles='commandOnSelected --command "${PAGER:-less}" --generator "git wherelastchangedfiles" --entries'
alias       lgitwherelasttouchedfiles='commandOnSelected --command "${PAGER:-less}" --generator "git wherelasttouchedfiles" --entries'
alias         lgitwherefirstloggfiles='commandOnSelected --command "${PAGER:-less}" --generator "git wherefirstloggfiles" --entries'
alias      lgitwherefirstchangedfiles='commandOnSelected --command "${PAGER:-less}" --generator "git wherefirstchangedfiles" --entries'
alias      lgitwherefirsttouchedfiles='commandOnSelected --command "${PAGER:-less}" --generator "git wherefirsttouchedfiles" --entries'

# vgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in GVIM.
# vgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in my last commit
#			in GVIM.
# vgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in our last
#			commit in GVIM.
# vgitbymefiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me in GVIM.
# vgitbyteamfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them in GVIM.
# vgitloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitwherelastloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitwherelastchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitwherelasttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitwherefirstloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitwherefirstchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitwherefirsttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   vgitshowfiles='commandOnSelected --command SendToGVIM --generator "git showfiles" --entries'
alias               vgitshowfilesmine='commandOnSelected --command SendToGVIM --generator "git showfilesmine" --entries'
alias               vgitshowfilesteam='commandOnSelected --command SendToGVIM --generator "git showfilesteam" --entries'
alias                   vgitbymefiles='commandOnSelected --command SendToGVIM --generator "git bymefiles" --entries'
alias                 vgitbyteamfiles='commandOnSelected --command SendToGVIM --generator "git byteamfiles" --entries'
alias              vgitwherelastfiles='commandOnSelected --command SendToGVIM --generator "git wherelastfiles" --entries'
alias                   vgitloggfiles='commandOnSelected --command SendToGVIM --generator "git loggfiles" --entries'
alias                vgitchangedfiles='commandOnSelected --command SendToGVIM --generator "git changedfiles" --entries'
alias                vgittouchedfiles='commandOnSelected --command SendToGVIM --generator "git touchedfiles" --entries'
alias          vgitwherelastloggfiles='commandOnSelected --command SendToGVIM --generator "git wherelastloggfiles" --entries'
alias       vgitwherelastchangedfiles='commandOnSelected --command SendToGVIM --generator "git wherelastchangedfiles" --entries'
alias       vgitwherelasttouchedfiles='commandOnSelected --command SendToGVIM --generator "git wherelasttouchedfiles" --entries'
alias         vgitwherefirstloggfiles='commandOnSelected --command SendToGVIM --generator "git wherefirstloggfiles" --entries'
alias      vgitwherefirstchangedfiles='commandOnSelected --command SendToGVIM --generator "git wherefirstchangedfiles" --entries'
alias      vgitwherefirsttouchedfiles='commandOnSelected --command SendToGVIM --generator "git wherefirsttouchedfiles" --entries'

# vimgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in Vim.
# vimgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in my last commit
#			in Vim.
# vimgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in our last
#			commit in Vim.
# vimgitbymefiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me in Vim.
# vimgitbyteamfiles [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them in Vim.
# vimgitloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitwherelastloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitwherelastchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitwherelasttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitwherefirstloggfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitwherefirstchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitwherefirsttouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   vimgitshowfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfiles" --entries'
alias               vimgitshowfilesmine='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesmine" --entries'
alias               vimgitshowfilesteam='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesteam" --entries'
alias                   vimgitbymefiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git bymefiles" --entries'
alias                 vimgitbyteamfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git byteamfiles" --entries'
alias              vimgitwherelastfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git wherelastfiles" --entries'
alias                   vimgitloggfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git loggfiles" --entries'
alias                vimgitchangedfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git changedfiles" --entries'
alias                vimgittouchedfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git touchedfiles" --entries'
alias          vimgitwherelastloggfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git wherelastloggfiles" --entries'
alias       vimgitwherelastchangedfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git wherelastchangedfiles" --entries'
alias       vimgitwherelasttouchedfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git wherelasttouchedfiles" --entries'
alias         vimgitwherefirstloggfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git wherefirstloggfiles" --entries'
alias      vimgitwherefirstchangedfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git wherefirstchangedfiles" --entries'
alias      vimgitwherefirsttouchedfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git wherefirsttouchedfiles" --entries'



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
#			Print selected unversioned filespecs that are not under
#			source control in the current directory and below.
alias sgitlsprivate='commandOnSelected --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# ygitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			Yank selected unversioned filespecs that are not under
#			source control in the current directory and below.
alias ygitlsprivate='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# lgitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			View selected unversioned files that are not under
#			source control in the current directory and below with
#			the pager.
alias lgitlsprivate='commandOnSelected --command "${PAGER:-less}" --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# vgitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			Edit selected unversioned files that are not under
#			source control in the current directory and below in
#			GVIM.
alias vgitlsprivate='commandOnSelected --command SendToGVIM --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# vimgitlsprivate [-X|--orphaned-submodules] [-x] [<path>] [-- SELECTIONs ...]
#			Edit selected unversioned files that are not under
#			source control in the current directory and below in
#			Vim.
alias vimgitlsprivate='commandOnSelected --command '"${_aliases_vim}"' --generator "git-lsprivate --long --ignore-empty-directories" --entries'



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



# sgitstIfiles [<path>] [-- SELECTIONs ...]
#			Print selected modified but not staged filespecs.
alias sgitstIfiles='commandOnSelected --generator "git-stIfiles" --entries'

# ygitstIfiles [<path>] [-- SELECTIONs ...]
#			Yank selected modified but not staged filespecs.
alias ygitstIfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-stIfiles" --entries'

# lgitstIfiles [<path>] [-- SELECTIONs ...]
#			View selected modified but not staged files with the
#			pager.
alias lgitstIfiles='commandOnSelected --command "${PAGER:-less}" --generator "git-stIfiles" --entries'

# vgitstIfiles [<path>] [-- SELECTIONs ...]
#			Edit selected modified but not staged files in GVIM.
alias vgitstIfiles='commandOnSelected --command SendToGVIM --generator "git-stIfiles" --entries'

# vimgitstIfiles [<path>] [-- SELECTIONs ...]
#			Edit selected modified but not staged files in Vim.
alias vimgitstIfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git-stIfiles" --entries'



# sgitstuntracked [<path>] [-- SELECTIONs ...]
#			Print selected new files not yet added to version
#			control.
alias sgitstuntracked='commandOnSelected --generator "git stuntracked" --entries'

# ygitstuntracked [<path>] [-- SELECTIONs ...]
#			Yank selected new files not yet added to version
#			control.
alias ygitstuntracked='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git stuntracked" --entries'

# lgitstuntracked [<path>] [-- SELECTIONs ...]
#			View selected new files not yet added to version
#			control.
alias lgitstuntracked='commandOnSelected --command "${PAGER:-less}" --generator "git stuntracked" --entries'

# vgitstuntracked [<path>] [-- SELECTIONs ...]
#			Edit selected new files not yet added to version
#			control.
alias vgitstuntracked='commandOnSelected --command SendToGVIM --generator "git stuntracked" --entries'

# vimgitstuntracked [<path>] [-- SELECTIONs ...]
#			Edit selected new files not yet added to version
#			control.
alias vimgitstuntracked='commandOnSelected --command '"${_aliases_vim}"' --generator "git stuntracked" --entries'



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
