#!/bin/bash source-this-script
shopt -qs extglob

: ${GIT_BRVARIANT_DEFAULT_COMMAND=${GIT_REVRANGE_DEFAULT_COMMAND:-lg}}

readonly scriptName="$(basename -- "$0")"
readonly scope="${scriptName#git-}"

printUsage()
{
    if [ "$scopeEndRevision" = BRANCH ]; then
	local from='the current / passed BRANCH'
	local to="${scopeWhat:?}"
    else
	local from="${scopeWhat:?}"
	local to='the current / passed BRANCH'
    fi
    cat <<HELPTEXT
Covers ${scopeWhatOverride:-the additions of ${from}
versus ${to}}.
HELPTEXT
    echo
    printf 'Usage: %q %s\n' "$(basename "$1")" "GIT-COMMAND ${scopeArgsOverride:-[...] [-b|--branch BRANCH] [...] }${scopeArgsOverride:+ }[-?|-h|--help]"
}

case "$1" in
    --help|-h|-\?)	shift; printUsage "$0"; exit 0;;
esac

othersCommand()
{
    typeset -a inversionArg=(); [[ "$gitCommand" =~ exceptby$ ]] && inversionArg=(--invert-authors)
    $EXEC git-dashdash-default-command --with-files : branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" "${revRangeAdditionalArgs[@]}" -$((7 + ${#inversionArg[@]})) authors-command "${inversionArg[@]}" --range RANGE -2 "${gitCommand%%?(except)by}" AUTHORS RANGE : "$@"
}

: ${EXEC:=exec}
if [ $# -lt ${#scopeMandatoryArgs[@]} ]; then
    printf >&2 'ERROR: Required arguments missing: %s\n' "${scopeMandatoryArgs[*]}"
    exit 2
elif [ $# -eq ${#scopeMandatoryArgs[@]} ]; then
    gitCommand="$GIT_BRVARIANT_DEFAULT_COMMAND"
else
    gitCommand="${1:?}"; shift
fi

typeset -a revRangeAdditionalArgs=()
case "$gitCommand" in
    lc?(f)?(mine|others|team))
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more-command log --one-more-with-padding -2 "$gitCommand" RANGE "$@";;
    lch)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more-command showh --one-more-with-padding -2 "$gitCommand" RANGE "$@";;
    (\
lg?([fv]|merges)|\
lg@(rel|tagged|st|i|I)\
)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more-command greyonelinelog --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    log?([fv]|merges|files))
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more-command greylog --one-more-with-padding --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi?(st|i|I))
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more-command "greyonelineloghighlight $gitCommand" --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;

    (\
@(lc?(l)|l?(o)g?(v)|count)@(g|changed|touched)?(mine|others|team)|\
@(log?(v)|show)@(last|first)@(g|changed|touched)?(mine|others|team)|\
lcl?(f)|\
lh?(mine|others|team)|\
l?(o)g?([fv]|merges)@(mine|others|team)|\
@(l?(o)|count|countmaxdaycommits|commitsperday|logdistribution|brlifetimes)?(mine|others|team)|\
brlifetimesbyeach|\
log?(mod|added|deleted|renamed)?(files)|glog|logbrowse|logsize|\
l[ou]url?(v)|\
@(files|versions|tags)@(g|changed|touched)|\
@(files|version|tag)@(last|first)@(g|changed|touched)|\
ss@(?([wcag])|changed|touched)|\
sls?(g|changed|touched)|\
dp[sg]|dpl?(s)[sg]|dpls@(changed|touched)|\
revert@(g|changed|touched|commit@(g|changed|touched))|\
@(correct|fix@(up|amend|wording)|commit@(identical|like|relate)|amendrelate)@(g|changed|touched|st|i|I)|\
detach@(g|changed|touched)|\
who@(when|first|last)|whatdid|relatedfiles|churn|\
activity?(mine|others|team)|\
subchanges|superchanges|subrevl@(?(o)g|c)\
)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "$gitCommand" RANGE "$@";;

    lgx)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 lg RANGE "$@";;

    d?([lbwcayYrt]|rl)|dsta?(t)|@(ad|ov)|subrevdiff)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --with-range ... -2 "$gitCommand" RANGE "$@";;
    ds)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position files-command --source-exec showfiles RANGE \; diffselected --log-range RANGE "$@";;
    dss)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position selectedcommit-command --single-only --with-range-from-end ^... --range-is-last -3 diff COMMITS RANGE "$@";;
    dsta?(t)byeach)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "log${gitCommand#d}" RANGE "$@";;
    @(ad|ov)p)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position selectedcommit-command --single-only --range-is-last -3 "$gitCommand" COMMITS RANGE "$@";;
    ma)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 format-patch RANGE "$@";;

    @(st|files|submodules)?(mine|others|team))
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "show$gitCommand" RANGE "$@";;
    @(st|files|submodules)?(except)by)
	gitCommand="show$gitCommand" othersCommand "$@";;
    subdo)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position files-command --source-exec showfiles RANGE \; --keep-position subdo --for FILES \; "$@";;

    inout|io?(files|submodules)|ab)
	if [ -n "$scopeInoutNote" ]; then
	    $EXEC echo "Note: ${gitCommand} ${scopeInoutNote}"
	else
	    $EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "$scopeCommand" ${scopeCommand:+-3} "$gitCommand" --base "${scopeRevision:?}" "${scopeEndRevision:?}" "$@"
	fi
	;;

    revive)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -3 "$gitCommand" --all RANGE "$@";;
    (\
lc?(f)?(except)by|\
lc?(l)@(g|changed|touched)?(except)by\
)
	revRangeAdditionalArgs=(--one-more-command log --one-more-with-padding)
	;&
	(\
l?(h|g|og)?(except)by|\
@(l?(o)g?(v)|count)@(g|changed|touched)?(except)by|\
@(log?(v)|show)@(last|first)@(g|changed|touched)?(except)by|\
l?(o)g?([fv]|merges)?(except)by|\
@(l?(o)|count|countmaxdaycommits|commitsperday|logdistribution|brlifetimes)?(except)by|\
activity?(except)by\
)
	[[ "$gitCommand" = lg?(except)by ]] && gitCommand="onelinelog${gitCommand#lg}"
	othersCommand "$@"
	;;
    @(show|tree)[ou]url)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position selectedcommit-command --range-is-last -3 "$gitCommand" COMMITS RANGE "$@";;
    compareourl)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --real-branch-name --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rbrurl-compare-to-base --remote origin --base "${scopeRevision:?}" --commit "${scopeEndRevision:?}" "${scopeCompareUrlArgs[@]}" "$@";;
    compareuurl)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --real-branch-name --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rbrurl-compare-to-base --remote upstream --base "${scopeRevision:?}" --commit "${scopeEndRevision:?}" "${scopeCompareUrlArgs[@]}" "$@";;
    lghipassedfiles)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 lghifiles RANGE "$@";;
    lghifiles)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lghipassedfiles" "$@";;
    lgfiles?(mine|others|team))
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lg${gitCommand#lgfiles}" "$@";;
    lgfiles?(except)by)
	quotedAuthorsAndRange="$(gitCommand=quoted othersCommand "$@")" || exit $?
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files $quotedAuthorsAndRange" $EXEC git-selected-command "onelinelog $quotedAuthorsAndRange --"
	;;
    files@(l?(o)g|logv|lc|logfiles))
	# Logs of files modified in the additions of the branch starting from before it.
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -3 showfiles-command --revision RANGE "${gitCommand#files}" "$scopeRevision" "$@";;

    cors)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 checkoutselectedrevisionselected RANGE "$@";;
    cops)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 checkoutselectedpreviousselected RANGE "$@";;

    revert)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 revertselectedcommit RANGE "$@";;
    revert@(files|hunk))
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "revertselected${gitCommand#revert}"  RANGE "$@";;
    revertcommit)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "${gitCommand}selected" RANGE "$@";;

    @(correct|fix@(up|amend|wording))|commit@(identical|like|relate)|amendrelate)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "${gitCommand}selected" RANGE "$@";;
    fix@(up|amend|wording)rb)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "${gitCommand%rb}selectedrb" RANGE "$@";;

    rb)
	if [ "$scopeRevision" = BRANCH ]; then
	    $EXEC echo "Note: ${gitCommand} is a no-op, because it always yields HEAD as the starting point."
	else
	    $EXEC echo "Note: $gitCommand is a no-op, because it iterates over the current range without touching fixups. Use the dedicated check|command|exec to iterate over all branch commits. To rebase onto ${scopeWhat}, there's a dedicated alias outside of \"git ${scope}\"."
	fi
	;;
    rbcheck)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -- rebasecheck "$@" --check-range;;
    check|command|exec|rewordremovescope)
	source "${libDir:?}/rebase.sh.part" "$@"
	;&
    rb?(n)i|segregate@(commits|andbifurcate)|bifurcate)
	if [ "$scopeRevision" = BRANCH ]; then
	    $EXEC echo "Note: ${gitCommand} is a no-op, because it always yields HEAD as the starting point."
	else
	    typeset -a segregateArgs=(); [[ "$gitCommand" =~ ^segregate ]] && segregateArgs=(--explicit-file-args)  # Avoid that the second argument of --path PATH-GLOB is parsed off as a FILE for commit selection.
	    $EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position selectedcommit-command --single-only --range-is-last "${segregateArgs[@]}" -5 previouscommit-command --commit COMMITS "$gitCommand" RANGE "$@"
	fi
	;;
    rblastfixup)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more -2 "$gitCommand" RANGE "$@";;
    move-to-branch)
	$EXEC git "${scopeCommand[@]}" ${scopeCommand:+-4} uncommit-to-branch --exclude-commit --from "${scopeRevision:?}" "$@";;
    uncommit-to-stash)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position selectedcommit-command --pass-file-args --range-is-last -5 "$gitCommand" --commits COMMITS \; RANGE "$@";;
    uncommit-to-branch)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position selectedcommit-command --single-only --range-is-last -4 "$gitCommand" --from COMMITS RANGE "$@";;

    createbr|stackbrfrom)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "${gitCommand}selected" RANGE "$@";;
    detach)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more -2 "${gitCommand}selected" RANGE "$@";;  # Note: --one-more to be able to select one beyond the range.
    wipe)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --one-more -2 "${gitCommand}toselected" RANGE "$@";;	# Note: --one-more to be able to select one beyond the range.
    wipe@(g|changed|touched))
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "wipeto${gitCommand#wipe}" RANGE "$@";;

    base?(lg|s))
	typeset -A mapping=([base]=lh [baselg]=onelinelog [bases]=show)
	GIT_RNLOG_COMMAND="${mapping["$gitCommand"]}" \
	    $EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 logfirst RANGE "$@"
	;;
    pred?(lg|s))
	typeset -A mapping=([pred]=echo [predlg]=lg1 [preds]=show)
	predCommit="$(${EXEC#exec} git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --with-range ' ' -2 merge-base RANGE "$@")"
	$EXEC git "${mapping["$gitCommand"]}" "$predCommit"
	;;

    cat|cp)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "${gitCommand}selectedonemore" RANGE "$@";;

    who@(created|lasttouched|did?(f)|g|changed|touched|owns|contributed|what)thosechangedfiles)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --keep-position files-command --source-exec showfiles RANGE \; "${gitCommand%thosechangedfiles}" "$@";;
    who@(created|lasttouched|did?(f)|g|changed|touched|owns|contributed|what)here)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -2 "${gitCommand%here}" RANGE "$@";;

    emaillog)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -3 email-command log RANGE "$@";;
    emaillc)
	$EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -3 email-command lc RANGE "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	printf >&2 "ERROR: '%s' cannot be used with a %s scope.\\n" "$gitCommand" "$scope"; exit 2;;
esac
