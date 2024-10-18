function run/main() {
  local pkg_path="$1"
  shift

  local -A pkg
  pkgsh/load pkg "$pkg_path/package.sh"

  # Look for dependencies to build import sheet
  import/init "${pkg[dependencies]}"
  import/add_package "${pkg[name]}" "$pkg_path/src"

  # run main script
  local main_script
  import/resolve main_script "${pkg[name]}" "${pkg[main]}"
  
  if [ -e "$main_script" ]; then
    source $main_script

    main_function="${pkg[name]}/main"
    $main_function $@
  else
    echo -e "\e[31mCan't run package main script\e[37m"
  fi
}
