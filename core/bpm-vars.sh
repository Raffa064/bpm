BPM_VERSION=1

BPM_DEPENDENCIES=(
  git
)

# Directories
BPM_BIN_PATH="$HOME/.local/bin"
BPM_DIR_PATH="$HOME/.local/.bpm"
BPM_STATE_PATH="$BPM_DIR_PATH/state"
BPM_DEPS_PATH="$BPM_DIR_PATH/deps"

BPM_MKD=(
  "$BPM_BIN_PATH"
  "$BPM_DIR_PATH"
  "$BPM_DEPS_PATH"
  "$BPM_STATE_PATH"
)

# Scripts
BPM_LOCATOR_PATH="$BPM_STATE_PATH/locator.sh"
BPM_CORE_PATH="$BPM_DIR_PATH/core.sh"
BPM_RUNNER_PATH="$BPM_DIR_PATH/runner.sh"

