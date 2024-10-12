function fs/root_dir() {
  local includeFile=1
  if [ "$1" == "-f" ]; then
    includeFile=0
    shift
  fi

  local root_file="$1"
  local path="$2"

  while :; do 
    if [ -e "$path/$root_file" ]; then
      if [ $includeFile -eq 0 ]; then
        echo "$path/$root_file"
      else
        echo "$path"
      fi
      return 0
    fi

    local _path="$(dirname $path)"

    if [ "$path" == "$_path" ] || [ "$_path" == "." ]; then
      return 1
    fi

    path="$_path"
  done
}
