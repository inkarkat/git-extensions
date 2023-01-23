# Feature development
superproject: `$ git com && git oup`
(directly from another feature: `$ git ofetch` and then using `git omco -b`
instead of `git mco -b` in the following step)
## a) start top-down
superproject: Create a branch: `$ git mco -b feat-4711/super-cool`
submodules: a) Create branches prior to changes:
	       `$ c ReLogic git omco -b feat-4711/super-cool`
	       `$ git subconewbr --query|SUBMODULE1 SUBMODULE2`
submodules: b) Create branches after uncommitted changes:
	       `$ git subdirtydo omco -b feat-4711/super-cool`
	       `$ git subuntrackeddo omco -b feat-4711/super-cool`
	       `$ git subdo --dirty --untracked omco -b feat-4711/super-cool`
## b) start bottom-up
submodule(s): Create branch: `$ git omco -b feat-4711/super-cool`
superproject: Create branch: `$ git mco -b $(git substdo --interactive brname | sort -u | singleLineOrSuppressAndError)`
## c) continue from elsewhere:
superproject: `$ git ocosub feat-4711/super-cool`
(or with querying: `$ git oco --queried-submodules feat-4711/super-cool`)
(or separately for superproject and submodules: `$ git oco feat-4711/super-cool && $ git subcoremotebr --query|--all`

## publish submodule changes
a) from superproject: `$ git subsamebrdo --interactive opublish`
b) from submodule(s): `$ git opublish`
c) single submodule, [commit and] publish superproject as well:
   `$ git osupersubpublish`

## create integration build
superproject: `$ git cu && git opublish`

## update integration build after submodule work
a) short-lived feature: `$ git amenu && git opush -f`
   or short `$ git amenupush`
   or short together with and in a submodule: `$ git osuperamensubpush [-f]`
b) superproject: maintain history of how the feature grew: `$ git cu && git opush`

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
a) from superproject: `$ hub-prtitle --as-integration-message --qualified-with-userrepo | cb && hub subsamebrdo --no-git-color --interactive pull-request`
   paste the superproject PR reference into the description text
b) from submodule(s): `$ hub superpr && hub pull-request`
   paste the superproject PR reference into the description text
superproject: `$ withSeparator -c git\ boml -c hub-bomsubchanges | cb && gh pr edit`

## integrate submodule changes first
superproject: `$ git ofetch`
Check for other open reintegrations (i.e. submodule commits on master not yet
referenced in the superproject):
superproject: `$ git bomsubmodules | git osuperhaspendingsubintegrations -`
superproject: `$ hub subsamebrdo --interactive reintegratetom`
(if you want to do this submodule by submodule: `$ hub reintegratetom`)
Note: When doing a bulk change, default check commands (that would run for each
submodule) can be skipped via `reintegrate* --no-checks`
## then update integration build after submodules have been reintegrated
0) submodule branch(es) have been fast-forwarded: that creates no commit on
   master, so no action here
a) amends to short-lived feature: `$ git amenu && git opush -f`
   or short `$ git amenupush`
   or short from single submodule: `$ git osuperamenpush`
b) maintain history of how the feature grew: `$ git cu -m 'feat-4711 Housekeeping: Reintegrate [...] submodule(s)' && git opush`
Note: If other changes have been reintegrated between branching off and now,
these now show up in the diffs as well. This is okay; we're already checked
that there were no open reintegrations that we'd take with us.

## peer review of integration (optional)
`$ gh pr ready`

## merge the superproject
Because of the `master` branch protection, we cannot do a local merge and push
master; the GitHub action must have successfully built the resulting merge
commit to accept a push. So we need to do a local rebase / merge of `master`
onto the branch, push that, wait for the action, and then can reintegrate (or
push the corresponding button in GitHub; both of which should be a simple
fast-forward).
`$ git ofetch`
`$ hub superffintegratetom` (or do it manually:)
Check that the amend of the superproject wasn't forgotten and that every
submodule has been reintegrated already.
`$ ! git dirty && git bomsubmodules | acceptStatus 99 git subdo --for - --predicate-command '[ "$(git brname --real-branch-only)" != main ]' --command 'git brname; false'`
a) single commit and then only amends to short-lived feature:
   `$ hub ffintegratetom --push-branch --rebase-single`
b) separate superproject commits and/or maintain history of how the feature
   grew: `$ hub ffintegratetom --push-branch --no-ff`

## Transactional only local merges, then remote updates in bulk at the end:
### Prepare transaction:
Note: Need to do a reverse integration (i.e. master to branch) because
submodule changes must be pushed so that the superproject can reference them,
but should not be visible on master yet. --no-merge stops short of the actual
reintegration.
`$ git subsamebrdo --interactive ffintegratetom --push-branch --no-merge --no-checks`
a) amends to short-lived feature:
   `$ git amenu`
   `$ git ffintegratetom --push-branch --no-delete --no-submodule-checkout --no-submodule-update --rebase-single`
b) maintain history of how the feature grew:
   `$ git cu -m 'feat-4711 Housekeeping: Reintegrate [...] submodule(s)'`   (no-op if all submodule branch(es) have been fast-forwarded)
   `$ git ffintegratetom --push-branch --no-delete --no-submodule-checkout --no-submodule-update --no-ff`
If the GitHub action does not trigger (if this is just a merge commit affecting
submodule references but no actual files in the superproject), trigger it
manually in GitHub.
The superproject now will be on master already, it must **not be pushed to origin**
**until the submodules have been reintegrated**.
### Commit transaction:
Note: There's no real transactional handling across repos; reintegration may
fail at any point. This just limits the critical time period.
`$ hub showsubdo --interactive reintegratetom --ff-only --no-checks`
Now wait until the GitHub action has built the superproject's pushed feature
branch successfully, then conclude by pushing master and cleaning up with
`$ git opush`
`$ git oldeletelb`


# Rules
- When checking out branches, do so everywhere (especially both in the
  superproject and submodule(s)). Mixing branches will lead to dirty working
  copies!
- When adding a new submodule, just editing `.gitmodules` followed by
  `git submodule update` isn't enough; you need to do `git submodule add <repo>`
  to add the reference and do the checkout (and update `.gitmodules` - you can
  edit the file beforehand to have the additional info already in there.)

# Switching between branches
superproject: `$ git co BRANCH && git subcolocalbr --query|--all|SUBMODULE1 ...`
or short `$ git cosub BRANCH`

# Conflicts
Resolution and merges have to be done in the submodule itself, as the
superproject can only reference a single commit! So, if there has been
concurrent development and there are now two diverging references to a
submodule, a commit that contains both changes needs to be found or created in
the submodule itself, and the superproject can then reference that commit.

Don't indiscriminately `git add --update` when there are conflicts!
Submodules show up as `M<u>M</u>` (merged updates, but the original references are still
checked out in the working copy), and an update would add those to the index
and thereby revert the merged changes.
