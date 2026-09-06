#!/usr/bin/env python
# SPDX-FileCopyrightText: 2026 AerynOS Developers
# SPDX-License-Identifier: MPL-2.0

import json
import logging
import re
import sys
from pathlib import Path
from string import Template
from typing import Any
from urllib import request

logger = logging.getLogger("update-mozc.py")
logging.basicConfig(level=logging.INFO)

RAW = "https://raw.githubusercontent.com"
GH_API = "https://api.github.com/repos"
FCITX = "https://github.com/fcitx/mozc.git"
MOZC_RAW = f"{RAW}/fcitx/mozc/fcitx"
BCR = "https://github.com/bazelbuild/bazel-central-registry.git"
BAZEL_URL = "https://github.com/bazelbuild/bazel/releases/download"
MOZC_DEPS_YAML = f"{RAW}/fcitx/flatpak-fcitx5/master/mozc-deps.yaml"

version_template = Template(
    """##@@BEGIN_VERSION
version     : "${version}"
##@@END_VERSION"""
)

upstreams_template = Template(
    """##@@BEGIN_GIT_UPSTREAMS
    - git|${fcitx}:
        ref: ${fcitx_sha}
        clonedir: mozc
    - git|${bcr}:
        ref: ${bcr_sha}
        clonedir: bazel-central-registry
##@@END_GIT_UPSTREAMS"""
)

block_template = Template(
    """##@@BEGIN_${name}
${entries}
##@@END_${name}"""
)


def fetch(url: str, tm: int = 90) -> bytes:
    try:
        r_obj = request.Request(url, headers={"User-Agent": "boulder/1.0"})
        with request.urlopen(r_obj, timeout=tm) as r:
            return r.read()
    except (OSError, ValueError) as e:
        sys.exit(f"Fetch failed {url}: {e}")


def fetch_json(url: str) -> Any:
    return json.loads(fetch(url).decode("utf-8"))


def get_sha(repo: str, ref: str) -> str:
    data = fetch_json(f"{GH_API}/{repo}/git/refs/{ref}")
    return data["object"]["sha"]


def parse_version(v: str) -> tuple[int, ...]:
    v = v.split("+", 1)[0]
    return tuple(int(p) for p in v.split("."))


def key_value(text: str, key: str) -> str:
    m = re.search(rf"^{key}\s*=\s*(\S+)", text, re.MULTILINE)
    if m is None:
        sys.exit(f"{key} not found")
    return m.group(1)


def bazel_bin_hash(bv: str) -> tuple[str, str]:
    url = f"{BAZEL_URL}/{bv}/bazel-{bv}-linux-x86_64"
    sha = fetch(url + ".sha256").decode("utf-8")
    m = re.search(r"([0-9a-fA-F]{64})", sha)
    if m is None:
        sys.exit(f"Bazel {bv} has no published .sha256 checksum")
    return url, m.group(1).lower()


def fetch_bazel_deps() -> dict[str, str]:
    yaml_data = fetch(MOZC_DEPS_YAML).decode("utf-8")
    deps = {}
    for m in re.finditer(
        r"- type: file\n\s+url: (\S+)\n\s+dest: bazel-deps\n\s+sha256: ([0-9a-fA-F]{64})",
        yaml_data,
    ):
        deps[m.group(1)] = m.group(2).lower()
    # The flatpak manifest lists both arches
    return {u: h for u, h in deps.items() if "aarch64" not in u and "aarch_64" not in u}


def fmt_entries(entries: dict[str, str]) -> str:
    return "\n".join(
        f"    - {u}:\n        hash: {entries[u]}\n        unpack: false"
        for u in sorted(entries)
    )


stone_recipe = Path("./stone.yaml")
if not stone_recipe.is_file():
    logger.error("This script needs to be run in the same directory as a stone.yaml")
    sys.exit(1)

with open(stone_recipe) as f:
    stone_content = f.read()

m = re.search(r'version\s*:\s*"([^"]+)"', stone_content)
if m is None:
    sys.exit("No version found in stone.yaml")
c_ver = m.group(1)

logger.info("Resolving mozc version")
vbzl = fetch(f"{MOZC_RAW}/src/version.bzl").decode("utf-8")
major = key_value(vbzl, "MAJOR")
minor = key_value(vbzl, "MINOR")
build = key_value(vbzl, "BUILD_OSS")
n_ver = f"{major}.{minor}.{build}.2"

logger.info("Checking mozc version against stone.yaml")
if parse_version(n_ver) == parse_version(c_ver):
    logger.info("Up to date (mozc %s, stone %s)", n_ver, c_ver)
    sys.exit(0)

logger.info("Resolving upstream refs")
f_sha = get_sha("fcitx/mozc", "heads/fcitx")
b_sha = fetch_json(f"{GH_API}/bazelbuild/bazel-central-registry/commits/HEAD")["sha"]

rc = fetch(f"{MOZC_RAW}/src/.bazeliskrc").decode("utf-8")
bv = key_value(rc, "USE_BAZEL_VERSION")

logger.info("Resolving bazel binary")
n_bin_url, n_bin_hash = bazel_bin_hash(bv)

logger.info("Fetching BAZEL_DEPS from mozc-deps.yaml")
n_deps = fetch_bazel_deps()

logger.info("Updating %s", stone_recipe)
replacements = {
    "VERSION": version_template.substitute(version=n_ver),
    "GIT_UPSTREAMS": upstreams_template.substitute(
        fcitx=FCITX, fcitx_sha=f_sha, bcr=BCR, bcr_sha=b_sha
    ),
    "BAZEL_BINARY": block_template.substitute(
        name="BAZEL_BINARY", entries=fmt_entries({n_bin_url: n_bin_hash})
    ),
    "BAZEL_DEPS": block_template.substitute(
        name="BAZEL_DEPS", entries=fmt_entries(n_deps)
    ),
}
for name, replacement in replacements.items():
    stone_content = re.sub(
        rf"##@@BEGIN_{name}.*?##@@END_{name}",
        replacement,
        stone_content,
        flags=re.DOTALL,
    )

with open(stone_recipe, "w") as f:
    f.write(stone_content)
logger.info("Success!")
