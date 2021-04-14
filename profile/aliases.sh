#!/bin/sh source-this-script

# Configure Git aliases for various built-in diff tools, depending on what is
# available.
# git diffFOO		Permanently set diff.tool to FOO.
# git diffFOO . | ARGS	Execute remaining arguments with temporary diff.tool set to FOO.
# git mergeFOO		Permanently set merge.tool to FOO.
# git mergeFOO . | ARGS	Execute remaining arguments with temporary merge.tool set to FOO.
# Note: This causes "error: could not lock config file
# /home/inkarkat/.local/.gitconfig: Permission denied" when executed under a
# different user (through withUnixhome), because git-userlocalconfig updates
# information. To avoid the error (and instead write the actual user's
# config), use the USER_HOME if provided by withUnixhome.
exists meld	&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithmeld 'customtool diff.tool meld' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithmeld 'customtool merge.tool meld'
exists kdiff3   && HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithkdiff3 'customtool diff.tool kdiff3' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithkdiff3 'customtool merge.tool kdiff3'
exists tkdiff   && HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithtkdiff 'customtool diff.tool tkdiff' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithtkdiff 'customtool merge.tool tkdiff'
exists vimdiff  && HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithvimdiff 'customtool diff.tool vimdiff' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithvimdiff 'customtool merge.tool vimdiff' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithvimdiff2 'customtool diff.tool vimdiff2' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithvimdiff2 'customtool merge.tool vimdiff2' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithvimdiff3 'customtool diff.tool vimdiff3' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithvimdiff3 'customtool merge.tool vimdiff3'
exists gvimdiff && HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithgvimdiff 'customtool diff.tool gvimdiff' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithgvimdiff 'customtool merge.tool gvimdiff' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithgvimdiff2 'customtool diff.tool gvimdiff2' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithgvimdiff2 'customtool merge.tool gvimdiff2' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithgvimdiff3 'customtool diff.tool gvimdiff3' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithgvimdiff3 'customtool merge.tool gvimdiff3'
exists xxdiff   && HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.diffwithxxdiff 'customtool diff.tool xxdiff' \
		&& HOME="${USER_HOME:-$HOME}" git-userlocalconfig alias.mergewithxxdiff 'customtool merge.tool xxdiff'
