function source_cli() {
  local current_dir="$(dirname $BASH_SOURCE)"

  local path
  for path in $(find $current_dir -regex ".*\.sh"); do
    if [ ! "$path" == "$BASH_SOURCE" ]; then
      source $path
    fi
  done

  for path in $(find "$current_dir/doc" -regex ".*\.txt"); do
    if [ ! "$path" == "$BASH_SOURCE" ]; then
      local section=$(basename "$path")
      section="${section%.*}"
      help_sections["$section"]=$(cat $path)
    fi
  done
}

source_cli
