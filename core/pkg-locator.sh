declare -gA LOCATOR

function locator/init() {
  locator/load_state
  locator/update
  locator/index_package $(pwd)
}

function locator/save_state() {
  sh/write_obj LOCATOR $BPM_LOCATOR_PATH
}

function locator/load_state() {
  sh/read_obj LOCATOR $BPM_LOCATOR_PATH
}

function locator/add() {
  local save_flag=0
  if [ "$1" == "-n" ]; then
    save_flag=1
    shift
  fi
  
  local pkg_name="$1"
  local pkg_path="$2"
  LOCATOR["$pkg_name"]="$pkg_path"
  
  if [ $save_flag -eq 0 ]; then
    locator/save_state
  fi

}

function locator/remove() {
  local save_flag=0
  if [ "$1" == "-n" ]; then
    save_flag=1
    shift
  fi
  
  local pkg_name="$1"
  unset LOCATOR[$pkg_name]
  
  if [ $save_flag -eq 0 ]; then
    locator/save_state
  fi
}

function locator/update() {
  local pkg_name

  for pkg_name in "${!LOCATOR[@]}"; do
    local pkg_path="${LOCATOR[$pkg_name]}"
    
    if [ ! -e "$pkg_path/package.sh" ]; then #TODO: check if name is the same in package.sh to prevent duplified entries
      locator/remove -n $pkg_name
      if [ "$1" == "--fix" ]; then
        echo "Lost package: $pkg_name => $pkg_path"
      fi
    else
      if [ "$1" == "--fix" ]; then
        local currName
        pkgsh/loadf currName "name" "$pkg_path/package.sh"
        if [ ! "$pkg_name" == "$currName" ]; then
          echo "Renamed: $pkg_name => $currName"
          locator/remove -n $pkg_name                
          locator/add -n "$currName" "$pkg_path"
        fi
      fi
    fi
  done

  locator/save_state
}

function locator/index_package() {
  local path="$1"
  path=$(pkgsh/locate_pkg_root $path)

  local name
  pkgsh/loadf name "$path/package.sh"
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

function locator/is_indexed() {
  local pkg_name="$1"
  if [ -z "${LOCATOR["$pkg_name"]}" ]; then
    return 1
  fi
}

function locator/print_index() {
  local i
  local keys
  local values

  read -a keys <<< "${!LOCATOR[@]}"
  read -a values <<< "${LOCATOR[@]}"

  local term_width=$(tput cols)
  local column_width=$((term_width / 2))

  printf "\e[34m%-${column_width}s%-${column_width}s\e[37m\n" "Package Name:" "Path:" 
  for i in "${!keys[@]}"; do
    printf "\e[33m%-${column_width}s%-${column_width}s\e[37m\n" "${keys[$i]}" $(arg/cutstr "${values[$i]}" $column_width) 
  done
}
