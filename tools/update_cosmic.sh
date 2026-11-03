#!/bin/bash
# SPDX-FileCopyrightText: 2024 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0

set -e
set -x

REPO="pop-os"

# The version of the cosmic desktop
VERSION="1.0.0-alpha.7"

# Find all `stone.yaml` files that contain pop-os in the upstreams section
# and update the upstream to the latest commit

for recipe in $(find . -name "stone.yaml"); do
  # Get the upstreams section
  upstreams=$(yq ".upstreams" $recipe)

  # Check if the upstreams section contains pop-os
  if [[ $upstreams == *"pop-os"* ]]; then
    # Get the package name
    package_name=$(yq ".name" $recipe)

    if [[ $package_name == "cosmic-workspaces" ]]; then
      package_name="cosmic-workspaces-epoch"
    elif [[ $package_name == "pop-os-launcher" ]]; then
      continue
    elif [[ $package_name == "pop-os-icon-theme" ]]; then
      continue
    elif [[ $package_name == "pop-os-sound-theme" ]]; then
      continue
    elif [[ $package_name == "system76-power" ]]; then
      continue
    fi

    # Get the latest commit from the github API
    latest_commit=$(gh api repos/$REPO/$package_name/commits --jq '.[0].sha')

    # change to working directory
    pushd $(dirname $recipe)

    # Update the recipe
    boulder recipe update --ver $VERSION --upstream "git|$latest_commit" --overwrite stone.yaml

    popd
  fi
done
