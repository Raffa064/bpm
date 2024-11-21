function is_installed() {
  local cmd="$1"
  local path=$(command -v "$cmd")
  local status=$?

  if [ $status -eq 0 ]; then
    if [ -e "$path" ]; then
      return 0
    fi
  fi

  return 1
}

SUDO=""
function check_for_permissions() {
  if is_installed sudo; then # Check if the system has sudo 
    if [ $EUID -eq 0 ]; then
      echo -e "\e[33m* This script can't be runned as sudo\e[37m"
      exit 1
    fi

    SUDO="sudo "

    echo "SUDO permission is necessary to install dependencies"
    sudo -v # Ask for sudo password
  fi
}

INSTALL_COMMAND="apt install"
function check_for_install_command() {
  while :; do
    local pkgman
    read -a pkgman <<< "$INSTALL_COMMAND"
    pkgman="${pkgman[0]}"

    if ! is_installed "$pkgman"; then
      clear
      echo -e "\e[33m* Can't locate $pkgman.\e[37m"
      echo -e "\nIf you are using other package manager, enter it's \e[32minstall command\e[37m bellow. \e[35m(Ex: apt install, pkg install):\e[37m"
      arg/q_input INSTALL_COMMAND "Install command" "$INSTALL_COMMAND"
    else
      break
    fi
  done
}

function exec_bpm() {
  local executable_path="$BPM_BIN_DIR_PATH/bpm"
  if [ -e "$executable_path" ]; then
    bash "$executable_path" $@
  else
    echo -e "\e[31mCan't locate bpm executable\e[37m"
    exit 1
  fi
}
