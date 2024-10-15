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

function arg/q_input() {
  local -n output="$1"

  if [ "$2" == "-s" ]; then # Skip if default exists
    shift
    if [ ! -z "$df" ]; then
      return
    fi
  fi

  local question="$2"
  local df="$3"
  
  local df_str
  if [ ! -z "$df" ]; then
    df_str=" (df.: $df)"
  fi

  echo -ne "\e[34m$question\e[33m$df_str\e[34m: \e[37m"
  read output

  if [ -z "$output" ]; then
    output="$df"
  fi
}
