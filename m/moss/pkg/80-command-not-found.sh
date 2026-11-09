command_not_found_handle() {
    local pkgs cmd=$1
    local FUNCNEST=10

    for bin_type in binary sysbinary ; do
        pkg=`NO_COLOR=1 moss pkg info $bin_type\($cmd\) 2>/dev/null`
        if [[ $? -eq 0 ]]; then
            pkg=$(echo "$pkg" | head -n1 | awk {'print $2'})
            local r
            read -r -p "Add package '$pkg' to your implicit system-model? [y/N] " r
            case $r in
                [Yy]* ) ;;
                * ) return 0;;
            esac
            echo " >> sudo moss pkg add '$bin_type($cmd)'"
            sudo moss pkg add "$pkg"
            return
        fi
    done

    printf "bash: %s: command not found\n" $cmd >&2

    return 127
}
