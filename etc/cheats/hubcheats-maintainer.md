# As an open-source maintainer

### check out a pull request for review
`$ hub pr checkout 134`
(creates a new local branch _username-branchname_) with the contents of the pull request)
→ `git fetch origin pull/134/head:BRANCHNAME`
→ `git checkout BRANCHNAME`

### check out a pull request for local amending / merging
`$ hub pr checkout 134`
(creates a new local branch _username-branchname_) with the contents of the pull request)
`$ git amend ...`
`$ git push`
- Reintegrate in GitHub or locally

### directly apply all commits from a pull request to the current branch
`$ hub am -3 [https://github.com/github/hub/pull/]134`

### directly merge a pull request in GitHub
`$ gh pr merge|rebase|squash 134`
`$ git opull`

### cherry-pick a GitHub URL
`$ hub cherry-pick https://github.com/xoebus/hub/commit/177eeb8`
→ `git remote add xoebus git://github.com/xoebus/hub.git`
→ `git fetch xoebus`
→ `git cherry-pick 177eeb8`

### `am` can be better than cherry-pick since it doesn't create a remote
`$ hub am https://github.com/xoebus/hub/commit/177eeb8`

### open the GitHub compare view between two releases
`$ hub compare v0.9..v1.0`

### put compare URL for a topic branch to clipboard
`$ hub compare -u feature | cb`

### fetch from multiple trusted forks, even if they don't yet exist as remotes
`$ hub fetch mislav,cehoffman`
→ `git remote add mislav git://github.com/mislav/hub.git`
→ `git remote add cehoffman git://github.com/cehoffman/hub.git`
→ `git fetch --multiple mislav cehoffman`


### Forking an abandoned project
- Recommended to rename the upstream remote to derelict, so that hub won't list
  upstream issues / PRs any longer.
  `$ git remote rename upstream derelict`
  (My git-uadd detects and offers this automatically.)
