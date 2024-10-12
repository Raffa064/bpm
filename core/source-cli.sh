function source_cli() {
  local current_dir="$(dirname $BASH_SOURCE)"

  local sh_file
  for sh_file in $(find $current_dir -regex ".*\.sh"); do
    if [ ! "$sh_file" == "$BASH_SOURCE" ]; then
      source $sh_file
    fi
  done
}

source_cli
