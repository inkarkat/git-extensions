# Submodules
⊕ Avoid that all collaborators have to fetch a massive codebase (even if
  working on unrelated areas).
⊕ Truly independent histories, working copy states, branches.

# Alternatives
These all duplicate the components' commits into the superproject, whereas
submodules just add references.
Source: https://medium.com/@porteneuve/mastering-git-subtrees-943d29a798ec

## manual subtree merges
It starts by reading another repo's tree into the index.
`$ git read-tree -P path/to/submodule -u submodule/master && git commit`
Updates then use the _subtree_ merge strategy.
`$ git merge -s subtree --squash submodule/master && git commit`
⊝ Syntax is tedious
⊕ Can mix superproject-specific customizations and backports to the submodule;
  only the latter can be cherry-picked for submittal.

## git subtree command
This uses the same Git commands under the hood, but it provides a cleaner API.
Started as a third-party contribution by apenwarr, now part of Git.
`$ git subtree add --prefix=path/to/submodule --squash submodule master`
`$ git subtree pull --prefix=path/to/submodule --squash submodule master`
⊝ Updates are done by maintaining a subtree-specific branch that gets merged
  (creating a bit of cluttered history) on every `git subtree pull` / `merge`.
⊝ It extracts its metadata from the commit messages, so there's no seamless
  transition from the manual approach.

## git-subrepo https://github.com/ingydotnet/git-subrepo
Uses `.gitrepo` metadata in the superproject (like submodules).
⊕ Convenient, use case-driven syntax similar to submodules

## Higher-level (than revision control)
If the technological context allows for packaging and formal dependency
management, you should absolutely go this route instead: it lets you better
split your codebase, avoid a number of side effects and pitfalls that litter
the submodule space, and let you benefit from versioning schemes such as
semantic versioning (semver) for your dependencies.
-- Christophe Porteneuve
   https://medium.com/@porteneuve/mastering-git-submodules-34c65e940407
