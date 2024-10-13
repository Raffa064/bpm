function bpm/help() {
  if [ -z "$@" ]; then
    bpm/help bpm
  else
    help_content="${help_sections[$1]}"
    if [ -z "$help_content" ]; then
      echo -e "\e[31mInvalid help section: $1\e[37m"
    else
      title=$(sed -n "1p" <<< "$help_content")
      command=$(sed -n "3p" <<< "$help_content")
      description=$(sed "1,3d" <<< "$help_content")

      local highlighted="\n\e[35m# $title\n\n \e[32m$\e[36m $command\e[33m\n$description\e[37m\n"

      highlighted=$(sed 's/"\([^"]*\)"/\\e[32m"\1"\\e[33m/g' <<< "$highlighted")   # "TEXT" 
      highlighted=$(sed 's/>\([^<]*\)</\\e[36m\1\\e[33m/g' <<< "$highlighted") # >TEXT<
      highlighted=$(sed 's/&lt;/</g' <<< "$highlighted") # <
      highlighted=$(sed 's/&gt;/>/g' <<< "$highlighted") # >
      
      echo -e "$highlighted"
    fi
  fi
}

function bpm/version() {
  echo $BPM_VERSION
}

function bpm/init() {
  local path="$1"

  arg/df_path path

  local pkgsh_path=$(pkgsh/locate_pkg_file $path;)

  if [ -z "$pkgsh_path" ]; then
    echo "TODO: Init package dialog"
  else
    echo -e "\e[33mAlready initialized: $pkgsh_path\e[37m"
  fi
}

function bpm/package() { 
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
      ;;
    remove|-r)
      local curr_pkg_name
      pkgsh/loadf curr_pkg_name "name" "$(pwd)"
      arg/df mode_arg "$curr_pkg_name" 
      locator/remove $mode_arg
      ;;
    locate|-l)
      locator/locate_package $mode_arg
      ;;
    *)
      bpm/help locator
      echo -e "\e[31mInvalid mode: $mode\e[37m"
      ;;
  esac
}

function bpm/uninstall() {
  echo -e "\e[32mState and installed packages will not be deleted."
  echo -e "\e[33mUninstalling executable scripts....\e[37m"
  rm $BPM_BIN_PATH
  rm -rf "$BPM_DIR_PATH/core"
}

function bpm/leak-test() {
  local env="$(set)"
  cat <<< "$env"
}
