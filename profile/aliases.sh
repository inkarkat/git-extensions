#!/bin/sh source-this-script

# Configure Git aliases for various built-in diff tools, depending on what is
# available.
# git diffFOO		Permanently set diff.tool to FOO.
# git diffFOO . | ARGS	Execute remaining arguments with temporary diff.tool set to FOO.
# git mergeFOO		Permanently set merge.tool to FOO.
# git mergeFOO . | ARGS	Execute remaining arguments with temporary merge.tool set to FOO.
exists meld	&& git-userlocalconfig alias.diffwithmeld 'customtool diff.tool meld' \
		&& git-userlocalconfig alias.mergewithmeld 'customtool merge.tool meld'
exists kdiff3   && git-userlocalconfig alias.diffwithkdiff3 'customtool diff.tool kdiff3' \
		&& git-userlocalconfig alias.mergewithkdiff3 'customtool merge.tool kdiff3'
exists tkdiff   && git-userlocalconfig alias.diffwithtkdiff 'customtool diff.tool tkdiff' \
		&& git-userlocalconfig alias.mergewithtkdiff 'customtool merge.tool tkdiff'
exists vimdiff  && git-userlocalconfig alias.diffwithvimdiff 'customtool diff.tool vimdiff' \
		&& git-userlocalconfig alias.mergewithvimdiff 'customtool merge.tool vimdiff' \
		&& git-userlocalconfig alias.diffwithvimdiff2 'customtool diff.tool vimdiff2' \
		&& git-userlocalconfig alias.mergewithvimdiff2 'customtool merge.tool vimdiff2' \
		&& git-userlocalconfig alias.diffwithvimdiff3 'customtool diff.tool vimdiff3' \
		&& git-userlocalconfig alias.mergewithvimdiff3 'customtool merge.tool vimdiff3'
exists gvimdiff && git-userlocalconfig alias.diffwithgvimdiff 'customtool diff.tool gvimdiff' \
		&& git-userlocalconfig alias.mergewithgvimdiff 'customtool merge.tool gvimdiff' \
		&& git-userlocalconfig alias.diffwithgvimdiff2 'customtool diff.tool gvimdiff2' \
		&& git-userlocalconfig alias.mergewithgvimdiff2 'customtool merge.tool gvimdiff2' \
		&& git-userlocalconfig alias.diffwithgvimdiff3 'customtool diff.tool gvimdiff3' \
		&& git-userlocalconfig alias.mergewithgvimdiff3 'customtool merge.tool gvimdiff3'
exists xxdiff   && git-userlocalconfig alias.diffwithxxdiff 'customtool diff.tool xxdiff' \
		&& git-userlocalconfig alias.mergewithxxdiff 'customtool merge.tool xxdiff'
