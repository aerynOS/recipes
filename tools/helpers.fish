#!/usr/bin/env fish
# SPDX-FileCopyrightText: 2024 AerynOS Developers
# SPDX-License-Identifier: MPL-2.0

function checkupdate -d "Check relaese-monitoring.org for a newer recipe version"
    if not test -e monitoring.yaml
        echo -s (set_color red) "monitoring.yaml file doesn't exist" (set_color --reset)
        return 1
    end

    if not test -e stone.yaml
        echo -s (set_color red) "stone.yaml file doesn't exist" (set_color --reset)
        return 1
    end

    # Check requirements before starting
    set -l REQUIREMENTS curl yq jq
    for i in $REQUIREMENTS
        if not type -q $i
            echo "Missing requirement: $i. Install it to continue."
            return 1
        end
    end

    set -l current_version (yq '.version' stone.yaml)
    set -l project_id (yq '.releases.id' monitoring.yaml)
    set -l new_version (curl -s -H "Accept: application/json" "https://release-monitoring.org/api/v2/versions/?project_id=$project_id" | jq -r '.stable_versions[:1]' | jq -c '.[]')

    # Strip any quotes and replace underscores with dots
    set new_version (string replace -a '"' '' -- $new_version)
    set new_version (string replace -a "'" '' -- $new_version)
    set new_version (string replace -a '_' '.' -- $new_version)
    set current_version (string replace -a '"' '' -- $current_version)
    set current_version (string replace -a "'" '' -- $current_version)

    echo "current version: $current_version"
    if test "$current_version" != "$new_version"
        echo -s (set_color yellow) "lastest version: $new_version" (set_color --reset)
        echo -s (set_color --bold) "Update available" (set_color --reset)
    else if test "$current_version" = "$new_version"
        echo -s (set_color green) "lastest version: $new_version" (set_color --reset)
        echo "Already using latest version"
    end
end

function __aos_repo_dir
    realpath (dirname (readlink -m (status -f)))/../
end

function __aos_toplevel
    git rev-parse --show-toplevel
end

function cpesearch -d "Search for known CPE entries for a program or library"
    if test "$argv[1]" = --help; or test "$argv[1]" = -h; or test (count $argv) -ne 1
        echo "usage: cpesearch <package-name>"
    else
        curl -s -X POST https://cpe-guesser.cve-search.org/search -d "{\"query\": [\"$argv[1]\"]}" | jq .

        echo "Verify successful hits by visiting https://cve.circl.lu/search/\$VENDOR/\$PRODUCT"
        echo "- CPE entries for software applications have the form 'cpe:2.3:a:\$VENDOR:\$PRODUCT"
    end
end

function gotoaosrepo -d "Go to the root of the AerynOS recipes repository"
    cd (__aos_repo_dir)
end

function goroot -d "Go to the root of the current Git repository"
    cd (__aos_toplevel)
end

function chpkg -a package -d "Go to a package directory"
    cd (__aos_toplevel)/*/$package
end

function fix-version-strings -d "Quote unquoted version strings in recipes"
    find . -type f -name "stone.yaml" -exec sed -i -E \
        -e 's|^([[:space:]]*version[[:space:]]*:[[:space:]]*)'\''([^'\'']*)'\''|\1"\2"|' \
        -e 's|^([[:space:]]*version[[:space:]]*:[[:space:]]*)([^"'\''[:space:]][^[:space:]]*)|\1"\2"|' \
        {} +
end

function fixup-recipe-commit -d "Quickly fixup a recipe commit for a source package"
    if not test -f stone.yaml
        echo "No stone.yaml found in the current directory, aborting!"
        return 1
    end

    if not git status --porcelain -- . | string match -qr "^ M"
        echo "No files in current directory are modified, aborting!"
        return 1
    end

    # Be explicit about adding files specific to packaging to avoid adding aliens
    set -l paths stone.yaml manifest.x86_64.bin manifest.x86_64.jsonc monitoring.yaml pkg/
    for path in $paths
        if test -e $path
            git add $path
        end
    end

    # Fixup the last commit in the directory
    git commit --fixup "$(git log -1 --format="%h" -- .)"
    git rebase origin/HEAD --autosquash --autostash

    # Print out the commit for the user
    git log -1 -- .
end

complete -c checkupdate -f
complete -c gotoaosrepo -f
complete -c goroot -f
complete -c chpkg -f
complete -c chpkg -a "(path basename (__aos_toplevel)/*/*)"
complete -c fixup-recipe-commit -f
