#!/bin/bash source-this-script
shopt -qs extglob

: ${GIT_DOEXTENSIONS_WRAPPEE:?}
: ${GIT_DOEXTENSIONS_DASHDASH_ARGS_BEFORE_SIMPLECOMMAND?}   # Flag whether there are -- ARGS [...] before a [-- SIMPLECOMMAND] (like in wcdo).
: ${GIT_DOEXTENSIONS_WHAT:=CONFIGURED SUBJECTS}

: ${SHELL:=bash}
printf -v quotedShell '%q' "$SHELL"

# A --color argument is not supported.
# Enable the user to abort the iteration via a special exit status.
typeset -ra shellCommandWcdoArgs=(--no-git-color --abort-on 126)
# Because of the interactive shell, we must not interfere with terminal access,
# so no header (the shell prompt will indicate the working directory, anyway),
# and no paging.
typeset -ra shellInteractiveWcdoArgs=(--no-git-color --interactive --abort-on 126)

printExtendedUsage()
{
    local wrapper="$GIT_DOEXTENSIONS_WRAPPER"; [ -n "$wrapper" ] || wrapper="$(basename "$1")"
    local splitPattern='/^Note:/'
    "$GIT_DOEXTENSIONS_WRAPPEE" --help 2>&1 | sed \
	-e "${splitPattern},\$d" \
	-e '/^Usage:$/N' -e '/\(^\|\n\)Usage: */{ s/\(^\|\n\)\(Usage: *\)\?\([^ ]\+ \)*'"${GIT_DOEXTENSIONS_WRAPPEE} /\\1\\2${wrapper}"' [--untracked|--dirty|--stageable|--wips [(+|-)CHECK [(+|-)...]|--uprogress [(+|-)CHECK [(+|-)...]]|--same-branch [-b|--branch BRANCH]] /; }'
    cat <<HELPTEXT

Supports the following special commands and options:
    repo-missing	    Show $GIT_DOEXTENSIONS_WHAT that are
			    not yet under Git source control.
    [branch-range] counts* [<log-options>] [<revision range>] [[--] <path>...]
			    Count and add up the amount of commits in
			    $GIT_DOEXTENSIONS_WHAT that fall into
			    the logged range.
			    [branch-range] is td, year, etc.
			    * stands for any filter (mine, team, ...)
    [branch-range] countsleaderboard* [<log-options>] [<revision range>] [[--] <path>...]
			    List $GIT_DOEXTENSIONS_WHAT
			    ordered by the amount of commits in the logged range
			    (omitting those without any commits).
			    [branch-range] is td, year, etc.
			    * stands for any filter (mine, team, ...)
    [branch-range] commitkeywordtallies* [OPTIONS ...] [<log-options>] [<revision range>] [[--] <path>...]
			    Report counts and percentages of commit message
			    keywords or scopes in $GIT_DOEXTENSIONS_WHAT
			    that fall into the logged range.
			    [branch-range] is td, year, etc.
			    * stands for any filter (mine, team, ...)
    [branch-range] committaskidtallies* [OPTIONS ...] [<log-options>] [<revision range>] [[--] <path>...]
			    Report counts and percentages of external task IDs
			    at the beginning of the commit summary in
			    $GIT_DOEXTENSIONS_WHAT
			    that fall into the logged range.
			    [branch-range] is td, year, etc.
			    * stands for any filter (mine, team, ...)
    [branch-range] logs-distribution* [LOGDISTRIBUTION-OPTIONS ...] [<log-options>] [<revision range>] [[--] <path>...]
			    Print the distribution of the number of commits in
			    $GIT_DOEXTENSIONS_WHAT that fall into
			    the logged range.
			    [branch-range] is td, year, etc.
			    * stands for any filter (mine, team, ...)
    [branch-range] br-lifetimes* [BRLIFETIMES-OPTIONS ...] [<log-options>] [<revision range>] [[--] <path>...]
			    One-line lifetime, number of commits, commit range,
			    author, date, tags and commit summary of merged
			    branches in
			    $GIT_DOEXTENSIONS_WHAT [that happened in
			    the logged range]. [branch-range] is td, year, etc.
			    * stands for any filter (mine, team, ...)
    [branch-range] br-lifetimesbyeach [BRLIFETIMES-OPTIONS ...] [<log-options>] [<revision range>]
			    One-line lifetime, number of commits, commit range,
			    author, date, tags and commit summary of merged
			    branches for each user in
			    $GIT_DOEXTENSIONS_WHAT [that happened in
			    the logged range]. [branch-range] is td, year, etc.
    [branch-range] br-lifetimes*over* [BRLIFETIMES-OPTIONS ...] [<log-options>] [<revision range>]
			    One-line lifetime, number of commits, commit range,
			    author, date, tags and commit summary of merged
			    branches staggered for date ranges in
			    $GIT_DOEXTENSIONS_WHAT [that happened in
			    the logged range]. [branch-range] is td, year, etc.
    [branch-range] logs-msgstat* [LOGMSGSTAT-OPTIONS ...] [<log-options>] [<revision range>] [[--] <path>...]
			    One-line statistics about the size of commit
			    messages (excluding trailers and quoted parts) in
			    $GIT_DOEXTENSIONS_WHAT [that happened in
			    the logged range]. [branch-range] is td, year, etc.
			    * stands for any filter (mine, team, ...)
    [branch-range] logs-msgstatbyeach [LOGMSGSTAT-OPTIONS ...] [<log-options>] [<revision range>]
			    One-line statistics about the size of commit
			    messages (excluding trailers and quoted parts) for
			    each user in
			    $GIT_DOEXTENSIONS_WHAT [that happened in
			    the logged range]. [branch-range] is td, year, etc.
    [branch-range] logs-msgstat*over* [LOGMSGSTAT-OPTIONS ...] [<log-options>] [<revision range>]
			    One-line statistics about the size of commit
			    messages (excluding trailers and quoted parts)
			    staggered for date ranges in
			    $GIT_DOEXTENSIONS_WHAT [that happened in
			    the logged range]. [branch-range] is td, year, etc.
     prs-reviewduration* [PRREVIEWDURATION-OPTIONS ...]
			    Print durations from the opening / request of a pull
			    request review to the actual review / comments on
			    the PR in ${GIT_DOEXTENSIONS_WHAT}.
			    * stands for any filter (mine, team, ...)
     prs-reviewdurationbyeach [PRREVIEWDURATION-OPTIONS ...]
			    Print durations from the opening / request of a pull
			    request review to the actual review / comments on
			    the PR for each reviewer separately in
			    ${GIT_DOEXTENSIONS_WHAT}.
     prs-reviewduration*over* [PRREVIEWDURATION-OPTIONS ...]
			    Print durations from the opening / request of a pull
			    request review to the actual review / comments on
			    the PR staggered for date ranges in
			    ${GIT_DOEXTENSIONS_WHAT}.
    untracked-sh [COMMAND ...]
			    Open an interactive shell / execute COMMAND in
			    $GIT_DOEXTENSIONS_WHAT that have
			    new files not yet added to version control (and not
			    covered by the ignore patterns).
			    You can abort the iteration by exiting the shell
			    with exit status 126.
    --untracked		    Also available as a standalone predicate (to combine
			    with other COMMAND(s)).
    dirty-sh [COMMAND ...]  Open an interactive shell / execute COMMAND in
			    $GIT_DOEXTENSIONS_WHAT that have
			    uncommitted changes. You can abort the iteration by
			    exiting the shell with exit status 126.
    --dirty		    Also available as a standalone predicate (to combine
			    with other COMMAND(s)).
    stageable-sh [COMMAND ...]
			    Open an interactive shell / execute COMMAND in
			    $GIT_DOEXTENSIONS_WHAT that have
			    new files not yet added to version control (and not
			    covered by the ignore patterns) and/or files with an
			    unstaged modification.
			    Equivalent to untracked + dirty - staged files.
			    You can abort the iteration by exiting the shell
			    with exit status 126.
    --stageable		    Also available as a standalone predicate (to combine
			    with other COMMAND(s)).
    wips [WIPS-ARGS ...]
			    Test whether $GIT_DOEXTENSIONS_WHAT
			    have work in progress.
    wips-sh [(+|-)CHECK [(+|-)...]] [COMMAND ...]
			    Open an interactive shell / execute COMMAND in
			    $GIT_DOEXTENSIONS_WHAT that have
			    work in progress. You can abort the iteration by
			    exiting the shell with exit status 126.
    --wips [(+|-)CHECK [(+|-)...]]
			    Also available as a standalone predicate (to combine
			    with other COMMAND(s)).
    fetchdate [--absolute|-a|--epoch] [-n|--newer|-o|--older|-lt|-le|-eq|-ne|-ge|-gt AGE[SUFFIX]]
			    Show when (any) remote was last fetched if it
			    matches the condition. Allows to identify repos in
			    need of an update.
    ufetch [--gui|--terminal|--none]
			    Fetch all upstream changes, and show a log of
			    changes.
    uprogress [WIPS-ARGS ...]
			    Test whether changes in upstream have been fetched
			    that could be incorporated into
			    $GIT_DOEXTENSIONS_WHAT.
			    Ignores local customizations and private files that
			    may happen when just following an upstream repo.
    uprogress-sh [(+|-)CHECK [(+|-)...]] [COMMAND ...]
			    Open an interactive shell / execute COMMAND in
			    $GIT_DOEXTENSIONS_WHAT that have
			    changes in upstream that could be incorporated.
			    You can abort the iteration by exiting the shell
			    with exit status 126.
    --uprogress [(+|-)CHECK [(+|-)...]]
			    Also available as a standalone predicate (to combine
			    with other COMMAND(s)).
    --same-branch	    Only consider $GIT_DOEXTENSIONS_WHAT
			    that are on the same branch as the current working
			    copy / also have the passed -b|-branch BRANCH.
    --branch|-b BRANCH	    Use a different branch than the current working
			    copy's for --same-branch, and consider
			    $GIT_DOEXTENSIONS_WHAT that have
			    (not necessarily are on) that BRANCH.
    --with-remote	    Only consider $GIT_DOEXTENSIONS_WHAT
			    that have a remote configured.
    --without-remote	    Only consider purely local
			    $GIT_DOEXTENSIONS_WHAT
			    that do not have a remote configured.
HELPTEXT
    [ "$GIT_DOEXTENSIONS_ADDITIONAL_EXTENSIONS" ] && printf '%s\n' "$GIT_DOEXTENSIONS_ADDITIONAL_EXTENSIONS"
    "$GIT_DOEXTENSIONS_WRAPPEE" --help 2>&1 | sed -e "${splitPattern}p" -e "1,${splitPattern}d"
}

countsExtension()
{
    local countCommand="${1:?}"; shift
    local quotedCountArgs=; [ $# -eq 0 ] || printf -v quotedCountArgs ' %q' "$@"
    wcdoArgs+=(--no-header --skip-files --no-git-color --command "${countCommand}${quotedCountArgs}")
    accumulationCommand=(sumField 1)
}

countsleaderboardExtension()
{
    local countCommand="${1:?}"; shift
    local quotedCountArgs=; printf -v quotedCountArgs ' %q' --skip-empty "$@"
    export HEADER_COLON=$'\t' HEADER_NEWLINE='' HEADER_SEPARATOR='' # Tab-separated single line header format for postprocessing.
    wcdoArgs+=(--skip-files --no-git-color --command "${countCommand}${quotedCountArgs}")
    accumulationCommand=(accumulateLeaderboard)
}

accumulateLeaderboard()
{
    sort --field-separator $'\t' --key 2,2 --numeric-sort --reverse \
	| column -s $'\t' -t
}

commitTalliesExtension()
{
    local aggregateCommand="${1?}"; shift
    local tallyCommand="${1:?}"; shift
    local filterSuffix="${1?}"; shift
    local logCommand="${aggregateCommand}${aggregateCommand:+ }l"; [[ "$tallyCommand" =~ taskid ]] || logCommand+='o'	# Task ID is at the beginning of the commit subject; keywords can be anywhere.
    typeset -a logArgs=()
    typeset -a commitKeywordTallyArgs=()
    while [ $# -ne 0 ]
    do
	case "$1" in
	    -+([s]))	commitKeywordTallyArgs+=("$1"); shift;;
	    --@(scopes|bare|no-percentages))
			commitKeywordTallyArgs+=("$1"); shift;;
	    -[N])	commitKeywordTallyArgs+=("$1" "${2?}"); shift; shift;;
	    --@(percentage-threshold|against-total-commits))
			commitKeywordTallyArgs+=("$1" "${2?}"); shift; shift;;
	    --)		logArgs+=("$1"); shift; break;;
	    *)		logArgs+=("$1"); shift;;
	esac
    done
    quotedLogArgs=; [ ${#logArgs[@]} -eq 0 ] || printf -v quotedLogArgs ' %q' "${logArgs[@]}"
    wcdoArgs+=(--no-header --skip-files --no-git-color --command "git-wrapper ${logCommand}${filterSuffix}${quotedLogArgs}")
    accumulationCommand=("$tallyCommand" "${commitKeywordTallyArgs[@]}")
}

logsDistributionExtension()
{
    local logDistributionCommand="${1:?}"; shift
    # Supply any arguments both to the git-logdistribution that gets iterated over
    # (it will pick the log options and ignore the distribution ones), and to the
    # git-logdistribution that accumulates and graphs the data (it will pick the
    # distribution options and ignore the log options).
    printf -v quotedLogDistributionArgs '%q ' --log-only "$@"; quotedLogDistributionArgs="${quotedLogDistributionArgs% }"
    wcdoArgs+=(--no-header --skip-files --no-git-color --command "$logDistributionCommand $quotedLogDistributionArgs")
    accumulationCommand=(git-logdistribution --stdin "$@")
}

logOnlyAndStdinDualCommandExtension()
{
    local logOnlyAndStdinDualCommand="${1:?}"; shift
    local scopedAndFilteredDualCommand="${1:?}"; shift
    # Supply any arguments both to the command that gets iterated over, and to the
    # command that accumulates and reports the data (it will ignore the log
    # options).
    printf -v quotedArgs '%q ' --log-only "$@"; quotedArgs="${quotedArgs% }"
    wcdoArgs+=(--no-header --skip-files --no-git-color --command "$scopedAndFilteredDualCommand $quotedArgs")
    accumulationCommand=("$logOnlyAndStdinDualCommand" --stdin "$@")
}

byEachCommandExtension()
{
    local aggregateCommandConfigVarPrefix="${1:?}"; shift
    local byEachCommand="${1:?}"; shift
    local scopedAndFilteredByEachCommand="${1:?}"; shift
    local wcdoCommand="$(basename -- "$0")"; wcdoCommand="${wcdoCommand#git-}"
    local quotedWcdoCommand; printf -v quotedWcdoCommand '%q ' "$wcdoCommand" "${wcdoCommandArgs[@]}" --no-header --no-git-color "${wcdoArgs[@]}" "${dashdashArgs[@]}" "${args[@]}"

    # The current wcdo-command needs to be injected into git-segregated-user-command
    # to obtain all users found in all working copies (not just the current
    # (potentially unrelated) one), and into $byEachCommand to iterate over all
    # working copies (for each user).
    eval "export ${aggregateCommandConfigVarPrefix}_AGGREGATE_COMMAND=\"\${quotedWcdoCommand}\${scopedAndFilteredOvertimeCommand}\""
    GIT_SEGREGATEDUSERCOMMAND_AGGREGATE_COMMAND="${quotedWcdoCommand}" \
	exec $byEachCommand "$@"
    # The exec aborts the original execution here, but that's fine as we'll be
    # invoked repeatedly for each user.
}

overtimeCommandExtension()
{
    local aggregateCommandConfigVarPrefix="${1:?}"; shift
    local overtimeCommand="${1:?}"; shift
    local scopedAndFilteredOvertimeCommand="${1:?}"; shift
    local wcdoCommand="$(basename -- "$0")"; wcdoCommand="${wcdoCommand#git-}"
    local quotedWcdoCommand; printf -v quotedWcdoCommand '%q ' "$wcdoCommand" "${wcdoCommandArgs[@]}" --no-header --no-git-color "${wcdoArgs[@]}" "${dashdashArgs[@]}" "${args[@]}"

    # The current wcdo-command needs to be injected into $overtimeCommand to iterate
    # over all working copies (for each date range). Unlike
    # byEachCommandExtension(), we don't need to obtain users across all working
    # copies here; the date ranges are the same everywhere.
    eval "export ${aggregateCommandConfigVarPrefix}_AGGREGATE_COMMAND=\"\${quotedWcdoCommand}\${scopedAndFilteredOvertimeCommand}\""
	exec $overtimeCommand "$@"
    # The exec aborts the original execution here, but that's fine as we'll be
    # invoked repeatedly for each user.
}

typeset -a wcdoArgs=()
typeset -a wcdoCommandArgs=()
let dashdashCnt=0
typeset -a dashdashArgs=()  # Including any -- (as executeCommand() needs to pass authentic arguments along).
typeset -a unknownOptions=()   # Non-wcdo options after -- ARGS ... --; these must be handled by the client; executeCommand() ignores them.
typeset -a args=()
typeset -a accumulationCommand=()
isSameBranch=
branch=

parseCommand()
{
    while [ $# -ne 0 ]
    do
	case ",${DEBUG:-}," in *,git-do-extensions,*) printf >&2 '%sgit-do-extensions: Parsing %s\n' "$PS4" "$1";; esac
	case "$1" in
	    --help|-h|-\?)  shift; printExtendedUsage "$0"; exit 0;;

	    --command|-c)
			    wcdoCommandArgs+=("$1" "$2"); shift; shift;;
	    -+([qs]))
			    wcdoArgs+=("$1"); shift;;
	    --@(no-pager|no-header|branch-name|interactive|separate-errors|no-git-color|no-color|color=*|abort-on-failure|single-success|status-99-is-noop|skip-files|skip-foreign|repeat))
			    wcdoArgs+=("$1"); shift;;
	    -[PX])
			    wcdoArgs+=("$1" "$2"); shift; shift;;
	    --@(abort-on|color|progress|foreign-command|predicate-command|subdo-command-name))
			    wcdoArgs+=("$1" "$2"); shift; shift;;

	    --untracked)    shift; wcdoArgs+=(--predicate-command 'git untracked');;
	    --dirty)	    shift; wcdoArgs+=(--predicate-command 'git-dirty --quiet');;
	    --stageable)    shift; wcdoArgs+=(--predicate-command 'git-stageable');;
	    --wips|--uprogress)
			    case "$1" in
				--wips)		predicateCommand='git wips';;
				--uprogress)	predicateCommand='git-existsremote upstream && git-progresswips';;
				*)		printf >&2 'ASSERT: Unhandled flag: %s\n' "$1"; exit 3;;
			    esac; shift
			    typeset -a wipsArgs=()
			    while [ $# -gt 0 ] && [[ "$1" =~ ^[+-][[:alpha:]]+$ ]]
			    do
				wipsArgs+=("$1"); shift
			    done
			    quotedWipsArgs=; [ ${#wipsArgs[@]} -gt 0 ] && printf -v quotedWipsArgs '%q ' "${wipsArgs[@]}"
			    wipsQuietArg='--quiet'; if [ $# -eq 0 ]; then
				# DWIM: When no COMMAND is given, don't print
				# the default working copy root / submodule
				# name, but instead keep the git-wips output.
				wipsQuietArg=''
				wcdoArgs+=(--no-git-color)
				args=(exec true)
			    fi
			    wcdoArgs+=(--predicate-command "$predicateCommand ${wipsQuietArg}${wipsQuietArg:+ }${quotedWipsArgs}")
			    ;;
	    --same-branch)  shift; isSameBranch=t;;
	    --branch|-b)    shift; branch="${1:?}"; shift;;
	    --with-remote)  shift; wcdoArgs+=(--predicate-command 'git-existsremote');;
	    --without-remote)
			    shift; wcdoArgs+=(--predicate-command '! git-existsremote');;

	    --)		    let dashdashCnt+=1
			    if [ "$GIT_DOEXTENSIONS_DASHDASH_ARGS_BEFORE_SIMPLECOMMAND" ]; then
				case $dashdashCnt in
				    1)	if [ ${#dashdashArgs[@]} -eq 0 ]; then
					    # -- ARGS
					    dashdashArgs+=("$1"); shift
					else
					    # ARGS ... --
					    dashdashArgs+=("$1"); shift
					    case "$1" in
						--) shift; break;;  # XXX: ARGS ... -- --
						-*) ;;
						*)  break;;
					    esac
					    dashdashCnt=2
					fi
					;;
				    2)	# -- ARGS ... --
					dashdashArgs+=("$1"); shift
					case "$1" in
					    --) shift; break;;  # XXX: ARGS ... -- --
					    -*) ;;
					    *)  break;;
					esac
					;;
				    *)	wcdoArgs+=("$1"); shift; break;;
				esac
			    else
				wcdoArgs+=("$1"); shift
				break
			    fi
			    ;;
	    *)		    if [ "$GIT_DOEXTENSIONS_DASHDASH_ARGS_BEFORE_SIMPLECOMMAND" ]; then
				if [ $dashdashCnt -ge 2 ]; then
				    # Already saw -- ARGS ... --
				    if [ "${1:0:1}" = '-' ]; then
					unknownOptions+=("$1"); shift
				    else
					break
				    fi
				else
				    dashdashArgs+=("$1"); shift
				fi
			    else
				break
			    fi
			    ;;
	esac
    done
    if [ "$isSameBranch" ]; then
	if [ -n "$branch" ]; then
	    printf -v quotedBranch '%q' "$branch"
	    wcdoArgs+=(--predicate-command "git-existsbr -- $quotedBranch")
	else
	    currentBranch="$(git-brname --real-branch-only)" || exit $?
	    printf -v quotedCurrentBranch '%q' "$currentBranch"
	    wcdoArgs+=(--predicate-command "[ \"\$(git-brname --real-branch-only 2>/dev/null)\" = $quotedCurrentBranch ]")
	fi
    fi

    case ",${DEBUG:-}," in *,git-do-extensions,*) printf >&2 '%sgit-do-extensions: Additional args: ' "$PS4"; dump-args -- "$@";; esac
    if [ ${#wcdoCommandArgs[@]} -eq 0 -a $# -eq 0 ]; then
	:
    elif [ "${1:0:1}" != '-' ]; then
	commandSubAlias="${wrapper:- does not exist}-$1-$2"
	commandAlias="${wrapper:- does not exist}-$1"
	if type -t "$commandSubAlias" >/dev/null; then
	    shift; shift	# The first two arguments are part of the alias.
	    $commandSubAlias "$@"
	    exit $?
	elif type -t "$commandAlias" >/dev/null; then
	    shift	# The first argument is part of the alias.
	    $commandAlias "$@"
	    exit $?
	fi

	case "$1" in
	    repo-missing)
		# Synthesized new command.
		shift
		wcdoArgs+=(--no-header --skip-files --foreign-command 'pwd' --command :)
		args=("$@")
		;;
	    untracked-sh)
		# Synthesized new command.
		shift
		wcdoArgs+=(--predicate-command 'git untracked')
		if [ $# -eq 0 ]; then
		    wcdoArgs+=("${shellInteractiveWcdoArgs[@]}" --command "$quotedShell -i")
		    echo "Note: To abort the iteration of $GIT_DOEXTENSIONS_WHAT, use \"exit 126\"."
		else
		    printf -v quotedSimpleCommand '%q ' "$@"
		    wcdoArgs+=("${shellCommandWcdoArgs[@]}" --command "${quotedSimpleCommand# }")
		fi
		;;
	    dirty-sh)
		# Synthesized new command.
		shift
		wcdoArgs+=(--predicate-command 'git-dirty --quiet')
		if [ $# -eq 0 ]; then
		    wcdoArgs+=("${shellInteractiveWcdoArgs[@]}" --command "$quotedShell -i")
		    echo "Note: To abort the iteration of $GIT_DOEXTENSIONS_WHAT, use \"exit 126\"."
		else
		    printf -v quotedSimpleCommand '%q ' "$@"
		    wcdoArgs+=("${shellCommandWcdoArgs[@]}" --command "${quotedSimpleCommand# }")
		fi
		;;
	    stageable-sh)
		# Synthesized new command.
		shift
		wcdoArgs+=(--predicate-command 'git-stageable')
		if [ $# -eq 0 ]; then
		    wcdoArgs+=("${shellInteractiveWcdoArgs[@]}" --command "$quotedShell -i")
		    echo "Note: To abort the iteration of $GIT_DOEXTENSIONS_WHAT, use \"exit 126\"."
		else
		    printf -v quotedSimpleCommand '%q ' "$@"
		    wcdoArgs+=("${shellCommandWcdoArgs[@]}" --command "${quotedSimpleCommand# }")
		fi
		;;
	    wips-sh)
		# Synthesized new command.
		shift
		typeset -a wipsArgs=()
		while [ $# -gt 0 ] && [[ "$1" =~ ^[+-][[:alpha:]]+$ ]]
		do
		    wipsArgs+=("$1"); shift
		done
		quotedWipsArgs=; [ ${#wipsArgs[@]} -gt 0 ] && printf -v quotedWipsArgs ' %q' "${wipsArgs[@]}"
		wcdoArgs+=(--predicate-command "git wips --quiet${quotedWipsArgs}")
		if [ $# -eq 0 ]; then
		    wcdoArgs+=("${shellInteractiveWcdoArgs[@]}" --command "git wips${quotedWipsArgs} && $quotedShell -i")
		    echo "Note: To abort the iteration of $GIT_DOEXTENSIONS_WHAT, use \"exit 126\"."
		else
		    printf -v quotedSimpleCommand '%q ' "$@"
		    wcdoArgs+=("${shellCommandWcdoArgs[@]}" --command "${quotedSimpleCommand# }")
		fi
		;;
	    uprogress-sh)
		# Synthesized new command.
		shift
		typeset -a wipsArgs=()
		while [ $# -gt 0 ] && [[ "$1" =~ ^[+-][[:alpha:]]+$ ]]
		do
		    wipsArgs+=("$1"); shift
		done
		quotedWipsArgs=; [ ${#wipsArgs[@]} -gt 0 ] && printf -v quotedWipsArgs ' %q' "${wipsArgs[@]}"
		wcdoArgs+=(--predicate-command "git-existsremote upstream && git-progresswips --quiet${quotedWipsArgs}")
		if [ $# -eq 0 ]; then
		    wcdoArgs+=("${shellInteractiveWcdoArgs[@]}" --command "git-progresswips${quotedWipsArgs} && $quotedShell -i")
		    echo "Note: To abort the iteration of $GIT_DOEXTENSIONS_WHAT, use \"exit 126\"."
		else
		    printf -v quotedSimpleCommand '%q ' "$@"
		    wcdoArgs+=("${shellCommandWcdoArgs[@]}" --command "${quotedSimpleCommand# }")
		fi
		;;
	    fetchdate)
		# Synthesized new command.
		shift
		typeset -a fetchDateFormatArgs=()
		typeset -a fetchDateMessageArgs=(--message 'Last fetched')
		typeset -a fetchDateAgeArgs=()
		while [ $# -ne 0 ]
		do
		    case "$1" in
			--absolute|-a|--epoch)	fetchDateFormatArgs+=("$1"); shift;;
			--message|-m)		fetchDateMessageArgs+=("$1" "$2"); shift; shift;;
			*)			fetchDateAgeArgs+=("$1"); shift;;
		    esac
		done
		if [ ${#fetchDateAgeArgs[@]} -gt 0 ]; then
		    printf -v quotedFetchDateAgeArgs '%q ' "${fetchDateAgeArgs[@]}"
		    wcdoArgs+=(--predicate-command "git-fetchdate ${quotedFetchDateAgeArgs% }")
		fi
		wcdoArgs+=(--no-git-color)
		args=(fetchdate "${fetchDateMessageArgs[@]}" "${fetchDateFormatArgs[@]}")
		;;
	    ufetch)
		# Synthesized new command.
		shift
		wcdoArgs+=(--predicate-command 'git-existsremote upstream')
		args=(ufetchonly-hushed "$@")
		;;
	    uprogress)
		# Synthesized new command.
		shift
		wcdoArgs+=(--predicate-command 'git-existsremote upstream')
		args=(progresswips "$@")
		;;
	    wips)
		# Succeed if a single working copy has WIP.
		wcdoArgs+=(--single-success)
		args=("$@")
		;;
	    shell)
		wcdoArgs+=("${shellInteractiveWcdoArgs[@]}")
		# Succeed if a single working copy has WIP.
		wcdoArgs+=(--single-success)
		echo "Note: To abort the iteration of $GIT_DOEXTENSIONS_WHAT, use \"exit 126\"."
		args=("$@")
		;;
	    browse|ci-status|compare|delete|pull-request|fork|release|sync)
		wcdoArgs+=(--single-success)
		# These hub commands need a remote.
		wcdoArgs+=(--predicate-command git-existsremote)
		args=("$@")
		;;
	    cr|crrecent|crstats|issue|pr|prtitle|reviews)
		wcdoArgs+=(--single-success)
		# These hub commands need a remote.
		if [ "$GIT_DOEXTENSIONS_EXCLUDE_FORKS" ]; then
		    # This setting indicates that I only care about my own projects,
		    # not my forks of other projects.
		    wcdoArgs+=(--predicate-command 'git-existsremote origin && ! git-existsremote upstream')
		else
		    wcdoArgs+=(--predicate-command git-existsremote)
		fi
		args=("$@")
		;;
	    labels)
		# This hub command needs a remote.
		if [ "$GIT_DOEXTENSIONS_EXCLUDE_FORKS" ]; then
		    # This setting indicates that I only care about my own projects,
		    # not my forks of other projects.
		    wcdoArgs+=(--predicate-command 'git-existsremote origin && ! git-existsremote upstream')
		else
		    wcdoArgs+=(--predicate-command git-existsremote)
		fi
		args=("$@")
		;;
	    create)
		wcdoArgs+=(--single-success)
		# This hub command (mostly) only applies to repos without a remote.
		wcdoArgs+=(--predicate-command '! git-existsremote')
		args=("$@")
		;;
	    countsleaderboard*)
		# Synthesized new command.

		# Translate e.g. countsleaderboardmine to "git countmine".
		# This way, all filters supplied by my various variants can be used.
		countCommand="git count${1#countsleaderboard}"; shift
		countsleaderboardExtension "$countCommand" "$@"
		;;
	# Synthesized new command variants of existing commands that support appended
	# filters (like *mine).
	    counts*)
		countCommand="git count${1#counts}"; shift
		countsExtension "$countCommand" "$@"
		;;
	    commit@(keyword|taskid)tallies*)
		tallyCommand="${1%tallies*}tally"; filterSuffix="${1#*tallies}"; shift
		commitTalliesExtension '' "git-$tallyCommand" "$filterSuffix" "$@"
		;;
	    logs-distribution*)
		logDistributionCommand="git logdistribution${1#logs-distribution}"; shift
		logsDistributionExtension "$logDistributionCommand" "$@"
		;;
	    br-lifetimesbyeach)
		shift
		byEachCommandExtension GIT_BRLIFETIMESBYEACH git-brlifetimesbyeach br-lifetimes "$@"
		;;
	    br-lifetimes*over*)
		brLifetimesCommand="git br${1#br-}"; shift
		overtimeCommandExtension GIT_BRLIFETIMESOVERTIME "$brLifetimesCommand" br-lifetimes "$@"
		;;
	    br-lifetimes*)
		brLifetimesCommand="git brlifetimes${1#br-lifetimes}"; shift
		logOnlyAndStdinDualCommandExtension git-brlifetimes "$brLifetimesCommand" "$@"
		;;
	    logs-msgstatbyeach)
		shift
		byEachCommandExtension GIT_LOGMSGSTATBYEACH git-logmsgstatbyeach logs-msgstat "$@"
		;;
	    logs-msgstat*over*)
		logMsgStatCommand="git log${1#logs-}"; shift
		overtimeCommandExtension GIT_LOGMSGSTATOVERTIME "$logMsgStatCommand" logs-msgstat "$@"
		;;
	    logs-msgstat*)
		logsMsgStatCommand="git logmsgstat${1#logs-msgstat}"; shift
		logOnlyAndStdinDualCommandExtension git-logmsgstat "$logsMsgStatCommand" "$@"
		;;
	    prs-reviewdurationbyeach)
		shift
		wcdoArgs+=(--predicate-command 'git-existsremote')
		byEachCommandExtension HUB_PRREVIEWDURATIONBYEACH hub-prreviewdurationbyeach prs-reviewduration "$@"
		;;
	    prs-reviewduration*over*)
		prReviewDurationCommand="hub pr${1#prs-}"; shift
		overtimeCommandExtension HUB_PRREVIEWDURATIONOVERTIME "$prReviewDurationCommand" prs-reviewduration "$@"
		;;
	    prs-reviewduration*)
		wcdoArgs+=(--predicate-command 'git-existsremote')
		hubPrreviewdurationCommand="hub-wrapper prreviewduration${1#prs-reviewduration}"; shift
		logOnlyAndStdinDualCommandExtension hub-prreviewduration "$hubPrreviewdurationCommand" "$@"
		;;
	    *)
		if git-br-variants --bare |  grep --quiet --fixed-strings --line-regexp "$1"; then
		    case "$2" in
			countsleaderboard*)
			    # Synthesized new command.
			    countCommand="git $1 count${2#countsleaderboard}"; shift; shift
			    countsleaderboardExtension "$countCommand" "$@"
			    set --
			    ;;
		    # Synthesized new command variants of existing commands that support appended
		    # filters (like *mine).
			counts*)
			    countCommand="git $1 count${2#counts}"; shift; shift
			    countsExtension "$countCommand" "$@"
			    set --
			    ;;
			commit@(keyword|taskid)tallies*)
			    aggregateCommand="$1"; tallyCommand="${2%tallies*}tally"; filterSuffix="${2#*tallies}"; shift; shift
			    commitTalliesExtension "$aggregateCommand" "git-$tallyCommand" "$filterSuffix" "$@"
			    set --
			    ;;
			logs-distribution*)
			    logDistributionCommand="git $1 logdistribution${2#logs-distribution}"; shift; shift
			    logsDistributionExtension "$logDistributionCommand" "$@"
			    set --
			    ;;
			br-lifetimesbyeach)
			    brLifetimesSynthesizedCommand="$1 br-lifetimes"; shift; shift
			    byEachCommandExtension GIT_BRLIFETIMESBYEACH git-brlifetimesbyeach "$brLifetimesSynthesizedCommand" "$@"
			    ;;
			br-lifetimes*over*)
			    brLifetimesCommand="git br${2#br-}"
			    brLifetimesSynthesizedCommand="$1 br-lifetimes"
			    shift; shift
			    overtimeCommandExtension GIT_BRLIFETIMESOVERTIME "$brLifetimesCommand" "$brLifetimesSynthesizedCommand" "$@"
			    ;;
			br-lifetimes*)
			    brLifetimesCommand="git $1 brlifetimes${2#br-lifetimes}"; shift; shift
			    logOnlyAndStdinDualCommandExtension git-brlifetimes "$brLifetimesCommand" "$@"
			    set --
			    ;;
			logs-msgstatbyeach)
			    logMsgStatSynthesizedCommand="$1 logs-msgstat"; shift; shift
			    byEachCommandExtension GIT_LOGMSGSTATBYEACH git-logmsgstatbyeach "$logMsgStatSynthesizedCommand" "$@"
			    ;;
			logs-msgstat*over*)
			    logMsgStatCommand="git log${2#logs-}"
			    logMsgStatSynthesizedCommand="$1 logs-msgstat"
			    shift; shift
			    overtimeCommandExtension GIT_LOGMSGSTATOVERTIME "$logMsgStatCommand" "$logMsgStatSynthesizedCommand" "$@"
			    ;;
			logs-msgstat*)
			    logsMsgStatCommand="git $1 logmsgstat${2#logs-msgstat}"; shift; shift
			    logOnlyAndStdinDualCommandExtension git-logmsgstat "$logsMsgStatCommand" "$@"
			    set --
			    ;;
			# no br-variant form of prs-reviewdurationbyeach
			# no br-variant form of prs-reviewduration*
		    esac
		fi

		args=("$@")
		;;
	esac
    else
	args=("$@")
    fi
}

executeCommand()
{
    if [ ${#accumulationCommand[@]} -eq 0 ]; then
	exec "$GIT_DOEXTENSIONS_WRAPPEE" "${wcdoCommandArgs[@]}" "${wcdoArgs[@]}" "${dashdashArgs[@]}" "${args[@]}"
    else
	"$GIT_DOEXTENSIONS_WRAPPEE" "${wcdoCommandArgs[@]}" "${wcdoArgs[@]}" "${dashdashArgs[@]}" "${args[@]}" | "${accumulationCommand[@]}"
    fi
}
