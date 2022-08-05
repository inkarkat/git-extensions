# rebase vs. merging

For merging, you switch to the target branch (e.g. master), then merge the source branch.
For rebasing, you stay in your working branch and rebase to master.
Therefore, the meaning of _ours_ and _theirs_ is somewhat unintuitive:
* what we have on the checked out master branch is _ours_
* what we had (and is being merged or replayed) in our working branch is _theirs_

# invoking
`rebase [<upstream> [<branch>]]`
* `<branch>` is optional and just a shortcut for doing `git switch <branch>`
  prior to rebasing; by default the current branch is used
* `<upstream>` is the earlier commit up to which (from `HEAD` (/ `<branch>`))
  the commits are replayed; this defaults to the tracked branch
The commits between `<upstream>` and `HEAD` that are NOT yet in `<upstream>`
will be replayed on top of `<upstream>`.
* `--onto <newbase>` will replay on top of `<newbase>` instead; this allows
  moving of commits to a different branch (but note that it will still replay
  on top of `<upstream>`; `<newbase>` won't be touched, so you have to
  duplicate `<upstream>` first to a dummy branch, move `<newbase>`, and then
  clean up `<upstream>`)

# special use cases
* `git rebase HEAD <feature> && git rebase HEAD @{-2}`
  Rebase `<feature>` to current branch and merge back to current
* `git rebase master --onto <newbase>` <=> `git bmrbi --onto <newbase>`
  Rebase the changes in the current branch (with regards to master) to appear
  as if they were committed onto `<newbase>`. Can be used to move a branch with
  a set of commits to another base commit.
* `git rebase HEAD^ --onto <newbase>` <=> `git rblast -n 1 --onto <newbase>`
  Rebase the last commit to appear as if they were committed onto `<newbase>`
  (but all on the current branch!)
* `git merge --squash`
  Create a single commit on top of the current branch whose effect is the same
  as merging the other branch. Shorter form of interactive rebasing where you
  choose squash for all following commits.

# interactive actions

a) Remove commits by **deleting** lines. Like the `revert` command, but off the
   record: it will be as if the commit never existed.
b) Reorder commits by **reordering** lines.
Replace pick with:
d) `edit` to mark a commit for amending.
e) `reword` to change the log message.
f) `squash` to merge a commit with the previous one.
g) `fixup` to merge a commit with the previous one and discard the log message.

# during a rebase

1. Resolve the conflicted files; `git conflicts` tells them (again)
   To completely override upstream's changes, we have to use _theirs_ (from the
   branch being rebased, i.e. `git cot`), not _ours_; this is unintuitive!
2. `git add` # after the conflicts have been resolved
3. `git rbc`
It may help to have both our and their changes separately:
`git lc master`
`git lc`

# getting out

`git rbq` # Cancels the whole rebase and returns to the original state.
`git rbs` # Skips the current patch as if you had initially deleted the line.
`git rbe` # Edit the todo list to change following choices (e.g. if you realize that a following patch needs editing, too)
`git rbu` # Undo the last rebase commit. Effectively squashes this patch with the previous one.
