# TODO: fix read/write order

function sh/read_obj() {
  local -n output_obj="$1"
  local obj_name="$2"
  local path="$3"

  if [ -z "$path" ]; then
    obj_name="$1"
    path="$2"
  fi

  local generated_code=$(
    create_array="declare -A $obj_name"
    $create_array
    
    source "$path" >/dev/null

    for key in $(eval "echo \${!${obj_name}[@]}"); do
      local value=$(eval "echo \"\${$obj_name[$key]}\"")
      echo "output_obj[$key]=\"$value\";"
    done
  )

  eval "$generated_code"
}

function sh/write_obj() {
  local -n obj="$1"
  local obj_name="$2"
  local path="$3"

  if [ -z "$path" ]; then
    obj_name="$1"
    path="$2"
  fi

  echo -n "" > "$path"
  local key
  for key in "${!obj[@]}"; do
    echo "$obj_name[$key]=\"${obj[$key]}\"" >> "$path"
  done
}

function sh/print_obj() {
  local -n obj="$1"
  local key

  echo "("
  for key in "${!obj[@]}"; do
    echo "  [$key]=\"${obj[$key]}\""
  done
  echo ")"
}
