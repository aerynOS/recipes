##
## Load flyline in interactive bash
##

# flyline only loads in interactive shells
case "$-" in
    *i*) ;;
    *) return 0 ;;
esac

[ -n "$BASH_VERSION" ] || return 0

# Loadables are per-process, so always enable. No-op if already loaded.
enable flyline 2>/dev/null || enable -f /usr/lib/bash/flyline flyline 2>/dev/null || :
