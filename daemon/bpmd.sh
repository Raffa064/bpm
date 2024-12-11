function start-routine() {
  local routine="$1"
  local pid_file="$BPMD_PROCS_DIR_PATH/$routine"

  if [ -e "$pid_file" ]; then
    stop-routine $routine
  fi

  local routine_func="d/$routine"
  $routine_func >"$BPMD_LOGS_PATH" & pid=$!
  echo "$pid" >> "$pid_file"
}

function stop-routine() {
  local routine="$1"
  local pid_file="$BPMD_PROCS_DIR_PATH/$routine"

  local pid="$(cat $pid_file)"
  if kill -0 $pid >/dev/null 2>&1; then
    kill $pid >/dev/null 2>&1
  fi
  
  rm "$pid_file"
}

function start() {
  echo "Start at $(date)" > "$BPMD_LOGS_PATH"

  if [ ! -d "$BPMD_PROCS_DIR_PATH" ]; then
    mkdir -p "$BPMD_PROCS_DIR_PATH"
  fi

  for routine in $(compgen -A function); do
    if [[ "$routine" =~ ^d/.+$ ]]; then
      start-routine "${routine:2}"
    fi
  done
}

function stop() {
  for routine in $(ls $BPMD_PROCS_DIR_PATH); do
    stop-routine $routine
  done
}

function restart() {
  stop
  start
}

function bpmd/main() {
  case $1 in
    start) start;;
    stop) stop;;
    restart) restart;;
    *) echo -e "\e[31mBMPD: Invalid command $1\e[37m" ;;
  esac
}
