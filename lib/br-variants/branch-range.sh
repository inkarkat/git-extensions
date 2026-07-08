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

typeset -a colorArg=()
case "$1" in
    --help|-h|-\?)	shift; printUsage "$0"; exit 0;;
    --no-color|--color=*)
			colorArg=("$1"); shift;;
    --color)		colorArg=("$1" "$2"); shift; shift;;
esac

othersCommand()
{
    typeset -a inversionArg=(); [[ "$gitCommand" =~ exceptby$ ]] && inversionArg=(--invert-authors)
    $EXEC git-dashdash-default-command --with-files : branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" -$((7 + ${#inversionArg[@]})) authors-command "${inversionArg[@]}" --range RANGE -2 "${gitCommand%%?(except)by}" AUTHORS RANGE : "$@"
}

getPredCommit()
{
    # Only extract a -b|--branch BRANCH argument, but skip any other arguments for
    # merge-base.
    local rangeWithArgs endRange range _
    rangeWithArgs="$(${EXEC#exec} git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" --with-range ' ' -2 echo RANGE "$@")" \
	&& [ -n "$rangeWithArgs" ] \
	&& IFS=' ' read -r endRange range _ <<<"$rangeWithArgs" \
	&& git merge-base "$endRange" "$range"
}


branchCommand()
{
    $EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rev-range --revision "${scopeRevision:?}" --end-revision "${scopeEndRevision:?}" "$@"
}
branchWithRangeCommand()
{
    local gitCommand="${1:?}"; shift
    branchCommand -2 "$gitCommand" RANGE "$@"
}

branchSelectedCommitCommand()
{
    branchCommand --keep-position selectedcommit-command "$@"
}

branchFilesCommand()
{
    branchCommand --keep-position files-command "$@"
}

compareRUrlCommand()
{
    local remote="${1:?}"; shift
    $EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --real-branch-name --keep-position "${scopeCommand[@]}" ${scopeCommand:+--keep-position} rbrurl-compare-to-base --remote "$remote" --base "${scopeRevision:?}" --commit "${scopeEndRevision:?}" "${scopeCompareUrlArgs[@]}" "$@"
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
set -- "${colorArg[@]}" "$@"

predCommit="$(getPredCommit "$@")"
if [ -z "$predCommit" -a "$EXEC" = exec ]; then    # Note: Exempt on non-standard $EXEC for testing and debugging.
    printf >&2 'ERROR: Cannot find merge base with %s.\n' "$scopeWhat"
    return 1
fi

case "$gitCommand" in
    (\
lg?([fv]|merges)|\
lg@(rel|tagged|st|i|I|samefiles)|\
logfiles\
)
	typeset -a revRangeAdditionalArgs=(); [ "$gitCommand" = logfiles ] && revRangeAdditionalArgs=(--one-more-with-padding)
	branchCommand --one-more-command greyonelinelog --one-more-only-to-terminal "${revRangeAdditionalArgs[@]}" -2 "$gitCommand" RANGE "$@";;
    (\
log?([fv]|merges)|\
log?(v)@(st|i|I|samefiles)?(mine|others|team)|\
lc?([fh]|@(st|i|I|samefiles))?(mine|others|team)\
)
	branchCommand --one-more-command greylog --one-more-with-padding --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi?(st|i|I|samefiles))
	branchCommand --one-more-command "greyonelineloghighlight $gitCommand" --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghicommits)
	branchCommand --one-more-command "greyonelineloghighlight $gitCommand" --one-more-only-to-terminal -3 "$gitCommand" --range RANGE "$@";;

    (\
@(@(log?(v)|show)@(last|first)?(f)|lc?(l)?(f)|l?(o)g?([fv])|count)@(g|changed|touched)?(mine|others|team)|\
logfiles?(st|i|I|samefiles)?(mine|others|team)|\
l?(h|o|ogv)f|l?(o)gfg|lcl?(f)|\
l?(o)g?([fv]|merges)@(mine|others|team)|\
@(l?([ho])|count?(f)|countmaxdaycommits|commitsperday|log@(distribution|msgstat)|l?(o)gtitle?(f)g|activity|brlifetimes|devstat)?(mine|others|team)|\
@(brlifetimes|logmsgstat)byeach|\
log?(mod|added|deleted|renamed)?(files)|glog|log@(browse|size|trailers|prlinks)|\
l[ou]url?([fv])|\
@(files|versions|tags)@(g|changed|touched)|\
@(files|version|tag)@(last|first)@(g|changed|touched)|\
ss@(?([wcag])?(st|i|I|samefiles)|changed|touched)|\
sls?(g|changed|touched)|\
dp[sg]|dpl?(s)[sg]|dpls@(changed|touched)|\
co[pr]s?(s)|\
revert@(g|changed|touched|commit@(g|changed|touched))|\
@(correct|fix@(up|amend|wording)|commit@(identical|like|relate|continue)|amendrelate)@(g|changed|touched|st|i|I)|\
detach@(g|changed|touched)|\
commitage|datediff|\
subchanges|superchanges|subrevl@(?(o)g|c)\
)
	branchWithRangeCommand "$gitCommand" "$@";;

    lgx)
	branchWithRangeCommand lg "$@";;

    d?([lbwcayYrt]|rl)|d?(ed)sta?(t)|@(ad|ov)|subrevdiff)
	branchCommand --with-range ... -2 "$gitCommand" RANGE "$@";;
    ds)
	branchFilesCommand --source-exec showfiles RANGE \; diffselected --log-range RANGE "$@";;
    dss)
	branchSelectedCommitCommand --single-only --with-range-from-end ^... --range-is-last -3 diff COMMITS RANGE "$@";;
    dsta?(t)byeach)
	branchWithRangeCommand "log${gitCommand#d}" "$@";;
    @(ad|ov)p)
	branchSelectedCommitCommand --single-only --range-is-last -3 "$gitCommand" COMMITS RANGE "$@";;
    ma)
	branchWithRangeCommand format-patch "$@";;
    repomove)
	branchCommand reporangemove "$@";;

    @(files|submodules)?(mine|others|team))
	branchWithRangeCommand "show$gitCommand" "$@";;
    @(files|submodules)?(except)by)
	gitCommand="show$gitCommand" othersCommand "$@";;
    subdo)
	branchFilesCommand --source-exec showfiles RANGE \; --keep-position subdo --for FILES \; "$@";;

    inout|io?(files|submodules)|ab)
	if [ -n "$scopeInoutNote" ]; then
	    $EXEC echo "Note: ${gitCommand} ${scopeInoutNote}"
	else
	    $EXEC git-branch-command "${branchCommandAdditionalArgs[@]}" --keep-position "${scopeCommand[@]}" ${scopeCommand:+-3} "$gitCommand" --base "${scopeRevision:?}" "${scopeEndRevision:?}" "$@"
	fi
	;;

    revive)
	branchCommand -3 "$gitCommand" --all RANGE "$@";;

	(\
l?(h|g|og)?(except)by|\
log?(v|files)?(st|i|I|samefiles)?(except)by|\
lc?([fh]|@(st|i|I|samefiles))?(except)by|\
lc?(l)@(g|changed|touched)?(except)by|\
@(@(log?(v)|show)@(last|first)|@(l?(o)g?(v)|count))@(g|changed|touched)?(except)by|\
l?(o)g?([fv]|merges)?(except)by|\
@(l?(o)|count?(f)|countmaxdaycommits|commitsperday|log@(distribution|msgstat)|l?(o)gtitleg|brlifetimes|devstat)?(except)by|\
activity?(except)by\
)
	[[ "$gitCommand" = lg?(except)by ]] && gitCommand="onelinelog${gitCommand#lg}"
	othersCommand "$@"
	;;
    @(show|tree)[ou]url?(f))
	branchSelectedCommitCommand --range-is-last -3 "$gitCommand" COMMITS RANGE "$@";;
    compareourl)
	compareRUrlCommand origin "$@";;
    compareuurl)
	compareRUrlCommand upstream "$@";;
    lghipassedfiles)
	branchCommand --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 lghifiles RANGE "$@";;
    lghifiles)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" \
	    $EXEC git-selected-command "$scope lghipassedfiles" "$@";;
    lgfiles?(mine|others|team))
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files${gitCommand#lgfiles}" \
	    $EXEC git-selected-command "$scope lg${gitCommand#lgfiles}" "$@";;
    lgfiles?(except)by)
	quotedAuthorsAndRange="$(gitCommand=quoted othersCommand "$@")" || exit $?
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files $quotedAuthorsAndRange" \
	    $EXEC git-selected-command "onelinelog $quotedAuthorsAndRange --"
	;;
    files@(l?(o)g|logv|lc|logfiles))
	# Logs of files modified in the additions of the branch starting from before it.
	branchCommand -3 showfiles-command --revision RANGE "${gitCommand#files}" "$scopeRevision" "$@";;

    revert)
	branchWithRangeCommand revertselectedcommit "$@";;
    revert@(files|hunk))
	branchWithRangeCommand "revertselected${gitCommand#revert}" "$@";;
    showfiles)
	branchWithRangeCommand showselectedfiles "$@";;

    fix@(up|amend|wording)rb)
	branchWithRangeCommand "${gitCommand%rb}selectedrb" "$@";;

    rb)
	if [ "$scopeRevision" = BRANCH ]; then
	    $EXEC echo "Note: ${gitCommand} is a no-op, because it always yields HEAD as the starting point."
	else
	    $EXEC echo "Note: $gitCommand is a no-op, because it iterates over the current range without touching fixups. Use the dedicated check|command|exec to iterate over all branch commits. To rebase onto ${scopeWhat}, there's a dedicated alias outside of \"git ${scope}\"."
	fi
	;;
    rbcheck)
	branchCommand -- rebasecheck "$@" --check-range;;
    check|command|exec|sedreword|rewordaddprefix|rewordremovescope)
	source "${libDir:?}/rebase.sh.part" "$@"
	;&
    rb?(n)i|segregate@(commits|andbifurcate)|bifurcate)
	if [ "$scopeRevision" = BRANCH ]; then
	    $EXEC echo "Note: ${gitCommand} is a no-op, because it always yields HEAD as the starting point."
	else
	    typeset -a segregateArgs=(); [[ "$gitCommand" =~ ^segregate ]] && segregateArgs=(--explicit-file-args)  # Avoid that the second argument of --path PATH-GLOB is parsed off as a FILE for commit selection.
	    branchSelectedCommitCommand --single-only --range-is-last "${segregateArgs[@]}" -5 previouscommit-command --commit COMMITS "$gitCommand" RANGE "$@"
	fi
	;;
    rblastfixup)
	branchCommand --one-more -2 "$gitCommand" RANGE "$@";;
    move-to-branch)
	$EXEC git "${scopeCommand[@]}" ${scopeCommand:+-4} uncommit-to-branch --exclude-commit --from "${scopeRevision:?}" "$@";;
    uncommit-to-stash)
	branchSelectedCommitCommand --pass-file-args --range-is-last -5 "$gitCommand" --commits COMMITS \; RANGE "$@";;
    uncommit-to-branch)
	branchSelectedCommitCommand --single-only --range-is-last -4 "$gitCommand" --from COMMITS RANGE "$@";;

    (\
createbr|stackbrfrom|reset[mn]|\
revertcommit|\
@(correct|fix@(up|amend|wording))|commit@(identical|like|relate|continue)|amendrelate\
)
	branchWithRangeCommand "${gitCommand}selected" "$@";;
    detach)
	branchCommand --one-more -2 "${gitCommand}selected" RANGE "$@";;  # Note: --one-more to be able to select one beyond the range.
    wipe)
	branchCommand --one-more -2 "${gitCommand}toselected" RANGE "$@";;	# Note: --one-more to be able to select one beyond the range.
    wipe@(g|changed|touched))
	branchWithRangeCommand "wipeto${gitCommand#wipe}" "$@";;

    base)
	GIT_RNLOG_COMMAND=lh \
	    branchCommand -2 logfirst RANGE "$@";;
    baselg)
	GIT_RNLOG_COMMAND=onelinelog \
	    branchCommand -2 logfirst RANGE "$@";;
    bases)
	GIT_RNLOG_COMMAND=show \
	    branchCommand -2 logfirst RANGE "$@";;
    pred)
	$EXEC git echo "$predCommit";;
    predlg)
	$EXEC git lg1 "$predCommit";;
    preds)
	$EXEC git show "$predCommit";;

    @(cat|cp)?(p))
	branchWithRangeCommand "${gitCommand}selected" "$@";;

    @(whatdid|changesetfiles|churn|who@(when|first|last|created|lasttouched|did?(f)|owns|contributed|what))thosefiles)
	branchFilesCommand --source-exec showfiles RANGE \; "${gitCommand%thosefiles}" "$@";;
    @(who@(g|changed|touched))thosefiles)
	branchFilesCommand --except-last --source-exec showfiles RANGE \; "${gitCommand%thosefiles}" "$@";;
    @(whatdid|churn|who@(when|first|last|created|lasttouched|did?(f)|g|changed|touched|owns|contributed|what))here)
	branchWithRangeCommand "${gitCommand%here}" "$@";;
    changesetfileshere@(st|i|I|samefiles)?(mine|others|team))
	branchWithRangeCommand "changesetfiles${gitCommand#changesetfileshere}" "$@";;
    changesetfileshere@(st|i|I|samefiles)?(except)by)
	gitCommand="changesetfiles${gitCommand#changesetfileshere}" \
	    othersCommand "$@";;
    changesetfileshere?(mine|others|team)passedfiles)
	gitCommand="changesetfiles${gitCommand#changesetfileshere}"; gitCommand="${gitCommand%passedfiles}"
	branchWithRangeCommand "$gitCommand" "$@";;
    changesetfileshere?(except)bypassedfiles)
	gitCommand="changesetfiles${gitCommand#changesetfileshere}"; gitCommand="${gitCommand%passedfiles}"
	othersCommand "$@";;
    changesetfileshere?(mine|others|team))
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files${gitCommand#changesetfileshere}" \
	    $EXEC git-selected-command "$scope ${gitCommand}passedfiles" "$@";;
    changesetfileshere?(except)by)
	quotedAuthorsAndRange="$(gitCommand=quoted othersCommand "$@")" || exit $?
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files $quotedAuthorsAndRange" \
	    $EXEC git-selected-command "$scope changesetfilesherepassedfiles $quotedAuthorsAndRange --"
	;;

    emaillog)
	branchCommand -3 email-command log RANGE "$@";;
    emaillc)
	branchCommand -3 email-command lc RANGE "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	printf >&2 "ERROR: '%s' cannot be used with a %s scope.\\n" "$gitCommand" "$scope"; exit 2;;
esac
