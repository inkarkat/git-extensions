#!/bin/bash source-this-script
shopt -qs extglob

: ${GIT_TIMESPAN_DEFAULT_COMMAND=${GIT_BRVARIANT_DEFAULT_COMMAND:-lg}}

readonly scriptName="$(basename -- "$0")"
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


: ${EXEC:=exec}
gitCommand="${1:-$GIT_TIMESPAN_DEFAULT_COMMAND}"; shift
case "$gitCommand" in
    (\
l?(o)g?(v)g?(mine)|\
lc?(l)g?(mine)|\
lc?(h)|\
lc@(?(l)?(f)|?(f)@(mine|team))|\
lh?(mine|team)|\
@(l?(o)g?([fv])|l?(o)|count|logdistribution)?(mine|team)|\
log?(mod|added|deleted|renamed)?(files)|glog|logbrowse|\
lg@(rel|tagged|st|i|I)|\
@(l|tree)?([ou])url?(v)|\
lghi?(st|i|I)|\
@(files|versions|tags)@(g|changed|touched)|\
l?(o)g?(v)@(changed|touched)?(mine)|\
lc?(l)@(changed|touched)?(mine)|\
@(log?(v)|show)@(last|first)g?(mine)|\
@(files|version|tag)@(last|first)@(g|changed|touched)|\
@(log?(v)|show)@(last|first)@(changed|touched)?(mine)|\
ss@(?([wcag])|changed|touched)|\
sls?(g|changed|touched)|\
dp[sg]|dpl?(s)[sg]|dpls@(changed|touched)|\
revert@(g|changed|touched|commit@(g|changed|touched))|\
@(correct|fix@(up|amend|wording)|commit@(identical|like|relate)|amendrelate)@(g|changed|touched|st|i|I)|\
detach@(g|changed|touched)|\
who@(when|first|last)|whatdid|churn\
)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "$gitCommand" TIMESPAN "$@";;

    lgx)
	# lgx is identical lg to because there's no one-more with timespans.
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 lg TIMESPAN "$@";;
    lc?(f)by)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command -2 "${gitCommand%by}" AUTHORS TIMESPAN : "$@";;

    d)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 diffuntil TIMESPAN "$@";;
    dsta)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 diffuntil TIMESPAN --shortstat "$@";;
    dstat)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 diffuntil TIMESPAN --stat --compact-summary "$@";;
    ds)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope d" "$@";;
    dss)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -8 selectedcommit-command --single-only --with-range-from-end ^... -2 diff COMMITS TIMESPAN "$@";;
    dsta?(t)byeach)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "log${gitCommand#d}" TIMESPAN "$@";;
    dt)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 difftooluntil TIMESPAN "$@";;
    d[lbwcayYr]|drl)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 "diffuntil${gitCommand#d}" TIMESPAN "$@";;
    ad)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 annotatediffuntil TIMESPAN "$@";;
    adp)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -6 selectedcommit-command --single-only -2 "$gitCommand" COMMITS TIMESPAN "$@";;
    ma)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more -2 format-patch TIMESPAN "$@";;

    st|files|submodules)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --range -2 "show$gitCommand" TIMESPAN "$@";;
    subdo)
	$EXEC git-revision-command --keep-position files-command --source-command "$scope submodules --revision REVISION" --keep-position subdo --for FILES \; "$@";;
    subchanges|superchanges|subrevl@(?(o)g|c))
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --range -2 "$gitCommand" TIMESPAN "$@";;
    subrevdiff)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --with-range ... -2 "$gitCommand" TIMESPAN "$@";;

    inout|io?(files|submodules)|ab)
	$EXEC echo "Note: $gitCommand does not make sense here because the second revision always is an ancestor of the first.";;

    revive)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -3 "$gitCommand" --all TIMESPAN "$@";;
    l?(h)by)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand:?}" -5 others-command -2 "${gitCommand%by}" AUTHORS TIMESPAN : "$@";;
    compareourl)
	$EXEC git-branch-command --real-branch-name --keep-position rbrurl-compare-to-base --remote origin --base-command "$scope pred --branch" --base-to-rev --commit BRANCH "$@";;
    compareuurl)
	$EXEC git-branch-command --real-branch-name --keep-position rbrurl-compare-to-base --remote upstream --base-command "$scope pred --branch" --base-to-rev --commit BRANCH "$@";;
    lghipassedfiles)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 lghifiles TIMESPAN "$@";;
    lghifiles)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lghipassedfiles" "$@";;
    lgby)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command TIMESPAN -2 onelinelog AUTHORS TIMESPAN : "$@";;
    logby)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand:?}" -6 others-command TIMESPAN -2 log AUTHORS TIMESPAN : "$@";;
    lgfiles@(mine|team|by))
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lg${gitCommand#lgfiles}" "$@";;

    cors)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 checkoutselectedrevisionselected TIMESPAN "$@";;
    cops)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 checkoutselectedpreviousselected TIMESPAN "$@";;

    revert)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 revertselectedcommit TIMESPAN "$@";;
    revert@(files|hunk))
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "revertselected${gitCommand#revert}" TIMESPAN "$@";;
    revertcommit)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand}selected" TIMESPAN "$@";;

    @(correct|fix@(up|amend|wording))|commit@(identical|like|relate)|amendrelate)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand}selected" TIMESPAN "$@";;
    fix@(up|amend|wording)rb)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand%rb}selectedrb" TIMESPAN "$@";;

    rb)
	$EXEC echo "Note: $gitCommand is a no-op, because it iterates over the current range without touching fixups.";;
    rb?(n)i|segregate@(commits|andbifurcate)|bifurcate)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -8 selectedcommit-command --single-only -4 previouscommit-command --commit COMMITS "$gitCommand" TIMESPAN "$@";;
    rblastfixup)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --one-more -2 "$gitCommand" TIMESPAN "$@";;
    move-to-branch)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more +1 TIMESPAN uncommit-to-branch --exclude-commit "$@";;
    uncommit-to-stash)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -8 selectedcommit-command --pass-file-args -4 uncommit-to-branch --commits COMMITS \; TIMESPAN "$@";;
    uncommit-to-branch)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -7 selectedcommit-command --single-only -3 uncommit-to-branch --from COMMITS TIMESPAN "$@";;

    createbr|stackbrfrom)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand}selected" TIMESPAN "$@";;
    detach)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --range --one-more -2 "${gitCommand}selected" TIMESPAN "$@";;
    wipe)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --range --one-more -2 "${gitCommand}toselected" TIMESPAN "$@";;
    wipe@(g|changed|touched))
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "wipeto${gitCommand#wipe}" TIMESPAN "$@";;

    base)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -3 name-rev --name-only TIMESPAN "$@";;
    baselg)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 lg1 TIMESPAN "$@";;
    bases)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range -2 show TIMESPAN "$@";;
    pred)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more -3 name-rev --name-only TIMESPAN "$@";;
    predlg)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more -2 lg1 TIMESPAN "$@";;
    preds)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION --no-range --one-more -2 show TIMESPAN "$@";;

    cat|cp)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand}selectedonemore" TIMESPAN "$@";;

    who@(created|lasttouched|did?(f)|owns|contributed|what)thosechangedfiles)
	$EXEC git-revision-command --keep-position files-command --source-command "$scope files --revision REVISION" "${gitCommand%thosechangedfiles}" "$@";;
    who@(created|lasttouched|did?(f)|owns|contributed|what)here)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -2 "${gitCommand%here}" TIMESPAN "$@";;

    activity?(mine|team))
	$EXEC echo "Note: $gitCommmand would just trim activity to ${scopeWhat}.";;

    emaillog)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -3 email-command log TIMESPAN "$@";;
    emaillc)
	$EXEC git-revision-command --keep-position "${scopeCommand:?}" --revision REVISION -3 email-command show TIMESPAN "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	printf >&2 "ERROR: '%s' cannot be used with a %s scope.\\n" "$gitCommand" "$scope"; exit 2;;
esac
