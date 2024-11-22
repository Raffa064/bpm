function cmd/init() {
  local path="$1"

  arg/df_path path

  local pkgsh_path=$(pkgsh/locate_pkg_file $path)

  if [ -z "$pkgsh_path" ]; then
    if [ ! -e "$path" ]; then
      mkdir -p "$path"
    fi

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
    return 1
  fi
}

function cmd/edit() {
  local file_name="$1"
  local root_path="$(pkgsh/locate_pkg_root $(pwd))"
  
  if [ -z "$root_path" ]; then
    echo -e "\e[33mYou aren't inside a bpm package\e[37m"
    return 1
  fi

  local file_path="$(find "$root_path" -type d -name ".git" -prune -o -type f -name "*$file_name*" -print)"

  if [ -z "$file_path" ]; then
    echo "Can't locate file: '$file_name'"
    return 1
  fi

  editor/open "$file_path"
}

function cmd/package() { 
  cmd/edit package.sh
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
      if [ "$BPM_DEPS_DIR_PATH" != "$(dirname "$pkg_path")" ]; then
        echo -e "\e[34m[?] $pkg_name is a local package, remove anyway?\e[37m"
        local confirm
        arg/confirm confirm 1

        if [ $confirm -ne 0 ]; then
          echo -e "  \e[33m* Skipped $pkg_name\e[37m"
          continue
        fi
      fi

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

  echo -e "\e[34mRun 'bpm clean' to empty trash\e[37m"
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
      return 1
    fi
  else
    echo -e "\e[33mTrash is empty\e[37m"
    return 1
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
    return 1
  fi
}

function cmd/list() {
  cmd/locator -p
}

install_skip_packages=""
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

  repo-man/load_state

  local pkg_name
  for pkg_name in "${install_packages[@]}"; do
    if [[ "$install_skip_packages" =~ $pkg_name ]]; then
      continue
    fi

    install_skip_packages+=" $pkg_name"
    
    local pkg_url="${PACKAGE_ENTRIES[entry-$pkg_name]}" 
    if [ -z "$pkg_url" ]; then
      echo -e "  \e[31m* Not found: $pkg_name\e[37m"
    else
      local pkg_path="$BPM_DEPS_DIR_PATH/$pkg_name"
      if ! locator/is_indexed $pkg_name; then
        echo -e "  \e[32m* Installing $pkg_name...\e[37m"
        
        mkdir -p $pkg_path
        git clone "$pkg_url" "$pkg_path" >/dev/null 2>&1
        local status=$?

        if [ $status -eq 0 ]; then
          locator/index_package $pkg_path
        else
          echo -e "  \e[31m- Error while installing package\e[37m"
        fi
      else
        echo -e "  \e[33m* Updating $pkg_name..."
        git -C $pkg_path fetch origin >/dev/null 2>&1
        local status=$?

        if [ $status -eq 0 ]; then
          git -C $pkg_path reset --hard origin/main >/dev/null 2>&1
        else
          echo -e "  \e[31m- Error while updating package\e[37m"
        fi
      fi

      # Install package deps
      cmd/install $(cmd/deps $pkg_path)
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
    return $?
  else
    echo -e "\e[31mCan't locate package file: $path\e[37m"
    return 1
  fi
}
