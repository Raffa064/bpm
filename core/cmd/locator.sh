cmp_locator="print update index remove locate"
function cmd/locator() {
  local mode="$1"
  local mode_arg="$2"

  case $mode in
    print|-p)
      locator/print_index
      ;;
    update|-u)
      locator/update
      ;;
    index|-i) # Index package
      arg/df_path mode_arg
      locator/index_package $mode_arg
      local status=$?
      case $status in
        $PKGSH_INVALID_PACKAGE)
          echo -e "\e[31mCan't locate package.sh\e[37m"
          ;;
        $PKGSH_INVALID_NAME)
          echo -e "\e[31mInvalid package name\e[37m"
          echo -e "\e[33mNOTE: package name must be a non empty string, without spaces and special characters\e[37m"
          ;;
        $PKGSH_INVALID_VERSION_NUM)
          echo -e "\e[31mInvalid package version: must be a valid number\e[37m"
          ;;
        *)
          echo -e "\e[32mPackage index sucessfully updated\e[37m"
          ;;
      esac
      return $status
      ;;
    remove|-r)
      local curr_dir="$(pwd)"
      local pkgsh_path=$(pkgsh/locate_pkg_file $curr_dir)
      local curr_pkg_name
      pkgsh/loadf curr_pkg_name "name" "$pkgsh_path"
      arg/df mode_arg "$curr_pkg_name" 
      locator/remove $mode_arg
      ;;
    locate|-l)
      locator/locate_package $mode_arg
      ;;
    *)
      cmd/help locator
      echo -e "\e[31mInvalid mode: $mode\e[37m"
      ;;
  esac
}

function cmd/deps() {
  local path="$1"
  arg/df_path path

  local pkgsh_path=$(pkgsh/locate_pkg_file $path)

  if [ -z "$pkgsh_path" ]; then
    echo -e "\e[31mCan't locate package file: $path\e[37m"
  else
    local pkg_name
    pkgsh/loadf pkg_name "name" "$pkgsh_path"
    
    local output=$(locator/dependencies "$pkg_name")
    read -a output <<< "$output"

    for dep in "${output[@]}"; do
      echo "$dep"
    done
  fi
}
