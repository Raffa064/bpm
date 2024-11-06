function cmd/help() {
  if [ -z "$@" ]; then
    cmd/help bpm
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

function cmd/leak-test() {
  # bpm leak-test query -> print value of a global var
  # bpm leak-test query command [-f (arg, ...)]-> print value of a global var after running command
  # bpm leak-test -> print value of all global vars and functions
  # bpm leak-test "" command [-f (arg, ...)]-> print value of all global vars and functions after running command
  
  local query
  local command
  local params=( "query" "command" )

  local i=0
  for arg in "$@"; do
    shift
    if [ "$arg" == "-f" ]; then
      break;
    fi
    
    local param="${params[$i]}"
    if [ -n "$param" ]; then
      eval "${param}=\"$arg\""
    else
      break
    fi

    ((i++))
  done

  if [ -n "$command" ]; then
    command="cmd/$command"
    $command $@
  fi

  if [ -n "$query" ]; then
    echo "[LEAK]: ${!query-Not found $query}"
    return
  fi

  local env="$(set)"
  cat <<< "$env"
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
}

cmp_uninstall="-d"
function cmd/uninstall() {
  echo -e "\e[33mUninstalling executable scripts....\e[37m"
  rm "$BPM_BIN_DIR_PATH/bpm"
  rm "$BPM_CORE_PATH"

  if [ "$1" == "-d" ]; then
    echo -e "\e[33mFully deleting all state and installed packages\e[37m"
    rm -rf "$BPM_DIR_PATH"
  else
    echo -e "\e[32mState and installed packages will not be deleted."
  fi
}

