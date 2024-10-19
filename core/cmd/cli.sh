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

function cmd/leak-test() {
  local env="$(set)"
  cat <<< "$env"
}

function cmd/fix() {
  echo "Creating bpm dirs.."
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
}

function cmd/uninstall() {
  echo -e "\e[33mUninstalling executable scripts....\e[37m"
  rm "$BPM_BIN_PATH/bpm"
  rm "$BPM_CORE_PATH"

  if [ "$1" == "-d" ]; then
    echo -e "\e[33mFully deleting all state and installed packages\e[37m"
    rm -rf "$BPM_DIR_PATH"
  else
    echo -e "\e[32mState and installed packages will not be deleted."
  fi
}

