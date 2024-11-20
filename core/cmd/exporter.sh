function cmd/export() {
  local pkg_name="$1"

  if locator/is_indexed "$pkg_name"; then
    # TODO: look for main
    local script_path="$BPM_EXPORT_DIR_PATH/$pkg_name"
    echo "bpm run $pkg_name \$@" > "$script_path"
    chmod 700 $script_path
    echo -e "\e[32mSucessfully exported\e[37m"
  else
    echo -e "\e[31mCan't locate package: $pkg_name\e[37m"
  fi
}

function cmd/unexport() {
  local pkg_name="$1"

  local script_path="$BPM_EXPORT_DIR_PATH/$pkg_name"
  if [ -e "$script_path" ]; then
    rm "$script_path"
    echo "\e[32mSucessfully removed from exports\e[37m"
  else
    echo -e "\e[31mRequested package haven't been exported\e[37m"
  fi
}

function cmd/list-exported() {
  ls "$BPM_EXPORT_DIR_PATH"
}
