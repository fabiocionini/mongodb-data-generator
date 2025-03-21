#!/bin/bash

SESSION_NAME="mongo-data-progress"

# Kill previous session if exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
  echo "🗑️  Removing existing tmux session '$SESSION_NAME'..."
  tmux kill-session -t $SESSION_NAME
fi

echo "🔄 Launching tmux session '$SESSION_NAME' with live progress bars..."

# Start tmux detached
tmux new-session -d -s $SESSION_NAME

# Split vertically (top/bottom)
tmux split-window -v

# Top pane → data-generator progress
tmux select-pane -t 0
tmux send-keys "export DOCKER_CLI_HINTS=false; docker compose --project-name mongodb-data-generator attach data-generator" C-m

# Middle pane → mongoimporter logs
tmux select-pane -t 1
tmux send-keys "
export DOCKER_CLI_HINTS=false;
echo '⏳ Waiting for mongoimporter container...';
while ! docker compose ps | grep mongoimporter | grep 'Up'; do
  sleep 2;
done;
echo '✅ mongoimporter running. Tailing importer.log...';
docker exec -it mongoimporter bash -c 'tail -f /data/importer.log'
" C-m

# Add third pane (small) to monitor container status
tmux split-window -v -p 10  # Small 10% bottom pane
tmux send-keys "
while true; do
  DG_STATUS=\$(docker compose ps | grep data-generator | grep -c 'Up')
  IMPORTER_STATUS=\$(docker compose ps | grep mongoimporter | grep -c 'Up')

  if [ \"\$DG_STATUS\" -eq 0 ] && [ \"\$IMPORTER_STATUS\" -eq 0 ]; then
    echo '✅ Both containers finished. Waiting 15 seconds...';
    sleep 15;
    echo '🚪 Exiting tmux now...';
    tmux kill-session -t $SESSION_NAME
    exit 0
  fi
  sleep 5
done
" C-m

# Start focused in top pane
tmux select-pane -t 0

echo "✨ Tmux session ready. It will auto-close 15 seconds after everything completes."

# Attach to tmux
tmux attach -t $SESSION_NAME
