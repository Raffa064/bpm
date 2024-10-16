#!/bin/bash

source core/bpm-vars.sh
source core/sh-obj.sh

function compile_docs() {
  local target_path="$1"
  rm "$target_path" >/dev/null 2>&1
  
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

function compile_core_scripts() {
  local target_path="$1"
  rm "$target_path" >/dev/null 2>&1

  echo -e "# Compiled by $(whoami) at $(date)\n" > "$target_path"
  local path
  for path in $(find "./core" -regex ".*\.sh"); do
    echo "# $path" >> "$target_path"
    cat $path >> "$target_path"
  done
}

function compile_resources() {
  mkdir -p tmp

  echo "Compiling core scrips..."
  compile_core_scripts tmp/core.sh

  echo "Compiling docs..."
  compile_docs tmp/docs.sh

  echo "Merging compiled sources..."

  local merged="./tmp/merged"
  cat "tmp/core.sh" > "$merged"
  echo "declare -gA help_sections" >> "$merged"
  cat "tmp/docs.sh" >> "$merged"

  mv "$merged" $BPM_CORE_PATH

  rm -rf tmp
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

  compile_resources
  
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
