# data transport commands overview
----- add ----> -- commit ----> -- publish ------>
----- addu ---> -- commit ----> -- push --------->
### [WORK.COPY]  [INDEX]    [LOCAL REPOSITORY]  [REMOTE REPO]
<------------ pull or rebase ----------------------------/
.                  XX                ^-- fetch ----------/
<--------- checkout-committed -------------/
<-- checkout -- . /------------------------/
.                            ^- uncommit --/
.                  <---------^- peel ------/
<------------------^---------^- wipecommit-/
.                  <-- unstage ------------/
<------------------^-- wipe ---------------/
.
<--------- dh -----------------------------/
.                  <--- di ----------------/
<---- d -----------/

-- rm --^---------->
<- undelete (checkout -- .)----------------/

`rev-parse`: Parsing of git revision syntaxes.

# Commit addressing
- parents: `head^^^` = `head~3`; second merge parent: `^2`; combined:
    $ git checkout 1b6d^^2~10 -b ancient
  starts a new branch "ancient" representing the state 10 commits back
  from the second parent of the first parent of the commit starting with
  1b6d.
- youngest commit message that matches: `:/<pattern>`
  (not anchored, use `^` for that)
- date: `@{yesterday}` "branch@{two days ago}"
- from reflog (where the tip of the branch used to be 2 moves ago): branch@{2}
  e.g. previous commit: `@{1}`
- previous checked out branch : `@{-1}`
- upstream branch: `@{u}` (added in git v1.7.0)

# Commit ranges
- `r1..r2` = `^r1 r2` means commits reachable from r2 but exclude the ones
  reachable from r1
  For diff, `r1..r2` is synonymous to `r1 r2`; i.e. changes between the two commits
  are shown (symmetric).
- `r1...r2` = `r1 r2 --not $(git merge-base --all r1 r2)`
  It is the set of commits that are reachable from either
  one of r1 or r2 but not from both (i.e. symmetric difference).
  Attention! For diff, `r1...r2` views the changes on the branch containing and
  up to the `r2`, starting at a common ancestor of both `r1` and `r2` (asymmetric).
