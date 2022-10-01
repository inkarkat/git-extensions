# Feature development
superproject: `$ git com && git oup`
(directly from another feature:) `$ git ofetch && git omco -b feat-4711/super-cool`
## a) start top-down
superproject: Create a branch: `$ git mco -b feat-4711/super-cool`
submodules: a) Create branches prior to changes:
	       `$ git subconewbr --query|SUBMODULE1 SUBMODULE2`
submodules: b) Create branches after uncommitted changes:
	       `$ git subdirtydo omco -b feat-4711/super-cool`
	       `$ git subuntrackeddo omco -b feat-4711/super-cool`
	       `$ git subdo --dirty --untracked omco -b feat-4711/super-cool`
## b) start bottom-up
submodule(s): Create branch: `$ git omco -b feat-4711/super-cool`
superproject: Create branch: `$ git mco -b $(git substdo --interactive brname | sort -u | singleLineOrSuppressAndError)`
## c) continue from elsewhere:
superproject: Check out branch:   `$ git oco feat-4711/super-cool`
superproject: Check out submodule branches: `$ git subcoremotebr --query|--all`

## create integration build
superproject: `$ git cu && git opublish`
optional: `$ git bml | cb && hub pull-request --draft`

## update integration build after submodule work
a) normal updates to short-lived feature: `$ git amenu && git opush -f`
b) maintain history of how the feature grew: `$ git cu && git opush`

## peer review of submodules (optional)
a) from superproject: `$ hub integrationpr && hub subsamebrdo --no-git-color --interactive pull-request`
b) from submodule(s), no superproject PR: `$ withSeparator -c git\ bml -c git-servername\ -m | cb && hub pull-request`
   paste the server into the description text
c) from submodule(s), with superproject PR: `$ hub superpr && hub pull-request`
   paste the superproject PR reference into the description text

superproject: [if PR there]:
  `$ withSeparator -c git\ bml -c hub\ bmsubchanges -c git-servername\ -m | cb && gh pr edit`
  paste the submodule PR references / changes + server into the description
  text
## peer review of superproject (optional)
For similar, mechanical changes in all submodules that don't need to be
reviewed separately.
  `$ withSeparator -c git\ bml -c hub\ bmsubchanges -c git-servername\ -m | cb && hub pull-request`
  paste the submodule PR references / changes + server into the description
  text

## integrate submodule changes first
superproject: `$ git ofetch`
Check for other open reintegrations (i.e. submodule commits on main not yet
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
`$ git subsamebrdo --interactive reintegratetom --no-checks --no-delete`
`$ git amenu` (or `$ git cu`)
`$ git reintegratetom --no-delete`
### Commit transaction:
`$ git showsubmodules | hub subdo --for - --interactive reintegratetom --continue`
`$ hub reintegratetom --continue`
Note: There's no real transactional handling across repos; reintegration may
fail at any point. This just limits the critical time period.

## peer review of integration (optional)
`$ gh pr ready`

## merge the superproject
`$ hub reintegratetom`

# Rules
- When checking out branches, do so everywhere (especially both in the
  superproject and submodule(s)). Mixing branches will lead to dirty working
  copies!
- When adding a new submodule, just editing `.gitmodules` followed by
  `git submodule update` isn't enough; you need to do `git submodule add <repo>`
  to add the reference and do the checkout (and update `.gitmodules` - you can
  edit the file beforehand to have the additional info already in there.)

# Switching between branches
superproject: `$ git co BRANCH && git subcolocalbr --query|SUBMODULE1 SUBMODULE2`

# Conflicts
Resolution and merges have to be done in the submodule itself, as the
superproject can only reference a single commit! So, if there has been
concurrent development and there are now two diverging references to a
submodule, a commit that contains both changes needs to be found or created in
the submodule itself, and the superproject can then reference that commit.
