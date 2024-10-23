#!/bin/bash source-this-script
shopt -qs extglob

countLogArgs()
{
    local isIncludeDiffArgs="${1?}"; shift

    [ "$isIncludeDiffArgs" ] \
	&& case "$1" in
	    -+([RWXabcpuw]))
		    return 1;;
	    --@(cc|color-moved|color-words|color|compact-summary|cumulative|dd|default-prefix|dirstat|dirstat-by-file|ext-diff|full-diff|function-context|histogram|ignore-all-space|ignore-blank-lines|ignore-cr-at-eol|ignore-space-at-eol|ignore-space-change|ignore-submodules|ita-invisible-in-index|minimal|no-color|no-color-moved|no-color-moved-ws|no-ext-diff|no-prefix|no-relative|no-textconv|numstat|patch|patch-with-raw|patch-with-stat|patience|relative|remerge-diff|shortstat|stat|text|textconv|word-diff))
		    return 1;;
	    -[IOU])
		    return 2;;
	    --@(anchored|color-moved-ws|diff-algorithm|diff-merges|dst-prefix|ignore-matching-lines|inter-hunk-context|line-prefix|rotate-to|skip-to|src-prefix|unified|word-diff-regex)=*)
		    return 1;;
	    --@(anchored|color-moved-ws|diff-algorithm|diff-merges|dst-prefix|ignore-matching-lines|inter-hunk-context|line-prefix|rotate-to|skip-to|src-prefix|unified|word-diff-regex))
		    return 2;;
	esac

    case "$1" in
	# Note: Exclude -N because that's taken by git-*-command(s).
	# +([0-9])
	-+([BCDEFMPgimstz]))
		return 1;;
	--@(?(no-)mailmap|?(no-)rename-empty|?(no-)standard-notes|?(no-)use-mailmap|abbrev|abbrev-commit|all|all-match|alternate-refs|ancestry-path|author-date-order|basic-regexp|binary|bisect|boundary|branches|break-rewrites|check|cherry|cherry-mark|cherry-pick|children|clear-decorations|combined-all-paths|date-order|decorate|dense|dense|do-walk|exclude-first-parent-only|expand-tabs|extended-regexp|find-copies|find-copies-harder|find-renames|first-parent|fixed-strings|follow|full-history|full-index|graph|ignore-missing|indent-heuristic|invert-grep|irreversible-delete|left-only|left-right|log-size|merge|merges|name-only|name-status|no-abbrev-commit|no-decorate|no-diff-merges|no-expand-tabs|no-indent-heuristic|no-max-parents|no-merges|no-min-parents|no-notes|no-patch|no-renames|no-walk|not|notes|oneline|parents|perl-regexp|pickaxe-all|pickaxe-regex|pretty|raw|reflog|regexp-ignore-case|relative-date|remotes|remove-empty|reverse|right-only|show-linear-break|show-notes|show-notes-by-default|show-pulls|show-pulls|show-signature|simplify-by-decoration|simplify-merges|simplify-merges|single-worktree|source|sparse|sparse|stdin|submodule|summary|tags|topo-order|walk-reflogs))
		return 1;;
	-[GLSln])
		return 2;;
	--@(after|author|before|committer|date|decorate-refs-exclude|decorate-refs|diff-filter|encoding|exclude-hidden|exclude|expand-tabs|find-object|format|glob|grep-reflog|grep|max-count|max-parents|min-parents|output-indicator-context|output-indicator-new|output-indicator-old|output|since-as-filter|since|skip|until|ws-error-highlight)=*)
		return 1;;
	--@(after|author|before|committer|date|decorate-refs-exclude|decorate-refs|diff-filter|encoding|exclude-hidden|exclude|expand-tabs|find-object|format|glob|grep-reflog|grep|max-count|max-parents|min-parents|output-indicator-context|output-indicator-new|output-indicator-old|output|since-as-filter|since|skip|until|ws-error-highlight))
		return 2;;
    esac

    return 0
}
