<!--
# SPDX-FileCopyrightText: 2026 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0
-->

## Maintainer notes for systemd

It is preferable to update systemd before doing kernel builds, if a minor systemd
update is available (major.minor version).

We only recommend proactively doing a round of kernel rebuilds in the event of:

- a major systemd version update,
- a cve that affects the boot process,
- or some kind of fix in systemd-boot or the uefi stub that's relevant to us.
