# Feature development
## a) start top-down
superproject: Create a branch: `$ git com -b feat-4711/super-cool`
submodules: a) Create branches prior to changes:
	       `$ git subconewbr --query|SUBMODULE1 SUBMODULE2`
submodules: b) Create branches after uncommitted changes:
	       `$ git (subdirtydo|subuntrackeddo|subdo --dirty --untracked) --no-git-color \`
	       `> co -b feat-4711/super-cool`
## b) start bottom-up
submodule(s): Create branch: `$ git com -b feat-4711/super-cool`
superproject: Create branch: `$ git com -b $(git substdo --no-git-color --interactive brname | sort -u | singleLineOrSuppressAndError)`
## c) continue from elsewhere:
superproject: Check out branch:   `$ git oco feat-4711/super-cool`
superproject: Check out branches: `$ git subcoremotebr --query|--all`

## create integration build
superproject: `$ git cu && git opublish`
optional: `$ hub pull-request --draft`

## update integration build after submodule work
a) normal updates to short-lived feature: `$ git amenu && git opush -f`
b) maintain history of how the feature grew: `$ git cu && git opush`

## peer review of submodules (optional)
a) from superproject: `$ hub integrationpr && hub subsamebrdo --no-git-color --interactive pull-request`
b) from submodule(s), no superproject PR: `$ hub pull-request`
c) from submodule(s), with superproject PR: `$ hub superpr && hub pull-request`
   paste the superproject PR reference into the description text

superproject: [if PR there]: `$ hub bmsubchanges && gh pr edit`
  paste the submodule PR references / changes into the description text

## integrate submodule changes first
`$ git ofetch`
`$ hub subsamebrdo --no-git-color --interactive reintegratetom`
(if you want to do this submodule by submodule: `$ hub reintegratetom`)
## then update integration build after submodules have been reintegrated
0) submodule branch(es) have been fast-forwarded: no changes, no action here
a) amends to short-lived feature: `$ git amenu && git opush -f`
b) maintain history of how the feature grew: `$ git cu -m 'feat-4711 has been reintegrated [into submodule(s)]' && git opush`

## peer review of integration (optional)
`$ gh pr ready`

## merge the superproject
`$ hub reintegratetom`

# Conflicts
Resolution and merges have to be done in the submodule itself, as the
superproject can only reference a single commit! So, if there has been
concurrent development and there are now two diverging references to a
submodule, a commit that contains both changes needs to be found or created in
the submodule itself, and the superproject can then reference that commit.
