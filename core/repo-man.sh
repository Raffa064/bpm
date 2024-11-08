declare -gA REPOS           # [repo-name]="source path"
declare -gA PACKAGE_ENTRIES # [pkg-name]="url"

function repo-man/load_state() {
  sh/read_obj REPOS "repo" $BPM_REPOS_SH_PATH
  
  local repo
  for repo in "${!REPOS[@]}"; do
    local -A info
    repo-man/get_info info $repo
    bpr-repo PACKAGE_ENTRIES "${info[path]}"
  done
}

function repo-man/save_state() {
  sh/write_obj REPOS "repo" "$BPM_REPOS_SH_PATH"
}

function repo-man/add() {
  local repo_name="$1"
  local repo_url="$2"
  local repo_path="$3"

  REPOS[$repo_name]="$repo_url $repo_path"

  repo-man/save_state
}

function repo-man/get_info() {
  local -n output="$1"
  local repo_name="$2"

  local data="${REPOS[$repo_name]}"
  read -a data <<< "$data"

  output["url"]="${data[0]}"
  output["path"]="${data[1]}"
}

function repo-man/remove() {
  local repo_name="$1"

  local -A repo_data
  repo-man/get_info repo_data "$repo_name"

  local repo_path="${repo_data[path]}"
  if [ -e "$repo_path" ]; then
    rm "$repo_path"
    unset REPOS[$repo_name]
    repo-man/save_state
    return 0
  fi

  return 1
}

function repo-man/download() {
  local repo_url="$1"

  local tmp="$BPM_TMP_DIR_PATH/repo-$RANDOM.bpr"

  curl -o "$tmp" "$repo_url" >/dev/null 2>&1
  local status=$?

  if [ $status -ne 0 ]; then
    return 1
  fi

  echo "$tmp"
}
