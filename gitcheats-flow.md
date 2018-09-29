# creating

`git init vim-PluginName`
`git flow init`
Branch name for production releases: stable
Branch name for "next release" development: master

`cp ~/.vim/.gitignore .`
`git adduntracked -m "Initial implementation"`
`hub create -d "Plugin description from doc/*.txt"`
`git opublish`
`hub url`
- Add GitHub repo link to ~/Unixhome/.vim/thesaurus/vimscripts.txt

# releases

`runVimTests tests/[all.suite]`
`git flow release start 1.00`
Inspect changed files list with `git showfiles stable..`
Update changelog; check with `git lg stable..`
vimdev: First GitHub release (of a small plugin): `:DeleteChangelog`
vimdev: First release: Create manifest
`git addu; git commit`

vimdev: Create Vimball: `:CloneHelpAsText` | `:Make 1.00` | `:Zip`
Note: I don't publish the release branch if it just contains trivial mechanics of preparing the release.
`git flow release finish 1.00`
`git opa` (git opush --tags && git opush --all)
