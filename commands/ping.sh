#!/bin/bash

# get interaction id from input
int_id="$(printf "%s\n" "$@" | jq -r '.id')"
# convert interaction id snowflake to unix time in ms
int_time="$(((int_id>>22)+1420070400000))"
# get ping by subtracting int_time from current unix time in ms
ping="Pong! ($((($(date +%s%N)/1000000)-${int_time}))ms)"
# get interaction token from input
int_token="$(printf "%s\n" "$@" | jq -r '.token')"

# use jq to create json and curl to make request to respond to interaction
jq -n --arg pg "$ping" '{ "type": 4, "data": { "content": $pg } }' | curl -sSLX POST -d @- -H 'content-type: application/json' "https://discord.com/api/v8/interactions/$int_id/$int_token/callback" > /dev/null
# log command, guild, user, and time
echo -e "\ncommand: $(printf "%s\n" "$@" | jq -r '.name')\nguild: $(printf "%s\n" "$@" | jq -r '.guildId')\nuser: $(printf "%s\n" "$@" | jq -r '.member.user.id')\ntime: $(date)"
