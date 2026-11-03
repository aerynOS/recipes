#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2023 Silke Hofstra
# SPDX-FileCopyrightText: 2024 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0

import argparse
import json
import os
import re
import subprocess
import sys
from typing import Any

scope_help = "# Scope and title, eg: nano: Update to v1.2.3\n"
help_msg = """

# Describe or link the changes here, for example:
#   - Resolves a bug
# You may also link to a changelog, for example:
#   Release notes can be found [here](https://example.com).

# Uncomment and fill in the following if this update includes security fixes:
# **Security**
# - CVE-

# For non-functional changes e.g. stone.yaml cleanup, use [NFC] in the title.
"""

FLAGS = re.VERBOSE | re.MULTILINE | re.DOTALL

WHITESPACE = re.compile(r'[ \t\n\r]*', FLAGS)
WHITESPACE_STR = ' \t\n\r'


class JSONWithCommentsDecoder(json.JSONDecoder):
    def __init__(self, **kw):
        super().__init__(**kw)

    def decode(self, s: str, _w=WHITESPACE.match) -> Any:
        s = '\n'.join(l for l in s.split('\n') if not l.lstrip(' ').startswith('/**'))
        return super().decode(s)


def commit_scope(commit_dir: str) -> str:
    if os.path.exists(os.path.join(commit_dir, 'stone.yaml')):

        recipe_diff_result = subprocess.run(['git', 'diff', '-U0', '--staged', os.path.join(commit_dir, 'stone.yaml')], stdout=subprocess.PIPE)
        if "+version" in recipe_diff_result.stdout.decode('utf-8'):
            # TODO: how to handle different ARCH manifests in future?
            with open(os.path.join(commit_dir, 'manifest.x86_64.jsonc')) as manifest:
                try:
                    data = json.load(manifest, cls=JSONWithCommentsDecoder)
                    version = data["source-version"]
                    if data["source-release"] == "1":
                        return os.path.basename(commit_dir) + ': Add at v' + str(version)
                    return os.path.basename(commit_dir) + ': Update to v' + str(version)
                except json.JSONDecodeError as e:
                    print(e)

        # Detect non-functional changes ([NFC])
        staged_files_result = subprocess.run(['git', 'diff', '--name-only', '--staged', commit_dir], stdout=subprocess.PIPE)
        if 'stone.yaml' in staged_files_result.stdout.decode('utf-8') and \
            not 'manifest.x86_64.jsonc' in staged_files_result.stdout.decode('utf-8'):
            return "[NFC] " + os.path.basename(commit_dir) + ': '

        return os.path.basename(commit_dir) + ': '

    return ''


def template(commit_dir: str, contents: str) -> str:
    return scope_help + commit_scope(commit_dir) + help_msg


def current_message(file: str) -> str:
    with open(file, 'r') as f:
        return f.read()


def render_template(file: str, commit_dir: str) -> None:
    contents = current_message(file)

    with open(file, 'w') as f:
        f.write(template(commit_dir, contents))
        f.write(contents)


def write_auto_commit_msg(file: str, commit_dir: str) -> None:
    with open(file, 'w') as f:
        f.write(commit_scope(commit_dir))


def is_auto_commit_msg(file: str) -> bool:
    contents = current_message(file).strip()

    if contents == "autocommitmsg":
        return True
    return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('file', type=str,
                        help='File containing the commit log message')
    parser.add_argument('source', type=str, nargs='?',
                        help='Source of the commit message')
    parser.add_argument('object', type=str, nargs='?',
                        help='Object name, if a `-c`, `-C` or `--amend` was given')
    args = parser.parse_args()
    pwd = os.getenv('PWD') or '/'

    match args.source:
        case 'template' | 'merge' | 'squash' | 'commit':
            pass
        case 'message':
            if is_auto_commit_msg(args.file):
                write_auto_commit_msg(args.file, pwd)
            else:
                pass
        case _:
            render_template(args.file, pwd)
