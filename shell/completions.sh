#!/bin/bash source-this-script
[ "${BASH_VERSION:-}" ] || return

type -t completeAsCommand >/dev/null || completeAsCommand()
{
    local name
    for name
    do
	complete -A function -A command "$name"
    done
}

completeAsCommand git-autostash git-inside \
    git-brrefdo git-localbrcdo git-localbrcrefdo git-localbrdo git-localbrrefdo git-rbrrefdo git-subIdo git-subdo git-subido git-substdo git-wc-with-suffix-do git-wcdo git-wcs-in-dir-do

gitCompleteAs()
{
    typeset sourceCommand="${1:?}"; shift
    local cmd; for cmd
    do
	eval "_git_${cmd}() { _git_${sourceCommand} \"\$@\"; }"
    done
}

gitCompleteAs branch \
    odeletebr oldeletebr \
    orenamebr olrenamebr \
    oremotebr \
    udeletebr uldeletebr \
    urenamebr ulrenamebr \
    uremotebr

gitCompleteAs checkout co oco uco \
    cosub ocosub ucosub \
    inout iofiles iosubmodules io ab \
    oinout oiofiles oiosubmodules oio oab \
    uinout uiofiles uiosubmodules uio uab \
    ominout omiofiles omiosubmodules omio omab \
    uminout umiofiles umiosubmodules umio umab

gitCompleteAs merge \
    mergeo merget mergerecordonly mergedryrun mergeto mergeselectedbranch mergesbr mergedryrunsbr mergedryrunselectedbranch \
    fast-forward ff ffto \
    noff noffto \
    reintegrate reintegrateto reintegratetoselected ffintegrateto ffintegratetoselected

gitCompleteAs rebase \
    rb rbi mrb nrb \
    rebaseselectedbranch rbsbr

unset -f gitCompleteAs


_git_cheat()
{
    local IFS=$'\n'
    COMPREPLY=()
    local gitCommand="${COMP_WORDS[0]}"; gitCommand="${gitCommand%-cheat}"
    local cur="${COMP_WORDS[COMP_CWORD]}"

    readarray -t COMPREPLY < <(
	command cd "$(dirname -- "$(command -v git-cheat)" 2>/dev/null)/../etc" \
	    && readarray -t files < <(find . -type f -name "${gitCommand}cheats-*.md" | sed -e 's#^\./[^-]\+-\(.*\)\.md$#\1#') \
	    && compgen -W "${files[*]}" -- "$cur"
    )
    [ ${#COMPREPLY[@]} -gt 0 ] && readarray -t COMPREPLY < <(printf "%q\n" "${COMPREPLY[@]}")
}
complete -F _git_cheat git-cheat hub-cheat

_git_complete()
{
    local IFS=$'\n'
    typeset -a aliases=(); readarray -t aliases < <(compgen -A command -- 'git-' 2>/dev/null \
	| grep -vFx -e git-add -e git-bisect -e git-checkout -e git-commit -e git-fetch -e git-log -e git-merge -e git-pull -e git-push -e git-rebase -e git-revert -e git-show \
	)   # XXX: Need to ignore my wrappers around built-in Git commands, as their completion functions use the same scheme (e.g. _git_add), but expect different arguments.
    aliases=("${aliases[@]/#git-/}")

    if [ $COMP_CWORD -ge 3 ] && contains "${COMP_WORDS[1]}-${COMP_WORDS[2]}" "${aliases[@]}"; then
	local gitAlias="_git_${COMP_WORDS[1]//-/_}_${COMP_WORDS[2]//-/_}"
	# Completing a sub-alias; delegate to its custom completion function (if
	# available)
	if type -t "$gitAlias" >/dev/null; then
	    typeset -a save_COMP_WORDS=("${COMP_WORDS[@]}"); COMP_WORDS=("git-${COMP_WORDS[1]}-${COMP_WORDS[2]}" "${COMP_WORDS[@]:3}")
		COMP_CWORD=$((COMP_CWORD-2)) \
		    "$gitAlias" "${COMP_WORDS[0]}" "${save_COMP_WORDS[COMP_CWORD]}" "${save_COMP_WORDS[COMP_CWORD-1]}"
	    COMP_WORDS=("${save_COMP_WORDS[@]}")
	fi
    fi
    if [ $COMP_CWORD -ge 2 ] && contains "${COMP_WORDS[1]}" "${aliases[@]}"; then
	local gitAlias="_git_${COMP_WORDS[1]//-/_}"
	# Completing an alias; delegate to its custom completion function (if
	# available)
	if type -t "$gitAlias" >/dev/null; then
	    typeset -a save_COMP_WORDS=("${COMP_WORDS[@]}"); COMP_WORDS=("git-${COMP_WORDS[1]}" "${COMP_WORDS[@]:2}")
		COMP_CWORD=$((COMP_CWORD-1)) \
		    "$gitAlias" "${COMP_WORDS[0]}" "${save_COMP_WORDS[COMP_CWORD]}" "${save_COMP_WORDS[COMP_CWORD-1]}"
	    COMP_WORDS=("${save_COMP_WORDS[@]}")
	fi
    fi

    IFS=$' \t\n' __git_wrap__git_main "$@"
    COMPREPLY=("${COMPREPLY[@]% }") # XXX: Git 2.41.0 adds a trailing space to the completion results.

    if [ $COMP_CWORD -eq 1 ]; then
	# Also offer aliases (git-aliasname, callable via my git wrapper
	# function as git aliasname).
	readarray -O ${#COMPREPLY[@]} -t COMPREPLY < <(compgen -W "${aliases[*]}" -X "!${2}*")
    elif [ $COMP_CWORD -eq 2 ]; then
	# Also offer aliases (git-aliasname-subaliasname, callable via my git wrapper
	# function as git aliasname subaliasname).
	typeset -a subAliases=(); readarray -t subAliases < <(compgen -A command -- "git-${COMP_WORDS[1]}-" 2>/dev/null)
	subAliases=("${subAliases[@]/#git-${COMP_WORDS[1]}-/}")
	readarray -O ${#COMPREPLY[@]} -t COMPREPLY < <(compgen -W "${subAliases[*]}" -X "!${2}*")
    fi
}
complete -F _git_complete git

_hub_complete()
{
    local IFS=$'\n'
    typeset -a aliases=(); readarray -t aliases < <(compgen -A command -- 'hub-' 2>/dev/null)
    aliases=("${aliases[@]/#hub-/}")

    typeset -a multiModeAliases=(); readarray -t multiModeAliases < <(
	command cd "$(dirname -- "$(command -v git-wrapper)" 2>/dev/null)" \
	    && grep --fixed-strings --files-with-matches --no-messages '"$HUB"' -- git-* 2>/dev/null
    )
    aliases=("${multiModeAliases[@]/#git-/}")

    if [ $COMP_CWORD -ge 3 ] && contains "${COMP_WORDS[1]}-${COMP_WORDS[2]}" "${aliases[@]}"; then
	local hubAlias="_hub_${COMP_WORDS[1]//-/_}_${COMP_WORDS[2]//-/_}"
	# Completing a sub-alias; delegate to its custom completion function (if
	# available)
	if type -t "$hubAlias" >/dev/null; then
	    typeset -a save_COMP_WORDS=("${COMP_WORDS[@]}"); COMP_WORDS=("hub-${COMP_WORDS[1]}-${COMP_WORDS[2]}" "${COMP_WORDS[@]:3}")
		COMP_CWORD=$((COMP_CWORD-2)) \
		    "$hubAlias" "${COMP_WORDS[0]}" "${COMP_WORDS[COMP_CWORD]}" "${COMP_WORDS[COMP_CWORD-1]}"
	    COMP_WORDS=("${save_COMP_WORDS[@]}")
	fi
    fi
    if [ $COMP_CWORD -ge 2 ] && contains "${COMP_WORDS[1]}" "${aliases[@]}"; then
	local hubAlias="_hub_${COMP_WORDS[1]//-/_}"
	# Completing an alias; delegate to its custom completion function (if
	# available)
	if type -t "$hubAlias" >/dev/null; then
	    typeset -a save_COMP_WORDS=("${COMP_WORDS[@]}"); COMP_WORDS=("hub-${COMP_WORDS[1]}" "${COMP_WORDS[@]:2}")
		COMP_CWORD=$((COMP_CWORD-1)) \
		    "$hubAlias" "${COMP_WORDS[0]}" "${COMP_WORDS[COMP_CWORD]}" "${COMP_WORDS[COMP_CWORD-1]}"
	    COMP_WORDS=("${save_COMP_WORDS[@]}")
	fi
    fi

    if [ $COMP_CWORD -eq 1 ]; then
	typeset -a builtinCommands=(api browse ci-status compare create delete fork gist issue pr pull-request release sync)
	# Also offer aliases (hub-aliasname, callable via my hub wrapper
	# function as hub aliasname).
	readarray -O ${#COMPREPLY[@]} -t COMPREPLY < <(compgen -W "${builtinCommands[*]}"$'\n'"${aliases[*]}" -X "!${2}*")
    elif [ $COMP_CWORD -eq 2 ]; then
	IFS=$' \t\n' __git_wrap__git_main "$@"

	# Also offer aliases (hub-aliasname-subaliasname, callable via my hub wrapper
	# function as hub aliasname subaliasname).
	typeset -a subAliases=(); readarray -t subAliases < <(compgen -A command -- "hub-${COMP_WORDS[1]}-" 2>/dev/null)
	subAliases=("${subAliases[@]/#hub-${COMP_WORDS[1]}-/}")
	readarray -O ${#COMPREPLY[@]} -t COMPREPLY < <(compgen -W "${subAliases[*]}" -X "!${2}*")
    else
	IFS=$' \t\n' __git_wrap__git_main "$@"
    fi
}
complete -F _hub_complete hub
