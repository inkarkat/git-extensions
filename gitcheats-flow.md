# creating

`git init vim-PluginName`
`git flow init`
Branch name for production releases: stable
Branch name for "next release" development: master

`cp ~/.vim/.gitignore .`
`rm tests/*.{out,msgout,msgresult,tap}`
`git adduntracked; git commit -m "Initial implementation"`
`hub create -d "Plugin description from doc/*.txt"`
`git opublish`
`hub url`
- Add GitHub repo link to ~/Unixhome/.vim/thesaurus/vimscripts.txt

# releases

vimdev: `runVimTests tests/[all.suite]`
`git flow release start 1.00`
Inspect changed files list with `git showfiles stable..`
Check changelog with `git lg stable..`
vimdev: Update changelog (at least with release date) in `doc/*.txt` and do `:UpdateHelpAsReadme`
`git cu -m 'Release 1.00'`
vimdev: First GitHub release (of a small plugin):
vimdev: Execute `:DeleteChangelog`
`git cu -m 'Cosmetics: Delete changelogs'`
vimdev: First release: Create manifest

vimdev: Create Vimball: `:CloneHelpAsText` | `:Make 1.00` | `:Zip`
Note: I don't publish the release branch if it just contains trivial mechanics of preparing the release.
`git flow release finish 1.00` -> tag name: "Version 1.00"
`git opa` (git opush --tags && git opush --all)
