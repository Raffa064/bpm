function d/update_locator() {
  while :; do
    locator/load_state
    locator/update --fix
    sleep $DAEMON_LOCATOR_UPDATE_DELAY
  done
}
