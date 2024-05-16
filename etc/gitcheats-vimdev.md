# creating

`$ git init vim-PluginName`
`$ git flow init`
Branch name for production releases: stable
Branch name for "next release" development: master

`$ cp -r ~/.vim/{.gitignore,.github} .`
`$ rm tests/*.{out,msgout,msgresult,tap}`
`$ git adduntracked; git commit -m "Initial implementation"`
`$ hub create -d "Plugin description from doc/*.txt"`
`$ git opublish`
`$ hub url`
- Add GitHub repo link to ~/Unixhome/.vim/thesaurus/vimscripts.txt
`$ hub labels set`
`$ gh repo edit --enable-discussions`

# releases

vimdev: `$ runVimTests tests/[all.suite]`
`$ git release start 1.00`
Inspect changed files list with `$ git stablefiles`
Check changelog with `$ git stablelg`
Inspect changes to prior release with `$ git stabled`
vimdev: Update changelog (at least with release date) in `doc/*.txt` and do `:UpdateHelpAsReadme`
`$ git release commit` (`$ git cu -m 'Release 1.00'`)
vimdev: First GitHub release (of a small plugin):
vimdev: Execute `:DeleteChangelog`
`$ git cu -m 'Cosmetics: Delete changelogs'`
vimdev: First release: Create manifest

vimdev: Create Vimball: `$ vim-pluginbuild` (`:EditManifest | :Make 1.00 | :Zip`)
vimdev: Update vim.org description (if necessary): `:EditDoc | CloneHelpAsText`
Note: I don't publish the release branch if it just contains trivial mechanics of preparing the release.
`$ git release finish` -> tag name: "Version 1.00"
`$ git opa` (`$ git opush --tags && git opush --all`)
