<!--
# SPDX-FileCopyrightText: 2026 AerynOS Developers
# SPDX-License-Identifier: MPL-2.0
-->

# Updating librime-data

Do not edit the version, release or upstream sections of `stone.yaml` by
hand. Those blocks are generated.

From this directory, run:

```
./update-librime-data.py
```

The script resolves the current `HEAD` of each rime schema repo with
`git ls-remote`, looks up the landing date of the updated revisions via the
GitHub API, and rewrites the version and upstream blocks in `stone.yaml`.

The version is the latest date ANY of the subpackages are updated
(`0.0.0.YYYYMMDD`), and is shared, so all schemas are updated together.
