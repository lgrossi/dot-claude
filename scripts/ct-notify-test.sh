#!/usr/bin/env bash
# ct-notify-test: Send test notifications for each type.
# Usage: ct-notify-test.sh [command]
#   ct-notify-test.sh           — test all notification types (icons, sounds)
#   ct-notify-test.sh focus     — test click-to-focus (sends one, waits for click)
#   ct-notify-test.sh [color]   — test all types with a tmux session color override

set -euo pipefail

# Clear icon cache so fresh icons generate
rm -f ~/.claude/icons/*.png 2>/dev/null || true

SESSION=$(tmux display-message -p '#S' 2>/dev/null || true)

send() {
    local type="$1" label="$2"
    echo "  $label"
    echo "{\"notification_type\":\"$type\",\"title\":\"Test\",\"message\":\"$label\"}" | ct notify
}

case "${1:-all}" in
    focus)
        echo "Focus test: a notification will appear."
        echo "  Click 'Focus terminal' (or 'Switch to session') to verify it raises this window."
        echo ""
        send "idle_prompt" "Click the action button to focus terminal"
        echo ""
        echo "Waiting... click the notification action button."
        echo "(If nothing happens, xdotool is needed for X11, and GNOME Wayland blocks window activation.)"
        ;;
    all|[#]*)
        if [ "${1:-}" != "all" ] && [ -n "${1:-}" ]; then
            COLOR="$1"
            if [ -n "$SESSION" ]; then
                tmux set-option -t "$SESSION" @session_color "$COLOR" 2>/dev/null || true
                echo "tmux session: $SESSION (color override: $COLOR)"
            else
                echo "No tmux session — color override ignored, using per-type colors"
            fi
        else
            if [ -n "$SESSION" ]; then
                echo "tmux session: $SESSION"
            else
                echo "No tmux session — using per-type colors"
            fi
        fi

        echo ""
        echo "Sending notifications (3s apart)..."
        echo "  Colors: red=permission, blue=idle, amber=question, green=complete"
        echo "  Sound: first 3 = warning beep, last = completion chime"
        echo ""

        send "permission_prompt"  "1/4 permission_prompt (red, lock)"
        sleep 3
        send "idle_prompt"        "2/4 idle_prompt (blue, chat)"
        sleep 3
        send "elicitation_dialog" "3/4 elicitation_dialog (amber, question)"
        sleep 3
        send "task_complete"      "4/4 task_complete (green, check)"

        echo ""
        echo "Icons generated:"
        ls ~/.claude/icons/ 2>/dev/null || echo "  (none)"
        ;;
esac
