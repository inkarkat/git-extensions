## a) peer review of submodules (optional)
When only one / few submodules are affected, changes are not related, and the
integration is trivial.
a) from superproject: `$ withSeparator -c git\ boml -c hub-additionalInfoForPullRequest | cb && hub subsamebrdo --no-git-color --interactive pull-request`
   paste the server into the description text
b) from submodule(s): `$ withSeparator -c git\ superdo\ --no-header\ boml -c git\ boml -c hub-additionalInfoForPullRequest | cb && hub pull-request`
   paste the server into the description text

## b) peer review of superproject (optional)
For similar, mechanical changes in all submodules that don't need to be
reviewed separately.
  `$ withSeparator -c git\ boml -c hub-bomsubchanges -c hub-additionalInfoForPullRequest | cb && hub pull-request --draft`
  paste the submodule PR references / changes + server into the description
  text

## c) peer review of superproject and submodules (optional)
Recommended if several submodules are affected and the integration is
non-trivial / covers multiple responsibilities.
superproject: `hub-additionalInfoForPullRequest | cb && hub pull-request --draft`
a) from superproject: `$ hub integrationpr && hub subsamebrdo --no-git-color --interactive pull-request`
   paste the superproject PR reference into the description text
b) from submodule(s): `$ hub superpr && hub pull-request`
   paste the superproject PR reference into the description text
superproject: `$ withSeparator -c git\ boml -c hub-bomsubchanges | cb && gh pr edit`

# Merging
## A) Reintegrate submodules, then superproject
This first reintegrates the submodules, pushes their master branches, then does
any updates of the superproject. This means that there is a timespan where the
submodule commits are already publicly visible but not yet referenced by the
superproject. Others must refrain from doing another reintegration during that
time.
### integrate submodule changes first
superproject: `$ git ofetchonly-hushed`
Check for other open reintegrations (i.e. submodule commits on master not yet
referenced in the superproject):
superproject: `$ git bom submodules | negateThis git osuperhaspendingsubintegrations -`
Check for pull request comments and approvals:
superproject: `$ hub subsamebrdo --single-success --include-superproject prcomments`
superproject: `$ hub subsamebrdo --single-success --include-superproject prapproval`
Do the integration:
superproject: `$ hub subsamebrdo --interactive reintegratetom --no-push --no-delete --no-checks`
(if you want to do this submodule by submodule: `$ hub reintegratetom --no-push --no-delete --no-checks`)
Note: When doing a bulk change, default check commands (that would run for each
submodule) can be skipped via `reintegrate* --no-checks`
Then update integration build after submodules have been reintegrated
0) submodule branch(es) have been fast-forwarded: that creates no commit on
   master, so no action here
a) amends to short-lived feature: `$ git amenu`
b) maintain history of how the feature grew: `$ git cu -m 'feat-4711 Housekeeping: Reintegrate [...] submodule(s)'`
Note: If other changes have been reintegrated between branching off and now,
these now show up in the diffs as well. This is okay; we're already checked
that there were no open reintegrations that we'd take with us.

### merge the superproject
superproject: `$ git ofetchup-hushed`
Check that the amend of the superproject wasn't forgotten and that every
submodule has been reintegrated already.
`$ ! git dirty && git bom submodules | ifne acceptStatus 99 git subdo --for - --predicate-command '[ "$(git brname --real-branch-only)" != main ]' --command 'git brname; false'`
a) single commit and then only amends to short-lived feature:
   `$ GIT_REINTEGRATE_PRE_PUSH_COMMAND='hub-workflow-status -r HEAD -W' hub ffintegratetom --push-submodules --delete-merged-submodule-branches --push-branch --rebase-single`
b) separate superproject commits and/or maintain history of how the feature
   grew: `$ GIT_REINTEGRATE_PRE_PUSH_COMMAND='hub-workflow-status -r HEAD -W' hub ffintegratetom --push-submodules --delete-merged-submodule-branches --push-branch --no-ff`
c) just the superproject, no submodules involved:
  `$ GIT_REINTEGRATE_PRE_PUSH_COMMAND='hub-workflow-status -r HEAD -W' hub ffintegratetom --push-branch --no-ff`

## B) Quasi-transactional only local merges, then remote updates in bulk at the end
This does a fast-forward-integration of both submodules and superproject.
There's only a short timespan during pushes when the superproject references
aren't yet up-to-date. The downside is increased complexity, especially when a
merge fails due to concurrent merges.
### Prepare transaction:
Note: Need to do a reverse integration (i.e. master to branch) because
submodule changes must be pushed so that the superproject can reference them,
but should not be visible on master yet.
First ffintegrate the submodules; --no-merge stops short of the actual
reintegration; submodules are still on their feature branch:
`$ git subsamebrdo --interactive ffintegratetom --push-branch --no-merge --no-checks`
Then ffintegrate the superproject; here, the merge will happen (locally):
0) submodule branch(es) have been fast-forwarded: that creates no commit on
   master, so no action here
   `$ git ffintegratetom --no-push --push-branch --no-delete --no-submodule-checkout --no-submodule-update --rebase-single`
   This will be the case if you've just recently started the feature and it was
   an automated process (like updating metadata files everywhere).
a) amends to short-lived feature without API changes:
   `$ git amenu`
   `$ git ffintegratetom --no-push --push-branch --no-delete --no-submodule-checkout --no-submodule-update --rebase-single`
b) across-submodule API changes / maintain history of how the feature grew:
   `$ git cu -m 'feat-4711 Housekeeping: Reintegrate [...] submodule(s)'`   (no-op if all submodule branch(es) have been fast-forwarded)
   `$ git ffintegratetom --no-push --push-branch --no-delete --no-submodule-checkout --no-submodule-update --no-ff`
If the **GitHub action** does not **trigger** (if this is just a merge commit affecting
submodule references but no actual files in the superproject), trigger it
manually in GitHub.
The superproject now will be on master already, it must **not be pushed to origin**
**until the submodules have been reintegrated**.
`$ hub showsubdo --interactive reintegratetom --ff-only --no-push --no-delete --no-checks`
The submodules are now on master, too. Everything just needs to be pushed.
### Commit transaction:
Now **wait until the GitHub action** has built the superproject's pushed feature
branch successfully, then conclude by pushing all master branches and cleaning
up branches.
Note: There's no real transactional handling across repos; reintegration may
fail at any point. This just limits the critical time period.
`$ hub showsubdo --interactive opush && git opush`
If any of the pushes fail, you still have the local branches; wipe the master
branches, check out the feature branch, fetch, and repeat.
`$ hub showsubdo --include-superproject --interactive oldeletelb`
