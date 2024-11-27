# Preparation
The tool wants a fresh repo clone; this also serves as a backup:
`$ git clone --no-local repo repo2`
This automatically changes into the `repo2` target working copy.

# Extracting a path
For extracting a single subdir into a separate repo, `git subtree` (a variant
of submodules that uses subtree merges instead of separate references) can be
used:
`$ git subtree split --prefix path/to/subdir -b subdir-extraction`
The new branch now creates the re-rooted commits touching only `subdir`. We can
create a new repo for that and pull in that branch:
`$ mkcd ../subdir-repo`
`$ git init`
`$ git pull ../repo subdir-extraction:master`
In the original repo, we can now remove the subtree:
`$ git rm -r path/to/subdir && git commit -m "Extracted subdir to separate repo"`
And then include the new repo either as a submodule or subtree:
a) `$ git submodule add ../subdir-repo path/to/subdir`
b) `$ git subtree add --prefix path/to/subdir --squash ../subdir-repo master`

# Keeping paths
`$ git-filter-repo --path bin/command --path LICENSE  --path README.md`

# Removing paths
`$ git-filter-repo --path bin/unwanted-command --path accidental-commit --invert-paths`

# Post treatment
* Copy any workingcopy-private files you want to keep.
* Copy previous commit messages (`.git/commit-msgs/`).
* Archive the original working copy.
