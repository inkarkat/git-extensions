#!/bin/sh source-this-script

# Add the short commit ID as additional prompt context information. This helps
# with recalling prior commits from the terminal history, as an alternative to
# Git's reflog.
_PS1PromptContext_git()
{
    git rev-parse --short HEAD 2>/dev/null
}
