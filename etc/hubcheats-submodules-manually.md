## a) peer review of submodules (optional)
When only one / few submodules are affected, changes are not related, and the
integration is trivial.
a) from superproject: `$ withSeparator -c git\ boml -c git-servername\ -m | cb && hub subsamebrdo --no-git-color --interactive pull-request`
   paste the server into the description text
b) from submodule(s): `$ withSeparator -c git\ superdo\ --no-header\ boml -c git\ boml -c git-servername\ -m | cb && hub pull-request`
   paste the server into the description text

## b) peer review of superproject (optional)
For similar, mechanical changes in all submodules that don't need to be
reviewed separately.
  `$ withSeparator -c git\ boml -c hub-bomsubchanges -c git-servername\ -m | cb && hub pull-request --draft`
  paste the submodule PR references / changes + server into the description
  text

## c) peer review of superproject and submodules (optional)
Recommended if several submodules are affected and the integration is
non-trivial / covers multiple responsibilities.
superproject: `git-servername -m | cb && hub pull-request --draft`
a) from superproject: `$ hub integrationpr && hub subsamebrdo --no-git-color --interactive pull-request`
   paste the superproject PR reference into the description text
b) from submodule(s): `$ hub superpr && hub pull-request`
   paste the superproject PR reference into the description text
superproject: `$ withSeparator -c git\ boml -c hub-bomsubchanges | cb && gh pr edit`

## integrate submodule changes first
superproject: `$ git ofetchonly-hushed`
Check for other open reintegrations (i.e. submodule commits on master not yet
referenced in the superproject):
superproject: `$ git bomsubmodules | negateThis git osuperhaspendingsubintegrations -`
Check for pull request comments and approvals:
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

## merge the superproject
superproject: `$ git ofetchup-hushed`
Check that the amend of the superproject wasn't forgotten and that every
submodule has been reintegrated already.
`$ ! git dirty && git bomsubmodules | ifne acceptStatus 99 git subdo --for - --predicate-command '[ "$(git brname --real-branch-only)" != main ]' --command 'git brname; false'`
a) single commit and then only amends to short-lived feature:
   `$ GIT_REINTEGRATE_PRE_PUSH_COMMAND='hub-workflow-status -r HEAD -W' hub ffintegratetom --push-submodules --delete-merged-submodule-branches --push-branch --rebase-single`
b) separate superproject commits and/or maintain history of how the feature
   grew: `$ GIT_REINTEGRATE_PRE_PUSH_COMMAND='hub-workflow-status -r HEAD -W' hub ffintegratetom --push-submodules --delete-merged-submodule-branches --push-branch --no-ff`
c) just the superproject, no submodules involved:
  `$ GIT_REINTEGRATE_PRE_PUSH_COMMAND='hub-workflow-status -r HEAD -W' hub ffintegratetom --push-branch --no-ff`
