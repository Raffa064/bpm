#!/bin/bash

if [ -n "$SUDO_USER" ]; then
  export HOME=$(eval echo "~$SUDO_USER")
fi

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
  mv bpm $BPM_BIN_DIR_PATH # Move to ~/local/bin
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

function compile_scripts() {
  local path="$1"
  local target_path="$2"

  rm "$target_path" >/dev/null 2>&1

  echo -e "# Compiled by $(whoami) at $(date)\n" > "$target_path"
  local file_path
  for file_path in $(find "$path" -regex ".*\.sh"); do
    echo "# $file_path" >> "$target_path"
    cat $file_path >> "$target_path"
  done
}

function compile_coresh() {
  echo "Compiling core.sh"
  mkdir -p tmp

  echo "  * Compiling core scripts..."
  compile_scripts ./core tmp/core.sh

  echo "  * Compiling docs..."
  compile_docs tmp/docs.sh

  echo "  * Merging compiled sources..."

  local merged="./tmp/merged"
  cat "tmp/core.sh" > "$merged"
  echo "declare -gA help_sections" >> "$merged"
  cat "tmp/docs.sh" >> "$merged"

  mv "$merged" $BPM_CORE_PATH

  rm -rf tmp
}

function compile_runtime() {
  echo "Generating runtime script..."
  cp -r ./runtime tmp

  echo "  * Copying dependencies..."
  for dep in $(cat ./runtime/deps.txt); do 
    cp "$dep" "tmp/$(basename $dep)"
  done

  echo "  * Compiling runtime..."
  compile_scripts tmp $BPM_RUNNER_PATH
  echo "run/main \$@" >> $BPM_RUNNER_PATH

  rm -rf tmp
}

function ensure_env_local() {
  local source_bpm="export PATH=\"\$PATH:$BPM_BIN_DIR_PATH\""

  if ! grep -Fxq "$source_bpm" "$HOME/.bashrc"; then
    echo -e "\e[34mThe '~/.local/bin' dir is not included into your PATH\e[37m"
    echo -e "  * Adding to \e[32m~/.bashrc\e[37m..."
    echo "$source_bpm" >> "$HOME/.bashrc"
    echo -e "\e[33mNOTE: You will need to reload your bash session to use bpm.\e[37m"
  fi
}

function generate_autocomplete() {
  echo "Generating autocomplete..."
 
  bash ./gen-cmp.sh # Generate autocomplete script

  local source_cmp="source $BPM_AUTOCOMPLETE_PATH"
  if ! grep -Fxq "$source_cmp" "$HOME/.bashrc"; then
    echo "  * Adding to ~/.bashrc..."
    echo "$source_cmp" >> "$HOME/.bashrc"
    echo -e "\e[33mNOTE: You will need to reload your bash session to apply completion.\e[37m"
  fi
} 

function fix_errors_and_configure() {
  echo "Fixing possible errors..."
  bpm fix

  echo "Installing official repo..."
  local official_repo="https://raw.githubusercontent.com/Raffa064/bpm/refs/heads/main/repo/official.sh"
  bpm repo add "$official_repo"
}

function install_bpm() {
   # Create lock file if not exists
  if [ ! -e "$BPM_INSTALL_LOCK_PATH" ]; then
    touch $BPM_INSTALL_LOCK_PATH
  fi

  download_dependencies
  make_dirs  
  generate_executable
  compile_coresh
  compile_runtime
  ensure_env_local
  generate_autocomplete
 
  rm $BPM_INSTALL_LOCK_PATH
  
  fix_errors_and_configure
  
  echo -e "\n\e[32mInstallation successfully finished!\e[37m"
}

function main() {
  clear
  bash banner.sh

  # Check for permissions
  if command -v sudo &>/dev/null 2>&1; then 
    if [ $EUID -ne 0 ]; then
      echo -e "\e[33m* This script must be runned as sudo\e[37m"
      exit 1
    fi
  fi

   if command -v bpm >/dev/null 2>&1; then
    current_version=$(bpm version)

    if [ $BPM_VERSION == "$current_version" ]; then
      echo -e "\e[33m[!] BPM is already installed."
      echo -e "\e[34m[?] Want to reinstall it anyway? (Y/n)\e[37m"

      while :; do
        read op

        case $op in
          "y"|"Y")
            install_bpm
            break
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

if [ -e "./test.sh" ]; then
  echo "Runnning test script..."
  bash ./test.sh
fi
