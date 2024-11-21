BPM_BASH_INSERTION=( "source $BPM_BASH_INSERTION_PATH" )
function bash/insert() {
  BPM_BASH_INSERTION+=( "$1" )
}

