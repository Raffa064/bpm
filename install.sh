#!/bin/bash

source core/bpm-vars.sh
source core/sh-obj.sh

function compile_docs() {
  local target_path="$1"

  local -A help_sections
  local path
  for path in $(find "./docs" -regex ".*\.txt"); do
    local section=$(basename "$path")
    section="${section%.*}"
    local sanitized_content=$(cat "$path")
    sh/sanitize_obj_entry sanitized_content
    help_sections["$section"]="$sanitized_content"
  done

  sh/write_obj help_sections "$target_path"
}

function install_bpm() {
  if [ -e "$BPM_BIN_PATH" ]; then
    rm $BPM_BIN_PATH
  fi

  echo "Installing bpm executable..."
  local content=$(cat bpm.sh)
  content=$(sed "s@source_core_scripts@source $BPM_CORE_PATH@" <<< "$content")
  echo "$content" > tmp 

  mv tmp $BPM_BIN_PATH
  chmod 700 $BPM_BIN_PATH # Only current user can access it

  echo "Creating bpm directories..."
  mkdir -p "$BPM_DIR_PATH"
  for dir in "${BPM_DIR_STRUCTURE[@]}"; do
    mkdir -p "$BPM_DIR_PATH/$dir"
  done

  echo "Compiling core scrips..."
  rm tmp >/dev/null 2>&1
  echo -e "# Compiled by $(whoami) at $(date)\n" > tmp
  local path
  for path in $(find "./core" -regex ".*\.sh"); do
    echo "# $path" >> tmp
    cat $path >> tmp
  done
  mv tmp "$BPM_CORE_PATH"


  echo "Compiling docs..."
  compile_docs $BPM_DOCS_PATH

  echo "Installation successfully finished!"
}

function main() {
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
}

main
