#!/bin/sh

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/lua-language-server"
exec /usr/lib/lua-language-server/bin/lua-language-server \
  --logpath="$CACHE_DIR/log" \
  --metapath="$CACHE_DIR/meta" \
  "$@"
