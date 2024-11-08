cmp_repo="add remove list list-repos update"
function cmd/repo() {
  local command="$1"
  shift

  repo-man/load_state

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
  local tmp=$(repo-man/download $repo_url)

  if [ -z "$tmp" ]; then
    echo -e "\e[31mCan't locate repo file from url: $repo_url"
    return 
  fi

  echo "Reading metadata..."
  local -A data
  bpr-repo data "$tmp"
  local status=$?


  if [ $status -ne 0 ]; then
    echo -e "  \e[31m* Error while reading repo: $status\e[37m"
    return
  fi

  local repo_name="${data[--metadata-name]}"
  local repo_path="$BPM_REPOS_DIR_PATH/$repo_name.bpr"

  if [ -e "$repo_path" ]; then
    echo -e "\e[33mRepo file already exists!\e[37m"
    local data="${REPOS[$repo_name]}"
    read -a data <<< "$data"
    echo -e "\e[34m  * Url:  ${data[0]}\n  * Path: ${data[1]}\e[37m"
    echo -e "\e[31m[Aborted]\e[37m"
    return
  fi

  echo "  * Repo name: $repo_name" 
  
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
    fi
  else
    echo -e "\e[33mRepo name must be specified\e[37m"
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
    echo "Updating repositories..."
  fi

  local repo_name="$1"

  if [ -z "$repo_name" ]; then
    for repo_name in $(repo/list-repos); do
      repo/update -s $repo_name
    done
    return
  fi

  local -A repo_data
  repo-man/get_data repo_data "$repo_name"

  local repo_url="${repo_data[url]}"
  local repo_path="${repo_data[path]}"
  local update_path=$(repo-man/download "$repo_url")

  if [ -z "$update_path" ]; then 
    echo -e "  \e[31m* Failed: $repo_name\e[37m"
    return
  fi

  rm "$repo_path"
  mv "$update_path" "$repo_path"

  echo -e "  \e[32m* Sucess: $repo_name\e[37m"
}
