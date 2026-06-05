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



multiplicityAliasOn()
{
    local what="${1:?}"; shift
    local aliasDefinition="${1:?}"; shift
    local multiplier; for multiplier in 1 2 3 4 5 6 7 x q z
    do
	alias "${aliasDefinition//"$what"/"${what}${multiplier}"}"
    done
}

# sgitshowfiles [<since>..<until>] [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs modified in passed commit or
#			commit range.
# sgitshowfiles{1..7,x,q,z} [<pathspec>...]
#			Print selected filespecs modified in the commit(s)
#			interactively chosen from the commits [that cover
#			<pathspec>...] in the <range>.
# sgitshowfilesmine [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs modified by me in my last commit.
# sgitshowfilesothers [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs modified by others in their
#			last commit.
# sgitshowfilesteam [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs modified by my team in our last
#			commit.
# sgitfileslastmine [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me.
# sgitfileslastothers [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs modified by others in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# sgitfileslastteam [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# sgitfilesg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# sgitfileschanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# sgitfilestouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# sgitfileslastg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# sgitfileslastchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# sgitfileslasttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# sgitfilesfirstg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# sgitfilesfirstchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# sgitfilesfirsttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
alias                   sgitshowfiles='commandOnSelected --generator "git showfiles" --entries'
multiplicityAliasOn showfiles sgitshowfiles='commandOnSelected --generator "git showfiles" --entries'
alias               sgitshowfilesmine='commandOnSelected --generator "git showfilesmine" --entries'
alias             sgitshowfilesothers='commandOnSelected --generator "git showfilesothers" --entries'
alias               sgitshowfilesteam='commandOnSelected --generator "git showfilesteam" --entries'
alias               sgitfileslastmine='commandOnSelected --generator "git fileslastmine" --entries'
alias             sgitfileslastothers='commandOnSelected --generator "git fileslastothers" --entries'
alias               sgitfileslastteam='commandOnSelected --generator "git fileslastteam" --entries'
alias                      sgitfilesg='commandOnSelected --generator "git filesg" --entries'
alias                sgitfileschanged='commandOnSelected --generator "git fileschanged" --entries'
alias                sgitfilestouched='commandOnSelected --generator "git filestouched" --entries'
alias                  sgitfileslastg='commandOnSelected --generator "git fileslastg" --entries'
alias            sgitfileslastchanged='commandOnSelected --generator "git fileslastchanged" --entries'
alias            sgitfileslasttouched='commandOnSelected --generator "git fileslasttouched" --entries'
alias                 sgitfilesfirstg='commandOnSelected --generator "git filesfirstg" --entries'
alias           sgitfilesfirstchanged='commandOnSelected --generator "git filesfirstchanged" --entries'
alias           sgitfilesfirsttouched='commandOnSelected --generator "git filesfirsttouched" --entries'

# ygitshowfiles [<since>..<until>] [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range.
# ygitshowfiles{1..7,x,q,z} [<pathspec>...]
#			Yank selected filespecs modified in the commit(s)
#			interactively chosen from the commits [that cover
#			<pathspec>...] in the <range>.
# ygitshowfilesmine [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by me in my last commit.
# ygitshowfilesothers [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by others in their last
#			commit.
# ygitshowfilesteam [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by my team in our last
#			commit.
# ygitfileslastmine [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me.
# ygitfileslastothers [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by others in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by them.
# ygitfileslastteam [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them.
# ygitfilesg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# ygitfileschanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# ygitfilestouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# ygitfileslastg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# ygitfileslastchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# ygitfileslasttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# ygitfilesfirstg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# ygitfilesfirstchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# ygitfilesfirsttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
alias                   ygitshowfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfiles" --entries'
multiplicityAliasOn showfiles ygitshowfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfiles" --entries'
alias               ygitshowfilesmine='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesmine" --entries'
alias             ygitshowfilesothers='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesothers" --entries'
alias               ygitshowfilesteam='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git showfilesteam" --entries'
alias               ygitfileslastmine='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslastmine" --entries'
alias             ygitfileslastothers='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslastothers" --entries'
alias               ygitfileslastteam='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslastteam" --entries'
alias                      sgitfilesg='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git filesg" --entries'
alias                sgitfileschanged='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileschanged" --entries'
alias                sgitfilestouched='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git filestouched" --entries'
alias                  sgitfileslastg='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslastg" --entries'
alias            sgitfileslastchanged='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslastchanged" --entries'
alias            sgitfileslasttouched='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git fileslasttouched" --entries'
alias                 sgitfilesfirstg='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git filesfirstg" --entries'
alias           sgitfilesfirstchanged='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git filesfirstchanged" --entries'
alias           sgitfilesfirsttouched='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git filesfirsttouched" --entries'

# lgitshowfiles [<since>..<until>] [<pathspec>...] [-- SELECTIONs ...]
#			View selected files modified in passed commit or commit
#			range with the pager.
# lgitshowfiles{1..7,x,q,z} [<pathspec>...]
#			View selected files modified in the commit(s)
#			interactively chosen from the commits [that cover
#			<pathspec>...] in the <range>.
# lgitshowfilesmine [<pathspec>...] [-- SELECTIONs ...]
#			View selected filespecs modified by me in my last commit
#			with the pager.
# lgitshowfilesothers [<pathspec>...] [-- SELECTIONs ...]
#			View selected filespecs modified by others in their last
#			commit with the pager.
# lgitshowfilesteam [<pathspec>...] [-- SELECTIONs ...]
#			View selected filespecs modified by my team in our last
#			commit with the pager.
# lgitfileslastmine [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			View selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me with the pager.
# lgitfileslastothers [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			View selected filespecs modified by others in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by them with the pager.
# lgitfileslastteam [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			View selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them with the pager.
# lgitfilesg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# lgitfileschanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# lgitfilestouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# lgitfileslastg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# lgitfileslastchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# lgitfileslasttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# lgitfilesfirstg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# lgitfilesfirstchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# lgitfilesfirsttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
alias                   lgitshowfiles='commandOnSelected --command "${PAGER:-less}" --generator "git showfiles" --entries'
multiplicityAliasOn showfiles lgitshowfiles='commandOnSelected --command "${PAGER:-less}" --generator "git showfiles" --entries'
alias               lgitshowfilesmine='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesmine" --entries'
alias             lgitshowfilesothers='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesothers" --entries'
alias               lgitshowfilesteam='commandOnSelected --command "${PAGER:-less}" --generator "git showfilesteam" --entries'
alias               lgitfileslastmine='commandOnSelected --command "${PAGER:-less}" --generator "git fileslastmine" --entries'
alias             lgitfileslastothers='commandOnSelected --command "${PAGER:-less}" --generator "git fileslastothers" --entries'
alias               lgitfileslastteam='commandOnSelected --command "${PAGER:-less}" --generator "git fileslastteam" --entries'
alias                      lgitfilesg='commandOnSelected --command "${PAGER:-less}" --generator "git filesg" --entries'
alias                lgitfileschanged='commandOnSelected --command "${PAGER:-less}" --generator "git fileschanged" --entries'
alias                lgitfilestouched='commandOnSelected --command "${PAGER:-less}" --generator "git filestouched" --entries'
alias                  lgitfileslastg='commandOnSelected --command "${PAGER:-less}" --generator "git fileslastg" --entries'
alias            lgitfileslastchanged='commandOnSelected --command "${PAGER:-less}" --generator "git fileslastchanged" --entries'
alias            lgitfileslasttouched='commandOnSelected --command "${PAGER:-less}" --generator "git fileslasttouched" --entries'
alias                 lgitfilesfirstg='commandOnSelected --command "${PAGER:-less}" --generator "git filesfirstg" --entries'
alias           lgitfilesfirstchanged='commandOnSelected --command "${PAGER:-less}" --generator "git filesfirstchanged" --entries'
alias           lgitfilesfirsttouched='commandOnSelected --command "${PAGER:-less}" --generator "git filesfirsttouched" --entries'

# vgitshowfiles [<since>..<until>] [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in GVIM.
# vgitshowfiles{1..7,x,q,z} [<pathspec>...]
#			Edit selected filespecs modified in the commit(s)
#			interactively chosen from the commits [that cover
#			<pathspec>...] in the <range> in GVIM.
# vgitshowfilesmine [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in my last commit
#			in GVIM.
# vgitshowfilesothers [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by others in their last
#			commit in GVIM.
# vgitshowfilesteam [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in our last
#			commit in GVIM.
# vgitfileslastmine [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me in GVIM.
# vgitfileslastothers [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by others in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by them in GVIM.
# vgitfileslastteam [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them in GVIM.
# vgitfilesg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vgitfileschanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vgitfilestouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vgitfileslastg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vgitfileslastchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vgitfileslasttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vgitfilesfirstg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vgitfilesfirstchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vgitfilesfirsttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
alias                   vgitshowfiles='commandOnSelected --command SendToGVIM --generator "git showfiles" --entries'
multiplicityAliasOn showfiles vgitshowfiles='commandOnSelected --command SendToGVIM --generator "git showfiles" --entries'
alias               vgitshowfilesmine='commandOnSelected --command SendToGVIM --generator "git showfilesmine" --entries'
alias             vgitshowfilesothers='commandOnSelected --command SendToGVIM --generator "git showfilesothers" --entries'
alias               vgitshowfilesteam='commandOnSelected --command SendToGVIM --generator "git showfilesteam" --entries'
alias               vgitfileslastmine='commandOnSelected --command SendToGVIM --generator "git fileslastmine" --entries'
alias             vgitfileslastothers='commandOnSelected --command SendToGVIM --generator "git fileslastothers" --entries'
alias               vgitfileslastteam='commandOnSelected --command SendToGVIM --generator "git fileslastteam" --entries'
alias                      vgitfilesg='commandOnSelected --command SendToGVIM --generator "git filesg" --entries'
alias                vgitfileschanged='commandOnSelected --command SendToGVIM --generator "git fileschanged" --entries'
alias                vgitfilestouched='commandOnSelected --command SendToGVIM --generator "git filestouched" --entries'
alias                  vgitfileslastg='commandOnSelected --command SendToGVIM --generator "git fileslastg" --entries'
alias            vgitfileslastchanged='commandOnSelected --command SendToGVIM --generator "git fileslastchanged" --entries'
alias            vgitfileslasttouched='commandOnSelected --command SendToGVIM --generator "git fileslasttouched" --entries'
alias                 vgitfilesfirstg='commandOnSelected --command SendToGVIM --generator "git filesfirstg" --entries'
alias           vgitfilesfirstchanged='commandOnSelected --command SendToGVIM --generator "git filesfirstchanged" --entries'
alias           vgitfilesfirsttouched='commandOnSelected --command SendToGVIM --generator "git filesfirsttouched" --entries'

# vimgitshowfiles [<since>..<until>] [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in Vim.
# vimgitshowfiles{1..7,x,q,z} [<pathspec>...]
#			Edit selected files modified in the commit(s)
#			interactively chosen from the commits [that cover
#			<pathspec>...] in the <range> in Vim.
# vimgitshowfilesmine [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in my last commit
#			in Vim.
# vimgitshowfilesothers [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by others in their last
#			commit in Vim.
# vimgitshowfilesteam [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in our last
#			commit in Vim.
# vimgitfileslastmine [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by me in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by me in Vim.
# vimgitfileslastothers [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by others in the last /
#			passed -r <commit> and directly preceding, as long as
#			they also were by them in Vim.
# vimgitfileslastteam [-r|--revision REVISION] [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected filespecs modified by my team in the last
#			/ passed -r <commit> and directly preceding, as long as
#			they also were by them in Vim.
# vimgitfilesg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vimgitfileschanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vimgitfilestouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vimgitfileslastg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vimgitfileslastchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vimgitfileslasttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vimgitfilesfirstg [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vimgitfilesfirstchanged [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
# vimgitfilesfirsttouched [<since>..<until>] [<pathspec>...] text|/regexp/ [-- SELECTIONs ...]
alias                   vimgitshowfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfiles" --entries'
multiplicityAliasOn showfiles vimgitshowfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfiles" --entries'
alias               vimgitshowfilesmine='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesmine" --entries'
alias             vimgitshowfilesothers='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesothers" --entries'
alias               vimgitshowfilesteam='commandOnSelected --command '"${_aliases_vim}"' --generator "git showfilesteam" --entries'
alias               vimgitfileslastmine='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslastmine" --entries'
alias             vimgitfileslastothers='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslastothers" --entries'
alias               vimgitfileslastteam='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslastteam" --entries'
alias                      vimgitfilesg='commandOnSelected --command '"${_aliases_vim}"' --generator "git filesg" --entries'
alias                vimgitfileschanged='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileschanged" --entries'
alias                vimgitfilestouched='commandOnSelected --command '"${_aliases_vim}"' --generator "git filestouched" --entries'
alias                  vimgitfileslastg='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslastg" --entries'
alias            vimgitfileslastchanged='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslastchanged" --entries'
alias            vimgitfileslasttouched='commandOnSelected --command '"${_aliases_vim}"' --generator "git fileslasttouched" --entries'
alias                 vimgitfilesfirstg='commandOnSelected --command '"${_aliases_vim}"' --generator "git filesfirstg" --entries'
alias           vimgitfilesfirstchanged='commandOnSelected --command '"${_aliases_vim}"' --generator "git filesfirstchanged" --entries'
alias           vimgitfilesfirsttouched='commandOnSelected --command '"${_aliases_vim}"' --generator "git filesfirsttouched" --entries'



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



# sgitlsprivate [-X|--orphaned-submodules] [-x] [<pathspec>] [-- SELECTIONs ...]
#			Print selected unversioned filespecs that are not under
#			source control in the current directory and below.
alias sgitlsprivate='commandOnSelected --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# ygitlsprivate [-X|--orphaned-submodules] [-x] [<pathspec>] [-- SELECTIONs ...]
#			Yank selected unversioned filespecs that are not under
#			source control in the current directory and below.
alias ygitlsprivate='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# lgitlsprivate [-X|--orphaned-submodules] [-x] [<pathspec>] [-- SELECTIONs ...]
#			View selected unversioned files that are not under
#			source control in the current directory and below with
#			the pager.
alias lgitlsprivate='commandOnSelected --command "${PAGER:-less}" --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# vgitlsprivate [-X|--orphaned-submodules] [-x] [<pathspec>] [-- SELECTIONs ...]
#			Edit selected unversioned files that are not under
#			source control in the current directory and below in
#			GVIM.
alias vgitlsprivate='commandOnSelected --command SendToGVIM --generator "git-lsprivate --long --ignore-empty-directories" --entries'

# vimgitlsprivate [-X|--orphaned-submodules] [-x] [<pathspec>] [-- SELECTIONs ...]
#			Edit selected unversioned files that are not under
#			source control in the current directory and below in
#			Vim.
alias vimgitlsprivate='commandOnSelected --command '"${_aliases_vim}"' --generator "git-lsprivate --long --ignore-empty-directories" --entries'



# sgitstfiles [<pathspec>] [-- SELECTIONs ...] Print selected changed filespecs.
alias sgitstfiles='commandOnSelected --generator "git-stfiles" --entries'

# ygitstfiles [<pathspec>] [-- SELECTIONs ...] Yank selected changed filespecs.
alias ygitstfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-stfiles" --entries'

# lgitstfiles [<pathspec>] [-- SELECTIONs ...]
#			View selected changed files with the pager.
alias lgitstfiles='commandOnSelected --command "${PAGER:-less}" --generator "git-stfiles" --entries'

# vgitstfiles [<pathspec>] [-- SELECTIONs ...]
#			Edit selected changed files in GVIM.
alias vgitstfiles='commandOnSelected --command SendToGVIM --generator "git-stfiles" --entries'

# vimgitstfiles [<pathspec>] [-- SELECTIONs ...]
#			Edit selected changed files in Vim.
alias vimgitstfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git-stfiles" --entries'



# sgitstifiles [<pathspec>] [-- SELECTIONs ...]
#			Print selected staged filespecs.
alias sgitstifiles='commandOnSelected --generator "git-stifiles" --entries'

# ygitstifiles [<pathspec>] [-- SELECTIONs ...]
#			Yank selected staged filespecs.
alias ygitstifiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-stifiles" --entries'

# lgitstifiles [<pathspec>] [-- SELECTIONs ...]
#			View selected staged files with the pager.
alias lgitstifiles='commandOnSelected --command "${PAGER:-less}" --generator "git-stifiles" --entries'

# vgitstifiles [<pathspec>] [-- SELECTIONs ...]
#			Edit selected staged files in GVIM.
alias vgitstifiles='commandOnSelected --command SendToGVIM --generator "git-stifiles" --entries'

# vimgitstifiles [<pathspec>] [-- SELECTIONs ...]
#			Edit selected staged files in Vim.
alias vimgitstifiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git-stifiles" --entries'



# sgitstIfiles [<pathspec>] [-- SELECTIONs ...]
#			Print selected modified but not staged filespecs.
alias sgitstIfiles='commandOnSelected --generator "git-stIfiles" --entries'

# ygitstIfiles [<pathspec>] [-- SELECTIONs ...]
#			Yank selected modified but not staged filespecs.
alias ygitstIfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-stIfiles" --entries'

# lgitstIfiles [<pathspec>] [-- SELECTIONs ...]
#			View selected modified but not staged files with the
#			pager.
alias lgitstIfiles='commandOnSelected --command "${PAGER:-less}" --generator "git-stIfiles" --entries'

# vgitstIfiles [<pathspec>] [-- SELECTIONs ...]
#			Edit selected modified but not staged files in GVIM.
alias vgitstIfiles='commandOnSelected --command SendToGVIM --generator "git-stIfiles" --entries'

# vimgitstIfiles [<pathspec>] [-- SELECTIONs ...]
#			Edit selected modified but not staged files in Vim.
alias vimgitstIfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git-stIfiles" --entries'



# sgitstuntracked [<pathspec>] [-- SELECTIONs ...]
#			Print selected new files not yet added to version
#			control.
alias sgitstuntracked='commandOnSelected --generator "git stuntracked" --entries'

# ygitstuntracked [<pathspec>] [-- SELECTIONs ...]
#			Yank selected new files not yet added to version
#			control.
alias ygitstuntracked='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git stuntracked" --entries'

# lgitstuntracked [<pathspec>] [-- SELECTIONs ...]
#			View selected new files not yet added to version
#			control.
alias lgitstuntracked='commandOnSelected --command "${PAGER:-less}" --generator "git stuntracked" --entries'

# vgitstuntracked [<pathspec>] [-- SELECTIONs ...]
#			Edit selected new files not yet added to version
#			control.
alias vgitstuntracked='commandOnSelected --command SendToGVIM --generator "git stuntracked" --entries'

# vimgitstuntracked [<pathspec>] [-- SELECTIONs ...]
#			Edit selected new files not yet added to version
#			control.
alias vimgitstuntracked='commandOnSelected --command '"${_aliases_vim}"' --generator "git stuntracked" --entries'



# sgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs that match PATTERN.
# sgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			Print selected filespecs that do not match PATTERN.
alias sgitgf='commandOnSelected --generator "git gf" --entries'
alias sgitgF='commandOnSelected --generator "git g-f" --entries'

# ygitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs that match PATTERN.
# ygitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			Yank selected filespecs that do not match PATTERN.
alias ygitgf='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git gf" --entries'
alias ygitgF='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git g-f" --entries'

# lgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			View selected files that match PATTERN with the pager.
# lgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			View selected files that do not match PATTERN with the
#			pager.
alias lgitgf='commandOnSelected --command "${PAGER:-less}" --generator "git gf" --entries'
alias lgitgF='commandOnSelected --command "${PAGER:-less}" --generator "git g-f" --entries'

# vgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected files that match PATTERN in GVIM.
# vgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected files that do not match PATTERN in GVIM.
alias vgitgf='commandOnSelected --command SendToGVIM --generator "git gf" --entries'
alias vgitgF='commandOnSelected --command SendToGVIM --generator "git g-f" --entries'

# vimgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected files that match PATTERN in Vim.
# vimgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec>...] [-- SELECTIONs ...]
#			Edit selected files that do not match PATTERN in Vim.
alias vimgitgf='commandOnSelected --command '"${_aliases_vim}"' --generator "git gf" --entries'
alias vimgitgF='commandOnSelected --command '"${_aliases_vim}"' --generator "git g-f" --entries'

eval "$(runWithPrompt --addAliasSupport git-eachFile \
    'lprdf' \
    'local-dir|no-git-color|paginate|separate-errors|recursive|directory|only-files' \
    '' \
    'submodule'
)"

eval "$(runWithPrompt --addAliasSupport git-ffintegrateto \
    'y' \
    'no-push|push|if-up-to-date|push-branch|force|push-submodules|delete-merged-submodule-branches|no-merge|no-delete|rebase-single|rebase|ff|ff-only|no-ff|no-submodule-checkout|no-submodule-update|no-merge-to-separate-integration-branch|yes' \
    'b' \
    'branch'
)"
eval "$(runWithPrompt --addAliasSupport git-reintegrate \
    'y' \
    'no-push|push|no-delete|delete-separate-integration-branch|rebase-single|rebase|ff|ff-only|no-ff|ff-target-to-tracked|no-submodule-update|ignore-dirty-submodules|yes|if-up-to-date' \
    'b' \
    'branch'
)"

unset multiplicityAliasOn
