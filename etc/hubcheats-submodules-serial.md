# Feature development through serial branches

Create subsequent branches (foo → foo-1 → foo-2 → ...) via `$ git supersubdo clonebr`

After the reintegration of one branch:
1. superproject: Check out the next branch; e.g. via `$ git cossbr`
2. submodule(s): Rebase: `$ git mrb`
3. superproject: Incorporate rebased submodule(s):
   a) amends to short-lived feature: `$ git amenu`
   b) maintain history of how the feature grew: `$ git cu -m 'feat-4711 Housekeeping: Rebase [...] submodule(s)'`
4. superproject: Rebase: `$ git mrb`
5. Force-push updated branches: `$ git osupersubpush -f`

If there are more outstanding follow-up branches:
6. superproject: Check out the next branch: `$ git cosubnextbr`
7. submodule(s): Rebase: `$ git pcrb`
8. superproject: Incorporate rebased submodule(s):
   a) amends to short-lived feature: `$ git amenu`
   b) maintain history of how the feature grew: `$ git cu -m 'feat-4711 Housekeeping: Rebase [...] submodule(s)'`
9. superproject: Rebase: `$ git pcrb`
10. Force-push updated branches: `$ git osupersubpush -f`
11. (Repeat with the next branch.)
