#!/bin/bash source-this-script
shopt -qs extglob

readonly scriptName="$(basename -- "${BASH_SOURCE[0]}")"
readonly scope="${scriptName#git-}"

printUsage()
{
    cat <<HELPTEXT
Log variants that only cover changes committed ${scopeWhat:?}.
HELPTEXT
    echo
    printf 'Usage: %q %s\n' "$(basename "$1")" 'GIT-COMMAND [...] [-?|-h|--help]'
}

case "$1" in
    --help|-h|-\?)	shift; printUsage "$0"; exit 0;;
esac


gitCommand="$1"; shift
case "$gitCommand" in
    (\
l?(o)gg?(v)?(mine)|\
lc?(l)g?(mine)|\
lc?(h)|\
@(l?(o)g?([fv])|l?(o)|count|logdistribution)?(mine|team)|\
log@(mod|added|deleted|renamed)?(files)|glog|logbrowse|\
lg@(rel|tagged|st|i|I)|\
@(l|tree)?([ou])url?(v)|\
lghi?(st|i|I)|\
@(logg|changed|touched)@(files|versions|tags)|\
@(changed|touched)l?(o)g?(v)?(mine)|\
@(changed|touched)lc?(l)?(mine)|\
where@(last|introduced)@(logg?(v)|showg)?(mine)|\
where@(last|introduced)@(logg|changed|touched)@(files|version|tag)|\
where@(last|introduced)@(changed|touched)@(log?(v)|show)?(mine)|\
ss@(?([wcag])|changed|touched)|\
sls?(g|changed|touched)|\
dp[sg]|dpl?(s)[sg]|dpls@(changed|touched)\
)
	exec "git-${scopeCommand:?}" -2 "$gitCommand" LASTYEAR "$@";;

    (\
lc@(?(f)?(l)|?(f)@(mine|team))|\
lh@(mine|team)\
)
	exec "git-${scopeCommand:?}" -3 "$gitCommand" --reverse LASTYEAR "$@";;
    lc?(f)by)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command -3 "${gitCommand%by}" --reverse AUTHORS LASTYEAR : "$@";;

    d)
	exec "git-${scopeCommand:?}" --no-range -2 diffuntil LASTYEAR "$@";;
    dsta)
	exec "git-${scopeCommand:?}" --no-range -2 diffuntil LASTYEAR --shortstat "$@";;
    dstat)
	exec "git-${scopeCommand:?}" --no-range -2 diffuntil LASTYEAR --stat --compact-summary "$@";;
    ds)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" exec git-selected-command "$scope d" "$@";;
    dss)
	exec "git-${scopeCommand:?}" -8 selectedcommit-command --single-only --with-range-from-end ^... -2 diff COMMITS LASTYEAR "$@";;
    dsta?(t)byeach)
	exec "git-${scopeCommand:?}" -2 "log${gitCommand#d}" LASTYEAR "$@";;
    dt)
	exec "git-${scopeCommand:?}" --no-range -2 difftooluntil LASTYEAR "$@";;
    d[lbwcayYr]|rl)
	exec "git-${scopeCommand:?}" --no-range -2 "diffuntil${gitCommand#d}" LASTYEAR "$@";;
    ad)
	exec "git-${scopeCommand:?}" --no-range -2 annotatediffuntil LASTYEAR "$@";;
    adp)
	exec "git-${scopeCommand:?}" -6 selectedcommit-command --single-only -2 "$gitCommand" COMMITS LASTYEAR "$@";;
    ma)
	exec "git-${scopeCommand:?}" --no-range --one-more -2 format-patch LASTYEAR "$@";;

    st|files|submodules)
	exec "git-${scopeCommand:?}" --range -2 "show$gitCommand" LASTYEAR "$@";;
    subdo)
	exec git-files-command --source-command "$scope submodules" --keep-position subdo --for FILES \; "$@";;
    subchanges|superchanges|subrevl@(?(o)g|c))
	exec "git-${scopeCommand:?}" --range -2 "$gitCommand" LASTYEAR "$@";;
    subrevdiff)
	exec "git-${scopeCommand:?}" --with-range ... -2 "$gitCommand" LASTYEAR "$@";;

    # inout does not make sense because the second revision always is an ancestor of the first
    # iofiles does not make sense because the second revision always is an ancestor of the first
    # iosubmodules does not make sense because the second revision always is an ancestor of the first
    # io does not make sense because the second revision always is an ancestor of the first
    # ab does not make sense because the second revision always is an ancestor of the first
    revive)
	exec "git-${scopeCommand:?}" -3 "$gitCommand" --all LASTYEAR "$@";;
    lby)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -5 others-command -2 l AUTHORS LASTYEAR : "$@";;
    lhby)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command -3 lh --reverse AUTHORS LASTYEAR : "$@";;
    compareourl)
	exec git-branch-command --real-branch-name --keep-position rbrurl-compare-to-base --remote origin --base-command "$scope pred --branch" --base-to-rev --commit BRANCH "$@";;
    compareuurl)
	exec git-branch-command --real-branch-name --keep-position rbrurl-compare-to-base --remote upstream --base-command "$scope pred --branch" --base-to-rev --commit BRANCH "$@";;
    lghipassedfiles)
	exec "git-${scopeCommand:?}" -2 lghifiles LASTYEAR "$@";;
    lghifiles)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" exec git-selected-command "$scope lghipassedfiles" "$@";;
    lgby)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command LASTYEAR -2 onelinelog AUTHORS LASTYEAR : "$@";;
    logby)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command LASTYEAR -2 log AUTHORS LASTYEAR : "$@";;
    lgfiles@(mine|team|by))
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" exec git-selected-command "$scope lg${gitCommand#lgfiles}" "$@";;

    cors)
	exec "git-${scopeCommand:?}" -2 checkoutselectedrevisionselected LASTYEAR "$@";;
    cops)
	exec "git-${scopeCommand:?}" -2 checkoutselectedpreviousselected LASTYEAR "$@";;

    revert)
	exec "git-${scopeCommand:?}" -2 revertselectedcommit LASTYEAR "$@";;
    revert@(files|hunk))
	exec "git-${scopeCommand:?}" -2 "revertselected${gitCommand#revert}" LASTYEAR "$@";;
    revert@(g|changed|touched|commit@(g|changed|touched)))
	exec "git-${scopeCommand:?}" -2 "$gitCommand" LASTYEAR "$@";;
    revertcommit)
	exec "git-${scopeCommand:?}" -2 "${gitCommand}selected" LASTYEAR "$@";;

    @(correct|fix@(up|amend|wording))|commit@(identical|like|relate)|amendrelate)
	exec "git-${scopeCommand:?}" -2 "${gitCommand}selected" LASTYEAR "$@";;
    @(correct|fix@(up|amend|wording)|commit@(identical|like|relate)|amendrelate)@(g|changed|touched|st|i|I))
	exec "git-${scopeCommand:?}" -2 "$gitCommand" LASTYEAR "$@";;
    fix@(up|amend|wording)rb)
	exec "git-${scopeCommand:?}" -2 "${gitCommand%rb}selectedrb" LASTYEAR "$@";;

    # rb is a no-op, because it iterates over the current range without touching fixups.
    rb?(n)i|segregate@(commits|andbifurcate)|bifurcate)
	exec "git-${scopeCommand:?}" -8 selectedcommit-command --single-only -4 previouscommit-command --commit COMMITS "$gitCommand" LASTYEAR "$@";;
    rblastfixup)
	exec "git-${scopeCommand:?}" --one-more -2 "$gitCommand" LASTYEAR "$@";;
    move-to-branch)
	exec "git-${scopeCommand:?}" --no-range --one-more +1 LASTYEAR uncommit-to-branch --exclude-commit "$@";;
    uncommit-to-stash)
	exec "git-${scopeCommand:?}" -8 selectedcommit-command --pass-file-args -4 uncommit-to-branch --commits COMMITS ; LASTYEAR "$@";;
    uncommit-to-branch)
	exec "git-${scopeCommand:?}" -7 selectedcommit-command --single-only -3 uncommit-to-branch --from COMMITS LASTYEAR "$@";;

    createbr|stackbrfrom)
	exec "git-${scopeCommand:?}" -2 "${gitCommand}selected" LASTYEAR "$@";;
    detach)
	exec "git-${scopeCommand:?}" --range --one-more -2 "${gitCommand}selected" LASTYEAR "$@";;
    detach@(g|changed|touched))
	exec "git-${scopeCommand:?}" -2 "$gitCommand" LASTYEAR "$@";;
    wipe)
	exec "git-${scopeCommand:?}" --range --one-more -2 "${gitCommand}toselected" LASTYEAR "$@";;
    wipe@(g|changed|touched))
	exec "git-${scopeCommand:?}" -2 "wipeto${gitCommand#wipe}" LASTYEAR "$@";;

    base)
	exec "git-${scopeCommand:?}" --no-range -3 name-rev --name-only LASTYEAR "$@";;
    baselg)
	exec "git-${scopeCommand:?}" --no-range -2 lg1 LASTYEAR "$@";;
    bases)
	exec "git-${scopeCommand:?}" --no-range -2 show LASTYEAR "$@";;
    pred)
	exec "git-${scopeCommand:?}" --no-range --one-more -3 name-rev --name-only LASTYEAR "$@";;
    predlg)
	exec "git-${scopeCommand:?}" --no-range --one-more -2 lg1 LASTYEAR "$@";;
    preds)
	exec "git-${scopeCommand:?}" --no-range --one-more -2 show LASTYEAR "$@";;

    cat|cp)
	exec "git-${scopeCommand:?}" -2 "${gitCommand}selectedonemore" LASTYEAR "$@";;

    who@(created|lasttouched|did?(f)|owns|contributed|what)thosechangedfiles)
	exec git-files-command --source-command "$scope files" "${gitCommand%thosechangedfiles}" "$@";;
    who@(created|lasttouched|did?(f)|owns|contributed|what)here)
	exec "git-${scopeCommand:?}" -2 "${gitCommand%here}" LASTYEAR "$@";;
    who@(when|first|last)|whatdid|churn)
	exec "git-${scopeCommand:?}" -2 "$gitCommand" LASTYEAR "$@";;

    emaillog)
	exec "git-${scopeCommand:?}" -3 email-command log LASTYEAR "$@";;
    emaillc)
	exec "git-${scopeCommand:?}" -3 email-command show LASTYEAR "$@";;

    *)	printf >&2 'Unknown sub-command: %s\n' "$gitCommand"; exit 2;;
esac
