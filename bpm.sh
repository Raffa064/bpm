#!/bin/bash

source_core_scripts

bpm_command="cmd/$1"

if [ ! "$bpm_command" == "cmd/fix" ]; then
  locator/init
fi

if declare -f "$bpm_command" >/dev/null; then
  shift
  $bpm_command "$@"
else
  cmd/help
  echo -e "\e[31mInvalid option: $1\e[37m"
fi

# Preventing to delete the entire root path
if [ ! -z "$BPM_TMP_DIR_PATH" ]; then
  rm -rf "$BPM_TMP_DIR_PATH/*" 
fi
