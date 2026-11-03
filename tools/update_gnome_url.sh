#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2024 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0

if [ ! -e "monitoring.yml" ] && [ ! -e "monitoring.yaml" ]; then
    echo "${RED} monitoring.y{a}ml file doesn't exist"
    exit 1
fi

if [ ! -e "stone.yml" ] && [ ! -e "stone.yaml" ]; then
    echo "${RED} stone.y{a}ml file doesn't exist"
    exit 1
fi

BOLD='\033[1m'
RED='\033[0;31m'
RESET='\033[0m'
YELLOW='\033[0;33m'
GREEN="\033[32m"

# Old URL and new version numbers
old_url=$(yq e '.upstreams[0] | keys[]' stone.yaml)
current_version=$(yq '.version' stone.yaml)
new_version=$(curl -s -H "Accept: application/json" https://release-monitoring.org/api/v2/versions/?project_id=`yq '.releases.id' monitoring.yaml` | jq -r '.stable_versions[:1]' | jq -c '.[]')

# Strip any quotes and replace underscores with dots
new_version=${new_version//\"/}
new_version=${new_version//\'/}
new_version=${new_version//_/.}
current_version=${current_version//\"/}
current_version=${current_version//\'/}

echo "current version: ${current_version}"
echo "new version    : ${new_version}"

if [ "$current_version" == "$new_version" ]; then
    echo -e "${GREEN}Version ${version} matches latest stable${RESET}"
    exit 0
fi

echo -e "${BOLD}${YELLOW}This script won't work as expected for GNOME .5 releases${RESET}"

echo -e "${BOLD}${GREEN}Newer version available${RESET}"

do_the_thing() {
    echo "current url: $old_url"
    echo "new url    : $new_url"

    boulder up --ver ${new_version} -u ${new_url} -w stone.yaml

    changelog_url="https://gitlab.gnome.org/GNOME/$(yq '.name' stone.yaml)/-/raw/${new_version}/NEWS?ref_type=tags"
    curl -IsfS ${changelog_url} > /dev/null
    if [ $? -eq 0 ]; then
        echo -e "${BOLD}Changelog: ${changelog_url}${RESET}"
    else
        echo -e "${BOLD}${YELLOW}Failed to find changelog, expected:${RESET} ${changelog_url}"
    fi
}

# Extract the major version
current_major_version=$(yq e '.upstreams[0] | keys[]' stone.yaml | awk -F '/' '{print $6}')

# Try the URL with semvar.major as the subversion
new_url=$(echo "$old_url" | sed "s/\/$current_major_version\//\/${new_version%%.*}\//; s/$current_version/$new_version/")
curl -IsfS ${new_url} > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${BOLD}Successfully found URL${RESET}"
    do_the_thing
    exit 0
fi

# Try the URL with semvar.major as the subversion
new_url=$(echo "$old_url" | sed "s/\/$current_major_version\//\/${new_version%.*}\//; s/$current_version/$new_version/")
curl -IsfS ${new_url} > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${BOLD}Successfully found URL${RESET}"
    do_the_thing
    exit 0
fi

echo -e "${BOLD}${RED}Failed to resolve new URL${RESET}"
