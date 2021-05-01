#!/usr/bin/env bash

################################# SET VARIABLES ################################

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pomodoro_duration_minutes="@pomodoro_mins"
pomodoro_break_minutes="@pomodoro_break_mins"

pomodoro_on="@pomodoro_on"
pomodoro_complete="@pomodoro_complete"
pomodoro_on_default="P:"
pomodoro_complete_default="✅"

POMODORO_DIR="/tmp"
POMODORO_FILE="$POMODORO_DIR/pomodoro.txt"
POMODORO_STATE_FILE="$POMODORO_DIR/pomodoro_state.txt"

source $CURRENT_DIR/helpers.sh

################################# FUNCTIONALITY ################################

get_pomodoro_duration () {
    get_tmux_option "$pomodoro_duration_minutes" "25"
}

get_pomodoro_break () {
    get_tmux_option "$pomodoro_break_minutes" "5"
}

get_seconds () {
    date +%s
}

write_pomodoro_start_time () {
    mkdir -p $POMODORO_DIR
    echo $(get_seconds) > $POMODORO_FILE
    echo "0" > $POMODORO_STATE_FILE
}

write_pomodoro_state () {
  echo "1" > $POMODORO_STATE_FILE
}

read_pomodoro_state () {
    if [ -f $POMODORO_STATE_FILE ]
    then
        cat $POMODORO_STATE_FILE
    else
        echo -1
    fi
}

read_pomodoro_start_time () {
    if [ -f $POMODORO_FILE ]
    then
        cat $POMODORO_FILE
    else
        echo -1
    fi
}

remove_pomodoro_state () {
    if [ -f $POMODORO_STATE_FILE ]
    then
        rm $POMODORO_STATE_FILE
    fi
}

remove_pomodoro_start_time () {
    if [ -f $POMODORO_FILE ]
    then
        rm $POMODORO_FILE
    fi
}

if_inside_tmux () {
    test -n "${TMUX}"
}

pomodoro_start () {
    write_pomodoro_start_time
    if_inside_tmux && tmux refresh-client -S
    return 0
}

pomodoro_cancel () {
    remove_pomodoro_start_time
    remove_pomodoro_state
    if_inside_tmux && tmux refresh-client -S
    return 0
}

notify () {
    local title=$1
    local message=$2
    osascript -e 'display notification "'"$title"'" with title "'"$message"'" subtitle "TBD" sound name "Glass"'
}

pomodoro_status () {
    local pomodoro_start_time=$(read_pomodoro_start_time)
    local has_pomodoro_finished=$(read_pomodoro_state)
    local current_time=$(get_seconds)
    local difference=$(( ($current_time - $pomodoro_start_time) / 60 ))
    
    if [ $pomodoro_start_time -eq -1 ]
    then
        echo ""
    elif [ $difference -ge $(( $(get_pomodoro_duration) + $(get_pomodoro_break) )) ]
    then
        pomodoro_start_time=-1
        echo ""
    elif [ $difference -ge $(get_pomodoro_duration) ]
    then
        if [ $has_pomodoro_finished -eq 0 ]
        then
          notify "Pomodoro" "Finished Pomodoro"
        fi
        write_pomodoro_state
        printf "$(get_tmux_option "$pomodoro_complete" "$pomodoro_complete_default")$(( -($difference - $(get_pomodoro_duration) - $(get_pomodoro_break)) )) "
    else
        printf "$(get_tmux_option "$pomodoro_on" "$pomodoro_on_default")$(( $(get_pomodoro_duration) - $difference )) "
    fi
}

main () {
    cmd=$1
    shift
    
    if [ "$cmd" = "start" ]
    then
        pomodoro_start
        notify "Pomodoro" "Starting Pomodoro"
    elif [ "$cmd" = "cancel" ]
    then
        pomodoro_cancel
        notify "Pomodoro" "Pomodoro Cancelled"
    else
        pomodoro_status
    fi
}

main $@
