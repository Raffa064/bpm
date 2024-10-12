while inotifywait -q -r -e close_write,moved_to,create ./; do
  yes | bash ./install.sh
  echo -e "\e[31m$RANDOM\e[37m\a\a"
done
