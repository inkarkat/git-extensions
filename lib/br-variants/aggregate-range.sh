#!/bin/bash source-this-script
# shellcheck disable=SC2145
shopt -qs extglob

: ${GIT_AGGREGATERANGEVARIANT_DEFAULT_COMMAND=${GIT_REVRANGE_DEFAULT_COMMAND:-lg}}

readonly scriptName="$(basename -- "$0")"
readonly scope="${scriptName#git-}"
: ${scopeArgs=-b|--branch BRANCH}
: ${scopeFinalArgs=}
typeset -a argsForLogScopeCommands=("${scopeCommandLogArgs[@]}")

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

withAggregateFiles()
{
    local quotedArgs=; [ $# -eq 0 ] || printf -v quotedArgs ' %q' "$@"
    # FIXME: Extract FILE arguments and pass them to the source command.
    GIT_SELECTED_COMMAND_DEFAULT_FILES="GIT_REVRANGE_SEPARATE_ERRORS=t git-$scope files --no-header 2>/dev/null | sort --unique" \
	$EXEC git-"$@"
}

withAggregateCommit()
{
    # FIXME: Extract FILE arguments and pass them to the source command.
    GIT_SELECTEDCOMMIT_NO_MANDATORY_RANGE=t \
    GIT_SELECTEDCOMMIT_COMMITS="GIT_REVRANGE_SEPARATE_ERRORS=t git-$scope log {} --no-header 2>/dev/null | uniqueStable" \
	$EXEC git-selectedcommit-command "$@"
}

withAggregateCommitWithLastArg()
{
    local logCommand="${1:?}"; shift
    local quotedLastArg=; [ $# -gt 0 ] && printf -v quotedLastArg %q "${!#}"
    [ $# -eq 0 ] || set -- "${@:1:$(($#-1))}"
    # FIXME: Extract FILE arguments and pass them to the source command.
    GIT_SELECTEDCOMMIT_NO_MANDATORY_RANGE=t \
    GIT_SELECTEDCOMMIT_COMMITS="GIT_REVRANGE_SEPARATE_ERRORS=t git-$scope $logCommand {} --no-header $quotedLastArg 2>/dev/null | uniqueStable" \
	$EXEC git-selectedcommit-command "$@"
}

othersCommand()
{
    typeset -a inversionArg=(); [[ "$gitCommand" =~ exceptby$ ]] && inversionArg=(--invert-authors)
    $EXEC git-dashdash-default-command --with-files : authors-command "${inversionArg[@]}" --keep-position "${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" "${scopeCommandLastArgs[@]}" "${revRangeAdditionalArgs[@]}" -3 "${gitCommand%%?(except)by}" AUTHORS RANGE : "$@"
}

: ${EXEC:=exec}
if [ $# -lt ${#scopeMandatoryArgs[@]} ]; then
    printf >&2 'ERROR: Required arguments missing: %s\n' "${scopeMandatoryArgs[*]}"
    exit 2
elif [ $# -eq ${#scopeMandatoryArgs[@]} ]; then
    gitCommand="$GIT_AGGREGATERANGEVARIANT_DEFAULT_COMMAND"
else
    gitCommand="${1:?}"; shift
fi

typeset -a revRangeAdditionalArgs=()
case "$gitCommand" in
    ds)
	withAggregateFiles selected-command "$scope d${quotedArgs}";;
    dss)
	withAggregateCommit --single-only dp "$@";;

    @(st|files|submodules)?(except)by)
	gitCommand="show$gitCommand" othersCommand "$@";;

    subdo)
	quotedArgs=; [ $# -eq 0 ] || printf -v quotedArgs ' %q' "$@"
	# FIXME: Extract FILE arguments and pass them to the source command.
	readarray -t submodules < <("git-$scope" submodules --no-header 2>/dev/null | sort --unique)
	[ ${#submodules[@]} -gt 0 ] || exit 99
	$EXEC git-subdo --for "${submodules[@]}" \; "$@";;

    inout|io?(files|submodules)|ab)
	if [ -n "$scopeInoutNote" ]; then
	    $EXEC echo "Note: ${gitCommand} ${scopeInoutNote}"
	else
	    $EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" --with-range ' ' --reverse -3 "$gitCommand" RANGE "$@"
	fi
	;;

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
@(l?(o)|count?(f)|countmaxdaycommits|commitsperday|log@(distribution|msgstat)|l?(o)gtitleg|brlifetimes|devstat)?(except)by|\
activity?(except)by\
)
	[ "$gitCommand" = lgby ] && gitCommand='onelinelog'
	othersCommand "$@"
	;;

    cors)
	withAggregateCommit checkoutrevisionselected "$@";;
    cops)
	withAggregateCommit checkoutpreviousselected "$@";;

    (\
@(show|tree)[ou]url?(f)|\
revert?(commit)|\
correct|commit@(identical|like|relate)|amendrelate\
)
	withAggregateCommit "$gitCommand" "$@";;
    (\
@(ad|ov)p|\
createbr|stackbrfrom|reset[mn]|detach|wipe|\
cat|cp\
)
	withAggregateCommit --single-only "$gitCommand" "$@";;

    revertfiles)
	withAggregateCommit revert --selected "$@";;
    reverthunk)
	withAggregateCommit revert --patch "$@";;

    (\
fix@(up|amend|wording)?(rb)|\
check|command|exec|rewordaddprefix|rewordremovescope|\
rb|rbcheck|rb?(n)i|segregate@(commits|andbifurcate)|bifurcate|rblastfixup|\
move-to-branch|uncommit-to-stash|uncommit-to-branch\
)
	$EXEC echo "Note: $gitCommand cannot work across branches.";;

    wipe@(g|changed|touched))
	withAggregateCommitWithLastArg "log${gitCommand#wipe}" wipe "$@";;

    base)
	$EXEC git-"${scopeCommand[@]}" --no-git-color --no-range -3 name-rev --name-only RANGE "$@";;
    baselg)
	$EXEC git-"${scopeCommand[@]}" --no-range -2 lg1 RANGE "$@";;
    bases)
	$EXEC git-"${scopeCommand[@]}" --no-range -2 show RANGE "$@";;
    pred)
	$EXEC git-"${scopeCommand[@]}" --no-git-color --no-range --one-more -3 name-rev --name-only RANGE "$@";;
    predlg)
	$EXEC git-"${scopeCommand[@]}" --no-range --one-more -2 lg1 RANGE "$@";;
    preds)
	$EXEC git-"${scopeCommand[@]}" --no-range --one-more -2 show RANGE "$@";;

    who@(created|lasttouched|did?(f)|g|changed|touched|owns|contributed|what)thosechangedfiles)
	withAggregateFiles "${gitCommand%thosechangedfiles}" "$@";;
    who@(created|lasttouched|did?(f)|g|changed|touched|owns|contributed|what)here)
	$EXEC git-"${scopeCommand[@]}" "${argsForLogScopeCommands[@]}" -2 "${gitCommand%here}" RANGE "$@";;

    emaillog)
	GIT_REVRANGE_SEPARATE_ERRORS=t \
	    $EXEC git-email-command "$scope log --no-header" "$@";;
    emaillc)
	GIT_REVRANGE_SEPARATE_ERRORS=t \
	    $EXEC git-email-command "$scope lc --no-header" "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	source "${BASH_SOURCE[0]/aggregate-/custom-}" "$gitCommand" "$@";;
esac
