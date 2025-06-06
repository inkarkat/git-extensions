#!/bin/bash source-this-script
[ "${BASH_VERSION:-}" ] || return   # Korn Shell complains: git-init: invalid function name

_git_initAndCloneExtension()
{
    typeset subCommand="$1"; shift
    typeset -r gitCommand="$(which hub 2>/dev/null || which git)"

    typeset externalGitBaseDirspec="${GIT_INIT_EXTERNAL_BASEDIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/gitdirs}"

    typeset isExternalGitDir=
    typeset -a gitArgs=()
    typeset -a gitCloneArgs=()
    typeset isForce=
    while [ $# -ne 0 ]
    do
	case "$1" in
	    --help|-h|-\?)
			shift
			$gitCommand help "$subCommand" 2>&1 | sed \
			    -e '/ \[--separate-git-dir /i\
		[--external-git-dir]' \
			    -e "/^ *--separate-git-dir=/i\\
       --external-git-dir\\
	   Externalize the Git metadata under\\
	       ${externalGitBaseDirspec}/<working-copy-name>\\
	   This is useful when the working copy is on a slow network share or\\
	   under the control of another content management system.\\
"
			return 0
			;;
	    --force|-f)	shift; isForce=t;;

	    # DWIM: Syntactic sugar around --separate-git-dir that automatically chooses the
	    # storage location.
	    --external-git-dir)
			shift; isExternalGitDir=t;;

	    -q)		gitArgs+=("$1"); shift;;
	    --quiet|--bare)
			gitArgs+=("$1"); shift;;
	    --template=*|--separate-git-dir=*|--object-format=*|--ref-format=*|--initial-branch=*|--shared=*)
			gitArgs+=("$1"); shift;;
	    --template|--separate-git-dir|--object-format|--ref-format|--initial-branch|-b|--shared)
			gitArgs+=("$1" "$2"); shift; shift;;

	    -[lsn])	gitCloneArgs+=("$1"); shift;;
	    --local|--no-checkout|--no-hardlinks|--reject-shallow|--no-reject-shallow|--mirror|--dissociate|--single-branch|--no-single-branch|--tags|--no-tags|--recurse-submodules|--shallow-submodules|--no-shallow-submodules|--remote-submodules|--no-remote-submodules|--sparse|--reject-allow|--no-reject-allow|--also-filter-submodules)
			gitCloneArgs+=("$1"); shift;;
	    --origin=*|--branch=*|--revision=*|--upload-pack=*|--config=*|--reference=*|--reference-if-able=*|--server-option=*|--recurse-submodules=*|--filter=*|--depth=*|--jobs=*|--shallow-since=*|--shallow-exclude=*|--bundle-uri=*)
			gitCloneArgs+=("$1"); shift;;
	    --origin|-o|--branch|--revision|--upload-pack|-u|--config|-c|--reference|--reference-if-able|--server-option|--filter|--depth|--jobs|-j|--shallow-since|--shallow-exclude|--bundle-uri)
			gitCloneArgs+=("$1" "$2"); shift; shift;;

	    --)		gitArgs+=("$1"); shift; break;;
	    *)		break;;
	esac
    done
    typeset wcDir
    case "$subCommand" in
	clone)
	    case $# in
		1)			# <repository>
		    typeset repoOrDir="$1"
		    wcDir="$(basename -- "${repoOrDir%.git}")"
		    ;;
		2)  wcDir="$2";;	# <repository> <directory>
	    esac
	    ;;
	init)
	    case $# in
		0)  wcDir="$PWD";;
		1)  wcDir="$1";;	# <directory>
	    esac
	    ;;
	*)  printf >&2 'ASSERT: Unhandled subcommand: %s\n' "$subCommand"; return 3;;
    esac

    if [ -n "$wcDir" ] && [ ! -e "$wcDir" ]; then
	# <directory> is passed, and it does not exist yet. If it is inside the
	# current directory, ensure that it won't be created inside a Git repo,
	# as this likely is a user error.
	if case "$wcDir" in
	    ../*)   false;;
	    /*)	    [ "${wcDir:0:$((${#PWD} + 1))}" = "${PWD}/" ];;
	esac; then
	    typeset existingRepoRootDir
	    if existingRepoRootDir="$(git root 2>/dev/null)"; then
		if [ "$isForce" ]; then
		    printf >&2 'Note: The new Git repository %s lies within the existing %s repo.\n' "${wcDir%/}" "$existingRepoRootDir"
		else
		    printf >&2 'ERROR: Will not create a Git repository within the existing %s working copy; use -f|--force to override.\n' "$existingRepoRootDir"
		    return 1
		fi
	    fi
	fi
    fi

    if [ "$isExternalGitDir" ]; then
	typeset wcName="$(basename -- "$(readlink -nf -- "${wcDir:?}")")"
	[ -d "$externalGitBaseDirspec" ] || mkdir --parents -- "$externalGitBaseDirspec" || { printf >&2 'ERROR: Could not initialize data store at %s\n' "$externalGitBaseDirspec"; return 3; }
	typeset externalGitDirspec="${externalGitBaseDirspec}/${wcName:?}"
	gitArgs+=(--separate-git-dir "$externalGitDirspec")
    fi

    "$gitCommand" "$subCommand" "${gitArgs[@]}" "${gitCloneArgs[@]}" "$@" || return $?

    if [ -n "$wcDir" ]; then
	[ -d "$wcDir" ] || \
	    { wcDir="${wcDir##*/}"; [ -d "$wcDir" ]; } || \
	    { echo >&2 'Note: Cannot locate working copy'; return 1; }

	# Feature: Automatically chdir into the created repository. That's why this
	# cannot be a script, and must be a function.
	cd "$wcDir"
    else
	[ -e .git ] || { echo >&2 'Note: No arguments and not in working copy'; return 1; }
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
git-oclone()
{
    if [ $# -eq 0 ]; then
	echo >&2 'ERROR: No REPO-NAME passed.'
	return 2
    fi
    local repoName="$1"; shift
    local me; me="$(git me-in-github)" || return $?
    _git_initAndCloneExtension clone "$@" "git@github.com:${me}/${repoName}"
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
# sgitshowfilesothers [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by others in their
#			last commit.
# sgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by my team in our last
#			commit.
# sgitfileslastmine [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me.
# sgitfileslastothers [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by others in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# sgitfileslastteam [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Print selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# sgitfilesg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitshowfileslastg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitshowfileslastchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitshowfileslasttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitshowfilesfirstg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitshowfilesfirstchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# sgitshowfilesfirsttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   sgitshowfiles='commandOnSelected --generator "git showfiles" --entries'
alias               sgitshowfilesmine='commandOnSelected --generator "git showfilesmine" --entries'
alias             sgitshowfilesothers='commandOnSelected --generator "git showfilesothers" --entries'
alias               sgitshowfilesteam='commandOnSelected --generator "git showfilesteam" --entries'
alias               sgitfileslastmine='commandOnSelected --generator "git fileslastmine" --entries'
alias             sgitfileslastothers='commandOnSelected --generator "git fileslastothers" --entries'
alias               sgitfileslastteam='commandOnSelected --generator "git fileslastteam" --entries'
alias                      sgitfilesg='commandOnSelected --generator "git filesg" --entries'
alias                sgitchangedfiles='commandOnSelected --generator "git changedfiles" --entries'
alias                sgittouchedfiles='commandOnSelected --generator "git touchedfiles" --entries'
alias              sgitshowfileslastg='commandOnSelected --generator "git showfileslastg" --entries'
alias        sgitshowfileslastchanged='commandOnSelected --generator "git showfileslastchanged" --entries'
alias        sgitshowfileslasttouched='commandOnSelected --generator "git showfileslasttouched" --entries'
alias             sgitshowfilesfirstg='commandOnSelected --generator "git showfilesfirstg" --entries'
alias       sgitshowfilesfirstchanged='commandOnSelected --generator "git showfilesfirstchanged" --entries'
alias       sgitshowfilesfirsttouched='commandOnSelected --generator "git showfilesfirsttouched" --entries'

# ygitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range.
# ygitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by me in my last commit.
# ygitshowfilesothers [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by others in their last
#			commit.
# ygitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by my team in our last
#			commit.
# ygitfileslastmine [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me.
# ygitfileslastothers [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by others in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by them.
# ygitfileslastteam [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# ygitfilesg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitshowfileslastg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitshowfileslastchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitshowfileslasttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitshowfilesfirstg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitshowfilesfirstchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# ygitshowfilesfirsttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   ygitshowfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfiles" --entries'
alias               ygitshowfilesmine='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesmine" --entries'
alias             ygitshowfilesothers='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesothers" --entries'
alias               ygitshowfilesteam='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesteam" --entries'
alias               ygitfileslastmine='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslastmine" --entries'
alias             ygitfileslastothers='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslastothers" --entries'
alias               ygitfileslastteam='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslastteam" --entries'
alias                      sgitfilesg='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git filesg" --entries'
alias                sgitchangedfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git changedfiles" --entries'
alias                sgittouchedfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git touchedfiles" --entries'
alias              sgitshowfileslastg='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfileslastg" --entries'
alias        sgitshowfileslastchanged='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfileslastchanged" --entries'
alias        sgitshowfileslasttouched='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfileslasttouched" --entries'
alias             sgitshowfilesfirstg='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesfirstg" --entries'
alias       sgitshowfilesfirstchanged='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesfirstchanged" --entries'
alias       sgitshowfilesfirsttouched='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesfirsttouched" --entries'

# lgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			View selected files modified in passed commit or commit
#			range with the pager.
# lgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by me in my last commit
#			with the pager.
# lgitshowfilesothers [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by others in their last
#			commit with the pager.
# lgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by my team in our last
#			commit with the pager.
# lgitfileslastmine [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me with the pager.
# lgitfileslastothers [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by others in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by them with the pager.
# lgitfileslastteam [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			View selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them with the pager.
# lgitfilesg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitshowfileslastg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitshowfileslastchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitshowfileslasttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitshowfilesfirstg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitshowfilesfirstchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# lgitshowfilesfirsttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   lgitshowfiles='commandOnSelected --command "${PAGER:-less}" --generator "git showfiles" --entries'
alias               lgitshowfilesmine='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesmine" --entries'
alias             lgitshowfilesothers='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesothers" --entries'
alias               lgitshowfilesteam='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesteam" --entries'
alias               lgitfileslastmine='commandOnSelected --command "${PAGER:-less}" --generator "git fileslastmine" --entries'
alias             lgitfileslastothers='commandOnSelected --command "${PAGER:-less}" --generator "git fileslastothers" --entries'
alias               lgitfileslastteam='commandOnSelected --command "${PAGER:-less}" --generator "git fileslastteam" --entries'
alias                      lgitfilesg='commandOnSelected --command "${PAGER:-less}" --generator "git filesg" --entries'
alias                lgitchangedfiles='commandOnSelected --command "${PAGER:-less}" --generator "git changedfiles" --entries'
alias                lgittouchedfiles='commandOnSelected --command "${PAGER:-less}" --generator "git touchedfiles" --entries'
alias              lgitshowfileslastg='commandOnSelected --command "${PAGER:-less}" --generator "git showfileslastg" --entries'
alias        lgitshowfileslastchanged='commandOnSelected --command "${PAGER:-less}" --generator "git showfileslastchanged" --entries'
alias        lgitshowfileslasttouched='commandOnSelected --command "${PAGER:-less}" --generator "git showfileslasttouched" --entries'
alias             lgitshowfilesfirstg='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesfirstg" --entries'
alias       lgitshowfilesfirstchanged='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesfirstchanged" --entries'
alias       lgitshowfilesfirsttouched='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesfirsttouched" --entries'

# vgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in GVIM.
# vgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in my last commit
#			in GVIM.
# vgitshowfilesothers [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by others in their last
#			commit in GVIM.
# vgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in our last
#			commit in GVIM.
# vgitfileslastmine [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me in GVIM.
# vgitfileslastothers [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by others in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by them in GVIM.
# vgitfileslastteam [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them in GVIM.
# vgitfilesg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitshowfileslastg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitshowfileslastchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitshowfileslasttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitshowfilesfirstg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitshowfilesfirstchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vgitshowfilesfirsttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   vgitshowfiles='commandOnSelected --command SendToGVIM --generator "git showfiles" --entries'
alias               vgitshowfilesmine='commandOnSelected --command SendToGVIM --generator "git showfilesmine" --entries'
alias             vgitshowfilesothers='commandOnSelected --command SendToGVIM --generator "git showfilesothers" --entries'
alias               vgitshowfilesteam='commandOnSelected --command SendToGVIM --generator "git showfilesteam" --entries'
alias               vgitfileslastmine='commandOnSelected --command SendToGVIM --generator "git fileslastmine" --entries'
alias             vgitfileslastothers='commandOnSelected --command SendToGVIM --generator "git fileslastothers" --entries'
alias               vgitfileslastteam='commandOnSelected --command SendToGVIM --generator "git fileslastteam" --entries'
alias                      vgitfilesg='commandOnSelected --command SendToGVIM --generator "git filesg" --entries'
alias                vgitchangedfiles='commandOnSelected --command SendToGVIM --generator "git changedfiles" --entries'
alias                vgittouchedfiles='commandOnSelected --command SendToGVIM --generator "git touchedfiles" --entries'
alias              vgitshowfileslastg='commandOnSelected --command SendToGVIM --generator "git showfileslastg" --entries'
alias        vgitshowfileslastchanged='commandOnSelected --command SendToGVIM --generator "git showfileslastchanged" --entries'
alias        vgitshowfileslasttouched='commandOnSelected --command SendToGVIM --generator "git showfileslasttouched" --entries'
alias             vgitshowfilesfirstg='commandOnSelected --command SendToGVIM --generator "git showfilesfirstg" --entries'
alias       vgitshowfilesfirstchanged='commandOnSelected --command SendToGVIM --generator "git showfilesfirstchanged" --entries'
alias       vgitshowfilesfirsttouched='commandOnSelected --command SendToGVIM --generator "git showfilesfirsttouched" --entries'

# vimgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in Vim.
# vimgitshowfilesmine [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in my last commit
#			in Vim.
# vimgitshowfilesothers [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by others in their last
#			commit in Vim.
# vimgitshowfilesteam [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in our last
#			commit in Vim.
# vimgitfileslastmine [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me in Vim.
# vimgitfileslastothers [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by others in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by them in Vim.
# vimgitfileslastteam [-r|--revision REVISION] [<path> ...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them in Vim.
# vimgitfilesg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitchangedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgittouchedfiles [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitshowfileslastg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitshowfileslastchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitshowfileslasttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitshowfilesfirstg [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitshowfilesfirstchanged [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
# vimgitshowfilesfirsttouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
alias                   vimgitshowfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfiles" --entries'
alias               vimgitshowfilesmine='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesmine" --entries'
alias             vimgitshowfilesothers='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesothers" --entries'
alias               vimgitshowfilesteam='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesteam" --entries'
alias               vimgitfileslastmine='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslastmine" --entries'
alias             vimgitfileslastothers='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslastothers" --entries'
alias               vimgitfileslastteam='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslastteam" --entries'
alias                      vimgitfilesg='commandOnSelected --command '"${_aliases_vim}"' --generator "git filesg" --entries'
alias                vimgitchangedfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git changedfiles" --entries'
alias                vimgittouchedfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git touchedfiles" --entries'
alias              vimgitshowfileslastg='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfileslastg" --entries'
alias        vimgitshowfileslastchanged='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfileslastchanged" --entries'
alias        vimgitshowfileslasttouched='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfileslasttouched" --entries'
alias             vimgitshowfilesfirstg='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesfirstg" --entries'
alias       vimgitshowfilesfirstchanged='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesfirstchanged" --entries'
alias       vimgitshowfilesfirsttouched='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesfirsttouched" --entries'



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
