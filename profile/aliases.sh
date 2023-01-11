#!/bin/sh source-this-script

# Configure Git aliases for various built-in diff tools, depending on what is
# available.
# git diffwithFOO		Permanently set diff.tool to FOO.
# git diffwithFOO . | ARGS	Execute remaining arguments with temporary diff.tool set to FOO.
# git mergewithFOO		Permanently set merge.tool to FOO.
# git mergewithFOO . | ARGS	Execute remaining arguments with temporary merge.tool set to FOO.
# Note: This causes "error: could not lock config file
# /home/inkarkat/.local/.gitconfig: Permission denied" when executed under a
# different user (through withUnixhome), because git-userlocalconfig updates
# information. To avoid the error (and instead write the actual user's
# config), use the USER_HOME if provided by withUnixhome.
if exists meld; then
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithmeld 'customtool diff.tool meld'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithmeld 'customtool merge.tool meld'
fi
if exists kdiff3; then
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithkdiff3 'customtool diff.tool kdiff3'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithkdiff3 'customtool merge.tool kdiff3'
fi
if exists tkdiff; then
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithtkdiff 'customtool diff.tool tkdiff'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithtkdiff 'customtool merge.tool tkdiff'
fi
if exists vimdiff; then
    # XXX: Git's vimdiff naming is likely historical but veery confusing. I'd
    # like the number mean the number of windows shown, so everything has to be
    # remapped.

    # vimdiff is a Git-custom 4 windows layout.
    # ------------------------------------------
    # |             |           |              |
    # |   LOCAL     |   BASE    |   REMOTE     |
    # |             |           |              |
    # ------------------------------------------
    # |                                        |
    # |                MERGED                  |
    # |                                        |
    # ------------------------------------------
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithvimdiff4 'customtool diff.tool vimdiff'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithvimdiff4 'customtool merge.tool vimdiff'

    # vimdiff3: Use Vim where only the MERGED file is shown
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithvimdiff1 'customtool diff.tool vimdiff3'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithvimdiff1 'customtool merge.tool vimdiff3'

    # vimdiff1: Use Vim with a 2 panes layout (LOCAL and REMOTE)
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithvimdiff2 'customtool diff.tool vimdiff1'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithvimdiff2 'customtool merge.tool vimdiff1'

    # vimdiff2: Use Vim with a 3 panes layout (LOCAL, MERGED and REMOTE)
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithvimdiff3 'customtool diff.tool vimdiff2'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithvimdiff3 'customtool merge.tool vimdiff2'
fi
if exists gvimdiff; then
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithgvimdiff4 'customtool diff.tool gvimdiff'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithgvimdiff4 'customtool merge.tool gvimdiff'

    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithgvimdiff1 'customtool diff.tool gvimdiff3'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithgvimdiff1 'customtool merge.tool gvimdiff3'

    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithgvimdiff2 'customtool diff.tool gvimdiff1'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithgvimdiff2 'customtool merge.tool gvimdiff1'

    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithgvimdiff3 'customtool diff.tool gvimdiff2'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithgvimdiff3 'customtool merge.tool gvimdiff2'
fi
if exists xxdiff; then
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithxxdiff 'customtool diff.tool xxdiff'
    HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithxxdiff 'customtool merge.tool xxdiff'
fi
