#!/bin/bash source-this-script
# shellcheck disable=SC2145
shopt -qs extglob

: ${GIT_CUSTOMRANGEVARIANT_DEFAULT_COMMAND=${GIT_REVRANGE_DEFAULT_COMMAND:-lg}}

readonly scriptName="$(basename -- "$0")"
readonly scope="${scriptName#git-}"

printUsage()
{
    cat <<HELPTEXT
Log variants that cover ${scopeWhat:?}.
HELPTEXT
    echo
    printf 'Usage: %q %s\n' "$(basename "$1")" 'GIT-COMMAND [...] [-b|--branch BRANCH] [...] [-?|-h|--help]'
}

case "$1" in
    --help|-h|-\?)	shift; printUsage "$0"; exit 0;;
esac

onLocalBranch()
{
    if [ "$scopeNoLocalBranch" ]; then
	$EXEC echo "Note: $gitCommand requires a local branch, but ${scope} does not provide one."
    else
	$EXEC "$@"
    fi
}


: ${EXEC:=exec}
gitCommand="${1:-$GIT_CUSTOMRANGEVARIANT_DEFAULT_COMMAND}"; shift
case "$gitCommand" in
    lc?(f)?(mine|team))
	$EXEC git-"${scopeCommand[@]}" --one-more-command log --one-more-with-padding -2 "$gitCommand" RANGE "$@";;
    lch)
	$EXEC git-"${scopeCommand[@]}" --one-more-command showh --one-more-with-padding -2 "$gitCommand" RANGE "$@";;
    (\
lg?([fv])|\
lg@(rel|tagged|st|i|I)\
)
	$EXEC git-"${scopeCommand[@]}" --one-more-command greyonelinelog --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    log?([fv]|files))
	$EXEC git-"${scopeCommand[@]}" --one-more-command greylog --one-more-with-padding --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi)
	$EXEC git-"${scopeCommand[@]}" --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi?(st|i|I))
	$EXEC git-"${scopeCommand[@]}" --one-more-command "greyonelineloghighlight $gitCommand" --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;

    (\
l?(o)g?(v)g?(mine)|\
lc?(l)g?(mine)|\
lcl?(f)|\
lh?(mine|team)|\
l?(o)g?([fv])@(mine|team)|\
@(l?(o)|count|logdistribution)?(mine|team)|\
log?(mod|added|deleted|renamed)?(files)|glog|logbrowse|\
@(l|tree)?([ou])url?(v)|\
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
who@(when|first|last)|whatdid|churn|\
activity?(mine|team)|\
subchanges|superchanges|subrevl@(?(o)g|c)\
)
	$EXEC git-"${scopeCommand[@]}" -2 "$gitCommand" RANGE "$@";;

    lgx)
	$EXEC git-"${scopeCommand[@]}" -2 lg RANGE "$@";;
    lc?(f)by)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand[@]}" --one-more-command log --one-more-with-padding others-command -2 "${gitCommand%by}" AUTHORS RANGE : "$@";;

    d?([lbwcayYrt]|rl)|dsta?(t)|ad|subrevdiff)
	$EXEC git-"${scopeCommand[@]}" --with-range ... -2 "$gitCommand" RANGE "$@";;
    ds)
	$EXEC git-branch-command --keep-position files-command --source-command "$scope files --branch BRANCH" "${scopeCommand[@]}" --branch BRANCH --with-range ... -2 diffselected RANGE "$@";;
    dss)
	$EXEC git-"${scopeCommand[@]}" --keep-position selectedcommit-command --single-only --with-range-from-end ^... --range-is-last -3 diff COMMITS RANGE "$@";;
    dsta?(t)byeach)
	$EXEC git-"${scopeCommand[@]}" -2 "log${gitCommand#d}" RANGE "$@";;
    adp)
	$EXEC git-"${scopeCommand[@]}" --keep-position selectedcommit-command --single-only --range-is-last -3 "$gitCommand" COMMITS RANGE "$@";;
    ma)
	$EXEC git-"${scopeCommand[@]}" -2 format-patch RANGE "$@";;

    st|files|submodules)
	$EXEC git-"${scopeCommand[@]}" -2 "show$gitCommand" RANGE "$@";;
    subdo)
	$EXEC git-branch-command --keep-position files-command --source-command "$scope submodules --branch BRANCH" --keep-position subdo --for FILES \; "$@";;

    inout|io?(files|submodules)|ab)
	if [ -n "$scopeInoutNote" ]; then
	    $EXEC echo "Note: ${gitCommand} ${scopeInoutNote}"
	else
	    $EXEC git-"${scopeCommand[@]}" --no-range -3 "$gitCommand" --base RANGE "$@"
	fi
	;;

    revive)
	$EXEC git-"${scopeCommand[@]}" -3 "$gitCommand" --all RANGE "$@";;
    lby)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand[@]}" -5 others-command -2 l AUTHORS RANGE : "$@";;
    lhby)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand[@]}" -6 others-command -2 lh AUTHORS RANGE : "$@";;
    compareourl)
	$EXEC git-"${scopeCommand[@]}" -5 rbrurl-compare-to-base --remote origin --range RANGE --base-to-rev --commit-to-rev "$@";;
    compareuurl)
	$EXEC git-"${scopeCommand[@]}" -5 rbrurl-compare-to-base --remote upstream --range RANGE --base-to-rev --commit-to-rev "$@";;
    lghipassedfiles)
	$EXEC git-"${scopeCommand[@]}" --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 lghifiles RANGE "$@";;
    lghifiles)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lghipassedfiles" "$@";;
    lgby)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand[@]}" -7 others-command --range RANGE -2 onelinelog AUTHORS RANGE : "$@";;
    logby)
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand[@]}" -7 others-command --range RANGE -2 log AUTHORS RANGE : "$@";;
    lgfiles@(mine|team|by))
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lg${gitCommand#lgfiles}" "$@";;

    cors)
	$EXEC git-"${scopeCommand[@]}" -2 checkoutselectedrevisionselected RANGE "$@";;
    cops)
	$EXEC git-"${scopeCommand[@]}" -2 checkoutselectedpreviousselected RANGE "$@";;

    revert)
	$EXEC git-"${scopeCommand[@]}" -2 revertselectedcommit RANGE "$@";;
    revert@(files|hunk))
	$EXEC git-"${scopeCommand[@]}" -2 "revertselected${gitCommand#revert}"  RANGE "$@";;
    revertcommit)
	$EXEC git-"${scopeCommand[@]}" -2 "${gitCommand}selected" RANGE "$@";;

    @(correct|fix@(up|amend|wording))|commit@(identical|like|relate)|amendrelate)
	$EXEC git-"${scopeCommand[@]}" -2 "${gitCommand}selected" RANGE "$@";;
    fix@(up|amend|wording)rb)
	onLocalBranch git-"${scopeCommand[@]}" -2 "${gitCommand%rb}selectedrb" RANGE "$@";;

    rb)
	onLocalBranch echo "Note: $gitCommand is a no-op, because it iterates over the current range without touching fixups. Use the dedicated check|command|exec to iterate over all branch commits. To rebase onto ${scopeWhat}, there's a dedicated alias outside of \"git ${scope}\".";;
    rb?(n)i|segregate@(commits|andbifurcate)|bifurcate)
	onLocalBranch git-"${scopeCommand[@]}" --keep-position selectedcommit-command --single-only --range-is-last -5 previouscommit-command --commit COMMITS "$gitCommand" RANGE "$@";;
    rblastfixup)
	onLocalBranch git-"${scopeCommand[@]}" --one-more -2 "$gitCommand" RANGE "$@";;
    move-to-branch)
	onLocalBranch git-"${scopeCommand[@]}" --no-range -4 uncommit-to-branch --exclude-commit --from RANGE "$@";;
    uncommit-to-stash)
	onLocalBranch git-"${scopeCommand[@]}" --keep-position selectedcommit-command --pass-file-args --range-is-last -5 "$gitCommand" --commits COMMITS \; RANGE "$@";;
    uncommit-to-branch)
	onLocalBranch git-"${scopeCommand[@]}" --keep-position selectedcommit-command --single-only --range-is-last -4 "$gitCommand" --from COMMITS RANGE "$@";;

    createbr|stackbrfrom)
	$EXEC git-"${scopeCommand[@]}" -2 "${gitCommand}selected" RANGE "$@";;
    detach)
	$EXEC git-"${scopeCommand[@]}" --one-more -2 "${gitCommand}selected" RANGE "$@";;
    wipe)
	$EXEC git-"${scopeCommand[@]}" --one-more -2 "${gitCommand}toselected" RANGE "$@";;
    wipe@(g|changed|touched))
	$EXEC git-"${scopeCommand[@]}" -2 "wipeto${gitCommand#wipe}" RANGE "$@";;

    base)
	$EXEC git-"${scopeCommand[@]}" --no-range -3 name-rev --name-only RANGE "$@";;
    baselg)
	$EXEC git-"${scopeCommand[@]}" --no-range -2 lg1 RANGE "$@";;
    bases)
	$EXEC git-"${scopeCommand[@]}" --no-range -2 show RANGE "$@";;
    pred)
	$EXEC git-"${scopeCommand[@]}" --no-range --one-more -3 name-rev --name-only RANGE "$@";;
    predlg)
	$EXEC git-"${scopeCommand[@]}" --no-range --one-more -2 lg1 RANGE "$@";;
    preds)
	$EXEC git-"${scopeCommand[@]}" --no-range --one-more -2 show RANGE "$@";;

    cat|cp)
	$EXEC git-"${scopeCommand[@]}" -2 "${gitCommand}selectedonemore" RANGE "$@";;

    who@(created|lasttouched|did?(f)|owns|contributed|what)thosechangedfiles)
	$EXEC git-branch-command --keep-position files-command --source-command "$scope files --branch BRANCH" "${gitCommand%thosechangedfiles}" "$@";;
    who@(created|lasttouched|did?(f)|owns|contributed|what)here)
	$EXEC git-"${scopeCommand[@]}" -2 "${gitCommand%here}" RANGE "$@";;

    emaillog)
	$EXEC git-"${scopeCommand[@]}" -3 email-command log RANGE "$@";;
    emaillc)
	$EXEC git-"${scopeCommand[@]}" -3 email-command lc RANGE "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	printf >&2 "ERROR: '%s' cannot be used with a %s scope.\\n" "$gitCommand" "$scope"; exit 2;;
esac
