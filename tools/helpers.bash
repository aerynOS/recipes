#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2024 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0

BOLD='\033[1m'
RED='\033[0;31m'
RESET='\033[0m'
YELLOW='\033[0;33m'
GREEN="\033[32m"

function checkupdate() {
    if [ ! -e "monitoring.yaml" ]; then
        echo -e "${RED}monitoring.yaml file doesn't exist"
        return 1
    fi
    if [ ! -e "stone.yaml" ]; then
        echo -e "${RED}stone.yaml file doesn't exist"
        return 1
    fi

    # Check requirements before starting
    REQUIREMENTS="curl yq jq"
    for i in $REQUIREMENTS; do
        if ! which $i &> /dev/null; then
            echo "Missing requirement: $i. Install it to continue."
            return 1
        fi
    done

    current_version=$(yq '.version' stone.yaml)
    new_version=$(curl -s -H "Accept: application/json" https://release-monitoring.org/api/v2/versions/?project_id=`yq '.releases.id' monitoring.yaml` | jq -r '.stable_versions[:1]' | jq -c '.[]')

    # Strip any quotes and replace underscores with dots
    new_version=${new_version//\"/}
    new_version=${new_version//\'/}
    new_version=${new_version//_/.}
    current_version=${current_version//\"/}
    current_version=${current_version//\'/}

    echo "current version: ${current_version}"
    if [ "$current_version" != "$new_version" ]; then
        echo -e "${YELLOW}lastest version: ${new_version}${RESET}"
        echo -e "${BOLD}Update available${RESET}"
    elif [ "$current_version" == "$new_version" ]; then
        echo -e "${GREEN}lastest version: ${new_version}${RESET}"
        echo "Already using latest version"
    fi
}

# Primitive CPE search tool
function cpesearch() {
    # Check requirements before starting
    REQUIREMENTS="curl jq"
    for i in $REQUIREMENTS; do
        if ! which $i &> /dev/null; then
            echo "Missing requirement: $i. Install it to continue."
            return 1
        fi
    done

    function search() {
        curl -s -X POST https://cpe-guesser.cve-search.org/search -d "{\"query\": [\"$1\"]}" | jq .

        echo "Verify successful hits by visiting https://cve.circl.lu/search/\$VENDOR/\$PRODUCT"
        echo "- CPE entries for software applications have the form 'cpe:2.3:a:\$VENDOR:\$PRODUCT'"
    }

    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "usage: cpesearch <package-name>"
    elif [[ $# -eq 0 ]]; then
        echo "Warning: No paramaters passed, using current directory name. Pass --help to see usage"
        search "$(basename "$(pwd)")"
    else
        search "$1"
    fi
}

# Goes to the root directory of the aerynOS recipes
# git repository from anywhere on the filesystem.
# This function will only work if this script is sourced
# by your bash shell.
function gotoaosrepo() {
    cd "$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")/../" || return 1
}

# Goes to the root directory of the git repository
function goroot() {
    cd "$(git rev-parse --show-toplevel)" || return 1
}

# Push into a package directory
function chpkg() {
    cd "$(git rev-parse --show-toplevel)"/${1:0:1}/"$1" || return 1
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

git-shortlog-updates () {
    local _arg="${1}"
    local _oneline="--format=oneline"
    if [[ -n ${_arg} ]]; then
        _oneline="--format=oneline ${_arg}..HEAD"
    fi
    git log ${_oneline} \
        |grep -E ': [Uu]pdate' \
        |cut -f1 -d' ' --complement \
        |sed -E -e 's|: [Uu]pdate to v?| |g'
}

git-shortlog-add () {
    local _arg="${1}"
    local _oneline="--format=oneline"
    if [[ -n ${_arg} ]]; then
        _oneline="--format=oneline ${_arg}..HEAD"
    fi
    git log ${_oneline} \
        |grep -E ': [Aa]dd' \
        |cut -f1 -d' ' --complement \
        |sed -E -e 's|: [Aa]dd at v?| |g'
}

git-shortlog-fix () {
    local _arg="${1}"
    local _oneline="--format=oneline"
    if [[ -n ${_arg} ]]; then
        _oneline="--format=oneline ${_arg}..HEAD"
    fi
    git log ${_oneline} \
        |grep -E ': [Ff]ix' \
        |cut -f1 -d' ' --complement
}


# Bash completions
_chpkg()
{
    # list of package directories we can go into
    _list=$(basename -a "$(git rev-parse --show-toplevel)"/{a..z}/*)

    local cur
    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}

    if [[ $COMP_CWORD -eq 1 ]] ; then
        # set up an array with valid package dirname completions
        readarray -t COMPREPLY < <(compgen -W "${_list}" -- "${cur}")
        return 0
    fi
}

complete -F _chpkg chpkg
