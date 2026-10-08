<!--
# SPDX-FileCopyrightText: 2025 AerynOS Developers
# SPDX-License-Identifier: MPL-2.0
-->

## This is a list of packages that should be removed from the repo once moss supports package removal

NB: Each entry *must* contain all sub-packages created by the package!

### Moved into other gcc packages
- gcc-devel
- gcc-32bit-devel

### Replaced by sdl2-compat
- sdl2
- sdl2-devel
- sdl2-dbginfo

### Replaced by mesa-clc
- intel-clc
- intel-clc-dbginfo

### Merged into llvm package
- libcxx-dbginfo
- llvm-bolt-dbginfo

### GDB didn't actually have any devel files
- gdb-devel

### Don't need
- libfuse2-32bit
- libfuse2-32bit-dbginfo
- libfuse2-32bit-devel

### Split into gtk3/gtk4 specific packages
- vte
- vte-devel

### Nodejs is now a meta-package that doesn't need headers
- nodejs-devel

### Not used
- python-32bit
- python-32bit-devel
- python-32bit-dbginfo

### Now part of linux-tools
- perf-dbginfo

### man3 is used by perl
- perl-parse-yapp-devel
- perl-xml-parser-devel
- perl-uri-devel

### Never used
- libxcomposite-32bit
- libxcomposite-32bit-dbginfo
- libxcomposite-32bit-devel
- libxdamage-32bit
- libxdamage-32bit-dbginfo
- libxdamage-32bit-devel
- libxdmcp-32bit
- libxdmcp-32bit-dbginfo
- libxdmcp-32bit-devel
- libxinerama-32bit
- libxinerama-32bit-dbginfo
- libxinerama-32bit-devel
- libxtst-32bit
- libxtst-32bit-dbginfo
- libxtst-32bit-devel

### Actually checked for by cmake
- sdl2-compat-staticlib

### Renamed and split
- linux-firmware-amd
- linux-firmware-intel
- linux-firmware-nvidia

### Split
- mesa-devel

### Split
- pulseaudio

### Double packaged
- pycairo
- pycairo-devel

### Split
- gnome-desktop
- gnome-desktop-devel

### No longer used apparently
- vulkan-volk

### freerdp was the last revdep of this and it uses sdl3-ttf now
- sdl2-ttf
- sdl2-ttf-devel
- sdl2-ttf-dbginfo

### Upstream split to new qgpgme package
- gpgme-qt6
- gpgme-qt6-devel

### No longer generated
- vscode-bin-dbginfo

### Replaced by libdbusmenu-docs
- libdbusmenu-gtk3-docs

### Split to subpackages
- glycin
- glycin-devel

### Renamed to jpegxl-dbginfo
- libjxl-dbginfo

### Replaced by gamescope
- gamescope-plus
- gamescope-plus-devel
- gamescope-plus-dbginfo

### Renamed to libgs-devel
- ghostscript-devel

### Now built in at-spi2-core
- at-spi2-atk-dbginfo

### Replaced by mozjs-140
- mozjs-128
- mozjs-128-devel
- mozjs-128-dbginfo

### Obsoleted by glycin
- heif-pixbuf-loader
- jxl-pixbuf-loader

### Not built since switching to meson build
- usbutils-devel

### No longer used
- autocc
- autocc-dbginfo

### Not built as of Boost 1.89
- boost-system

### Deprecated upstream
- docker-scan
- docker-scan-dbginfo

### No longer built
- gst-plugins-rs-devel

### Merged into the mighty llvm omni-package
- lldb-dbginfo

### No longer used
- hyper-ffi
- hyper-ffi-devel
- hyper-ffi-32bit
- hyper-ffi-32bit-devel
- hyper-ffi-dbginfo
- rustls-ffi
- rustls-ffi-devel
- rustls-ffi-32bit
- rustls-ffi-32bit-devel
- rustls-ffi-dbginfo

### Renamed
- prismlauncher
- intel-vaapi-driver

### No longer used
- python-ruamel-yaml-clib
- python-ruamel-yaml-clib-dbginfo

### Renamed
- gnome-online-accounts-devel

### No longer used
- xwaylandvideobridge
- xwaylandvideobridge-dbginfo

### Not built
- scx-scheds-devel

### Renamed
- nfs-utils-devel

### Merged into main package
- cli11-devel

### Renamed/Rebranded upstream
- mangowc
- mangowc-dbginfo

### Devel-only, merged with libclc
- libclc-devel

### Not needed
- spirv-llvm-translator-32bit
- spirv-llvm-translator-32bit-devel
- spirv-llvm-translator-32bit-dbginfo

### These were internal build tools all along
- libde265-examples

### Removed in ffmpeg 8.0
- libpostproc
- libpostproc-devel

### Not needed in newer Python
- python-backports.tarfile

### Replaced by linux-stable
- linux-desktop
- linux-desktop-devel
- linux-desktop-dbginfo
- linux-kvm
- linux-kvm-devel
- linux-kvm-dbginfo

### Relpaced by linux-gaming
- linux-handheld
- linux-handheld-devel
- linux-handheld-dbginfo

### Whoops
- "$(name)-devel"

### Merged into GCC
- libatomic-static
- libatomic-32bit-static

### Deprecate (use gst-thumbnailers instead)
- ffmpegthumbnailer
- ffmpegthumbnailer-dbginfo
- ffmpegthumbnailer-devel

### No longer used
- yajl
- yajl-devel
- yajl-dbginfo

### Provided by pipewire
- libjack2
- libjack2-devel
- jack2-dbginfo

### Renamed to vlc-plugin-jack
- vlc-plugin-jack2

### Renamed
- systemd-32bit
- systemd-32bit-devel
- systemd-devel

### Merged into libjpeg-turbo-devel
- turbojpeg-devel

### Replaced by malm
- ferrite
- ferrite-dbginfo

### Replaced by gnist
- oxidize
- oxidize-dbginfo

### Replaced by kf6-kmime
- kmime
- kmime-devel
- kmime-dbginfo

### Replaced by mesa-libclc
- libclc

### No longer used
- hyprland-qt-support
- hyprland-qt-support-dbginfo

### No longer built
- gvfs-afp
- gvfs-archive

### Refactored so the session files are in labwc
- labwc-session

### Renamed to cosmic-app-library
- cosmic-applibrary
- cosmic-applibrary-dbginfo
