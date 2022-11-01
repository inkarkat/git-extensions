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

## create integration build
superproject: `$ git cu && git opublish`

## update integration build after submodule work
a) normal updates to short-lived feature: `$ git amenu && git opush -f`
b) maintain history of how the feature grew: `$ git cu && git opush`

## peer review of submodules (optional)
Can be omitted in favor of a superproject PR for similar, mechanical changes in
all submodules that don't need to be reviewed separately.
a) from superproject: `$ hub integrationpr && hub subsamebrdo --no-git-color --interactive pull-request`
b) from submodule(s), no superproject PR: `$ withSeparator -c git\ bml -c git-servername\ -m | cb && hub pull-request`
   paste the server into the description text
c) from submodule(s), with superproject PR: `$ hub superpr && hub pull-request`
   paste the superproject PR reference into the description text

## peer review of superproject (optional)
Recommended if several submodules are affected and the integration is
non-trivial / covers multiple responsibilities.
  `$ withSeparator -c git\ bml -c hub-bmsubchanges -c git-servername\ -m | cb && hub pull-request --draft`
  paste the submodule PR references / changes + server into the description
  text

## integrate submodule changes first
superproject: `$ git ofetch`
Check for other open reintegrations (i.e. submodule commits on master not yet
referenced in the superproject):
superproject: `$ git bmshowsubmodules | git osuperhaspendingsubintegrations -`
superproject: `$ hub subsamebrdo --interactive reintegratetom`
(if you want to do this submodule by submodule: `$ hub reintegratetom`)
Note: When doing a bulk change, default check commands (that would run for each
submodule) can be skipped via `reintegrate* --no-checks`
## then update integration build after submodules have been reintegrated
0) submodule branch(es) have been fast-forwarded: no changes, no action here
a) amends to short-lived feature: `$ git amenu && git opush -f`
b) maintain history of how the feature grew: `$ git cu -m 'feat-4711 has been reintegrated [into submodule(s)]' && git opush`
Note: If other changes have been reintegrated between branching off and now,
these now show up in the diffs as well. This is okay; we're already checked
that there were no open reintegrations that we'd take with us.
## Transactional only local merges, then remote updates in bulk at the end:
### Prepare transaction:
Note: Need to do a reverse integration (i.e. master to branch) because
submodule changes must be pushed so that the superproject can reference them,
but should not be visible on master yet. --no-merge stops short of the actual
reintegration.
`$ git subsamebrdo --interactive ffintegratetom --push-branch --no-merge --no-checks`
a) amends to short-lived feature:
   `$ git amenu`
   `$ git ffintegratetom --push-branch --no-submodule-update --rebase-single`
b) maintain history of how the feature grew:
   `$ git cu`
   `$ git ffintegratetom --push-branch --no-submodule-update --no-ff`
If the GitHub action does not trigger (if this is just a merge commit affecting
submodule references but no actual files in the superproject), trigger it
manually in GitHub.
The superproject now will be on master already, it must **not be pushed to origin**
**until the submodules have been reintegrated**.
### Commit transaction:
Note: There's no real transactional handling across repos; reintegration may
fail at any point. This just limits the critical time period.
`$ git showsubmodules --diff-merges=on | hub subdo --for - --interactive reintegratetom --ff-only --no-checks`
Now wait until the GitHub action has built the superproject's pushed feature
branch successfully, then conclude by pushing master with `$ git opush`

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
0) submodule branch(es) have been fast-forwarded
   `$ hub ffintegratetom`
a) amends to short-lived feature:
   `$ hub ffintegratetom --rebase-single`
b) maintain history of how the feature grew:
   `$ hub ffintegratetom`

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
