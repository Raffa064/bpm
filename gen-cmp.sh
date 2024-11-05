# Load variables
source ./core/bpm-vars.sh
rm $BPM_AUTOCOMPLETE_PATH # clear output file

# Load bpm core functions
source $BPM_CORE_PATH

declare -A BPM_COMMANDS
for func in $(compgen -A function); do
  if [[ $func =~ ^cmd ]]; then
    func_name="${func:4}"
    cmp_var=$(sed "s/-/_/g" <<< "cmp_$func_name")
    
    BPM_COMMANDS[bpm]+=" $func_name"
    if [ -n "${!cmp_var}" ]; then
      BPM_COMMANDS[$func_name]="${!cmp_var}"
    fi
  fi
done
 
gen_script=""
for cmd in "${!BPM_COMMANDS[@]}"; do
  "$cmd" "${bpm_commands[$cmd]}"
  gen_script+="
  $cmd) opts=\"${BPM_COMMANDS[$cmd]}\";;"
done

TEMPLATE_SCRIPT="
_bpm_autocomplete() {
  local curr_word=\"\${COMP_WORDS[\$COMP_CWORD]}\"
  local prev_word=\"\${COMP_WORDS[\$COMP_CWORD-1]}\"

  COMPREPLY=()
  
  local opt
  case \$prev_word in $gen_script
    *)
  esac

  COMPREPLY=( \$(compgen -W \"\$opts\" -- \"\$curr_word\") )
}

complete -r bpm >/dev/null 2>&1
complete -F _bpm_autocomplete bpm
"

echo "$TEMPLATE_SCRIPT" > "$BPM_AUTOCOMPLETE_PATH"
