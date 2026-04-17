hub is a command-line wrapper for git that makes you better at GitHub; it
precedes the official gh CLI tool.

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

### Example workflow for contributing to a project
`$ hub clone github/hub`
`$ cd hub`
  Create a topic branch:
`$ git checkout -b feature`
  (Making changes...)
`$ git commit -m "done with feature"`
  It's time to fork the repo:
`$ hub fork`
→ (forking repo on GitHub...)
→ `git remote add YOUR_USER git://github.com/YOUR_USER/hub.git`
`$ gh repo set-default` (select my fork)
`# push the changes to your new remote`
`$ git push YOUR_USER feature`
  Open a pull request for the topic branch you've just pushed:
`$ hub pull-request`
→ (opens a text editor for your pull request message)
