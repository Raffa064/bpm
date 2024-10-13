function arg/df() {
  local -n arg="$1"
  local val="$2"
  local df_val="$3"

  if [ -z "$df_val" ]; then
    val="$arg"
  fi

  if [ -z "$val" ]; then
    arg="$df_val"
  else
    arg="$val"
  fi
}

function arg/df_path() {
  local -n arg_path="$1"
  local val="$2"

  if [ -z "$val" ]; then
    val="$arg_path"
  fi

  arg/df arg_path "$val" "$(pwd)"
}
