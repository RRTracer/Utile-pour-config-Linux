#!/usr/bin/env bash

echo '#!/usr/bin/env bash'
echo

tmux list-sessions -F '#{session_name}' | while read -r session; do

    first_window=1

    tmux list-windows -t "$session" \
        -F '#{window_index}|#{window_name}|#{window_layout}' |
    while IFS='|' read -r win_idx win_name layout; do

        if [ "$first_window" -eq 1 ]; then
            echo "tmux new-session -d -s '$session' -n '$win_name'"
            first_window=0
        else
            echo "tmux new-window -t '$session' -n '$win_name'"
        fi

        pane_count=$(
            tmux list-panes \
                -t "$session:$win_idx" \
                | wc -l
        )

        for ((i=1; i<pane_count; i++)); do
            echo "tmux split-window -t '$session:$win_name'"
        done

        echo "tmux select-layout -t '$session:$win_name' '$layout'"

        pane_idx=0
        tmux list-panes \
            -t "$session:$win_idx" \
            -F '#{pane_current_path}' |
        while read -r path; do
            echo "tmux send-keys -t '$session:$win_name.$pane_idx' 'cd \"$path\"' C-m"
            pane_idx=$((pane_idx+1))
        done

    done

done