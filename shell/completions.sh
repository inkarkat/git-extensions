#!/bin/bash source-this-script
[ "${BASH_VERSION:-}" ] || return

_scriptDir="$([ "${BASH_SOURCE[0]}" ] && dirname -- "${BASH_SOURCE[0]}" || exit 3)" || return $?
[ -d "$_scriptDir" ] || { echo >&2 'ERROR: Cannot determine script directory!'; return 3; }

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

typeset -ga _git_complete_brvariant_commands=()
readarray -t _git_complete_brvariant_commands < "${_scriptDir}/../lib/br-variants/commands.txt"
typeset -gA _git_complete_brvariants=()
while IFS=$'\n' read -r _line
do
    _git_complete_brvariants["$_line"]=t
done < <(git-br-variants --bare)
unset _line

_git_complete_filterAliasCounts()
{
    typeset -a compReplyWithoutAliasCounts=()
    typeset -A aliasStems=()
    local element; for element in "${COMPREPLY[@]}"
    do
	if [[ "$element" =~ .([1234567xqz]\ )$ ]]; then
	    aliasStems["${element%${BASH_REMATCH[1]}}"]=t
	else
	    compReplyWithoutAliasCounts+=("$element")
	fi
    done

    # Filter out aliases that have a count suffix, as long as we're not only
    # completing that single alias stem itself.
    if [ ${#aliasStems[@]} -gt 1 ]; then
	COMPREPLY=("${!aliasStems[@]}" "${compReplyWithoutAliasCounts[@]}")
    fi
}
_git_complete_filterVariants()
{
    typeset -a compReplyWithoutVariants=()
    typeset -A aliasStems=()
    local element; for element in "${COMPREPLY[@]}"
    do
	if [[ ! "$element" =~ (hi|lg|log)\ ?$ ]] \
	    && [[ "$element" =~ .((last|lastst|lasti|last-i|adst|adi|ad-i|st|i|-i|g)\ ?)$ ]]
	then
	    aliasStems["${element%${BASH_REMATCH[1]}}"]=t
	else
	    compReplyWithoutVariants+=("$element")
	fi
    done
    ####D DUMPARGS_SINK='&1' dump-args -a aliasStems -- "${!aliasStems[@]}" | surround -- '[s[1;1H[0K[37;44m[' '][0m[u' | noeol

    # Filter out aliases that have a variant suffixes, as long as we're not only
    # completing that single variant stem itself.
    if [ ${#aliasStems[@]} -gt 1 ]; then
	COMPREPLY=("${!aliasStems[@]}" "${compReplyWithoutVariants[@]}")
    fi
}

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

    if ! type -t __git_wrap__git_main >/dev/null; then
	# Bash completion for Git is dynamically loaded, so its completion
	# function may not exist yet; especially because its auto-loading will
	# never be triggered as we've overridden it here.
	# However, if hub is installed, its completion eagerly loads Git's
	# completion (to be able to patch it).
	[ -e /usr/share/bash-completion/completions/git ] \
	    && source /usr/share/bash-completion/completions/git \
	    && type -t __git_wrap__git_main >/dev/null
    fi && {
	if [[ "${COMP_WORDS[1]}" =~ do(-core)?$ ]]; then
	    # Also offer Git commands and defined aliases as "git SIMPLECOMMAND"
	    # after a *do command.
	    typeset -a save_COMP_WORDS=("${COMP_WORDS[@]}"); COMP_WORDS=(git "${COMP_WORDS[-1]}")
		COMP_CWORD=1 \
		    IFS=$' \t\n' __git_wrap__git_main "${COMP_WORDS[0]}" "${COMP_WORDS[1]}" ""
	    COMP_WORDS=("${save_COMP_WORDS[@]}")
	else
	    IFS=$' \t\n' __git_wrap__git_main "$@"
	fi
    }

    if [ $COMP_CWORD -eq 1 ]; then
	# Bash completion for Git already offer git-aliasnames.
	:
    elif [ $COMP_CWORD -eq 2 ]; then
	if [ "${_git_complete_brvariants["${COMP_WORDS[1]}"]}" ]; then
	    # Offer commands applicable to a branch-range variant.
	    readarray -t COMPREPLY < <(compgen -W "${_git_complete_brvariant_commands[*]}" -- "$2")
	    return
	fi

	# Also offer aliases (git-aliasname-subaliasname, callable via my git wrapper
	# function as git aliasname subaliasname).
	typeset -a subAliases=(); readarray -t subAliases < <(compgen -A command -- "git-${COMP_WORDS[1]}-" 2>/dev/null)
	subAliases=("${subAliases[@]/#git-${COMP_WORDS[1]}-/}")
	readarray -O ${#COMPREPLY[@]} -t COMPREPLY < <(compgen -W "${subAliases[*]}" -- "$2")
    fi

    # Need to filter in reverse order: First drop counts, then variants.
    _git_complete_filterAliasCounts
    _git_complete_filterVariants
}
complete -o bashdefault -o default -o nospace -F _git_complete git

_hub_complete()
{
    local IFS=$'\n'

    # Custom commands that only make sense in the hub context should be named
    # hub-*, so that they won't be offered in the Git completion.
    # Pure hub aliases should be made a small wrapper script.
    typeset -a aliases=(); readarray -t aliases < <(compgen -A command -- 'hub-' 2>/dev/null)
    aliases=("${aliases[@]/#hub-/}")

    # Detect commands that can be used with both git and hub by having a check
    # for the "$HUB" variable in their source code.
    typeset -a multiModeCommands=(); readarray -t multiModeCommands < <(
	command cd "$(dirname -- "$(command -v git-wrapper)" 2>/dev/null)" \
	    && grep --fixed-strings --files-with-matches --no-messages '"$HUB"' -- git-* 2>/dev/null
    )
    aliases+=("${multiModeCommands[@]/#git-/}")

    # Detect aliases that can be used with both git and hub through a "HUB" marker comment at the end of the line of the alias definition.
    typeset -a multiModeAliases=(); readarray -t multiModeAliases < <(
	command cd "$(dirname -- "$(command -v git-wrapper)" 2>/dev/null)/.." \
	    && sed -ne 's#^[[:space:]]*\(;; \([[:alnum:]]\+\):\|\([[:alnum:]]\+\) =\) .* HUB$#\2\3#p' gitconfig* 2>/dev/null
    )
    aliases+=("${multiModeAliases[@]}")

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
	readarray -O ${#COMPREPLY[@]} -t COMPREPLY < <(compgen -W "${builtinCommands[*]}"$'\n'"${aliases[*]}" -- "$2")
    elif [ $COMP_CWORD -eq 2 ]; then
	IFS=$' \t\n' __git_wrap__git_main "$@"

	# Also offer aliases (hub-aliasname-subaliasname, callable via my hub wrapper
	# function as hub aliasname subaliasname).
	typeset -a subAliases=(); readarray -t subAliases < <(compgen -A command -- "hub-${COMP_WORDS[1]}-" 2>/dev/null)
	subAliases=("${subAliases[@]/#hub-${COMP_WORDS[1]}-/}")
	readarray -O ${#COMPREPLY[@]} -t COMPREPLY < <(compgen -W "${subAliases[*]}" -- "$2")
    else
	IFS=$' \t\n' __git_wrap__git_main "$@"
    fi
}
complete -o bashdefault -o default -o nospace -F _hub_complete hub

unset _scriptDir
