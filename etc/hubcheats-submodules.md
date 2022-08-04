# Feature development
## a) start top-down
superproject: Create a branch: `git com -b feat-4711/super-cool`
submodules: a) Create branches prior to changes:
	       `git subconewbr --query|SUBMODULE1 SUBMODULE2`
submodules: b) Create branches after uncommitted changes:
	       `git subdirtydo|subuntrackeddo|subdo --dirty --untracked com -b feat-4711/super-cool`
## b) start bottom-up
submodule(s): Create branch: `git com -b feat-4711/super-cool`
superproject: Create branch: `git com -b feat-4711/super-cool`
## c) continue from elsewhere:
superproject: Check out branch:   `git oco feat-4711/super-cool`
superproject: Check out branches: `git subcoremotebr --query|--all`

## create integration build
superproject: `git cu && git opublish`
`hub bmsubchanges && hub pull-request --draft`, paste the submodule changes into the description text

## update integration build after submodule work
a) normal updates to short-lived feature: `git amenu && git opush -f`
b) maintain history of how the feature grew: `git cu && git opush`

## integrate submodule changes first
(optional: `hub superpr && git subsamebrdo pull-request`, paste the superproject PR reference into the description text)
`git ofetch; git subsamebrdo reintegratetom` (`hub reintegratetom` if you want to do this submodule by submodule)
## merge the superproject
`hub reintegratetom`
