#!/bin/bash

#whitelist=("4d63.com/gocheckcompilerdirectives" "4d63.com/gochecknoglobals" "github.com/4meepo/tagalign" "github.com/Abirdcfly/dupword")

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
config_file="$project_root/scripts/config/gomodcheck-config.yml"

whitelist=($(yq e '.allowed-dep[]' "$config_file"))

# fetch what we have in require(..) blocks, skip indirect dependencies
dependencies=$(awk '/require[[:space:]]+\(/,/\)/ {if ($1 !~ /^require$/ && $1 !~ /^\($/ && $1 !~ /^\)$/ && $0 !~ /indirect$/) print $1}' "$project_root/go.mod")

found=0

echo "Running gomodcheck..."

# Check each dependency
for dep in $dependencies; do
    is_approved=0
    for white_item in "${whitelist[@]}"; do
        if [[ "$dep" == "$white_item" ]]; then
            is_approved=1
            break
        fi
    done

    if [[ $is_approved -eq 0 ]]; then
        echo "Unapproved dependency: $dep"
        found=1
    fi
done

if [ $found -eq 1 ]; then
    exit 1
fi
