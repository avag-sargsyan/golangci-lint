#!/bin/bash

# Define your whitelist
declare -a whitelist=("4d63.com/gocheckcompilerdirectives" "4d63.com/gochecknoglobals" "github.com/4meepo/tagalign" "github.com/Abirdcfly/dupword")

# Extract direct dependencies from go.mod, skipping 'require', '(', 'indirect', and ')'
dependencies=$(awk '/require[[:space:]]+\(/,/\)/ {if ($1 !~ /^require$/ && $1 !~ /^\($/ && $1 !~ /^\)$/ && $0 !~ /indirect$/) print $1}' go.mod)

# Check each dependency
for dep in $dependencies; do
    if [[ ! " ${whitelist[@]} " =~ " ${dep} " ]]; then
        echo "Unapproved dependency: $dep"
    fi
done
