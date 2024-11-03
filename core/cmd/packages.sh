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
      arg/q_input pkg_main "Main script" "${pkg_main}"
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

            if [ ! -z "$pkg_main" ]; then
              local main_path=$(sed "s@\\.@/@g" <<< "$pkg_main")
              main_path="$path/src/$main_path.sh"
              mkdir -p $(dirname $main_path)
              echo -e "function $pkg_name/main() {\n  echo \"Hello world\"\n}" > "$main_path"
            else
              mkdir -p "$path/src"
            fi

            git init $path >/dev/null 2>&1

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

function cmd/remove() {
  local packages="$@"
  read -a packages <<< "$packages"

  local trash_dir="$BPM_CACHE_DIR_PATH/trash"
  mkdir -p "$trash_dir"

  echo "Removing packages..."
  local pkg_name
  for pkg_name in "${packages[@]}"; do
    local pkg_path=$(locator/locate_package $pkg_name)
    if [ -n "$pkg_path" ]; then
      echo -e "  \e[33m* Moving '$pkg_name' to trash...\e[37m"
      locator/remove "$pkg_name"
      
      echo "$pkg_path" >> "$pkg_path/.path"
      mv "$pkg_path" "$trash_dir/$pkg_name"
    else
      echo -e "  \e[31m* Package $pkg_name not found:\e[37m"
    fi
  done

  cd $trash_dir
  zip -r "../trash.zip" "." >/dev/null 2>&1
  rm -rf "$trash_dir"

  echo -e "\e[34mRun 'bpm clean' to delete packages\e[37m"
}

function cmd/restore() {
  local pkg_name="$1"
  local pkg_path="$2"

  local trash_path="$BPM_CACHE_DIR_PATH/trash.zip" 
  if [ -e "$trash_path" ] && [[ ! "$(unzip -l $trash_path 2>&1)" =~ "is empty" ]]; then  
    cd $BPM_CACHE_DIR_PATH
    unzip trash.zip "$pkg_name/*" >/dev/null 2>&1
    local status=$?

    if [ $status -eq 0 ]; then
      zip -d trash.zip "$pkg_name/*" >/dev/null 2>&1

      if [ -z "$pkg_path" ]; then
        pkg_path=$(cat "$pkg_name/.path")
      fi

      rm "$pkg_name/.path"

      mkdir -p $(dirname $pkg_path)
      mv "$pkg_name" "$pkg_path"
      cmd/locator -i $pkg_path
    else
      echo -e "\e[31mNot found: $pkg_name\e[37m"
    fi
  else
    echo -e "\e[33mTrash is empty\e[37m"
  fi
}

function cmd/clean() {
  local trash_path="$BPM_CACHE_DIR_PATH/trash.zip"
  if [ -e "$trash_path" ]; then
    local size=$(du -sh $trash_path | cut -f1)
    echo "Cleaning trash... $size"
    rm "$trash_path"
  else
    echo "Nothing to clear"
  fi
}

function cmd/list() {
  cmd/locator -p
}

function cmd/install() {
  local install_packages="$@"
  local path=$(pwd)
  local pkgsh_path="$(pkgsh/locate_pkg_file $path)"

  if [ -z "$pkgsh_path" ]; then
    read -a install_packages <<< "$@" # Convert argmunts into an indexed array
  else
    if [ -z "$install_packages" ]; then
      echo -e "\e[33mInstaling project dependencies\e[37m"
  
      local dependencies
      pkgsh/loadf dependencies $pkgsh_path

      read -a install_packages <<< "$dependencies"
    else
      read -a install_packages <<< "$install_packages"
    fi
  fi

  repos/load_state

  local pkg_name
  for pkg_name in "${install_packages[@]}"; do
    local pkg_url="${PACKAGE_ENTRIES[$pkg_name]}" 
    if [ -z "$pkg_url" ]; then
      echo -e "  \e[31m* Not found: $pkg_name\e[37m"
    else
      local pkg_path="$BPM_DEPS_DIR_PATH/$pkg_name"
      if ! locator/is_indexed $pkg_name; then
        echo -e "  \e[32m* Installing $pkg_name...\e[37m"
        
        mkdir -p pkg_path
        git clone "$pkg_url" "$pkg_path" >/dev/null 2>&1

        locator/index_package $pkg_path
      else
        echo -e "  \e[33m* Updating $pkg_name..."
        git -C $pkg_path fetch origin
        git -C $pkg_path reset --hard origin/main
        echo -e "\e[37m"
      fi
    fi
  done
}

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
