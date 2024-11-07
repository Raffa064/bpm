NOT_FOUND=1
INVALID_PACKAGE=2

declare -A IMPORT_SHEET     # [com_package_file]="pkg-name path/to/that/file"
declare -A IMPORTED_SCRIPTS # [com_package_file]="imported"

function import/add_package() {
  local pkg_name="$1"
  local pkg_path="$2"
  local namespace="$3"

  local file
  for file in $(ls $pkg_path); do
    if [ -d "$pkg_path/$file" ]; then
      import/add_package "$pkg_name" "$pkg_path/$file" "${namespace}_$file"
    else
      if [ "${file##*.}" == "sh" ]; then
        # echo ": ${namespace}_${file%.*} -> $pkg_name $pkg_path/$file"
        IMPORT_SHEET["${namespace}_${file%.*}"]="$pkg_name $pkg_path/$file"
      fi
    fi
  done
}

function import/init() {
  local dependencies
  read -a dependencies <<< "$1"

  local dep
  for dep in "${dependencies[@]}"; do
    local dep_path=$(bpm locator -l "$dep")
    
    if [ -z "$dep_path" ]; then
      echo -e "\e[31mCan't resolve dependency: $dep\e[37m"
      exit 1
    else
      import/add_package "$dep" "$dep_path/src"
      
      local pkg_deps
      pkgsh/loadf pkg_deps "dependencies" "$dep_path/package.sh"
      import/init $pkg_deps
    fi
  done
}

function import/format_path() {
  local -n ouptut="$1"
  ouptut=$(sed "s/\\./_/g" <<< "_$ouptut")
}

function import/resolve() {
  # returns path to a script 
  # import/resolve com.pkg.name.script  --> just returns the path 
  # import/resolve {pkg} com.pkg.script --> ensure that script is from specified package
  
  local -n output="$1"
  local import_path="$2"

  local import_pkg
  if [ ! -z "$3" ]; then
    import_pkg="$2"
    import_path="$3"
  fi

  import/format_path import_path

  local import_data="${IMPORT_SHEET[$import_path]}"

  
  if [ -z "$import_data" ]; then
    return $NOT_FOUND
  fi

  read -a import_data <<< "$import_data"
  
  if [ -z "$import_pkg" ]; then
    output="${import_data[1]}"
  else
    if [ "${import_data[0]}" == "$import_pkg" ]; then
      output="${import_data[1]}"
    else
      return $INVALID_PACKAGE
    fi
  fi
}

function import() {
  # manage importing file
  local import_path="$1"
  
  local script_path
  import/resolve script_path $import_path
  local status=$?
  
  if [ $status -ne 0 ]; then
    echo -e "\e[31mImport error: Can't locate script: $import_path err_code=$status\e[37m"
    exit
  fi

  import/format_path import_path
  if [ -z "${IMPORTED_SCRIPTS[$import_path]}" ]; then
    source $script_path
    IMPORTED_SCRIPTS[$import_path]=1
  fi
}
