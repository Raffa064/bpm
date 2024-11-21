# Merge all scripts from a given path into a single on the target path
function compile_scripts() {
  local path="$1"
  local target_path="$2"

  rm "$target_path" >/dev/null 2>&1

  echo -e "# Compiled by $(whoami) at $(date)\n" > "$target_path"
  local file_path
  for file_path in $(find "$path" -regex ".*\.sh"); do
    echo "# $file_path" >> "$target_path"
    cat $file_path >> "$target_path"
  done
}

# Compiles the ./<module-name> to single script on the specified path
# NOTE: A module can define a deps.txt file, wich can import scripts outside module folder
function compile_module() {
  local module_name="$1"
  local module_path="$2"

  mkdir ./tmp 

  echo "Generating $module_name module..."
  cp -r "./$module_name" ./tmp

  echo "  * Copying dependencies..."
  for dep in $(cat "./$module_name/deps.txt"); do 
    cp "$dep" "tmp/$(basename $dep)"
  done

  echo "  * Compiling $module..."
  compile_scripts ./tmp $module_path

  rm -rf tmp
}
