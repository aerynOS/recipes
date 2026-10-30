<!--
# SPDX-FileCopyrightText: 2026 AerynOS Developers
# SPDX-License-Identifier: MPL-2.0
-->

# Update order

Suggested update order for the Podman stack (dependencies first):

- catatonit
- conmon
- crun
- passt
- aardvark-dns
- netavark
- containers-common
- skopeo
- buildah
- podman

`catatonit`, `conmon`, `crun`, and `passt` are independent leaves and can be updated in any order among themselves.

Netavark v2 drops iptables (nftables only) and changes default network isolation. Update aardvark-dns alongside netavark on the same minor.
