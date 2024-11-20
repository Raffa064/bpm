#!/bin/bash

source_core_scripts

if [ -e "$BPM_INSTALL_LOCK_PATH" ]; then
  echo "BPM installer is running..."
  echo "Lock file at: $BPM_INSTALL_LOCK_PATH"
  exit
fi

bpm_command="cmd/$1"

if [ ! "$bpm_command" == "cmd/fix" ]; then
  locator/init
fi

exit_status=0
if declare -f "$bpm_command" >/dev/null; then
  shift
  $bpm_command "$@"
  exit_status=$?
else
  cmd/help
  echo -e "\e[31mInvalid option: $1\e[37m"
  exit_status=1
fi

if [ ! -z "$BPM_TMP_DIR_PATH" ]; then  # Preventing to delete the entire root path
  rm -rf "$BPM_TMP_DIR_PATH"/* 
fi

exit $exit_status
