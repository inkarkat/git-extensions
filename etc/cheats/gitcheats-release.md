# Inspections and Tests
- Inspect changed files list with `$ git stable files`
- Check changelog with `$ git stable lg`
- Inspect changes to prior release with `$ git stable d`
- Run checks (`runTests`, `make test`, etc.)

# releases without Git flow, just a stable branch
1. `$ git resetbr stable [COMMIT-ID]`  # move stable to current HEAD / selected
   stable COMMIT
2. `$ git opa` or `$ git opush stable`
Alternatively:
1. `$ git co stable`
2. `$ git mff`
3. `$ git opush && git com`

# releases with Git flow
1. `$ git release start 1.00`
2. Update `CHANGELOG.md` (at least with release date); remove empty change
   categories.
3. `$ git release commit` (`$ git cu -m 'Release 1.00'`)
4. `$ git release finish` -> tag name: "Version 1.00"
5. `$ git opa` (`$ git opush --tags && git opush --all`)
