# convert writebackup plugin to GitHub - import

Copy / sync all plugin files from ~/data/data/Unixhome/.vim to ~/tmp/vim
`git init vim-PluginName`
`git-writebackup-ingo-import ~/tmp/vim`
`git create -d "Plugin description from doc/*.txt"`
`git opublish`

# convert writebackup plugin to GitHub - git flow

`git branch stable`
`git flow init`

Which branch should be used for bringing forth production releases?
   - master
   - stable
Branch name for production releases: [master] stable

Which branch should be used for integration of the "next release"?
   - master
Branch name for "next release" development: [master]

How to name your supporting branch prefixes?
Feature branches? [feature/]
Bugfix branches? [bugfix/]
Release branches? [release/]
Hotfix branches? [hotfix/]
Support branches? [support/]
Version tag prefix? []
Hooks and filters directory?

`git opush --all`

# convert writebackup plugin to GitHub - readme

`vim doc/*.txt`
Add github snippets after INSTALLATION and after IDEAS.

`:CloneHelpAsReadme`
`:MarkdownPreview`

`cp ~/.vim/.gitignore .`
`git adduu`
`git c -m "Add Readme and gitignore"`
`git opush`
