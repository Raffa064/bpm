cmp_repo="add remove list list-repos update"
function cmd/repo() {
  local command="$1"
  shift

  repos/load_state

  local command_function="repo/$command"
  
  if declare -f "$command_function" >/dev/null; then
    $command_function $@
  else
    echo -e "\e[31mInvalid command: $command\e[37m"
  fi
}

function repo/add() {
  local repo_url="$1"

  echo "Downloanding repo file..."
  local tmp=$(repos/download $repo_url)

  if [ -z "$tmp" ]; then
    echo -e "\e[31mCan't locate repo file from url: $repo_url"
    return 
  fi

  echo "Reading metadata..."
  local -A entry
  sh/read_obj entry "$tmp"

  local repo_name="${entry[--repo-name]}"
  local repo_path="$BPM_REPOS_DIR_PATH/$repo_name.sh"
  local repo_count="${#entry[@]}"
  repo_count=$((repo_count - 1))

  echo "  * Repo name: $repo_name" 
  echo "  * Package count: $repo_count" 

  if [ -e "$repo_path" ]; then
    echo -e "\e[33mRepo file already exists!\e[37m"
    local repo_data="${REPOS[$repo_name]}"
    read -a repo_data <<< "$repo_data"
    echo -e "\e[34m  * Url:  ${repo_data[0]}\n  * Path: ${repo_data[1]}\e[37m"
    echo -e "\e[31m[Aborted]\e[37m"
    return
  fi

  mv "$tmp" "$repo_path"
  
  repos/add "$repo_name" "$repo_url" "$repo_path"
}

function repo/remove() {
  local repo_name="$1"

  if [ ! -z "$repo_name" ]; then
    repos/remove "$repo_name"
  else
    echo -e "\e[31mCan't locate repo: '$repo_name'\e[37m"
  fi
}

function repo/list() {
  local pkg_name  
  for pkg_name in "${!PACKAGE_ENTRIES[@]}"; do
    if [ ! "$pkg_name" == "--repo-name" ]; then
      echo "$pkg_name"
    fi
  done
}

function repo/list-repos() {
  for pkg_name in "${!REPOS[@]}"; do
    echo "$pkg_name"
  done
}

function repo/update() {
  if [ "$1" == "-s" ]; then
    shift
  else
    echo "Updating repo(s): $@"
  fi

  local repo_name="$1"

  if [ -z "$repo_name" ]; then
    for repo_name in $(repo/list-repos); do
      repo/update -s $repo_name
    done
    return
  fi

  local -A repo_data
  repos/get_data repo_data "$repo_name"

  local repo_url="${repo_data[url]}"
  local repo_path="${repo_data[path]}"
  local update_path=$(repos/download "$repo_url")

  if [ -z "$update_path" ]; then 
    echo -e "  \e[31m* Failed: $repo_name\e[37m"
    return
  fi

  rm "$repo_path"
  mv "$update_path" "$repo_path"

  echo -e "  \e[32m* Sucess: $repo_name\e[37m"
}
