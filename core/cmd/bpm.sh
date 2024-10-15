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

function cmd/uninstall() {
  echo -e "\e[32mState and installed packages will not be deleted."
  echo -e "\e[33mUninstalling executable scripts....\e[37m"
  rm $BPM_BIN_PATH
  rm -rf "$BPM_DIR_PATH/core"

  if [ "$1" == "-d" ]; then
    echo -e "\e[33mDeleting dependencies...\e[37m"
    rm -rf "$BPM_DEPS_PATH"
  fi
}

