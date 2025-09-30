# Set a custom session root path. Default is `$HOME`.
# layouts/cc-dev.session.sh
# Must be called before `initialize_session`.
session_root "$HOME/Documents/github-uphill/civil-communicator/"
# Check if tmux is running, and start it if not
if ! pgrep tmux >/dev/null; then
  tmux start-server
fi

# Create session with specified name if it does not already exist. If no
# argument is given, session name will be based on layout file name.
if initialize_session "cc-dev"; then
  new_window ""
  run_cmd "cd $session_root"
  run_cmd "yazi"
  new_window ""
  run_cmd "cd $session_root"
  run_cmd "claude"
  new_window ""
  run_cmd "cd $session_root"
  run_cmd "npm run dev"
  select_window 1
fi

# Finalize session creation and switch/attach to it.
finalize_and_go_to_session
