#!/bin/bash

# TODO: move to config file
prefix="github.com/golangci/golangci-lint"
root_dir="internal"
modules=("errorutil")
aggregator="errorutil"
allowed_packages=()

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
found=0
generated_marker="Code generated" # TODO: maybe check for file name instead?

check_imports() {
    local file=$1
    local current_module=$2
    local inside_import_block=0

    while IFS= read -r line; do
        if [[ $line =~ ^import[[:space:]]+\( ]]; then
            inside_import_block=1
            continue
        fi

        if [[ $inside_import_block -eq 1 ]]; then
            if [[ $line =~ ^[[:space:]]*\) ]]; then
                inside_import_block=0
                continue
            fi

            import_path=$(echo "$line" | tr -d '"' | cut -d ' ' -f2)

            # trim for correct comparison
            import_path="${import_path//[[:blank:]]/}"

            if [[ "$import_path" == "$prefix"* ]]; then
                for module in "${modules[@]}"; do
                    # do not verify self imports
                    if [[ $module == $current_module ]]; then
                        continue
                    fi

                    if [[ $aggregator == $current_module ]]; then
                        # additional check for aggregator
                        if [[ "$import_path" == "$prefix/$root_dir/$module"* ]]; then
                            local allowed=0
                            for allowed_pkg in "${allowed_packages[@]}"; do
                                if [[ "$import_path" == "$prefix/$root_dir/$module/$allowed_pkg"* ]]; then
                                    allowed=1
                                    break
                                fi
                            done
                            if [[ $allowed -eq 0 ]]; then
                                echo "disallowed import of package in aggregator: '$import_path' in $file"
                                found=1
                            fi
                        fi
                    else
                        # check if $import_path is a cross-module dependency
                        if [[ "$import_path" == "$prefix/$root_dir/$module"* ]]; then
                            echo "disallowed import $import_path found in $file"
                            found=1
                        fi
                    fi
                done
            fi
        fi
    done < <(grep -E "^(import[[:space:]]+\(|[[:space:]]*\)|[[:space:]]*\".*\")$" "$file")
}

for module in "${modules[@]}"; do
    echo "Checking module: $module"
    while IFS= read -r file; do
        if ! grep -q "$generated_marker" "$file"; then
            check_imports "$file" "$module"
        # TODO: remove
        else
            echo "Skipping generated file: $file"
        fi
    done < <(find "$project_root/$root_dir/$module" -type f -name "*.go")
done

if [ $found -eq 1 ]; then
    exit 1
fi
