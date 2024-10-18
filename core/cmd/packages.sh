function cmd/init() {
  local path="$1"

  arg/df_path path

  local pkgsh_path=$(pkgsh/locate_pkg_file $path)

  if [ -z "$pkgsh_path" ]; then
    local pkg_name pkg_version pkg_main pkg_deps

    echo -e "\e[33mInitializing a new package\e[37m"
    
    while :; do
      arg/q_input pkg_name "Name" "$pkg_name"
      arg/q_input pkg_version "Version" "${pkg_version-1}"
      arg/q_input pkg_main "Main script" "${pkg_script-main.sh}"
      arg/q_input pkg_dependencies "Dependencies" "$pkg_dependencies"

      local -A pkg=(
        [name]="$pkg_name"
        [version]="$pkg_version"
        [main]="$pkg_main"
        [dependencies]="$pkg_dependencies"
      )

      if locator/is_indexed "$pkg_name"; then
        echo -e "\e[31mInvalid name: Already in use\e[37m"
        pkg_name=""
      else
        pkgsh/create pkg "$path"

        local status=$?

        case $status in
          $PKGSH_INVALID_NAME)
            echo -e "\e[31mInvalid name: Can't use spaces or special characters\e[37m"
            pkg_name=""
            ;;
          $PKGSH_INVALID_VERSION_NUM)
            echo -e "\e[31mInvalid version: It must be a integer number\e[37m"
            pkg_version=""
            ;;
          0)
            locator/index_package $path
            echo -e "\n\e[32mPackage successfully initialized\e[37m"
            echo -e "Use \e[32mbpm package\e[37m to edit package.sh"
            break;
        esac
      fi
    done
  else
    echo -e "\e[33mAlready initialized: $pkgsh_path\e[37m"
  fi
}

function cmd/package() { 
  local path="$1"

  if [ -z "$path" ]; then
    path=$(pwd)
  fi

  local pkgsh_path=$(pkgsh/locate_pkg_file $path)
  
  if [ -z "$pkgsh_path" ]; then
    echo -e "\e[33mYou aren't inside a bpm package\e[37m"
  else
    if [ -z "$EDITOR" ]; then
      echo -e "\e[33mYou don't have a configured editor.\e[37m"
      echo -e "use \e[34m'export EDITOR=\"<your editor>\"'\e[37m to setup it"
    else
      $EDITOR $pkgsh_path
    fi
  fi
}

function cmd/list() {
  cmd/locator -p
}

function cmd/install() {
  local install_packages=""
  local path=$(pwd)
  local pkgsh_path="$(pkgsh/locate_pkg_file $path)"

  if [ -z "$pkgsh_path" ]; then
    echo -e "\e[33mNOTE: You're installing outside an bpm project.\e[37m"
    read -a install_packages <<< "$@" # Convert argmunts into an indexed array
  else
    if [ -z "$install_packages" ]; then
      echo -e "\e[33mInstaling project dependencies\e[37m"
  
      local dependencies
      pkgsh/loadf dependencies $pkgsh_path

      read -a install_packages <<< "$dependencies"
    fi
  fi

  local pkg_path
  for pkg_path in "${install_packages[@]}"; do
    echo "pkg: $pkg_path"
    echo "TODO: locate or install packages here"
    #if ! get_package $pkg; then
    #  echo -e "\e[31mPackage not found: $pkg\e[37m"
    #fi
  done
}
