# BPR Format
# The bpr format is defined by 2 sections, one for the entry type, and another
# for a key-value pair: "type key=value"

BPR_EXTENSION_ERROR=1
BPR_NOT_FOUND_EXTENSION_ERROR=2

function bpr/load() {
  local -n output="$1"
  local ext="$2"
  local repo_path="$3"

  local line
  while IFS= read -r line; do
    local trimmed_line=$(sed "s/ //g" <<< "$line")
    if [ -z "$trimmed_line" ] || [ "${line:0:1}" == "#" ]; then
      continue
    fi

    IFS=" " read -r e_type e_pairs <<< "$line"
    IFS="=" read -r e_name e_value <<< "$e_pairs"

    local bpr_ext="bpr-$ext/$e_type"
    
    if declare -f $bpr_ext >/dev/null 2>&1; then
      $bpr_ext "$e_name" "$e_value"
      local status=$?

      if [ $status -ne 0 ]; then
        echo -e "\e[31mError while running extension '$bpr_ext' at '$line' err_code=$status\e[37m"
        return $BPR_EXTENSION_ERROR
      fi
    else
      echo -e "\e[31mNot found extension: Invalid type '$e_type' at '$line'\e[37m"
      return $BPR_NOT_FOUND_EXTENSION_ERROR
    fi
  done < "$repo_path"
}
