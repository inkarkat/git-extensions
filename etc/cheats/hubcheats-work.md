# Using GitHub for work

### whitelist your GitHub Enterprise hostname
`$ git config --global --add hub.host my.example.org`

### open a pull request using a message generated from script, then put its URL to the clipboard
`$ git push origin feature`
`$ hub pull-request -F prepared-message.md | cb`
→ (URL ready for pasting in a chat room)

### push to multiple remotes
`$ git push production,staging`
