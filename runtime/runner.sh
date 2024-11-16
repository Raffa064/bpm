function run/main() {
  local pkg_path="$1"
  shift

  local -A pkg
  pkgsh/load pkg "$pkg_path/package.sh"

  if [ -z "${pkg[main]}" ]; then
    echo -e "\e[33mCan't run package: There is no main script\e[37m"
    return
  fi

  # Look for dependencies to build import sheet
  import/init "${pkg[dependencies]}"
  import/add_package "${pkg[name]}" "$pkg_path/src"

  declare -g DIR_NAME="$(pwd)"
  declare -g RUNNER_PACKAGE="${pkg[name]}"
  declare -g RUNNER_DIR="$pkg_path"
  declare -g TMPDIR="$HOME/.local/.bpm/tmp"

  # run main script
  local main_script
  import/resolve main_script "${pkg[name]}" "${pkg[main]}"
  
  if [ -e "$main_script" ]; then
    source $main_script

    main_function="${pkg[name]}/main"
    if declare -f "$main_function" >/dev/null; then
      $main_function $@
    else
      echo -e "\e[31mPackage main function is not found: $main_function\e[37m"
      return
    fi
  else
    echo -e "\e[31mCan't run package main script\e[37m"
    return
  fi
}
