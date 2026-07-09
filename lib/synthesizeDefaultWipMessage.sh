#!/bin/bash

printf 'WIP on %s' "$(git log --max-count 1 --pretty=format:'%h %s')"
