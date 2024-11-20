# Load variables
source ./core/bpm-vars.sh

# Load bpm core functions
source $BPM_CORE_PATH

echo "  * Loading commands..."
declare -A BPM_COMMANDS
for func in $(compgen -A function); do
  if [[ $func =~ ^cmd ]]; then # check for cmd prefix
    cmd_name="${func:4}"
    cmp_var=$(sed "s/-/_/g" <<< "cmp_$cmd_name")
    
    BPM_COMMANDS[bpm]+="$cmd_name " # bpm command
    if [ -n "${!cmp_var}" ]; then
      BPM_COMMANDS[$cmd_name]="${!cmp_var}" # bpm subcommand
    fi
  fi
done

# Generate completion script 
echo "  * Generating script..." 
gen_script=""
for cmd in "${!BPM_COMMANDS[@]}"; do
  gen_script+="
  $cmd) opts=\"${BPM_COMMANDS[$cmd]}\";;"
done

TEMPLATE_SCRIPT="# Autogenerated script
_bpm_autocomplete() {
  local curr_word=\"\${COMP_WORDS[\$COMP_CWORD]}\"
  local prev_word=\"\${COMP_WORDS[\$COMP_CWORD-1]}\"
  
  local opt
  case \$prev_word in $gen_script
    *) return 1
  esac

  COMPREPLY=( \$(compgen -W \"\$opts\" -- \"\$curr_word\") )
}

complete -r bpm >/dev/null 2>&1
complete -F _bpm_autocomplete bpm
"

# Write into the output file (replace mode)
echo "  * Writing to a file..."
echo "$TEMPLATE_SCRIPT" > "$BPM_AUTOCOMPLETE_PATH"
