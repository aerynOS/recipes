#!/usr/bin/env bash

_FRONTEND=lichen-cli
_BACKEND=lichen_backend
SOCKET=/run/lichen.sock

# The privileged backend owns all installer logic; the frontend runs unprivileged.
pkexec ${_BACKEND} > /dev/null 2>&1 &
sleep 0.5s

PARSED=$(getopt -o i:s:hV --long install-model,system-model,help,version -n "$0" -- "$@")

if [ $? -ne 0 ]; then
  ${_FRONTEND} -h
  exit 0
fi

# Reset positional parameters to the parsed output
eval set -- "$PARSED"

# Process the options sequentially
INSTALL_MODEL=""
SYSTEM_MODEL=""

while true; do
  case "$1" in
    -i|--install-model)
      INSTALL_MODEL="$2"
      shift 2
      ;;
    -s|--system-model)
      SYSTEM_MODEL="$2"
      shift 2
      ;;
    -h|--help)
      ${_FRONTEND} -h
      exit 0
      ;;
    -V|--version)
      ${_FRONTEND} -V
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

echo "INSTALL_MODEL: $INSTALL_MODEL"
echo "SYSTEM_MODEL: $SYSTEM_MODEL"

LICHEN_ARGS=()

[[ -n "$INSTALL_MODEL" ]] && LICHEN_ARGS+=("-i" "$INSTALL_MODEL")
[[ -n "$SYSTEM_MODEL" ]] && LICHEN_ARGS+=("-s" "$SYSTEM_MODEL")

echo "${LICHEN_ARGS[@]}"

${_FRONTEND} "${LICHEN_ARGS[@]}"

if [[ $? -ne 0 ]]; then
  echo
  read -p "Press any key to exit..."
fi
