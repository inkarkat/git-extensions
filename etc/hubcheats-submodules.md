# Feature development
superproject: `$ git com && git ofetchup-hushed`
(directly from another feature: `$ git ofetchonly-hushed`)
## a) start top-down
superproject: Create a branch: `$ git omco -b feat-4711/super-cool`
submodules: `$ c SUBMODULE1 git cosuperbr`
  with querying: `$ git subconewbr --query|SUBMODULE1 SUBMODULE2`
  after uncommitted changes:
   `$ git subuntrackeddo cosuperbr`
   `$ git subdirtydo cosuperbr`
   `$ git substageabledo cosuperbr`
## b) start bottom-up
submodule(s): Create branch: `$ git checkoutbranch -b feat-4711/super-cool`
superproject: Create branch: `$ git checkoutbranch -b $(git substdo --no-header brname | sort -u | singleLineOrSuppressAndError)`
## c) continue from development started on another system:
superproject: `$ git ocosub feat-4711/super-cool`
(or with querying: `$ git oco --queried-submodules feat-4711/super-cool`)
(or separately for superproject and submodules: `$ git oco feat-4711/super-cool && $ git subcoremotebr --query|--all`
## d) Create branches after uncommitted changes:
   `$ git subuntrackeddo -j checkoutbranch -b feat-4711/super-cool`
   `$ git subdirtydo -j checkoutbranch -b feat-4711/super-cool`
   `$ git substageabledo -j checkoutbranch -b feat-4711/super-cool`

## publish submodule changes
a) from superproject or submodule, [commit and] publish superproject as well:
   `$ git osupersubpublish`
b) from superproject: `$ git subsamebrdo --interactive opublish`
c) from submodule(s): `$ git opublish`

## create integration build
superproject: `$ git cu && git opublish`

## update integration build after submodule work
a) short-lived feature without API changes: `$ git amenu && git opush -f`
   or short `$ git amenupush`
   or short together with and in a submodule: `$ git osuperamensubpush [-f]`
b) before API changes in each submodule:
   `$ git superamen` # Amend the last compatible revision.
   `$ git commit ...`
   superproject: `$ git cu && git opush`
c) superproject: maintain history of how the feature grew: `$ git cu && git opush`

## a) peer review of submodules (optional)
When only one / few submodules are affected, changes are not related, and the
integration is trivial.
`$ hub subpull-request`

## b) peer review of superproject (optional)
For similar, mechanical changes in all submodules that don't need to be
reviewed separately.
`$ hub superpull-request`

## c) peer review of superproject and submodules (optional)
Recommended if several submodules are affected and the integration is
non-trivial / covers multiple responsibilities.
`$ hub supersubpull-request`

## integrate submodule changes first
superproject (will integrate all affected submodules) / each submodule:
`$ hub supersubreintegratetom`

## peer review of integration (optional)
`$ gh pr ready`

# Merging
## 0) Reintegrate submodules, then superproject
Without branch protection, first submodules can be reintegrated and pushed.
After that, any superproject references should be updated, and the superproject
reintegrated as well. Each is done (individually) via
`$ hub reintegratetom`

## A) Reintegrate submodules, then branch-protected superproject
Because of the `master` branch protection, we cannot do a local merge and push
master; the GitHub action must have successfully built the resulting merge
commit to accept a push. So we need to do a local rebase / merge of `master`
onto the branch, push that, wait for the action, and then can reintegrate (or
push the corresponding button in GitHub; both of which should be a simple
fast-forward).
a) `$ hub supersubreintegratetom`
b) just the superproject, no submodules involved:
  `$ hub superonlyreintegratetom`

## B) Quasi-transactional only local merges, then remote updates in bulk at the end
This does a fast-forward-integration of both submodules and superproject.
There's virtually no point in time where the superproject references aren't yet
up-to-date. The downside is increased complexity, especially when a merge fails
due to concurrent merges.
a) `$ hub supersubffintegratetom`
b) just the superproject, no submodules involved:
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
superproject: `$ git co BRANCH && git subcobr --query|--all|SUBMODULE1 ...`
or short `$ git cosub BRANCH`

# Removing
a) Just temporarily (e.g. to disable an optional dependency):
   `$ git submodule deinit path/to/submodule`
   It's gone from the working copy, but `init` / `update` will restore it.
b) Permanently:
   `$ git submodule deinit path/to/submodule && git rm path/to/submodule`
   This will remove the `.gitmodules` entry and the directory.
   The `deinit` ensures that the local config doesn't retain submodule
   information.

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
