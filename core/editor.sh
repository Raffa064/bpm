function editor/load_defaults() {
  if [ -z "$EDITOR" ]; then
    local common_editors=(lvim nvim nano vim vi)
    local cmd
    for cmd in "${common_editors[@]}"; do
      local path=$(command -v "$cmd")
      local status=$?

      if [ $status -eq 0 ]; then
        if [ -e "$path" ]; then
          export EDITOR="$cmd"
          return 0
        fi
      fi
    done

    return 1
  fi
}

function editor/open() {
  local files="$@"

  if ! editor/load_defaults; then
    echo -e "\e[31mNo default editor is set.\e[37m"
    echo -e "\e[33mUse 'export EDITOR=<editor-command>'.\e[37m"
    return 1
  fi

  $EDITOR $EDITOR_ARGS $files
}
