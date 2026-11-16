#!/usr/bin/env python
# SPDX-FileCopyrightText: 2026 AerynOS Developers
# SPDX-License-Identifier: MPL-2.0

import configparser
import hashlib
import logging
from pathlib import Path
import re
import shutil
from string import Template
import sys
import tarfile
from urllib import request

def print_usage():
    print("This script should be ran with only a single argument provided")
    print("That argument should be in the format $major.$minor.$patch, with or without a following esr string. The patch value is optional")
    print("Valid examples:")
    print("./update.py 25.3.5")

n = len(sys.argv)

if n != 2:
    print_usage()
    exit(1)

version = sys.argv[1]

version_regex = re.compile('[0-9]*\\.[0-9]*(?:\\.[0-9]*)?(?:esr)?$')
if not version_regex.match(version):
    print_usage()
    exit(1)

logger = logging.getLogger("update-mesa.py")
logging.basicConfig(level=logging.INFO)

stone_recipe = Path("./stone.yaml")
if not stone_recipe.is_file():
    logger.error("This script needs to be ran in the same directory as a stone.yaml")
    exit(1)

source_url = f"https://mesa.freedesktop.org/archive/mesa-{version}.tar.xz"

logger.info("Downloading mesa source")

tmp_dir = Path("./.tmp_mesa")
if tmp_dir.exists():
    logger.info("Deleting temporary directory from previous run")
    shutil.rmtree(tmp_dir)

logger.info("Creating temporary directory for source")
tmp_dir.mkdir()

logger.info("Downloading mesa source")
request.urlretrieve(source_url, "./.tmp_mesa/source.tar.xz")

logger.info("Extracting source")
source = Path("./.tmp_mesa/source.tar.xz")
tarfile.open(source).extractall(path = tmp_dir)

crate_output = \
"""##@@BEGIN_CRATES
"""

crate_template = Template(\
"""    - ${source_url}:
        hash: ${source_hash}
        rename: ${source_filename}
        unpack: false
""")

wrap_files = tmp_dir.glob(f"mesa-{version}/subprojects/*.wrap")
for wrap_file in sorted(wrap_files):
    logger.info(wrap_file)
    parser = configparser.ConfigParser()
    parser.read(wrap_file)
    if 'wrap-file' in parser.sections():
        if "https://static.crates.io" in parser["wrap-file"]["source_url"]:
            output = crate_template.substitute(
                source_url = parser["wrap-file"]["source_url"],
                source_hash = parser["wrap-file"]["source_hash"],
                source_filename = parser["wrap-file"]["source_filename"])
            crate_output += output

crate_output += \
"""##@@END_CRATES"""

# Update the version string
version_template = Template(\
"""##@@BEGIN_VERSION
version     : "${version}"
##@@END_VERSION""")

version_output = version_template.substitute(version = version)

# Update the source
source_template = Template(\
"""##@@BEGIN_SOURCE
    - ${source_url}:
        hash: ${checksum}
        unpackdir: mesa
##@@END_SOURCE""")
with open(source, 'rb', buffering=0) as f:
    checksum = hashlib.file_digest(f, 'sha256').hexdigest()

source_output = source_template.substitute(source_url = source_url, checksum = checksum)

# Read the stone so we can modify it
with open(stone_recipe, 'r') as file:
    stone_content = file.read()

# Replace the crates section
stone_content = re.sub('##@@BEGIN_CRATES?(.*?)##@@END_CRATES', crate_output, stone_content, flags=re.DOTALL)

# Replace version section
stone_content = re.sub('##@@BEGIN_VERSION?(.*?)##@@END_VERSION', version_output, stone_content, flags=re.DOTALL)

# Replace source section
stone_content = re.sub('##@@BEGIN_SOURCE?(.*?)##@@END_SOURCE', source_output, stone_content, flags=re.DOTALL)

logger.info("Updating stone.yaml")
with open(stone_recipe, "w") as f:
    f.write(stone_content)

logger.info("Success!")
