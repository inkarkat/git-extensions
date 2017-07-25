# creating

`git flow init`
Branch name for production releases: stable
Branch name for "next release" development: master

# releases

`git flow release start 1.00`
Update changelog
vimdev: First release (of a small plugin): `:DeleteChangelog`
vimdev: First release: Create manifest

`git lg stable..`
Note: I don't publish the release branch if it just contains trivial mechanics of preparing the release.
`git flow release finish 1.00`
`git opush --tags`
`git opush --all`
