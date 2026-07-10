#!/bin/bash source-this-script
shopt -qs extglob

: ${GIT_LASTTIMESPAN_DEFAULT_COMMAND=${GIT_BRVARIANT_DEFAULT_COMMAND:-lg}}

readonly scriptName="$(basename -- "$0")"
readonly scope="${scriptName#git-}"

printUsage()
{
    cat <<HELPTEXT
Covers changes committed ${scopeWhat:?}.
HELPTEXT
    echo
    printf 'Usage: %q %s\n' "$(basename "$1")" "GIT-COMMAND [...] ${scopeArgs}${scopeArgs:+ [...] }[-?|-h|--help]"
}

typeset -a colorArg=()
case "$1" in
    --help|-h|-\?)	shift; printUsage "$0"; exit 0;;
    --no-color|--color=*)
			colorArg=("$1"); shift;;
    --color)		colorArg=("$1" "$2"); shift; shift;;
esac

timespanCommand()
{
    $EXEC "git-${scopeCommand:?}" "$@"
}

filesCommand()
{
    $EXEC git-files-command "$@"
}

selectedFilesCommand()
{
    GIT_SELECTED_COMMAND_DEFAULT_FILES="git-$scope files${filesAppendix}" \
	$EXEC git-selected-command "$@"
}

othersCommand()
{
    typeset -a inversionArg=(); [[ "$gitCommand" =~ exceptby$ ]] && inversionArg=(--invert-authors)
    $EXEC git-dashdash-default-command --with-files : "${scopeCommand:?}" --range -$((7 + ${#inversionArg[@]})) authors-command "${inversionArg[@]}" --range TIMESPAN -2 "${gitCommand%%?(except)by}" AUTHORS TIMESPAN : "$@"
}

: ${EXEC:=exec}
if [ $# -lt ${#scopeMandatoryArgs[@]} ]; then
    printf >&2 'ERROR: Required arguments missing: %s\n' "${scopeMandatoryArgs[*]}"
    exit 2
elif [ $# -eq ${#scopeMandatoryArgs[@]} ]; then
    gitCommand="$GIT_LASTTIMESPAN_DEFAULT_COMMAND"
else
    gitCommand="${1:?}"; shift
fi
set -- "${colorArg[@]}" "$@"

case "$gitCommand" in
    (\
@(@(log?(v)|show)@(last|first)?(f)|lc?(l)?(f)|l?(o)g?([fv])|count)@(g|changed|touched)?(mine|others|team)|\
l?(h|o|ogv)f|\
l@([cg]|og|ogv|ghi)ofchangesetfiles@(st|i|I|samefiles)|\
@(files|versions|tags)@(g|changed|touched)|\
@(files|version|tag)@(last|first)@(g|changed|touched)|\
lc?(h|@(st|i|I|samefiles))?(mine|others|team)|\
lc@(?(l)?(f)|?(f)@(mine|others|team))|\
@(l?(o)g?([fv]|merges)|l?([ho])|count?(f)|countmaxdaycommits|commitsperday|log@(distribution|msgstat|files?(st|i|I|samefiles))|log?(v)@(st|i|I|samefiles)|l?(o)gtitle?(f)g|brlifetimes|devstat)?(mine|others|team)|\
@(brlifetimes|logmsgstat)byeach|\
log?(mod|added|deleted|renamed)?(files)|glog|log@(browse|size|trailers|prlinks)|\
lg@(rel|tagged|st|i|I|samefiles)|\
l[ou]url?([fv])|\
lghi?(st|i|I|samefiles|commits)|\
ss@(?([wcag])?(st|i|I|samefiles)|changed|touched)|\
sls?(g|changed|touched)|\
dp[sg]|dpl?(s)[sg]|dpls@(changed|touched)|\
co[pr]s?(s)|\
revert@(g|changed|touched|commit@(g|changed|touched))|\
@(correct|fix@(up|amend|wording)|commit@(identical|like|relate|continue)|amendrelate)@(g|changed|touched|st|i|I)|\
detach@(g|changed|touched)|\
commitage|datediff\
)
	timespanCommand -2 "$gitCommand" TIMESPAN "$@";;

    lgx)
	# lgx is identical lg to because there's no one-more with timespans.
	timespanCommand -2 lg TIMESPAN "$@";;
    (\
l?(c?(f|h|st|i|I|samefiles)|h|g|og?(files?(st|i|I|samefiles)|st|i|I|samefiles))?(except)by|\
@(@(log?(v)|show)@(last|first)|@(lc?(l)|l?(o)g?(v)|count))@(g|changed|touched)?(except)by|\
lc@(?(l)?(f)|?(f))?(except)by|\
@(l?(o)g?([fv]|merges)|l?(o)|count?(f)|countmaxdaycommits|commitsperday|log@(distribution|msgstat)|log?(v)@(st|i|I|samefiles)|l?(o)gtitleg|brlifetimes|devstat)?(except)by|\
activity?(except)by\
)
	[[ "$gitCommand" = lg?(except)by ]] && gitCommand="onelinelog${gitCommand#lg}"
	othersCommand "$@"
	;;

    d)
	timespanCommand --no-range -2 diffuntil TIMESPAN "$@";;
    dsta)
	timespanCommand --no-range -2 diffuntil TIMESPAN --shortstat "$@";;
    dstat)
	timespanCommand --no-range -2 diffuntil TIMESPAN --stat --compact-summary "$@";;
    dedsta)
	timespanCommand --no-range -2 duntiledstat TIMESPAN --shortstat "$@";;
    dedstat)
	timespanCommand --no-range -2 duntiledstat TIMESPAN "$@";;
    ds)
	selectedFilesCommand --exec "$scope" d \; "$@";;
    dss)
	timespanCommand -8 selectedcommit-command --single-only --with-range-from-end ^... -2 diff COMMITS TIMESPAN "$@";;
    dsta?(t)byeach)
	timespanCommand -2 "log${gitCommand#d}" TIMESPAN "$@";;
    dt)
	timespanCommand --no-range -2 difftooluntil TIMESPAN "$@";;
    d[lbwcayYr]|drl)
	timespanCommand --no-range -2 "diffuntil${gitCommand#d}" TIMESPAN "$@";;
    @(ad|ov))
	timespanCommand --no-range -2 annotatediffuntil TIMESPAN "$@";;
    @(ad|ov)p)
	timespanCommand -6 selectedcommit-command --single-only -2 "$gitCommand" COMMITS TIMESPAN "$@";;
    ma)
	timespanCommand --no-range --one-more -2 format-patch TIMESPAN "$@";;
    repomove)
	timespanCommand --no-range --one-more reporangemove "$@";;

    @(files|submodules)?(mine|others|team))
	timespanCommand --range -2 "show$gitCommand" TIMESPAN "$@";;
    @(files|submodules)?(except)by)
	gitCommand="show$gitCommand" \
	    othersCommand "$@";;
    subdo)
	filesCommand --source-command "$scope submodules" --keep-position subdo --for FILES \; "$@";;
    subchanges|superchanges|subrevl@(?(o)g|c))
	timespanCommand --range -2 "$gitCommand" TIMESPAN "$@";;
    subrevdiff)
	timespanCommand --with-range ... -2 "$gitCommand" TIMESPAN "$@";;

    inout|io?(files|submodules)|ab)
	$EXEC echo "Note: $gitCommand does not make sense here because the second revision always is an ancestor of the first.";;

    revive)
	timespanCommand -3 "$gitCommand" --all TIMESPAN "$@";;
    @(show|tree)[ou]url?(f))
	timespanCommand -5 selectedcommit-command -2 "$gitCommand" COMMITS TIMESPAN "$@";;
    compareourl)
	$EXEC git-branch-command --real-branch-name --keep-position rbrurl-compare-to-base --remote origin --base-command "$scope pred --branch" --base-to-rev --commit BRANCH "$@";;
    compareuurl)
	$EXEC git-branch-command --real-branch-name --keep-position rbrurl-compare-to-base --remote upstream --base-command "$scope pred --branch" --base-to-rev --commit BRANCH "$@";;
    lghipassedfiles)
	timespanCommand -2 lghifiles TIMESPAN "$@";;
    lghifiles)
	selectedFilesCommand --exec "$scope" lghipassedfiles \; "$@";;
    lgfiles?(mine|others|team))
	filesAppendix="${gitCommand#lgfiles}" \
	    selectedFilesCommand --exec "$scope" "lg${gitCommand#lgfiles}" \; "$@";;
    lgfiles?(except)by)
	quotedAuthorsAndRange="$(gitCommand=quoted othersCommand "$@")" || exit $?
	filesAppendix=" $quotedAuthorsAndRange" \
	    selectedFilesCommand --command "onelinelog $quotedAuthorsAndRange --"
	;;
    files@(l?(o)g|logv|lc|logfiles))
	# Logs of files modified in the last timespan starting from before it.
	# Need to obtain the end revision of the range separately here. As some
	# scopeCommand may evaluate some passed arguments, these must be passed, and
	# anything that's still echoed is ignored.
	< <(${EXEC#exec} git-"${scopeCommand:?}" --last-only --reverse --one-more -2 echo TIMESPAN "$@") IFS=' ' read -r startRevision _
	if [ -n "$startRevision" ]; then
	    set -- "$startRevision" "$@"
	else
	    ${EXEC#exec} printf >&2 'Note: Failed to determine the start revision of the range; the %s scope is included in the log now.\n' "$scope"
	fi
	$EXEC git-"${scopeCommand:?}" --range -3 showfiles-command --revision TIMESPAN "${gitCommand#files}" "$@";;

    revert)
	timespanCommand -2 revertselectedcommit TIMESPAN "$@";;
    revert@(files|hunk))
	timespanCommand -2 "revertselected${gitCommand#revert}" TIMESPAN "$@";;
    showfiles)
	timespanCommand -2 showselectedfiles TIMESPAN "$@";;

    fix@(up|amend|wording)rb)
	timespanCommand -2 "${gitCommand%rb}selectedrb" TIMESPAN "$@";;

    rb)
	$EXEC echo "Note: $gitCommand is a no-op, because it iterates over the current range without touching fixups.";;
    rbcheck)
	timespanCommand -- rebasecheck "$@" --check-range;;
    check|command|exec|sedreword|rewordaddprefix|rewordremovescope)
	source "${libDir:?}/rebase.sh.part" "$@"
	;&
    rb?(n)i|segregate@(commits|andbifurcate)|bifurcate)
	typeset -a segregateArgs=(); [[ "$gitCommand" =~ ^segregate ]] && segregateArgs=(--explicit-file-args)  # Avoid that the second argument of --path PATH-GLOB is parsed off as a FILE for commit selection.
	timespanCommand -8 selectedcommit-command --single-only "${segregateArgs[@]}" -4 previouscommit-command --commit COMMITS "$gitCommand" TIMESPAN "$@"
	;;
    rblastfixup)
	timespanCommand --one-more -2 "$gitCommand" TIMESPAN "$@";;
    move-to-branch)
	timespanCommand --no-range --one-more +1 TIMESPAN uncommit-to-branch --exclude-commit "$@";;
    uncommit-to-stash)
	timespanCommand -8 selectedcommit-command --pass-file-args -4 uncommit-to-branch --commits COMMITS \; TIMESPAN "$@";;
    uncommit-to-branch)
	timespanCommand -7 selectedcommit-command --single-only -3 uncommit-to-branch --from COMMITS TIMESPAN "$@";;

    (\
createbr|stackbrfrom|reset[mn]|\
revertcommit|\
@(correct|fix@(up|amend|wording))|commit@(identical|like|relate|continue)|amendrelate\
)
	timespanCommand -2 "${gitCommand}selected" TIMESPAN "$@";;
    detach)
	timespanCommand --range --one-more -2 "${gitCommand}selected" TIMESPAN "$@";;
    wipe)
	timespanCommand --range --one-more -2 "${gitCommand}toselected" TIMESPAN "$@";;
    wipe@(g|changed|touched))
	timespanCommand -2 "wipeto${gitCommand#wipe}" TIMESPAN "$@";;

    base)
	timespanCommand --no-range -3 name-rev --name-only TIMESPAN "$@";;
    baselg)
	timespanCommand --no-range -2 lg1 TIMESPAN "$@";;
    bases)
	timespanCommand --no-range -2 show TIMESPAN "$@";;
    pred)
	timespanCommand --no-range --one-more -3 name-rev --name-only TIMESPAN "$@";;
    predlg)
	timespanCommand --no-range --one-more -2 lg1 TIMESPAN "$@";;
    preds)
	timespanCommand --no-range --one-more -2 show TIMESPAN "$@";;

    @(cat|cp)?(p))
	timespanCommand -2 "${gitCommand}selected" TIMESPAN "$@";;

    @(l@([cg]|og|ogv)|l@([cg]|og|ogv|ghi)ofchangesetfiles|whatdid|changesetfiles|churn|who@(when|first|last|created|lasttouched|did?(f)|owns|contributed|what))thosefiles)
	filesCommand --source-command "$scope files" "${gitCommand%thosefiles}" "$@";;
    lghithosefiles)
	filesCommand --source-command "$scope files" "${gitCommand%thosefiles}files" "$@";;
    @(who@(g|changed|touched))thosefiles)
	filesCommand --except-last --source-command "$scope files" "${gitCommand%thosefiles}" "$@";;
    @(whatdid|churn|who@(when|first|last|created|lasttouched|did?(f)|g|changed|touched|owns|contributed|what))here)
	timespanCommand -2 "${gitCommand%here}" TIMESPAN "$@";;
    changesetfileshere@(st|i|I|samefiles)?(mine|others|team))
	timespanCommand -2 "changesetfiles${gitCommand#changesetfileshere}" TIMESPAN "$@";;
    changesetfileshere@(st|i|I|samefiles)?(except)by)
	gitCommand="changesetfiles${gitCommand#changesetfileshere}" \
	    othersCommand "$@";;
    changesetfileshere?(mine|others|team)passedfiles)
	gitCommand="changesetfiles${gitCommand#changesetfileshere}"; gitCommand="${gitCommand%passedfiles}"
	timespanCommand -2 "$gitCommand" TIMESPAN "$@";;
    changesetfileshere?(except)bypassedfiles)
	gitCommand="changesetfiles${gitCommand#changesetfileshere}"; gitCommand="${gitCommand%passedfiles}"
	othersCommand "$@";;
    changesetfileshere?(mine|others|team))
	filesAppendix="${gitCommand#changesetfileshere}" \
	    selectedFilesCommand --exec "$scope" "${gitCommand}passedfiles" \; "$@";;
    changesetfileshere?(except)by)
	quotedAuthorsAndRange="$(gitCommand=quoted othersCommand "$@")" || exit $?
	filesAppendix=" $quotedAuthorsAndRange" \
	    selectedFilesCommand --command "$scope changesetfilesherepassedfiles $quotedAuthorsAndRange --"
	;;

    activity?(mine|others|team))
	$EXEC echo "Note: $gitCommand would just trim activity to ${scopeWhat}.";;

    emaillog)
	timespanCommand -3 email-command log TIMESPAN "$@";;
    emaillc)
	timespanCommand -3 email-command show TIMESPAN "$@";;

    '')	echo >&2 'ERROR: No GIT-COMMAND.'; echo >&2; printUsage "$0" >&2; exit 2;;
    *)	printf >&2 "ERROR: '%s' cannot be used with a %s scope.\\n" "$gitCommand" "$scope"; exit 2;;
esac
