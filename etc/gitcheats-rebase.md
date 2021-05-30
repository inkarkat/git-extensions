# rebase vs. merging

For merging, you switch to the target branch (e.g. master), then merge the source branch.
For rebasing, you stay in your working branch and rebase to master.
Therefore, the meaning of _ours_ and _theirs_ is somewhat unintuitive:
* what we have on the checked out master branch is _ours_
* what we had (and is being merged or replayed) in our working branch is _theirs_

# actions

a) Remove commits by **deleting** lines. Like the `revert` command, but off the record: it will be as if the commit never existed.
b) Reorder commits by **reordering** lines.
Replace pick with:
d) `edit` to mark a commit for amending.
e) `reword` to change the log message.
f) `squash` to merge a commit with the previous one.
g) `fixup` to merge a commit with the previous one and discard the log message.

# during a rebase

1. Resolve the conflicted files; `git conflicts` tells them (again)
   To completely override upstream's changes, we have to use _theirs_ (from the branch being rebased, i.e. `git cot`), not _ours_; this is unintuitive!
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
