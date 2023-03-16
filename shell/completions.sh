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
