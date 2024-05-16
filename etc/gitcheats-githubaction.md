# releases

1. `$ git release start v1`
   Inspect changed files list with `$ git stablefiles`
   Check changelog with `$ git stablelg`
   Inspect changes to prior release with `$ git stabled`
2. Edit README.md and change NAME@master to NAME@v1
   `$ git cu -m 'Release: Update release version in Readme'`
3. Freeze dependencies:
   - Cherry-pick the last freeze commit:
     `$ git cherrypickg 'Release: Freeze dependencies'`
   - Update any refs in action.yml
   - `$ git cu -m 'Release: Freeze dependencies'`
4. Update CHANGELOG.md:
   - Replace UNRELEASED with v1, add the date
   - Add new section above: _<Leader>il_
   `$ git release commit` (`$ git cu -m 'Release 1.00'`)
5. `$ git release finish` -> tag name: "Version v1"
6. Undo the version pinning and freezing:
   `$ git revertg 'Release: Update release version in Readme'`
   `$ git revertg 'Release: Freeze dependencies'`
   `$ git amenu`
7. `$ git opa` (`$ git opush --tags && git opush --all`)
