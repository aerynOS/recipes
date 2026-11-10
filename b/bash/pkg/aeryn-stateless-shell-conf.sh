#!/usr/bin/sh
#
# Begin /usr/share/defaults/aeryn-stateless-shell-conf.sh

# The idea is that all shells are built/patched to have their startup
# scripts look inside /usr/share/defaults/(...) for their preferred
# system-level default initialization files.

# For bash, this implies a fan-in configuation where both
# /usr/share/defaults/profile and /usr/share/defaults/bashrc
# source the present file, so as to ensure that there is no difference
# in the experience whether a user logs in via getty, via sshd or opens
# a new virtual terminal in a desktop environment.
#
# This should make testing configuration changes more straightforward.
#
# In addition, it does away with the need to ship skeleton files, which
# are a 3-way merge nightmare for users to keep up to date in the face of
# upstream changes.
#
# Instead, users can just drop in their changes in ~/.*sh.d/ directories
# which match their shell and are automagically sourced from this file.

# Files in the below dir MUST be in portable .sh format!
if [ -d /usr/share/defaults/profile.d ] ; then
    for script in /usr/share/defaults/profile.d/*.sh
    do
      source $script
    done
    unset script
fi

# Files in the below dir MUST be in portable .sh format!
if [ -d /etc/profile.d ] ; then
    for script in /etc/profile.d/*.sh
    do
      source $script
    done
    unset script
fi

# Contents of the below file MUST be in portable .sh format!
if [ -f /etc/profile ] ; then
    source /etc/profile
fi

unset _shprefix

# Support bash
if [ -n "$BASH_VERSION" ] ; then
    _shprefix=ba
# Support zsh
elif [ -n "$ZSH_VERSION" ] ; then
    _shprefix=z
# elif [ add tests for other supported POSIX sh compatible shells here ] ; then
fi

if [ -n "$_shprefix" ] ; then
    if [ -e /etc/"$_shprefix"shrc ] ; then
        source /etc/"$_shprefix"shrc
    fi
    # Here mostly for zsh compatibility but doesn't hurt.
    if [ -e /etc/"$_shprefix"sh/"$_shprefix"shrc ] ; then
        source /etc/"$_shprefix"sh/"$_shprefix"shrc
    fi

    # https://uapi-group.org/specifications/specs/linux_file_system_hierarchy/ (UAPI.9)
    # mandates that systemd systems should offer ~/.local/bin as part of PATH;
    # see also the output of 'systemd-path user-binaries'.
    # Note that putting the PATH change here makes user-binaries available to
    # any user-specific shell drop-ins below. By default, they will *not*
    # override existing system-binaries.
    if [ -n "$HOME" ]; then
        user_binaries="$HOME/.local/bin"
        # only add ^ to PATH if it is not already present.
        case :${PATH}:
            in *:${user_binaries}:*) ;;
            *) export PATH="$PATH:$user_binaries" ;;
        esac
        unset user_binaries
    fi

    # We want to source all files ending in sh, like *.sh, *.bash, *.zsh etc.
    #
    # This enables users to add e.g. a `.disabled` extension to scripts
    # (or remove `sh` extensions from scripts or links to scripts) to disable
    # them temporarily, which can be handy when troubleshooting.
    #
    if [ -d ~/."$_shprefix"shrc.d ]; then
        for rc in ~/."$_shprefix"shrc.d/*sh; do
            if [ -f "$rc" ]; then
                source "$rc"
            fi
        done
        unset rc
    fi
fi

unset _shprefix
# End /usr/share/defaults/aeryn-stateless-shell-conf.sh
