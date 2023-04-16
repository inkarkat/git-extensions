#!/bin/sh source-this-script

[ -w ~/.local/.gitconfig -o -w ~/.local -o -w ~ ] || return

# Configure the pager to base tabstops on column 2, as the first column in diff
# output is added (for the +/- prefix). With that, there won't be a discrepancy
# in indenting between changed and context lines any longer (as long as the
# tabstop value is kept at 8).
# This can be overridden for single repositories via "git config --local", or by
# setting the GIT_PAGER environment variable.
#
# The setting is for the user (as pager availability is per-user) and for the
# current system only (again, a pager may only be available on that system).
# Note: This causes "error: could not lock config file
# /home/inkarkat/.local/.gitconfig: Permission denied" when executed under a
# different user (through withUnixhome), because git-userlocalconfig updates
# information. To avoid the error (and instead write the actual user's
# config), use the USER_HOME if provided by withUnixhome.
HOME="${USER_HOME:-$HOME}" git-userlocalconfig core.pager "${PAGER:-less} --tabs=1,9"
