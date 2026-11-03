#!/bin/sh
# SPDX-FileCopyrightText: 2024 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0

# https://gitlab.gnome.org/GNOME/releng/-/blob/master/tools/versions-stable?ref_type=heads
# manually match up names as required

GNOME_PKGS="
adwaita-icon-theme
at-spi2-core
baobab
font-cantarell
d-spy
dconf
dconf-editor
devhelp
epiphany
evince
evolution-data-server
folks
gcab
gcr
gcr-3
gdk-pixbuf
gdm
geocode-glib
gexiv2
gi-docgen
gjs
glib2
glib-networking
glibmm
gmime
gnome-autoar
gnome-backgrounds
gnome-bluetooth
gnome-boxes
gnome-builder
gnome-calculator
gnome-calendar
gnome-characters
gnome-clocks
gnome-color-manager
gnome-connections
gnome-console
gnome-contacts
gnome-control-center
gnome-desktop
gnome-disk-utility
gnome-font-viewer
gnome-keyring
gnome-logs
gnome-maps
gnome-menus
gnome-music
gnome-online-accounts
gnome-remote-desktop
gnome-session
gnome-settings-daemon
gnome-shell
gnome-shell-extensions
gnome-software
gnome-system-monitor
gnome-text-editor
gnome-user-docs
gnome-user-share
gnome-weather
gobject-introspection
gom
grilo
grilo-plugins
gsettings-desktop-schemas
gsound
gspell
gssdp
gtk-3
gtk-4
gtk-doc
gtk-vnc
gtkmm-4
gtksourceview
gtksourceview4
gupnp
gupnp-av
gupnp-dlna
gvfs
json-glib
jsonrpc-glib
libadwaita
libdex
libgee
libgsf
libgtop
libgweather
libgxps
libhandy
libmediaart
libnma
libnotify
libpanel
libpeas
libpeas-2
librest
librsvg
libsecret
libshumate
libsigc++
libsoup
loupe
mm-common
mutter
nautilus
orca
pango
pangomm
phodav
pyatspi2
python-pygobject
rygel
simple-scan
snapshot
gnome-sushi
sysprof
tecla
template-glib
totem
totem-pl-parser
localsearch
tinysparql
vala
vte
xdg-desktop-portal-gnome
yelp
yelp-tools
yelp-xsl
"

FAILED=""

for i in ${GNOME_PKGS}; do

    cd $(git rev-parse --show-toplevel)/*/${i} || continue

    name=$(yq '.name' stone.yaml)
    version=$(yq '.version' stone.yaml)
    stable_version=$(curl -s -H "Accept: application/json" https://release-monitoring.org/api/v2/versions/?project_id=`yq '.releases.id' monitoring.yaml` | jq -r '.stable_versions[:1]' | jq -c '.[]')

    # Strip any quotes and replace underscores with dots
    stable_version=${stable_version//\"/}
    stable_version=${stable_version//\'/}
    new_version=${new_version//_/.}
    version=${version//\"/}
    version=${version//\'/}

    if [ "$version" == "$stable_version" ]; then
        echo "$name: Version $version matches latest stable"
    else
        echo "$name: Version $version does not match latest stable $stable_version"
        FAILED+="${i} "
    fi
done

echo "The following gnome pkgs are not up to date: ${FAILED}"
