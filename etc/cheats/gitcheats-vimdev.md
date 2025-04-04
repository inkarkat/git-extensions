# Vim plugin creation

1. `$ git init vim-PluginName`
2. `$ git flow init`
   Branch name for production releases: stable
   Branch name for "next release" development: master
3. Boilerplate
   `$ cp -r ~/.vim/{.gitignore,.github} .`
   `$ rm tests/*.{out,msgout,msgresult,tap}`
   `$ git adduntracked; git commit -m "Initial implementation"`
4. GitHub
   `$ hub create` (automatically added: `-d "Plugin description from doc/*.txt"`)
   .            (automatically done: `$ git opublish`)
   .            (automatically done: `$ hub labels set`)
   .            (automatically done: `$ gh repo edit --enable-discussions`)
   `$ hub url`
   - Add GitHub repo link to ~/Unixhome/.vim/thesaurus/vimscripts.txt

# Vim plugin releases

1. Checks
   `$ runVimTests tests/[all.suite]`
2. `$ git release start 1.00` (see `$ git cheat release` for detailed inspections)
3. Update changelog (at least with release date) in `doc/*.txt`
   - `:UpdateHelpAsReadme`
4. `$ git release commit` (`$ git cu -m 'Release 1.00'`)
5. First GitHub release (of a small plugin):
   - Execute `:DeleteChangelog`
   - `$ git cu -m 'Cosmetics: Delete changelogs'`
   - Create manifest
6. Create Vimball:
   `$ vim-pluginbuild` (`:EditManifest | :Make 1.00 | :Zip`)
7. Update vim.org description (if necessary):
   `:EditDoc | CloneHelpAsText`
8. `$ git release finish` -> tag name: "Version 1.00"
9. `$ git opa` (`$ git opush --tags && git opush --all`)
