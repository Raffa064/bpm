PKGSH_INVALID_PACKAGE=1
PKGSH_INVALID_NAME=2
PKGSH_INVALID_VERSION_NUM=3

function pkgsh/locate_pkg_root() {
  local path="$1"
  fs/root_dir "package.sh" $path
  return $?
}

function pkgsh/locate_pkg_file() {
  local path="$1"
  fs/root_dir -f "package.sh" $path
  return $?
}

function pkgsh/load() {
  local -n output="$1"
  local pkgsh_path="$2"

  pkgsh_path=$(pkgsh/locate_pkg_file $pkgsh_path)

  if [ -z "$pkgsh_path" ]; then
    return $PKGSH_INVALID_PACKAGE
  fi

  sh/read_obj output bpd "$pkgsh_path"

  local name="${output[name]}"
  local version="${output[version]}"

  if [[ ! "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_\-]*$ ]]; then
    return $PKGSH_INVALID_NAME
  fi

  if [ -z "$version" ]; then
    version=1
  fi

  if [[ ! "$version" =~ ^-?[0-9]+$ ]]; then
    return $PKGSH_INVALID_VERSION_NUM 
  fi
  
  output[name]="$name"
  output[version]="$version"
}

# Stands for load field
function pkgsh/loadf() {
  local -n output="$1"
  local field_name="$2"
  local path="$3"

  if [ -z "$path" ]; then
    field_name="$1"
    path="$2"
  fi

  local -A bpd
  pkgsh/load bpd "$path"
  local status=$?

  if [ $status -ne 0 ]; then
    return $status
  fi

  output="${bpd[$field_name]}"
}
