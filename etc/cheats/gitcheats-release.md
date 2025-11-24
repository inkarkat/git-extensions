- Inspect changed files list with `$ git stable files`
- Check changelog with `$ git stable lg`
- Inspect changes to prior release with `$ git stable d`

# releases without Git flow, just a stable branch
`$ git resetbr stable [COMMIT-ID]`  # move stable to current HEAD
`$ git opa` or `$ git opush stable`
Alternatively:
`$ git co stable`
`$ git mff`
`$ git opush && git com`

# releases with Git flow
`$ git release start 1.00`
`$ git release commit` (`$ git cu -m 'Release 1.00'`)
`$ git release finish` -> tag name: "Version 1.00"
`$ git opa` (`$ git opush --tags && git opush --all`)
