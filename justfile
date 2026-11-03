# SPDX-FileCopyrightText: 2024 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0

default: (_build build_file)

set dotenv-load
set quiet
# respect variables set in .env file next to the present justfile
boulder := env('BOULDER', 'boulder')
boulder_args := env('BOULDER_ARGS', '')
boulder_profile := env('BOULDER_PROFILE', 'local-x86_64')
build_file := join(invocation_directory(), "stone.yaml")
local_repo := env('LOCAL_REPO', '${HOME}/.cache/local_repo/x86_64')

# Build the stone.yaml recipe using boulder
_build target:
    cd {{ invocation_directory() }}; {{boulder}} build {{boulder_args}} -u {{ if path_exists(target) == "true" { target } else { error("Missing stone.yaml file") } }} -p {{ boulder_profile }}

# Build stone.yaml from the current directory
build: (_build build_file)

# Chroot into target from stone.yaml recipe with boulder
_chroot target:
    cd {{ invocation_directory() }}; {{boulder}} {{boulder_args}} chroot {{ if path_exists(target) == "true" { target } else { error("Missing stone.yaml file") } }}

_bump target:
    cd {{ invocation_directory() }}; {{boulder}} recipe bump
bump: (_bump build_file)

# check existing monitoring.yaml files in the tree for missing mandatory fields
check-monitoring-fields:
    #!/usr/bin/env bash

    total_count=0
    missing_count=0
    for f in $(find -type f -name "monitoring.yaml" 2>/dev/null |sort -n ); do
        let "total_count=total_count+1"
        cpe="$( grep "cpe:" "${f}" )"
        id="$( grep "id:" "${f}" )"
        rss="$( grep "rss:" "${f}" )"
        if [[ "${cpe}" == "" || "${id}" == "" || "${rss}" == "" ]]; then
             echo -en "\n${f} is missing mandatory fields:\n>> "
             [[ "${cpe}" == "" ]] && echo -n "cpe "
             [[ "${id}" == "" ]] && echo -n "id "
             [[ "${rss}" == "" ]] && echo -n "rss "
             echo -e "<<\nContents:\n---------"
             cat "${f}"
             echo "---------"
             let "missing_count=missing_count+1"
        fi
    done
    echo -e "\nOut of ${total_count} monitoring.yaml files, ${missing_count} are missing mandatory fields.\n"
    unset missing_count
    unset total_count
    # end

# check the entire tree for package recipes missing monitoring.yaml files
check-monitoring-missing:
    #!/usr/bin/env bash
    OUTPUT=/tmp/check-monitoring-missing.txt
    missing_count=0
    # find all dirs with a stone.yaml file
    find -mindepth 3 -maxdepth 3 -type f -name 'stone.yaml' -exec /usr/bin/dirname '{}' \; 2>/dev/null > "${OUTPUT}"
    total_count=$( wc -l "${OUTPUT}" |cut -f1 -d' ' )
    # find all dirs with a monitoring.yaml file
    find -mindepth 3 -maxdepth 3 -type f -name 'monitoring.yaml' -exec /usr/bin/dirname '{}' \; 2>/dev/null >> "${OUTPUT}"
    echo "The following directories have a stone.yaml recipe but no monitoring.yaml file:"
    # the non-duplicate lines are most likely dirs with no monitoring.yaml
    for d in $( sort -n ${OUTPUT} | uniq -u ); do
        [[ -f ${d}/monitoring.yml ]] && echo -n " (has .yml) " || echo -n "            "
        echo -en "${d}\n"
        let "missing_count=missing_count+1"
    done
    echo -e "\nOut of ${total_count} package recipes, ${missing_count} are missing monitoring.yaml files.\n"
    unset missing_count
    unset total_count
    [[ -f "${OUTPUT}" ]] && rm -f "${OUTPUT}"
    # end

# Chroot into pkg from the current directory
chroot: (_chroot build_file)

# Clean up .stone files
_clean target:
    cd {{ invocation_directory() }}; rm -v *.stone || echo "No .stone file(s) found"

# Clean *.stone artefacts from the current directory
clean: (_clean build_file)

# Init git hooks
_init target:
    #!/usr/bin/env bash
    ln -sfv ../../tools/prepare-commit-msg.py $(git rev-parse --git-path hooks)/prepare-commit-msg
    ln -sfv ../../tools/pre-commit.py $(git rev-parse --git-path hooks)/pre-commit
    gitconfig="$(git rev-parse --git-path config)"
    grep -q '\[diff "moss"\]' "$gitconfig" || {
        echo 'Enabling binary diff for manifest.*.bin files in' "${gitconfig}"
        cat <<'EOT' | tee -a "$gitconfig"
    [diff "moss"]
    	textconv = moss inspect
    	binary = true
    EOT
    }

    grep -Pzq '\[alias\]\n\s*gone =' "$gitconfig" || {
        echo -e '\nEnabling "git gone" alias in' "${gitconfig}"
        cat <<'EOT' | tee -a "$gitconfig"
    [alias]
    	gone = "!f() { git fetch --all --prune; git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D; }; f"
    EOT
    }
init: (_init build_file)

[confirm('This will delete ALL .stones in your local repo -- continue?')]
_clean-local:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -d {{local_repo}} ]]; then
       rm -f {{local_repo}}/*.stone
    fi

# clean the LOCAL_REPO dir of .stones and reindex it
clean-local: ls-local && index-local
  just _clean-local

# create LOCAL_REPO dir if it doesn't exist
create-local:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -d {{local_repo}} ]]; then
       mkdir -pv {{local_repo}}
    fi

# index .stones in LOCAL_REPO (create it if it doesn't exist)
index-local: create-local
    cd {{ invocation_directory() }} && moss index -i {{local_repo}}

# list .stones in LOCAL_REPO (create it if it doesn't exist)
ls-local: create-local
    cd {{ invocation_directory() }} && ls -AFcghlot {{local_repo}}

# move .stones to LOCAL_REPO (create if it doesn't exist) and reindex it
mv-local: create-local
    cd {{ invocation_directory() }} && mv -v *.stone {{local_repo}}/ && moss index -i {{local_repo}}

# remove individual .stones present in LOCAL_REPO (create if it doesn't exist) and reindex it.
rm-local target: create-local
    cd {{ invocation_directory() }} && rm -v {{local_repo}}/{{target}} && moss index -i {{local_repo}}

# Check for upstream updates
updates:
    cd {{ invocation_directory() }} && ent check updates

# Verify REUSE compliance.
verify-reuse:
    reuse lint
