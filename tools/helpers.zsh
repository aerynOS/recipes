#!/usr/bin/env zsh
# SPDX-FileCopyrightText: 2024 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0

autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# Primitive CPE search tool
function cpesearch() {
    if [[ -z $1 || $1 == "--help" || $1 == "-h" ]]; then
        echo "usage: cpesearch <package-name>"
    else
        curl -s -X POST https://cpe-guesser.cve-search.org/search -d "{\"query\": [\"$1\"]}" | jq .

        echo "Verify successful hits by visiting https://cve.circl.lu/search/\$VENDOR/\$PRODUCT"
        echo "- CPE entries for software applications have the form 'cpe:2.3:a:\$VENDOR:\$PRODUCT'"
    fi
}


# Goes to the root directory of the aerynOS recipes
# git repository from anywhere on the filesystem.
# This function will only work if this script is sourced
# by your zsh shell.
function gotoaosrepo() {
    SCRIPT_PATH=$functions_source[gotoaosrepo]
    cd $(dirname $(readlink -m "${SCRIPT_PATH}"))/../
}

# Goes to the root directory of the git repository
function goroot() {
    cd $(git rev-parse --show-toplevel)
}

# Change into a package directory
function chpkg() {
    cd $(git rev-parse --show-toplevel)/*/$1
}

# Quote unquoted version strings in recipes
function fix-version-strings () {
    find . -type f -name "stone.yaml" -exec sed -i -E \
    -e 's|^([[:space:]]*version[[:space:]]*:[[:space:]]*)'\''([^'\'']*)'\''|\1"\2"|' \
    -e 's|^([[:space:]]*version[[:space:]]*:[[:space:]]*)([^"'\''[:space:]][^[:space:]]*)|\1"\2"|' \
    {} +
}

# Quickly fixup a recipe commit for a source package
function fixup-recipe-commit() {
    if [[ ! -f "stone.yaml" ]]; then
        echo "No stone.yaml found in current directory, aborting!"
        return 1
    fi

    if ! git status --porcelain -- . | grep -q '^ M'; then
        echo "No files in current directory are modified, aborting!"
        return 1
    fi

    # Be explicit about adding files specific to packaging to avoid adding aliens
    local paths=(stone.yaml manifest.x86_64.bin  manifest.x86_64.jsonc monitoring.yaml pkg/)
    for path in "${paths[@]}"; do
        [[ -e $path ]] && git add "$path"
    done

    # Fixup the last commit in the directory
    git commit --fixup "$(git log -1 --format="%h" -- .)"
    git rebase origin/HEAD --autosquash --autostash

    # Print out the commit for the user
    git log -1 -- .
}


# Package name completion
_chpkg()
{
    _list=$(ls $(git rev-parse --show-toplevel)/*/)

    local cur prev
    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ $COMP_CWORD -eq 1 ]] ; then
        COMPREPLY=( $(compgen -W "${_list}" -- ${cur}) )
        return 0
    fi
}

complete -F _chpkg chpkg
