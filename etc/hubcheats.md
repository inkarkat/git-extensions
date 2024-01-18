hub is a command-line wrapper for git that makes you better at GitHub.


### clone your own project
`$ hub clone dotfiles`
→ `git clone git://github.com/YOUR_USER/dotfiles.git`

### clone another project
`$ hub clone github/hub`
→ `git clone git://github.com/github/hub.git`

### open the current project's issues page
`$ hub browse -- issues`
→ open https://github.com/github/hub/issues

### open another project's wiki
`$ hub browse mojombo/jekyll wiki`
→ open https://github.com/mojombo/jekyll/wiki

### Example workflow for contributing to a project:
`$ hub clone github/hub`
`$ cd hub`
### create a topic branch
`$ git checkout -b feature`
  ( making changes ... )
`$ git commit -m "done with feature"`

### It's time to fork the repo!
`$ hub fork`
→ (forking repo on GitHub...)
→ `git remote add YOUR_USER git://github.com/YOUR_USER/hub.git`
`$ gh repo set-default` (select my fork)

### push the changes to your new remote
`$ git push YOUR_USER feature`
### open a pull request for the topic branch you've just pushed
`$ hub pull-request`
→ (opens a text editor for your pull request message)


# As an open-source maintainer

### fetch from multiple trusted forks, even if they don't yet exist as remotes
`$ hub fetch mislav,cehoffman`
→ `git remote add mislav git://github.com/mislav/hub.git`
→ `git remote add cehoffman git://github.com/cehoffman/hub.git`
→ `git fetch --multiple mislav cehoffman`

### check out a pull request for review
`$ hub pr checkout 134`
  or
`$ hub checkout https://github.com/github/hub/pull/134`
(creates a new local branch _username-branchname_) with the contents of the pull request)
→ `git fetch origin pull/134/head:BRANCHNAME`
→ `git checkout BRANCHNAME`

### directly apply all commits from a pull request to the current branch
`$ hub am -3 https://github.com/github/hub/pull/134`

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


### Forking an abandoned project
- Recommended to rename the upstream remote to derelict, so that hub won't list
  upstream issues / PRs any longer.
  `$ git remote rename upstream derelict`
  (My git-uadd detects and offers this automatically.)

# Using GitHub for work

### whitelist your GitHub Enterprise hostname
`$ git config --global --add hub.host my.example.org`

### open a pull request using a message generated from script, then put its URL to the clipboard
`$ git push origin feature`
`$ hub pull-request -F prepared-message.md | cb`
→ (URL ready for pasting in a chat room)

### push to multiple remotes
`$ git push production,staging`
