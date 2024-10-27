declare -gA REPOS           # [repo-name]="source path"
declare -gA PACKAGE_ENTRIES # [pkg-name]="url"

function repos/load_state() {
  sh/read_obj REPOS "repo" $BPM_REPOS_SH_PATH
  
  local repo
  for repo in "${!REPOS[@]}"; do
    local -A repo_data
    repos/get_data repo_data $repo
    sh/read_obj PACKAGE_ENTRIES "entry" "${repo_data[path]}"
  done
}

function repos/save_state() {
  sh/write_obj REPOS "repo" "$BPM_REPOS_SH_PATH"
}

function repos/add() {
  local repo_name="$1"
  local repo_url="$2"
  local repo_path="$3"

  REPOS[$repo_name]="$repo_url $repo_path"

  repos/save_state
}

function repos/get_data() {
  local -n output="$1"
  local repo_name="$2"

  local data="${REPOS[$repo_name]}"
  read -a data <<< "$data"

  output["url"]="${data[0]}"
  output["path"]="${data[1]}"
}

function repos/remove() {
  local repo_name="$1"

  local -A repo_data
  repos/get_data repo_data "$repo_name"

  rm ${repo_data[path]}
  unset REPOS[$repo_name]

  repos/save_state
}

function repos/download() {
  local repo_url="$1"

  local tmp="$BPM_TMP_DIR_PATH/repo-$RANDOM.sh"

  curl -o "$tmp" "$repo_url" >/dev/null 2>&1
  local status=$?

  if [ $status -ne 0 ]; then
    return 1
  fi

  echo "$tmp"
}