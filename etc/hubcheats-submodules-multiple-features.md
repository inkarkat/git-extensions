# Reintegrate multiple feature branches at once
## Setup
You have `feat-A`, `feat-B`, and then `feat-C` that depends on the two previous
ones. Each has in the superproject been independently branched off of master;
in the submodule(s), `feat-C` begins with a merge of `feat-A` into `feat-B`.
superproject: `/--- feat-A       `submodule(s): `/--- feat-A -\           `
    master ------- feat-B            master ------ feat-B --*- feat-C  
              \--- feat-C                                              
These cannot be integrated separately; you want a single integration that in
the submodules contains each feature merged sequentially, and the superproject
has three commits pointing to each reintegrated feature in the submodule(s).
superproject: `  feat-A --> feat-B --> feat-C --> master  `
submodule(s): `-----------------*---*----------------*--> master  `
               \--- feat-A ---/   / \--- feat-C ---/             
                \--- feat-B -----/                               
## Process
1. Check out `feat-A`
   reintegrate submodule(s) `$ hub supersubreintegratetom`
2. superproject: `$ git mrb`
   run checks manually
3. Check out `feat-B`,
   reintegrate submodule(s) `$ hub supersubreintegratetom`;
   accept that the master branch is ahead of origin
4. superproject: `$ git rb feat-A`
   run checks manually
5. Check out `feat-C`
   submodule(s): rebase `$ git mrb` (this gets rid of the previous merge commit of
   `feat-A` to `feat-B`; however, you need to re-apply manual merge adaptations!)
   then reintegrate submodule(s) `$ hub supersubreintegratetom`
   accept that the master branch is ahead of origin (again)
6. superproject: `$ git rb feat-B`
7. superproject: Check out a separate integration branch (to be able to easily
   undo everything and start over): `$ git co -b feat-ABC/ibranch`
8. Reintegrate the integration branch; after the checks, the submodule's master
   branches will be pushed: `$ hub supersubreintegratetom`
9. Delete all feature branches

Undo/start over: Check out each feature branch and `$ git owipe -f` first
all submodule(s), then superproject
