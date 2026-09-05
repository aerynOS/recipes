<!--
# SPDX-FileCopyrightText: 2026 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0
-->

# Updating LibreOffice

Do not edit the version, source, or vendored sections of `stone.yaml` by hand.
Those blocks are generated.

From this directory, run:

```
./update-libreoffice.py <version>
```

Replace `<version>` with the new LibreOffice version.

The script downloads the source, dictionaries, help, and translations tarballs,
refreshes their hashes, and regenerates the vendored external sources. After it
finishes, `stone.yaml` is fully updated for the new version.
