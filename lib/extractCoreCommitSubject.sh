#!/bin/bash
shopt -qs extglob

commitSubject="${1?}"; shift
coreInformation="$commitSubject"

# Remove all parenthesized commitSubject commitSubject.
coreInformation="${coreInformation//(+([^)]))/}"
# Remove all leading "scope:" and "keyword:" prefixes.
coreInformation="${coreInformation/#+(+([^ ]): )/}"

[ -n "$coreInformation" -a "$coreInformation" != "$commitSubject" ] \
    && printf '%s' "$coreInformation"
