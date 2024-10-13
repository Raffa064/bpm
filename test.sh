# This script is a playground for testing

title=$(sed -n "1p" <<< "string")
command=$(sed -n "3p" <<< cat ./core/doc/bpm.txt)
text=$(sed "1,3d" <<< cat ./core/doc/bpm.txt)

echo -e "\e[34m$title\n\e[32m\n$command\e[37m\n$text"
