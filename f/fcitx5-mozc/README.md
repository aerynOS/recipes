<!--
# SPDX-FileCopyrightText: 2026 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0
-->

# Updating fcitx5-mozc

Do not edit the version, source, or vendored sections of `stone.yaml` by hand.
Those blocks are generated.

From this directory, run:

```
./update-mozc.py
```

Script automatically resolves `%(version)` from version.bzl. If no update, script exits.

If an update is available, the script fetches https://raw.githubusercontent.com/fcitx/flatpak-fcitx5/master/mozc-deps.yaml
and updates download urls and hashes for the bazel deps and rewrites `stone.yaml` (From Arch). Also updates bazel central repo and bazel version used from .bazeliskrc
