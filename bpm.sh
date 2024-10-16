#!/bin/bash

source_core_scripts

declare -gA help_sections
source $BPM_DOCS_PATH

locator/init

bpm_command="cmd/$1"

if declare -f "$bpm_command" >/dev/null; then
  shift
  $bpm_command "$@"
else
  cmd/help
  echo -e "\e[31mInvalid option: $1\e[37m"
fi
