DBG_CLEAR_CONSOLE="dbg-clear-console"

function cmd/leak-test() {
  # bpm leak-test query -> print value of a global var
  # bpm leak-test query command [-f (arg, ...)]-> print value of a global var after running command
  # bpm leak-test -> print value of all global vars and functions
  # bpm leak-test "" command [-f (arg, ...)]-> print value of all global vars and functions after running command
  
  local query
  local command
  local params=( "query" "command" )

  local i=0
  for arg in "$@"; do
    shift
    if [ "$arg" == "-f" ]; then
      break;
    fi
    
    local param="${params[$i]}"
    if [ -n "$param" ]; then
      eval "${param}=\"$arg\""
    else
      break
    fi

    ((i++))
  done

  if [ -n "$command" ]; then
    command="cmd/$command"
    $command $@
  fi

  if [ -n "$query" ]; then
    echo "[LEAK]: ${!query-Not found $query}"
    return
  fi

  local env="$(set)"
  cat <<< "$env"
}

function cmd/shell() {
  cd $BPM_DIR_PATH

  clear
  echo -e "\n\e[34mYou're inside BPM's shell.\nThis shell is very usefull for maintenance and debug.\e[37m\n"

  local cmd
  while :; do  
    local clampped_pwd="$(pwd)"
    printf "\e[33m%.20s\e[32m [bpm]: \e[37m" "${clampped_pwd: -20}"
    read cmd
    eval "$cmd"
  done
}

function dbg/make_output_file() {
  if [ ! -p "$BPM_LOGS_PATH" ]; then
    mkfifo $BPM_LOGS_PATH
  fi
}

function dbg/log() {
  dbg/make_output_file
  echo "$@" > "$BPM_LOGS_PATH"
}

function dbg/clear() {
  dbg/log $DBG_CLEAR_CONSOLE
}

function cmd/output-logs() {
  dbg/make_output_file

  while true; do
    local line
    if read line <"$BPM_LOGS_PATH"; then
      if [ "$line" == "$DBG_CLEAR_CONSOLE" ]; then
        clear
      else
        echo -e "$line"
      fi
    fi
  done
}
