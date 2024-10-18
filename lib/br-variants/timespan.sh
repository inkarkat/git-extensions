#!/bin/bash source-this-script
shopt -qs extglob

: ${GIT_TIMESPAN_DEFAULT_COMMAND=${GIT_BRVARIANT_DEFAULT_COMMAND:-lg}}

readonly scriptName="$(basename -- "${BASH_SOURCE[0]}")"
readonly scope="${scriptName#git-}"

printUsage()
{
    cat <<HELPTEXT
Log variants that only cover changes committed ${scopeWhat:?}
of the current / passed via -r|--revision REVISION.
HELPTEXT
    echo
    printf 'Usage: %q %s\n' "$(basename "$1")" 'GIT-COMMAND [...] [-r|--revision REVISION] [...] [-?|-h|--help]'
}

case "$1" in
    --help|-h|-\?)	shift; printUsage "$0"; exit 0;;
esac


gitCommand="${1:-$GIT_TIMESPAN_DEFAULT_COMMAND}"; shift
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
dp[sg]|dpl?(s)[sg]|dpls@(changed|touched)|\
revert@(g|changed|touched|commit@(g|changed|touched))|\
@(correct|fix@(up|amend|wording)|commit@(identical|like|relate)|amendrelate)@(g|changed|touched|st|i|I)|\
detach@(g|changed|touched)|\
who@(when|first|last)|whatdid|churn\
)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "$gitCommand" TIMESPAN "$@";;

    (\
lc@(?(f)?(l)|?(f)@(mine|team))|\
lh@(mine|team)\
)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -3 "$gitCommand" --reverse TIMESPAN "$@";;
    # No lgx because there's no one-more with timespans.
    lc?(f)by)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command -3 "${gitCommand%by}" --reverse AUTHORS TIMESPAN : "$@";;

    d)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 diffuntil TIMESPAN "$@";;
    dsta)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 diffuntil TIMESPAN --shortstat "$@";;
    dstat)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 diffuntil TIMESPAN --stat --compact-summary "$@";;
    ds)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" exec git-selected-command "$scope d" "$@";;
    dss)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -8 selectedcommit-command --single-only --with-range-from-end ^... -2 diff COMMITS TIMESPAN "$@";;
    dsta?(t)byeach)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "log${gitCommand#d}" TIMESPAN "$@";;
    dt)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 difftooluntil TIMESPAN "$@";;
    d[lbwcayYr]|rl)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 "diffuntil${gitCommand#d}" TIMESPAN "$@";;
    ad)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 annotatediffuntil TIMESPAN "$@";;
    adp)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -6 selectedcommit-command --single-only -2 "$gitCommand" COMMITS TIMESPAN "$@";;
    ma)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more -2 format-patch TIMESPAN "$@";;

    st|files|submodules)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --range -2 "show$gitCommand" TIMESPAN "$@";;
    subdo)
	exec git-revision-command --keep-position files-command --source-command "$scope submodules --revision REVISION" --keep-position subdo --for FILES \; "$@";;
    subchanges|superchanges|subrevl@(?(o)g|c))
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --range -2 "$gitCommand" TIMESPAN "$@";;
    subrevdiff)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --with-range ... -2 "$gitCommand" TIMESPAN "$@";;

    # inout does not make sense because the second revision always is an ancestor of the first
    # iofiles does not make sense because the second revision always is an ancestor of the first
    # iosubmodules does not make sense because the second revision always is an ancestor of the first
    # io does not make sense because the second revision always is an ancestor of the first
    # ab does not make sense because the second revision always is an ancestor of the first
    revive)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -3 "$gitCommand" --all TIMESPAN "$@";;
    lby)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -5 others-command -2 l AUTHORS TIMESPAN : "$@";;
    lhby)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command -3 lh --reverse AUTHORS TIMESPAN : "$@";;
    compareourl)
	exec git-branch-command --real-branch-name --keep-position rbrurl-compare-to-base --remote origin --base-command "$scope pred --branch" --base-to-rev --commit BRANCH "$@";;
    compareuurl)
	exec git-branch-command --real-branch-name --keep-position rbrurl-compare-to-base --remote upstream --base-command "$scope pred --branch" --base-to-rev --commit BRANCH "$@";;
    lghipassedfiles)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 lghifiles TIMESPAN "$@";;
    lghifiles)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" exec git-selected-command "$scope lghipassedfiles" "$@";;
    lgby)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command TIMESPAN -2 onelinelog AUTHORS TIMESPAN : "$@";;
    logby)
	exec git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command TIMESPAN -2 log AUTHORS TIMESPAN : "$@";;
    lgfiles@(mine|team|by))
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" exec git-selected-command "$scope lg${gitCommand#lgfiles}" "$@";;

    cors)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 checkoutselectedrevisionselected TIMESPAN "$@";;
    cops)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 checkoutselectedpreviousselected TIMESPAN "$@";;

    revert)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 revertselectedcommit TIMESPAN "$@";;
    revert@(files|hunk))
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "revertselected${gitCommand#revert}" TIMESPAN "$@";;
    revertcommit)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand}selected" TIMESPAN "$@";;

    @(correct|fix@(up|amend|wording))|commit@(identical|like|relate)|amendrelate)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand}selected" TIMESPAN "$@";;
    fix@(up|amend|wording)rb)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand%rb}selectedrb" TIMESPAN "$@";;

    # rb is a no-op, because it iterates over the current range without touching fixups.
    rb?(n)i|segregate@(commits|andbifurcate)|bifurcate)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -8 selectedcommit-command --single-only -4 previouscommit-command --commit COMMITS "$gitCommand" TIMESPAN "$@";;
    rblastfixup)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --one-more -2 "$gitCommand" TIMESPAN "$@";;
    move-to-branch)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more +1 TIMESPAN uncommit-to-branch --exclude-commit "$@";;
    uncommit-to-stash)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -8 selectedcommit-command --pass-file-args -4 uncommit-to-branch --commits COMMITS ; TIMESPAN "$@";;
    uncommit-to-branch)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -7 selectedcommit-command --single-only -3 uncommit-to-branch --from COMMITS TIMESPAN "$@";;

    createbr|stackbrfrom)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand}selected" TIMESPAN "$@";;
    detach)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --range --one-more -2 "${gitCommand}selected" TIMESPAN "$@";;
    wipe)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --range --one-more -2 "${gitCommand}toselected" TIMESPAN "$@";;
    wipe@(g|changed|touched))
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "wipeto${gitCommand#wipe}" TIMESPAN "$@";;

    base)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -3 name-rev --name-only TIMESPAN "$@";;
    baselg)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 lg1 TIMESPAN "$@";;
    bases)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 show TIMESPAN "$@";;
    pred)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more -3 name-rev --name-only TIMESPAN "$@";;
    predlg)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more -2 lg1 TIMESPAN "$@";;
    preds)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more -2 show TIMESPAN "$@";;

    cat|cp)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand}selectedonemore" TIMESPAN "$@";;

    who@(created|lasttouched|did?(f)|owns|contributed|what)thosechangedfiles)
	exec git-revision-command --keep-position files-command --source-command "$scope files --revision REVISION" "${gitCommand%thosechangedfiles}" "$@";;
    who@(created|lasttouched|did?(f)|owns|contributed|what)here)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand%here}" TIMESPAN "$@";;

    emaillog)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -3 email-command log TIMESPAN "$@";;
    emaillc)
	exec git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -3 email-command show TIMESPAN "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	printf >&2 "ERROR: '%s' cannot be used with a %s scope.\\n" "$gitCommand" "$scope"; exit 2;;
esac
