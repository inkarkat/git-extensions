#!/bin/bash source-this-script
shopt -qs extglob

countLogArgs()
{
    local isIncludeDiffArgs="${1?}"; shift

    [ "$isIncludeDiffArgs" ] \
	&& case "$1" in
	    -+([RWabw]))
		    return 1;;
	    --@(color-moved|color-words|color|default-prefix|ext-diff|function-context|ignore-all-space|ignore-blank-lines|ignore-cr-at-eol|ignore-space-at-eol|ignore-space-change|ignore-submodules|ita-invisible-in-index|no-color|no-color-moved|no-color-moved-ws|no-ext-diff|no-prefix|no-relative|no-textconv|relative|text|textconv|word-diff))
		    return 1;;
	    -[IO])
		    return 2;;
	    --@(color-moved-ws|dst-prefix|ignore-matching-lines|inter-hunk-context|line-prefix|rotate-to|skip-to|src-prefix|word-diff-regex)=*)
		    return 1;;
	    --@(color-moved-ws|dst-prefix|ignore-matching-lines|inter-hunk-context|line-prefix|rotate-to|skip-to|src-prefix|word-diff-regex))
		    return 2;;
	esac

    case "$1" in
	# Note: Exclude -N because that's taken by git-*-command(s).
	# +([0-9])
	-+([BCDEFMPXcgimpstuz]))
		return 1;;
	--@(?(no-)mailmap|?(no-)rename-empty|?(no-)standard-notes|?(no-)use-mailmap|abbrev|abbrev-commit|all|all-match|alternate-refs|ancestry-path|author-date-order|basic-regexp|binary|bisect|boundary|branches|break-rewrites|cc|check|cherry|cherry-mark|cherry-pick|children|clear-decorations|combined-all-paths|compact-summary|cumulative|date-order|dd|decorate|dense|dense|dirstat|dirstat-by-file|do-walk|exclude-first-parent-only|expand-tabs|extended-regexp|find-copies|find-copies-harder|find-renames|first-parent|fixed-strings|follow|full-diff|full-history|full-index|graph|histogram|ignore-missing|indent-heuristic|invert-grep|irreversible-delete|left-only|left-right|log-size|merge|merges|minimal|name-only|name-status|no-abbrev-commit|no-decorate|no-diff-merges|no-expand-tabs|no-indent-heuristic|no-max-parents|no-merges|no-min-parents|no-notes|no-patch|no-renames|no-walk|not|notes|numstat|oneline|parents|patch|patch-with-raw|patch-with-stat|patience|perl-regexp|pickaxe-all|pickaxe-regex|pretty|raw|reflog|regexp-ignore-case|relative-date|remerge-diff|remotes|remove-empty|reverse|right-only|shortstat|show-linear-break|show-notes|show-notes-by-default|show-pulls|show-pulls|show-signature|simplify-by-decoration|simplify-merges|simplify-merges|single-worktree|source|sparse|sparse|stat|stdin|submodule|summary|tags|topo-order|walk-reflogs))
		return 1;;
	-[GLSUln])
		return 2;;
	--@(after|anchored|author|before|committer|date|decorate-refs-exclude|decorate-refs|diff-algorithm|diff-filter|diff-merges|encoding|exclude-hidden|exclude|expand-tabs|find-object|format|glob|grep-reflog|grep|max-count|max-parents|min-parents|output-indicator-context|output-indicator-new|output-indicator-old|output|since-as-filter|since|skip|unified|until|ws-error-highlight)=*)
		return 1;;
	--@(after|anchored|author|before|committer|date|decorate-refs-exclude|decorate-refs|diff-algorithm|diff-filter|diff-merges|encoding|exclude-hidden|exclude|expand-tabs|find-object|format|glob|grep-reflog|grep|max-count|max-parents|min-parents|output-indicator-context|output-indicator-new|output-indicator-old|output|since-as-filter|since|skip|unified|until|ws-error-highlight))
		return 2;;
    esac

    return 0
}
