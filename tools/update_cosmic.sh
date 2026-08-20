#!/bin/bash
# SPDX-FileCopyrightText: 2024 AerynOS Developers
# SPDX-License-Identifier: MPL-2.0

set -e
set -x

# The version of the cosmic desktop
VERSION="1.4.0"

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

    # change to working directory
    pushd $(dirname $recipe)

    # Update the recipe
    # I HEAVILY recommend commenting it out after all the recipes related to COSMIC get updated, just so you don't bump the package twice.
    boulder recipe update --ver $VERSION stone.yaml
    just build
    just mv-local

    popd
  fi
done
