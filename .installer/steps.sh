function download_dependencies() {
  check_for_install_command

  echo "Looking for dependencies..."
  local dep
  for dep in "${BPM_DEPENDENCIES[@]}"; do
    if is_installed $dep; then
      echo -e "  * \e[32m$dep\e[37m is installed"
    else
      echo -e "  * \e[31m$dep\e[37m is not installed\n  \e[33mInstalling...\e[37m"
      eval "yes | $SUDO$INSTALL_COMMAND $dep" >/dev/null 2>&1
    fi
  done
}

function make_dirs() {
  echo "Creating bpm directories..."
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

  bash/insert "export PATH=\"\$PATH:$BPM_BIN_DIR_PATH\""
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
  compile_module runtime $BPM_RUNNER_PATH
  echo "run/main \$@" >> $BPM_RUNNER_PATH
}

function setup_exporter() {
  bash/insert "export PATH=\"\$PATH:$BPM_EXPORT_DIR_PATH\""
}

function generate_autocomplete() {
  echo "Generating autocomplete..."
 
  bash ./.installer/gen-cmp.sh # Generate autocomplete script

  bash/insert "source $BPM_AUTOCOMPLETE_PATH"
} 

function fix_errors_and_configure() {
  echo "Fixing possible errors..."
  exec_bpm fix

  echo "Checking for repos..."
  local repo_list="$(exec_bpm repo list-repos)"
  if [[ ! "$repo_list" =~ official ]]; then
    echo "* Installing official repo..."
    local official_repo="https://raw.githubusercontent.com/Raffa064/bpm/refs/heads/main/repo/official.bpr"
    exec_bpm repo add "$official_repo"
  else
    echo "* Updating repos..."
    exec_bpm repo update
  fi
}

function generate_bash_insertion() {
  if [ -e "$BPM_BASH_INSERTION_PATH" ]; then
    echo "Removing old insertions..."
    bash "$BPM_BASH_INSERTION_PATH" remove
  fi

  echo "Generating bash insertion..." 

  local gen_script
  local ins
  for ins in "${BPM_BASH_INSERTION[@]}"; do
    gen_script+="insert \$MODE '$ins'
"
  done

  local template="MODE=\"\$1\"

function insert() {
  local opt=\"\$1\"
  local insertion=\"\$2\"

  case \$opt in
    add)  
      if ! grep -Fxq \"\$insertion\" \"\$HOME/.bashrc\"; then
        echo \"\$insertion\" >> \"\$HOME/.bashrc\"
      fi
      ;;
    remove)
      sed -i \"\\#^\$insertion\\\$#d\" \"\$HOME/.bashrc\"
      ;;
  esac
}

$gen_script
"
  echo "$template" > "$BPM_BASH_INSERTION_PATH"

  echo "  * Running bash inserion script..."
  bash "$BPM_BASH_INSERTION_PATH" add
}

function install_bpm() {
  download_dependencies
  make_dirs  
  
  touch $BPM_INSTALL_LOCK_PATH # Create lock file
  
  generate_executable
  compile_coresh
  compile_runtime
  setup_exporter
  generate_autocomplete
  generate_bash_insertion
 
  rm $BPM_INSTALL_LOCK_PATH # Remove lock file
  
  fix_errors_and_configure
  
  echo -e "\n\e[32mInstallation successfully finished!\e[37m"
  echo -e "\e[33mMaybe necessary to restart your bash session to work properly.\e[37m"
}

