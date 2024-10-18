function cmd/run() {
  local path="$1"

  shift
  local args
  read -a args <<< "$@"

  arg/df_path path                                       # Use arg path or $(pwd)
  arg/df path "$(locator/locate_package $path)" "$path"  # Use arg path as module name and load path ffrom locator

  local pkg_path=$(pkgsh/locate_pkg_root $path)

  if [ -e "$pkg_path" ]; then
    bash $BPM_RUNNER_PATH $pkg_path ${args[@]}
  else
    echo -e "\e[31mCan't locate package file: $path\e[37m"
  fi
}
