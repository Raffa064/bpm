function bpr-repo() {
  local -n _output="$1"
  local repo_path="$2"
 
  bpr/load _output repo "$repo_path"
  return $?
}

function bpr-repo/metadata() {
  output["--metadata-$1"]="$2"
}

function bpr-repo/entry() {
  output["repo-$1"]="$2"
}

