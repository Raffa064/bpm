function bpm/help() {
  if [ -z "$@" ]; then
    echo "bpm help    - Show this dialog"
    echo "bpm version - Display bpm version"
    echo "bpm init    - Creates a new bpm project"
    echo "bpm install - Install project dependencies"
    echo "bpm delete  - Delete some package"
    echo "bpm update  - Update package"
    echo "bpm clean   - Delete all installed packages"
    echo "bpm edit    - Open package.sh"
    echo "bpm list    - List installed packages"
    echo "bpm locator - Update locator index for package"
  else
    help_content="${help[$1]}"
    if [ -z "$help_content" ]; then
      echo -e "\e[31mInvalid help section: $1\e[37m"
    else
      echo -e "$help_content" 
    fi
  fi
}

function bpm/version() {
  echo $BPM_VERSION
}

function bpm/init() {
  echo "Can't init from here"
}

function bpm/list() {
  local term_width=$(tput cols)
  local column_width=$((term_width / 2))
  local -A bpd
    
  printf "\e[34m%-${column_width}s%-${column_width}s\n\e[33m" "Package Name/Version:" "Description:"
  for pkg in $(ls "$BPM_DIR_PATH/deps"); do
    pkgsh/load bpd "$BPM_DIR_PATH/deps/$pkg/package.sh"
    
    pkg_name="${bpd[name]}"
    pkg_version="v${bpd[version]}"
    pkg_description="${bpd[description]}"
    
    name_length=${#pkg_name}
    printf "%-${name_length}s \e[35m%-$((column_width - name_length - 1))s\e[33m%-${column_width}s\n" "$pkg_name" "$pkg_version" "$pkg_description"
  done

  echo -en "\e[37m"
}

function bpm/install() {
  local install_packages=""
  local path=$(pwd)
  local package_sh_path="$(pkgsh/locate_pkg_root $path)/package.sh"

  if [ -z "$package_sh_path" ]; then
    echo -e "\e[33mNOTE: You're installing outside an bpm project.\e[37m"
    read -a install_packages <<< "$@" # Convert argmunts into an indexed array
  else
    if [ -z "$install_packages" ]; then
      echo -e "\e[33mInstaling project dependencies\e[37m"
  
      local dependencies
      pkgsh/loadf dependencies $package_sh_path

      read -a install_packages <<< "$dependencies"
    fi
  fi

  for pkg in "${install_packages[@]}"; do
    echo "pkg: $pkg"
    echo "TODO: locate or install packages here"
    #if ! get_package $pkg; then
    #  echo -e "\e[31mPackage not found: $pkg\e[37m"
    #fi
  done
}

function bpm/locator() {
  local mode="$1"
  local path="$2"

  if [ -z "$path" ]; then
    path=$(pwd)
  fi
  
  case $mode in
    update|-u)
      locator/update
      ;;
    index|-i) # Index package
      if ! locator/index_package $path; then
        echo -e "\e[31mCan't locate package file: $path\e[37m"
      fi
      ;;
    locate|-l)
      locator/locate_package $path
      ;;
    *)
      echo -e "\e[31mInavlid mode: $mode\e[37m"
      ;;
  esac
}

function bpm/uninstall() {
  # TODO: remove executable
  # remove from PATH
  echo "Unimplemented feature"
}

function bpm/leak-test() {
  local env="$(set)"
  cat <<< "$env"
}
