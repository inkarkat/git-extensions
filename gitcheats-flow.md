# creating

`git flow init`
Instead of naming each ref to push, specifies that all refs / tags
be mirrored to the remote repository. Newly created local refs will be pushed
to the remote end, locally updated refs will be force updated on the remote
end, and deleted refs will be removed from the remote end.
`git config remote.origin.mirror true`

# releases

`git flow release start 1.00`
Update changelog
`git lg master..`
Note: I don't publish the release branch if it just contains trivial mechanics of preparing the release.
`git flow release finish 1.00`
`git opush`
