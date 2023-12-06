#!/bin/bash

# Define your whitelist
declare -a whitelist=("4d63.com/gocheckcompilerdirectives" "4d63.com/gochecknoglobals" "github.com/4meepo/tagalign" "github.com/Abirdcfly/dupword")

# Extract direct dependencies from go.mod, skipping 'require', '(', 'indirect', and ')'
dependencies=$(awk '/require[[:space:]]+\(/,/\)/ {if ($1 !~ /^require$/ && $1 !~ /^\($/ && $1 !~ /^\)$/ && $0 !~ /indirect$/) print $1}' go.mod)

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