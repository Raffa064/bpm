function cmd/help() {
  if [ -z "$@" ]; then
    cmd/help bpm
  else
    help_content="${help_sections[$1]}"
    if [ -z "$help_content" ]; then
      echo -e "\e[31mInvalid help section: $1\e[37m"
      return 1
    else
      title=$(sed -n "1p" <<< "$help_content")
      command=$(sed -n "3p" <<< "$help_content")
      description=$(sed "1,3d" <<< "$help_content")

      if [ -n "$command" ]; then
        command="\n\n  \e[32m$\e[36m $command" 
      fi

      local highlighted="\n\e[35m# $title$command\e[33m\n$description\e[37m\n"

      highlighted=$(sed 's/"\([^"]*\)"/\\e[32m"\1"\\e[33m/g' <<< "$highlighted") # "TEXT" 
      highlighted=$(sed 's/>\([^<]*\)</\\e[36m\1\\e[33m/g' <<< "$highlighted")   # >TEXT<
      highlighted=$(sed 's/&lt;/</g' <<< "$highlighted") # <
      highlighted=$(sed 's/&gt;/>/g' <<< "$highlighted") # >
      
      echo -e "$highlighted"
    fi
  fi
}

function cmd/version() {
  echo $BPM_VERSION
}

function cmd/update() {
  echo "Cloning repo files..."
  cd "$BPM_DIR_PATH"
  git clone https://github.com/Raffa064/bpm --depth 1 bpm-clone >/dev/null 2>&1
  cd ./bpm-clone

  echo "Running installation script..."
  yes | bash ./install.sh >/dev/null

  echo "Removing installation files..."
  cd ..
  rm -rf bpm-clone
}

function cmd/fix() {
  echo "Creating bpm dirs.."
  local dir
  for dir in "${BPM_MKD[@]}"; do
    mkdir -p "$dir"
  done

  if [ ! -e "$BPM_LOCATOR_PATH" ]; then
    echo -e "\e[33mLocator state was lost...\e[37m"
    touch $BPM_LOCATOR_PATH
    locator/save_state
  else
    echo "Fixing package index..."
    locator/load_state
    locator/update --fix
  fi

  echo "Indexing dependencies..."
  local dep_package
  for dep_package in $(ls $BPM_DEPS_DIR_PATH); do
    cmd/locator -i "$BPM_DEPS_DIR_PATH/$dep_package" >/dev/null 2>&1
    local status=$?

    if [ $status -ne 0 ]; then
      echo "Failed to fix deps/$dep_package"
    fi
  done

  echo "Removing unknown exports..."
  local exported_pkg
  for exported_pkg in $(ls "$BPM_EXPORT_DIR_PATH"); do
    if ! locator/is_indexed $exported_pkg; then
      echo "  * $exported_pkg"
      cmd/unexport $exported_pkg 
    fi
  done
}

cmp_uninstall="-d"
function cmd/uninstall() {
  if [ "$1" == "-d" ]; then
    echo "Do you really want to fully unintall bpm?"
    echo -e "\e[33mIt will delete all installed packages and configurations.\e[37m"
    local confirm
    arg/confirm confirm

    if [ $confirm -eq 0 ]; then
      echo "Removing bash insertions..."
      bash $BPM_BASH_INSERTION_PATH remove
      echo -e "\e[33mFully deleting all state and installed packages...\e[37m"
      rm -rf "$BPM_DIR_PATH"
    else
      echo -e "\e[33mUnstallation aborted\e[37m"
    fi
  else
    echo -e "\e[32mCurrent bpm state and installed packages will not be deleted."
    echo "Removing bash insertions..."
    bash $BPM_BASH_INSERTION_PATH remove
  
    echo -e "\e[33mUninstalling executable scripts....\e[37m"
    rm "$BPM_BIN_DIR_PATH/bpm"
    rm -rf "$BPM_SRC_DIR_PATH"
  fi
}

