# Preparation
The tool wants a fresh repo clone; this also serves as a backup:
`$ git clone --no-local repo repo2`
This automatically changes into the `repo2` target working copy.

# Keeping paths
`$ git-filter-repo --path bin/command --path LICENSE  --path README.md`

# Removing paths
`$ git-filter-repo --path bin/unwanted-command --path accidental-commit --invert-paths`

# Post treatment
* Copy any workingcopy-private files you want to keep.
* Copy previous commit messages (`.git/commit-msgs/`).
* Archive the original working copy.
