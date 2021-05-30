#!/bin/bash
# Author: Syretia
# License: MIT
# script to create fifo pipe, run while loop to monitor it, and start node bot process

# set botdir variable
export botdir="$(dirname "$(readlink -f "$0")")"
# get variables from .env file
source "$botdir"/.env

# function to create fifo pipe and run while loop to monitor it
pipestart() {
	# remove pipe on exit
	trap "rm -f /tmp/.botpipe" EXIT
	# create pipe if it doesn't exist
	if [[ ! -p "/tmp/.botpipe" ]]; then
		mkfifo /tmp/.botpipe
	fi
	# while loop to monitor pipe
	while true; do
		# read line from fifo pipe
		if IFS= read -r line </tmp/.botpipe; then
			# get set .name in json as input
			input="$(printf "%s\n" "$line" | jq -r '.name' 2>/dev/null)"
			# check if command script exists for input
			if [[ -f "${botdir}/commands/${input}.sh" ]]; then
				# source command script with line var as argument and fork it
				source "$botdir"/commands/"$input".sh "$line" & disown
			# break if input is exit and user id == owner_id
			elif [[ "$input" == "exit" && "$(printf "%s\n" "$line" | jq -r '.member.user.id')" == "$owner_id" ]]; then
				break
			# else unknown input
			else
				echo -e "\nUnknown input:"
				printf "%s\n" "$line" | jq -r '.' 2>/dev/null || printf "%s\n" "$line"
			fi
			unset input
		fi
	done
	# remove pipe before exiting
	rm -f /tmp/.botpipe
	exit 0
}

# function to kill node and this script on exit or sigint
exitfunc() {
	pkill node
	pkill bashbot
}

# start and fork pipe function
echo "Starting bashbot pipe..."
pipestart & disown

# sleep to allow pipe to be created
sleep 1
trap "exitfunc" EXIT SIGINT
# cd to botdir and start node process redirected to fifo pipe
echo "Starting bashbot node process..."
cd "$botdir"
node index.js > /tmp/.botpipe
