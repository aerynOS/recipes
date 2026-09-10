#!/usr/bin/env python
# SPDX-FileCopyrightText: 2026 AerynOS Developers
# SPDX-License-Identifier: MPL-2.0

import datetime
import json
import logging
import re
import subprocess
import sys
from pathlib import Path
from string import Template
from typing import Any
from urllib import request

logger = logging.getLogger("update-librime-data.py")
logging.basicConfig(level=logging.INFO)

GH_API = "https://api.github.com/repos"
GIT_URL = "https://github.com/rime/rime-{package}.git"

PACKAGES = [
    "bopomofo",
    "cangjie",
    "essay",
    "luna-pinyin",
    "prelude",
    "quick",
    "stroke",
    "terra-pinyin",
]

block_template = Template(
    """##@@BEGIN_${name}
${body}
##@@END_${name}"""
)

upstream_template = Template(
    """    - git|${repo}:
        ref: ${ref}
        clonedir: rime-data/${package}"""
)


def fetch_json(url: str) -> Any:
    req = request.Request(url, headers={"User-Agent": "boulder/1.0"})
    with request.urlopen(req, timeout=90) as resp:
        return json.load(resp)


def commit_date(package: str, commit: str) -> datetime.date:
    data = fetch_json(f"{GH_API}/rime/rime-{package}/commits/{commit}")
    landed = data["commit"]["committer"]["date"].replace("Z", "+00:00")
    return datetime.datetime.fromisoformat(landed).astimezone(datetime.UTC).date()


def next_release(stone_content: str) -> int:
    pattern = r"^release[ \t]*:[ \t]*(\d+)[ \t]*$"
    release = re.findall(pattern, stone_content, re.MULTILINE)
    return int(release[0]) + 1


stone_recipe = Path("./stone.yaml")
if not stone_recipe.is_file():
    sys.exit("This script needs to be run in the same directory as a stone.yaml")

# TODO: maybe make this follow path
git = Path("/usr/bin/git")
if not git.is_file():
    sys.exit("git binary not found, please install it from your package manager")

# Read the stone so we can modify it
stone_content = stone_recipe.read_text()

upstreams_block = re.search(
    r"##@@BEGIN_GIT_UPSTREAMS(.*?)##@@END_GIT_UPSTREAMS", stone_content, re.DOTALL
)
if upstreams_block is None:
    sys.exit("No GIT_UPSTREAMS section found in stone.yaml")
current_shas = re.findall(r"ref:\s*([0-9a-fA-F]{40})", upstreams_block.group(1))

logger.info("Resolving upstream refs")
head_shas = []
for package in PACKAGES:
    repo = GIT_URL.format(package=package)
    output = subprocess.run(
        [git, "ls-remote", repo, "HEAD"], capture_output=True, check=True
    ).stdout.decode()
    commit = re.search(r"^([0-9a-f]{40})", output, re.MULTILINE)
    if commit is None:
        sys.exit(f"No HEAD ref found for {repo}")
    head_shas.append(commit.group(1))

if head_shas == current_shas:
    logger.info("Up to date")
    sys.exit(0)

logger.info("Resolving dates of updated revisions")
changed = [
    (package, commit)
    for package, commit in zip(PACKAGES, head_shas)
    if commit not in current_shas
]
if not changed:
    changed = list(zip(PACKAGES, head_shas))
updated = max(commit_date(package, commit) for package, commit in changed)

recorded = re.search(r'version\s*:\s*"0\.0\.0\.(\d{8})"', stone_content)
if recorded is not None:
    previous = datetime.datetime.strptime(recorded.group(1), "%Y%m%d").replace(
        tzinfo=datetime.UTC
    )
    updated = max(updated, previous.date())

version = f"0.0.0.{updated:%Y%m%d}"
release = next_release(stone_content)
logger.info("Updating %s to %s (release %d)", stone_recipe, version, release)

upstreams = "\n".join(
    upstream_template.substitute(
        repo=GIT_URL.format(package=package), ref=commit, package=package
    )
    for package, commit in zip(PACKAGES, head_shas)
)
replacements = {
    "VERSION": block_template.substitute(
        name="VERSION", body=f'version     : "{version}"\nrelease     : {release}'
    ),
    "GIT_UPSTREAMS": block_template.substitute(name="GIT_UPSTREAMS", body=upstreams),
}
for name, replacement in replacements.items():
    stone_content = re.sub(
        rf"##@@BEGIN_{name}.*?##@@END_{name}",
        replacement,
        stone_content,
        flags=re.DOTALL,
    )

stone_recipe.write_text(stone_content)

logger.info("Success!")
