# Feature development through serial stacked branches

Create subsequent branches (foo → foo-1 → foo-2 → ...) via `$ git supersubdo stackbr`

Create pull requests for a series of stacked branches via
`$ hub stackedbrpull-requesttops` (or `stackedbr[super][sub]pull-requesttops`)
The first branch requests a reintegration [to the default branch / --base BASE]
while following branches open drafts towards the previous branch, so everything
can be reviewed separately and then the branches can be (subsequently rebased
and) merged.

After the reintegration of one branch:
1. superproject: Check out the next branch; e.g. via `$ git cossbr`
2. Rebase
   a) from superproject: `$ git subsamebrdo -i mrb`
   b) from submodule(s): `$ git mrb`
3. superproject: Incorporate rebased submodule(s):
   a) amends to short-lived feature: `$ git amenu`
   .  Rebase: `$ git mrb`
   .  (If previous serial branches had maintained history, but the current one
   .  does not, do an interactive rebase and drop the housekeeping commits.
   .  Alternatively, keep the history and skip rebasing completely.)
   b) maintain history of how the feature grew: `$ git cu -m 'feat-4711 Housekeeping: Rebase [...] submodule(s)'`
4. Force-push updated branches: `$ git osupersubpush -f`

If there are more outstanding follow-up branches:
6. superproject: Check out the next branch: `$ git cosubnextbr`
7. Rebase
   a) from superproject: `$ git subsamebrdo -i psrb`
   b) from submodule(s): `$ git psrb`
8. superproject: Incorporate rebased submodule(s):
   a) amends to short-lived feature: `$ git amenu`
   .  Rebase, dropping all earlier commits (we get these in rebased form from
   .    the previous branch); just keep the last (feature branch) commit:
   .    `$ git rev-range-to-previous-stack --no-range -2 rebasepicklast RANGE`
   .    Accept the current, conflicted submodule(s):
   .    `$ git addconflicts && git rbnc`
   b) maintain history of how the feature grew: `$ git cu -m 'feat-4711 Housekeeping: Rebase [...] submodule(s)'`
   .  (If this rebasing was already done once, just amend to that housekeeping
   .  commit; no need for a separate commit.)
   .  (No rebase here because it'd result in conflicts for the intermediate
   .  commits. The separate commit records the rebasing of the submodules, and
   .  everything before is a testament to the original development history.)
9. Force-push updated branches: `$ git osupersubpush -f`
10. (Repeat with the next branch.)
