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
    printf 'Usage: %q %s\n' "$(basename "$1")" "GIT-COMMAND ${scopeArgsOverride:-[...] ${scopeArgs:+[}${scopeArgs}${scopeArgs:+]}${scopeAdditionalArgs:+ }${scopeAdditionalArgs}${scopeArgs:+ [...] }${scopeFinalArgs}${scopeFinalArgs:+ }}[-?|-h|--help]"
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

: ${EXEC:=exec}
gitCommand="${1:-$GIT_CUSTOMRANGEVARIANT_DEFAULT_COMMAND}"; shift
typeset -a revRangeAdditionalArgs=()
case "$gitCommand" in
    lc?(f)?(mine|team))
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command log --one-more-with-padding -2 "$gitCommand" RANGE "$@";;
    lch)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command showh --one-more-with-padding -2 "$gitCommand" RANGE "$@";;
    (\
lg?([fv])|\
lg@(rel|tagged|st|i|I)\
)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command greyonelinelog --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    log?([fv]|files))
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command greylog --one-more-with-padding --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;
    lghi?(st|i|I))
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command "greyonelineloghighlight $gitCommand" --one-more-only-to-terminal -2 "$gitCommand" RANGE "$@";;

    (\
lc?(l)@(g|changed|touched)?(mine)|\
l?(o)g?(v)@(g|changed|touched)?(mine)|\
@(log?(v)|show)@(last|first)@(g|changed|touched)?(mine)|\
@(files|versions|tags)@(g|changed|touched)|\
@(files|version|tag)@(last|first)@(g|changed|touched)\
)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" "${scopeCommandLastArgs[@]}" -2 "$gitCommand" RANGE "$@";;
(\
lcl?(f)|\
lh?(mine|team)|\
l?(o)g?([fv])@(mine|team)|\
@(l?(o)|count|logdistribution)?(mine|team)|\
log?(mod|added|deleted|renamed)?(files)|glog|logbrowse|\
@(l|tree)?([ou])url?(v)|\
ss@(?([wcag])|changed|touched)|\
sls?(g|changed|touched)|\
dp[sg]|dpl?(s)[sg]|dpls@(changed|touched)|\
who@(when|first|last)|whatdid|churn|\
activity?(mine|team)|\
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

    d?([lbwcayYrt]|rl)|dsta?(t)|ad|subrevdiff)
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
    adp)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --keep-position selectedcommit-command --single-only --range-is-last -3 "$gitCommand" COMMITS RANGE "$@";;
    ma)
	$EXEC git-"${scopeCommand[@]}" -2 format-patch RANGE "$@";;

    st|files|submodules)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -2 "show$gitCommand" RANGE "$@";;
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
    lc?(f)by)
	revRangeAdditionalArgs=(--one-more-command log --one-more-with-padding)
	;&
    l?(h|g|og)by)
	[ "$gitCommand" = lgby ] && gitCommand='onelinelog'
	$EXEC git-dashdash-default-command --with-files : "${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" "${scopeCommandLastArgs[@]}" "${revRangeAdditionalArgs[@]}" -5 others-command -2 "${gitCommand%by}" AUTHORS RANGE : "$@";;
    compareourl)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -5 rbrurl-compare-to-base --remote origin --range RANGE --base-to-rev --commit-to-rev "$@";;
    compareuurl)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -5 rbrurl-compare-to-base --remote upstream --range RANGE --base-to-rev --commit-to-rev "$@";;
    lghipassedfiles)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --one-more-command 'greyonelineloghighlight lghighlight' --one-more-only-to-terminal -2 lghifiles RANGE "$@";;
    lghifiles)
	GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files" $EXEC git-selected-command "$scope lghipassedfiles" "$@";;
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

    who@(created|lasttouched|did?(f)|owns|contributed|what)thosechangedfiles)
	withScoped files "${gitCommand%thosechangedfiles}" "$@";;
    who@(created|lasttouched|did?(f)|owns|contributed|what)here)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -2 "${gitCommand%here}" RANGE "$@";;

    emaillog)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -3 email-command log RANGE "$@";;
    emaillc)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -3 email-command lc RANGE "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	printf >&2 "ERROR: '%s' cannot be used with a %s scope.\\n" "$gitCommand" "$scope"; exit 2;;
esac
