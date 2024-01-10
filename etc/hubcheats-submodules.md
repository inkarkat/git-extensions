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

## merge the superproject
Because of the `master` branch protection, we cannot do a local merge and push
master; the GitHub action must have successfully built the resulting merge
commit to accept a push. So we need to do a local rebase / merge of `master`
onto the branch, push that, wait for the action, and then can reintegrate (or
push the corresponding button in GitHub; both of which should be a simple
fast-forward).
a) `$ hub supersubreintegratetom`
b) just the superproject, no submodules involved:
  `$ hub superonlyreintegratetom`

## Transactional only local merges, then remote updates in bulk at the end:
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
