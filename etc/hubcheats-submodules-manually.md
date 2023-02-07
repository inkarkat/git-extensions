## integrate submodule changes first
superproject: `$ git ofetchup-hushed`
Check for other open reintegrations (i.e. submodule commits on master not yet
referenced in the superproject):
superproject: `$ git bomsubmodules | negateThis git osuperhaspendingsubintegrations -`
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
   `$ hub ffintegratetom --push-submodules --delete-merged-submodule-branches --push-branch --rebase-single`
b) separate superproject commits and/or maintain history of how the feature
   grew: `$ hub ffintegratetom --push-submodules --delete-merged-submodule-branches --push-branch --no-ff`
