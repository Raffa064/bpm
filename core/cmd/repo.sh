cmp_repo="add remove list list-repos update info"
function cmd/repo() {
  local command="$1"
  shift

  if [ -z "$command" ]; then
    cmd/help repo
    return
  fi

  repo-man/load_state

  local command_function="repo/$command"
  
  if declare -f "$command_function" >/dev/null; then
    $command_function $@
    return $?
  else
    repo/info "$command"
    return $?
  fi
}

function repo/add() {
  local repo_url="$1"

  echo "Downloanding repo file..."
  local tmp=$(repo-man/download $repo_url)

  if [ -z "$tmp" ]; then
    echo -e "\e[31mCan't locate repo file from url: $repo_url"
    return 1
  fi

  echo "Reading metadata..."
  local -A repo_data
  bpr-repo repo_data "$tmp"
  local status=$?

  if [ $status -ne 0 ]; then
    echo -e "  \e[31m* Error while reading repo: $status\e[37m"
    return 1
  fi

  local repo_name="${repo_data[--metadata-name]}"
  local repo_author="${repo_data[--metadata-author]}"
  local repo_path="$BPM_REPOS_DIR_PATH/$repo_name.bpr"

  if [ -e "$repo_path" ]; then
    echo -e "\e[33mRepo is already installed!\e[37m"
    local -A info
    repo-man/get_info info "$repo_name"
    echo -e "\e[34m  * Url:  ${info[url]}\n  * Path: ${info[path]}\e[37m"
    echo -e "\e[31mTo update repo, use 'bpm update'.\e[37m"
    return 1
  fi
  
  echo "  * Name: $repo_name" 
  echo "  * Author: $repo_author" 
  
  mv "$tmp" "$repo_path"
  
  repo-man/add "$repo_name" "$repo_url" "$repo_path"
}

function repo/remove() {
  local repo_name="$1"

  if [ -n "$repo_name" ]; then
    repo-man/remove "$repo_name"
    local status=$?

    if [ $status -ne 0 ]; then
      echo -e "\e[31mRepo not found\e[37m"
      return 1
    fi
  else
    echo -e "\e[33mRepo name must be specified\e[37m"
    return 1
  fi
}

function repo/info() {
  local repo_name="$1"

  local -A repo_info
  repo-man/get_info repo_info "$repo_name" # Get path and url
  local status=$?

  if [ $status -ne 0 ]; then
    echo -e "\e[31mUnknown repo: '$repo_name'\e[37m"
    return 1
  fi

  bpr-repo repo_info "${repo_info[path]}"  # Get metadata (and all packages)
  local entry_count=${#repo_info[@]}
  entry_count=$(( entry_count - 4 )) # 4 = url + path + name + author

  echo "  * Name: ${repo_info[--metadata-name]}"
  echo "  * Author: ${repo_info[--metadata-author]}"
  echo "  * Entries: $(( entry_count ))"
  echo "  * Url: ${repo_info[url]}"
  echo "  * Path: ${repo_info[path]}"
}

function repo/list() {
  local pkg_name  
  for pkg_name in "${!PACKAGE_ENTRIES[@]}"; do
    echo "${pkg_name:6}" # print repo names without prefix
  done
}

function repo/list-repos() {
  for pkg_name in "${!REPOS[@]}"; do
    echo "$pkg_name"
  done
}

function repo/update() {
  if [ "$1" == "-s" ]; then # silent
    shift
  else
    echo "Updating repositories..."
  fi

  local repo_name="$1"

  if [ -z "$repo_name" ]; then
    for repo_name in $(repo/list-repos); do
      repo/update -s $repo_name
    done
    return
  fi

  local -A repo_info
  repo-man/get_info repo_info "$repo_name"

  local repo_url="${repo_info[url]}"
  local repo_path="${repo_info[path]}"

  local update_path=$(repo-man/download "$repo_url")

  if [ -z "$update_path" ]; then 
    echo -e "  \e[31m* Failed: $repo_name\e[37m"
    return 1
  fi

  rm "$repo_path"
  mv "$update_path" "$repo_path"

  echo -e "  \e[32m* Sucess: $repo_name\e[37m"
}
