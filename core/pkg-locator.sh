declare -A LOCATOR

function locator/init() {
  locator/load_state
  locator/index_package $(pwd)
  locator/update
}

function locator/save_state() {
  sh/write_obj LOCATOR $BPM_LOCATOR_PATH
}

function locator/load_state() {
  if [ -e "$BPM_LOCATOR_PATH" ]; then
    sh/read_obj LOCATOR $BPM_LOCATOR_PATH
  fi
}

function locator/add() {
  local pkg_name="$1"
  local pkg_path="$2"

  LOCATOR[$pkg_name]="$pkg_path"
  
  locator/save_state
}

function locator/remove() {
  local pkg_name="$1"

  unset LOCATOR[$pkg_name]
  
  locator/save_state
}

function locator/update() {
  local pkg_name

  for pkg_name in "${!LOCATOR[@]}"; do
    local pkg_path="${LOCATOR[$pkg_name]}"
    if [ ! -e "$pkg_path/package.sh" ]; then
      locator/remove $pkg_name
    fi
  done
}

function locator/index_package() {
  local path="$1"

  local name
  pkgsh/loadf name $path
  local status=$?

  if [ $status -eq 0 ]; then
    locator/add "$name" "$path"
  else
    return $status
  fi
}

function locator/locate_package() {
  echo "${LOCATOR[$1]}"
}
