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
# sgitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Print selected filespecs modified in passed commit or
#			commit range where text or /regexp/ was added or
#			removed.
# sgitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Print selected filespecs modified in passed commit or
#			commit range where lines were modified where text or
#			/regexp/ appears.
alias        sgitshowfiles='commandOnSelected --generator "git-showfiles" --entries'
alias    sgitshowfilesfind='commandOnSelected --generator "git-showfilesfind" --entries'
alias sgitshowfilestouched='commandOnSelected --generator "git-showfilestouched" --entries'

# ygitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range.
# ygitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range where text or /regexp/ was added or
#			removed.
# ygitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Yank selected filespecs modified in passed commit or
#			commit range where lines were modified where text or
#			/regexp/ appears.
alias        ygitshowfiles='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-showfiles" --entries'
alias    ygitshowfilesfind='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-showfilesfind" --entries'
alias ygitshowfilestouched='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-showfilestouched" --entries'

# vgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in GVIM.
# vgitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range where text or /regexp/ was added or removed in
#			GVIM.
# vgitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range where lines were modified where text or /regexp/
#			appears in GVIM.
alias        vgitshowfiles='commandOnSelected --command SendToGVIM --generator "git-showfiles" --entries'
alias    vgitshowfilesfind='commandOnSelected --command SendToGVIM --generator "git-showfilesfind" --entries'
alias vgitshowfilestouched='commandOnSelected --command SendToGVIM --generator "git-showfilestouched" --entries'

# vimgitshowfiles [<since>..<until>] [<path> ...] [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range in Vim.
# vimgitshowfilesfind [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range where text or /regexp/ was added or removed in
#			Vim.
# vimgitshowfilestouched [<since>..<until>] [<path> ...] text|/regexp/ [-- SELECTIONs ...]
#			Edit selected files modified in passed commit or commit
#			range where lines were modified where text or /regexp/
#			appears in Vim.
alias        vimgitshowfiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git-showfiles" --entries'
alias    vimgitshowfilesfind='commandOnSelected --command '"${_aliases_vim}"' --generator "git-showfilesfind" --entries'
alias vimgitshowfilestouched='commandOnSelected --command '"${_aliases_vim}"' --generator "git-showfilestouched" --entries'



# sgitconflicts [DIR ...] [-- SELECTIONs ...]
#			Print selected filespecs with conflicts.
alias sgitconflicts='commandOnSelected --generator "git-conflicts" --entries'

# ygitconflicts [DIR ...] [-- SELECTIONs ...]
#			Yank selected filespecs with conflicts.
alias ygitconflicts='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git-conflicts" --entries'

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

# vgitstifiles [<path>] [-- SELECTIONs ...]
#			Edit selected staged files in GVIM.
alias vgitstifiles='commandOnSelected --command SendToGVIM --generator "git-stifiles" --entries'

# vimgitstifiles [<path>] [-- SELECTIONs ...]
#			Edit selected staged files in Vim.
alias vimgitstifiles='commandOnSelected --command '"${_aliases_vim}"' --generator "git-stifiles" --entries'



# sgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec> ...] [-- SELECTIONs ...]
#			Print selected filespecs that match PATTERN.
# sgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec> ...] [-- SELECTIONs ...]
#			Print selected filespecs that do not match PATTERN.
alias sgitgf='commandOnSelected --generator "git gf" --entries'
alias sgitgF='commandOnSelected --generator "git g-f" --entries'

# ygitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec> ...] [-- SELECTIONs ...]
#			Yank selected filespecs that match PATTERN.
# ygitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec> ...] [-- SELECTIONs ...]
#			Yank selected filespecs that do not match PATTERN.
alias ygitgf='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git gf" --entries'
alias ygitgF='commandOnSelected --command "printf %s\\\\n {} | clipboard" --generator "git g-f" --entries'

# vgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec> ...] [-- SELECTIONs ...]
#			Edit selected files that match PATTERN in GVIM.
# vgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec> ...] [-- SELECTIONs ...]
#			Edit selected files that do not match PATTERN in GVIM.
alias vgitgf='commandOnSelected --command SendToGVIM --generator "git gf" --entries'
alias vgitgF='commandOnSelected --command SendToGVIM --generator "git g-f" --entries'

# vimgitgf [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec> ...] [-- SELECTIONs ...]
#			Edit selected files that match PATTERN in Vim.
# vimgitgF [<GREP-OPTIONS> ...] [-e] PATTERN [<pathspec> ...] [-- SELECTIONs ...]
#			Edit selected files that do not match PATTERN in Vim.
alias vimgitgf='commandOnSelected --command '"${_aliases_vim}"' --generator "git gf" --entries'
alias vimgitgF='commandOnSelected --command '"${_aliases_vim}"' --generator "git g-f" --entries'
