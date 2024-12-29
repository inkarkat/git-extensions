#!/bin/bash source-this-script
# shellcheck disable=SC2145
shopt -qs extglob

: ${GIT_CUSTOMRANGEVARIANT_DEFAULT_COMMAND=${GIT_REVRANGE_DEFAULT_COMMAND:-lg}}

[ -n "$scriptName" ] || readonly scriptName="$(basename -- "$0")"
[ -n "$scope" ] || readonly scope="${scriptName#git-}"
: ${scopeArgs=-b|--branch BRANCH}
: ${scopeFinalArgs=}
typeset -a argsForLogScopeCommands=("${scopeCommandLogArgs[@]}")
case " ${!scopeDiffCommandRangeArgs*} " in
    *" scopeDiffCommandRangeArgs "*) ;;
    *) scopeDiffCommandRangeArgs=(--with-range ...);;
esac

printUsage()
{
    cat <<HELPTEXT
Covers ${scopeWhat:?}.
HELPTEXT
    echo
    printf 'Usage: %q %s\n' "$(basename "$1")" "GIT-COMMAND ${scopeArgsOverride:-[...] ${scopeArgs:+[}${scopeArgs}${scopeArgs:+]}${scopeAdditionalArgs:+ }${scopeAdditionalArgs}${scopeArgs:+ [...] }${scopeFinalArgs}${scopeFinalArgs:+ }}${scopeArgsOverride:+ }[-?|-h|--help]"
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

withScoped()
{
    local what="${1:?}"; shift
    if [ ${#scopeArgSyphon[@]} -gt 0 ]; then
	$EXEC git-argsyphon-command "${scopeArgSyphon[@]}" --keep-position "${scopeCommand[@]}" ARGS "${argsForLogScopeCommands[@]}" --keep-position files-command --source-exec "show$what" RANGE \; "$@"
    else
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --keep-position files-command --source-exec "show$what" RANGE \; "$@"
    fi
}

withAggregateCommit()
{
    # FIXME: Extract FILE arguments and pass them to the source command.
    GIT_SELECTEDCOMMIT_NO_MANDATORY_RANGE=t \
    GIT_SELECTEDCOMMIT_COMMITS="GIT_REVRANGE_SEPARATE_ERRORS=t git-$scope log {} --no-header 2>/dev/null | uniqueStable" \
	$EXEC git-selectedcommit-command "$@"
}

othersCommand()
{
    typeset -a inversionArg=(); [[ "$gitCommand" =~ exceptby$ ]] && inversionArg=(--invert-authors)
    $EXEC git-dashdash-default-command --with-files : "${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" "${scopeCommandLastArgs[@]}" "${revRangeAdditionalArgs[@]}" -$((7 + ${#inversionArg[@]})) authors-command "${inversionArg[@]}" --range RANGE -2 "${gitCommand%%?(except)by}" AUTHORS RANGE : "$@"
}

: ${EXEC:=exec}
if [ $# -lt ${#scopeMandatoryArgs[@]} ]; then
    printf >&2 'ERROR: Required arguments missing: %s\n' "${scopeMandatoryArgs[*]}"
    exit 2
elif [ $# -eq ${#scopeMandatoryArgs[@]} ]; then
    gitCommand="$GIT_CUSTOMRANGEVARIANT_DEFAULT_COMMAND"
else
    gitCommand="${1:?}"; shift
fi

typeset -a revRangeAdditionalArgs=()
case "$gitCommand" in
    lc?(f)?(mine|others|team))
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command log --one-more-with-padding -2 "$gitCommand" RANGE "$@";;
    lch)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command showh --one-more-with-padding -2 "$gitCommand" RANGE "$@";;
    (\
lg?([fv]|merges)|\
lg@(rel|tagged|st|i|I)\
)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command greyonelinelog --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    log?([fv]|merges|files))
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command greylog --one-more-with-padding --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi?(st|i|I))
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command "greyonelineloghighlight $gitCommand" --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;

    (\
@(@(log?(v)|show)@(last|first)?(f)|lc?(l)?(f)|l?(o)g?([fv])|count)@(g|changed|touched)?(mine|others|team)|\
l?(o)gfg|\
@(files|versions|tags)@(g|changed|touched)|\
@(files|version|tag)@(last|first)@(g|changed|touched)\
)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" "${scopeCommandLastArgs[@]}" -2 "$gitCommand" RANGE "$@";;
(\
l?(h|o|ogv)f|lcl?(f)|\
l?(o)g?([fv]|merges)@(mine|others|team)|\
@(l?([ho])|count?(f)|countmaxdaycommits|commitsperday|log@(distribution|msgstat)|l?(o)gtitle?(f)g|activity|brlifetimes)?(mine|others|team)|\
@(brlifetimes|logmsgstat)byeach|\
log?(mod|added|deleted|renamed)?(files)|glog|log@(browse|size|trailers|prlinks)|\
l[ou]url?([fv])|\
ss@(?([wcag])|changed|touched)|\
sls?(g|changed|touched)|\
dp[sg]|dpl?(s)[sg]|dpls@(changed|touched)|\
who@(when|first|last)|whatdid|relatedfiles|churn|\
subchanges|superchanges|subrevl@(?(o)g|c)\
)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -2 "$gitCommand" RANGE "$@";;
(\
revert@(g|changed|touched|commit@(g|changed|touched))|\
@(correct|fix@(up|amend|wording)|commit@(identical|like|relate)|amendrelate)@(g|changed|touched|st|i|I)|\
detach@(g|changed|touched)\
)
	$EXEC git-"${scopeCommand[@]}" -2 "$gitCommand" RANGE "$@";;

    lgx)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -2 lg RANGE "$@";;

    d?([lbwcayYrt]|rl)|dsta?(t)|@(ad|ov)|subrevdiff)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" "${scopeDiffCommandRangeArgs[@]}" -2 "$gitCommand" RANGE "$@";;
    ds)
	# diffselected does not understand log args; these here are only used to determine the affected files and revision range.
	# Therefore, turn a configured --log-args-for-range into --log-args-only-for-range.
	[ "${argsForLogScopeCommands[*]}" = --log-args-for-range ] \
	    && argsForLogScopeCommands=(--log-args-only-for-range)

	withScoped files diffselected --log-range RANGE "$@";;
    dss)
	$EXEC git-"${scopeCommand[@]}" --keep-position selectedcommit-command "${argsForLogScopeCommands[@]}" --single-only --with-range-from-end ^... --range-is-last -3 diff COMMITS RANGE "$@";;
    dsta?(t)byeach)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -2 "log${gitCommand#d}" RANGE "$@";;
    @(ad|ov)p)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --keep-position selectedcommit-command --single-only --range-is-last -3 "$gitCommand" COMMITS RANGE "$@";;
    ma)
	$EXEC git-"${scopeCommand[@]}" -2 format-patch RANGE "$@";;
    repomove)
	$EXEC git-"${scopeCommand[@]}" reporangemove "$@";;

    @(st|files|submodules)?(mine|others|team))
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -2 "show$gitCommand" RANGE "$@";;
    @(st|files|submodules)?(except)by)
	gitCommand="show$gitCommand" othersCommand "$@";;
    subdo)
	withScoped submodules --keep-position subdo --for FILES \; "$@";;

    inout|io?(files|submodules)|ab)
	if [ -n "$scopeInoutNote" ]; then
	    $EXEC echo "Note: ${gitCommand} ${scopeInoutNote}"
	else
	    $EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --no-range -3 "$gitCommand" --base RANGE "$@"
	fi
	;;

    revive)
	$EXEC git-"${scopeCommand[@]}" -3 "$gitCommand" --all RANGE "$@";;
    (\
lc?(f)?(except)by|\
lc?(l)@(g|changed|touched)?(except)by\
)
	revRangeAdditionalArgs=(--one-more-command log --one-more-with-padding)
	;&
	(\
l?(h|g|og)?(except)by|\
@(@(log?(v)|show)@(last|first)|@(l?(o)g?(v)|count))@(g|changed|touched)?(except)by|\
l?(o)g?([fv]|merges)?(except)by|\
@(l?(o)|count?(f)|countmaxdaycommits|commitsperday|log@(distribution|msgstat)|l?(o)gtitleg|brlifetimes)?(except)by|\
activity?(except)by\
)
	[[ "$gitCommand" = lg?(except)by ]] && gitCommand="onelinelog${gitCommand#lg}"
	othersCommand "$@"
	;;
    @(show|tree)[ou]url?(f))
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --keep-position selectedcommit-command --range-is-last -3 "$gitCommand" COMMITS RANGE "$@";;
    compareourl)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -5 rbrurl-compare-to-base --remote origin --range RANGE --base-to-rev --commit-to-rev "$@";;
    compareuurl)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -5 rbrurl-compare-to-base --remote upstream --range RANGE --base-to-rev --commit-to-rev "$@";;
    lghipassedfiles)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 lghifiles RANGE "$@";;
    lghifiles)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lghipassedfiles" "$@";;
    lgfiles?(mine|others|team))
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lg${gitCommand#lgfiles}" "$@";;
    lgfiles?(except)by)
	quotedAuthorsAndRange="$(gitCommand=quoted othersCommand "$@")" || exit $?
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files $quotedAuthorsAndRange" $EXEC git-selected-command "onelinelog $quotedAuthorsAndRange --"
	;;
    files@(l?(o)g|logv|lc|logfiles))
	# Logs of files modified in the additions of the custom range starting from before it.
	# Need to obtain the end revision of the range separately here. As some
	# scopeCommand may evaluate some passed arguments, these must be passed, and
	# anything that's still echoed is ignored.
	< <(${EXEC#exec} git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --last-only --reverse -2 echo RANGE "$@") IFS=' ' read -r startRevision _
	if [ -n "$startRevision" ]; then
	    set -- "$startRevision" "$@"
	else
	    ${EXEC#exec} printf >&2 'Note: Failed to determine the start revision of the range; the %s scope is included in the log now.\n' "$scope"
	fi
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -3 showfiles-command --revision RANGE "${gitCommand#files}" "$@";;

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
    rbcheck)
	onLocalBranch git-"${scopeCommand[@]}" -- rebasecheck "$@" --check-range;;
    check|command|exec|rewordremovescope)
	source "${libDir:?}/rebase.sh.part" "$@"
	;&
    rb?(n)i|segregate@(commits|andbifurcate)|bifurcate)
	typeset -a segregateArgs=(); [[ "$gitCommand" =~ ^segregate ]] && segregateArgs=(--explicit-file-args)  # Avoid that the second argument of --path PATH-GLOB is parsed off as a FILE for commit selection.
	onLocalBranch git-"${scopeCommand[@]}" --keep-position selectedcommit-command --single-only --range-is-last "${segregateArgs[@]}" -5 previouscommit-command --commit COMMITS "$gitCommand" RANGE "$@";;
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
	$EXEC git-"${scopeCommand[@]}" --one-more -2 "${gitCommand}selected" RANGE "$@";;   # Note: --one-more to be able to select one beyond the range.
    wipe)
	$EXEC git-"${scopeCommand[@]}" --one-more -2 "${gitCommand}toselected" RANGE "$@";; # Note: --one-more to be able to select one beyond the range.
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

    who@(created|lasttouched|did?(f)|g|changed|touched|owns|contributed|what)thosechangedfiles)
	withScoped files "${gitCommand%thosechangedfiles}" "$@";;
    who@(created|lasttouched|did?(f)|g|changed|touched|owns|contributed|what)here)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -2 "${gitCommand%here}" RANGE "$@";;

    emaillog)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -3 email-command log RANGE "$@";;
    emaillc)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -3 email-command lc RANGE "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	printf >&2 "ERROR: '%s' cannot be used with a %s scope.\\n" "$gitCommand" "$scope"; exit 2;;
esac
