# convert writebackup plugin to GitHub - import

Copy / sync all plugin files from ~/data/Unixhome/.vim to ~/tmp/vim
- **Don't forget to move the tests/ directory** from ~/.vim/tests/PLUGIN-NAME to ~/tmp/vim/tests
- Remove test artifacts:
`$ rm ~/tmp/vim/tests/*.{out,msgout,msgresult,tap}`
`$ hasdir ~/tmp/vim/tests/ && rm ~/tmp/vim/tests/*/*.{out,msgout,msgresult,tap}`
- Do a directory compare to **ensure that old deleted files are not reintroduced**

`$ cd ~/Unixhome/.vim/pack/ingo/start/`
`$ git init vim-PluginName`
`$ withGVIM git-writebackup-ingo-import --yes ~/tmp/vim`
- Backup and remove plugin files from ~/Unixhome/.vim/
`$ runVimTests tests/[all.suite]` to verify that the tests haven't been broken by the conversion
- Remove tests invocation from ~/Unixhome/.vim/tests/noninteractive.suite
- Add tests invocation to ~/Unixhome/.vim/pack/ingo/start/noninteractive.suite
`$ hub create -d "Plugin description from doc/*.txt"`
`$ git opublish`
`$ hub url`
- Add GitHub repo link to ~/Unixhome/.vim/thesaurus/vimscripts.txt
`$ hub labels set`
`$ gh repo edit --enable-discussions`

# convert plugin from writebackups to GitHub - git flow

`$ git flow init --push`

# convert plugin from writebackups to GitHub - readme

`$ vim doc/*.txt`
Add github snippets after INSTALLATION and after IDEAS.

`:CloneHelpAsReadme`
`:MarkdownPreview`

`$ cp -r ~/.vim/{.gitignore,.github} .`
`$ git adduu && git c -m "Add Readme and gitignore"`
`$ git opush`

(Continue at `git cheat flow`)
