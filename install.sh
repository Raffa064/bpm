#!/bin/bash

source core/bpm-vars.sh
source core/sh-obj.sh
source core/arg.sh

INSTALL_COMMAND="apt install"

function check_for_install_command() {
  while :; do
    local pkgman
    read -a pkgman <<< "$INSTALL_COMMAND"
    pkgman="${pkgman[0]}"

    if ! command -v "$pkgman" >/dev/null; then
      clear
      echo -e "\e[33m* Can't locate $pkgman.\e[37m"
      echo -e "\nIf you are using other package manager, enter it's \e[32minstall command\e[37m bellow. \e[35m(Ex: apt install, pkg install):\e[37m"
      arg/q_input INSTALL_COMMAND "Install command" "$INSTALL_COMMAND"
    else
      break
    fi
  done
}

function download_dependencies() {
  check_for_install_command

  echo "Looking for dependencies..."
  local dep
  for dep in "${BPM_DEPENDENCIES[@]}"; do
    if command -v $dep >/dev/null; then
      echo -e "  * \e[32m$dep\e[37m is installed"
    else
      echo -e "  * \e[31m$dep\e[37m is not installed\n  \e[33mInstalling...\e[37m"
      eval "yes | $INSTALL_COMMAND $dep" >/dev/null 2>&1
    fi
  done
}

function make_dirs() {
  echo "Creating bpm directories..."
  mkdir -p "$BPM_DIR_PATH"
  for dir in "${BPM_MKD[@]}"; do
    mkdir -p "$dir"
  done
}

function generate_executable() {
  echo "Installing bpm executable..."
  local content=$(cat bpm.sh)
  content=$(sed "s@source_core_scripts@source $BPM_CORE_PATH@" <<< "$content")
  echo "$content" > bpm

  chmod 700 bpm        # Only current user can access it
  mv bpm $BPM_BIN_PATH # Move to ~/local/bin
} 

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

  echo "Compiling core scripts..."
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
  download_dependencies
  make_dirs  
  generate_executable
  compile_resources

  echo -e "\n\e[32mInstallation successfully finished!\e[37m"
}

function main() {
  clear
  echo -e "\e[33mBPM INSTALLER - 2024\e[37m\n"

  if [ -e "$BPM_BIN_PATH" ]; then
    current_version=$(bpm version)

    if [ $BPM_VERSION == "$current_version" ]; then
      echo -e "\e[33m[!] BPM is already installed."
      echo -e "\e[34m[?] Want to reinstall it anyway? (Y/n)\e[37m"

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
