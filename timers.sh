#!/bin/bash
# script to execute timed events for bashbot

# while loop that checks timers every 60 seconds
while true; do
    # check if timers dir exists
    if [[ ! -d "$botdir/timers" ]]; then
        mkdir -p "$botdir"/timers
    fi
    # cd to timers dir and run a for loop on each timer in dir
    cd "$botdir"/timers
    for timer in *; do
        # check if any timers exist
        if [[ -z "$timer" ]]; then
            break
        fi
        # if timer is less than or equal to current unix time in nanoseconds
        if [[ "$timer" -le "$(date +%s%N)" ]]; then
            # get timer_action from stored json
            timer_action="$(cat "$botdir"/timers/"$timer" | jq -r '.name')"
            # check if command for timer_action exists
            if [[ -f "${botdir}/commands/${timer_action}.sh" ]]; then
                # get timer_json from timer file
                timer_json="$(cat "$botdir"/timers/"$timer")"
                # run timer_action command with timer_json as argument
                source "$botdir"/commands/"$timer_action".sh "$timer_json"
                rm "$botdir"/timers/"$timer"
            else
                # unknown timer_action
                echo -e "\nUnknown timer action: $timer_action"
                cat "$botdir"/timers/"$timer" | jq '.'
                rm "$botdir"/timers/"$timer"
            fi
        fi
    done
    sleep 60
done
