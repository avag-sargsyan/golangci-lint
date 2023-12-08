#!/bin/bash

# TODO: move to config file
whitelist=("4d63.com/gocheckcompilerdirectives" "4d63.com/gochecknoglobals" "github.com/4meepo/tagalign" "github.com/Abirdcfly/dupword")

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

# fetch what we have in require(..) blocks, skip indirect dependencies
dependencies=$(awk '/require[[:space:]]+\(/,/\)/ {if ($1 !~ /^require$/ && $1 !~ /^\($/ && $1 !~ /^\)$/ && $0 !~ /indirect$/) print $1}' "$project_root/go.mod")

found=0

# Check each dependency
for dep in $dependencies; do
    if [[ ! " ${whitelist[@]} " =~ " ${dep} " ]]; then
        echo "Unapproved dependency: $dep"
        found=1
    fi
done

if [ $found -eq 1 ]; then
    exit 1
fi
