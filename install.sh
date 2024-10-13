source core/bpm.vars.sh

function install_bpm() {
  if [ -e "$BPM_BIN_PATH" ]; then
    rm $BPM_BIN_PATH
  fi

  echo "Installing bpm executable..."
  cat bpm.sh >> tmp
  local bpm_sh_content=$(cat bpm.sh)
  bpm_sh_content=$(sed "s|source_cli|source $BPM_DIR_PATH/core/source-cli.sh|" <<< "$bpm_sh_content")
  
  touch tmp
  echo "$bpm_sh_content" > tmp

  mv tmp $BPM_BIN_PATH
  chmod 777 $BPM_BIN_PATH

  echo "Creating bpm directories"
  mkdir -p "$BPM_DIR_PATH"
  for dir in "${BPM_DIR_STRUCTURE[@]}"; do
    mkdir -p "$BPM_DIR_PATH/$dir"
  done

  local core_dir="$BPM_DIR_PATH/core"
  if [ -e "$core_dir" ]; then
    echo "Overwriting core scripts"
    rm -rf "$core_dir"
  fi

  echo "Copying core scripts..."
  cp -r ./core $core_dir

  echo "Installation successfully finished!"
}

clear
echo "BPM INSTALLER - 2024"

if [ -e "$BPM_BIN_PATH" ]; then
  current_version=$(bpm version)

  if [ $BPM_VERSION == "$current_version" ]; then
    echo "BPM is already installed."
    echo "Want to reinstall it anyway? (Y/n)"

    while :; do
      read op

      case $op in
        "y"|"Y")
          install_bpm
          exit
          ;;
        "n"|"N")
          echo "Aborting operation..."
          exit
          ;;
        "*")
          echo "Invalid option"
          ;;
     esac
    done
  else
    echo "Updating bpm v$current_version to v$BPM_VERSION"
    install_bpm
  fi
else
  install_bpm
fi
