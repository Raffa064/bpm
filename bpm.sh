source_core

locator/init

bpm_command="bpm/$1"

if declare -f "$bpm_command" >/dev/null; then
  shift
  $bpm_command "$@"
else
  bpm/help
  echo -e "\e[31mInvalid option: $1\e[37m"
fi
