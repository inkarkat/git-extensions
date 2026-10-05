# Feature development through serial stacked branches

Create subsequent branches (foo → foo-1 → foo-2 → ...) via `$ git stackbr`

View changes in the current stacked branch via `$ git ps`⏎ (ps=_previous stacked_)

## Pull requests
### a) Separately
1. Create the first branch's pull request normally: `$ hub pull-request`
2. Check out the next branch: `$ git conextbr`
3. Create a (draft) pull request to the previous stacked branch via
   `$ hub pull-requesttops`

### b) All at once: Create pull requests for a series of stacked branches via
`$ hub stackedbrpull-requesttops`

The first branch requests a reintegration [to the default branch / --base BASE]
while following branches open drafts towards the previous branch, so everything
can be reviewed separately and then the branches can be (subsequently rebased
and) merged.

## Before the reintegration of one branch
1. Go through all open pull requests and change the base branch from the
   to-be-integrated branch to master:
   `$ hub pr-rebase`
   (Without that, the PR will be automatically closed after the reintegration
   deletes that branch.)

## After the reintegration of one branch
1. Check out the next branch; e.g. via `$ git cosbr`
2. Rebase: `$ git mrb`
3. Directly force-push the updated branch: `$ git opush -f`
   (or defer and do it after rebasing all outstanding follow-up branches.)

If there are more outstanding follow-up branches:
4. Check out the next branch: `$ git conextbr`
5. Rebase: `$ git ps rb`
6. Directly force-push the updated branch: `$ git opush -f`
   (or defer and do it after rebasing all outstanding follow-up branches.)
7. (Repeat with the next branch.)

8. If you've deferred the force-pushes, do them now: `$ git stackedbropush -f`
