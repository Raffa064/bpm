# ./watch.sh install.sh  Automatically install bpm 
# ./watch.sh test.sh -j  Automatically run test script

script="$1"
opt="$2"

if [ -z "$script" ]; then
  echo "Your must specify some script to run."
  exit
fi

watch_path="./"

if [ "$opt" == "-j" ]; then
  # Just script
  watch_path="$script"
fi

function notibell() {
  local delays

  read -a delays <<< "$@ 0"

  for delay in "${delays[@]}"; do
    echo -en "\a"  
    sleep $delay
  done
}

reload_count=1
while inotifywait -q -r -e close_write,moved_to,create $watch_path; do
  notibell .24
  clear
  yes | bash "$script"
  echo -e "\e[31m[ Watched $reload_count time(s) ]\e[37m"
  reload_count=$((reload_count + 1))
  notibell 0.15 0.1 0.1
  sleep 1
done
