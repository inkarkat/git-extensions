# Feature development through serial stacked branches

Create subsequent branches (foo → foo-1 → foo-2 → ...) via `$ git stackbr`

View changes in the current stacked branch via `$ git ps`⏎ (ps=_previous stacked_)

## x) Pull requests (same repo)
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

## y) Pull requests from origin to upstream
- The first PR can be opened normally against the upstream repo.
For subsequent stacked branches, those would have to be pushed to upstream to
be available for a PR there, requiring write access, which typically isn't
available, and messy (per-user namespacing required, unexpected if the project
normally adheres to the classic forking model).
- Open subsequent stacked branches' PRs against your own (origin) repo, and
  reference them in the current upstream PR, inviting discussion and review
  over there.
- After the current upstream PR is merged, the next PR (in origin) can be moved
  to upstream:
`$ hub pr-move --make-ready --edit`

# Reintegrating serial stacked branches

## Before the reintegration of one branch
1. Go through all open pull requests and change the base branch from the
   to-be-integrated branch to master:
   `$ hub pr-rebase`
   (Without that, the PR will be automatically closed after the reintegration
   deletes that branch.)

## After the reintegration of one branch
1. Check out the next branch; e.g. via `$ git cosbr`
2. Rebase: `$ git ps mrb`
3. Directly force-push the updated branch: `$ git opush -f`
   (or defer and do it after rebasing all outstanding follow-up branches.)

If there are more outstanding follow-up branches:
4. Check out the next branch: `$ git conextbr`
5. Rebase: `$ git ps rb`
6. Directly force-push the updated branch: `$ git opush -f`
   (or defer and do it after rebasing all outstanding follow-up branches.)
7. (Repeat with the next branch.)

8. If you've deferred the force-pushes, do them now: `$ git stackedbropush -f`
