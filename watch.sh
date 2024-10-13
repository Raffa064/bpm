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

reload_count=1
while inotifywait -q -r -e close_write,moved_to,create $watch_path; do
  clear
  yes | bash "$script"
  echo -e "\e[31m[ Watched $reload_count time(s) ]\e[37m\a\a"
  reload_count=$((reload_count + 1))
done
