function main() {
  clear
  bash ./.installer/banner.sh

  check_for_permissions
  
  if is_installed bpm; then
    current_version=$(exec_bpm version)

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
