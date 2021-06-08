#!/bin/bash

# function to get list of supported distros from spreadsheet maintained by Faith
info_supported() {
    # use mapfile to create an array split on linebreaks from:
    # curl spreadsheet |
    # get rid of DataTable junk which leaves just json |
    # get rid of first line |
    # output each row from table |
    # get rid of first 3 rows |
    # find results that match $q |
    # limit results to 25 (max amount of fields that can be in embed)
    mapfile -t results < <(curl -sL 'https://spreadsheets.google.com/tq?&tq=&key=124ayAVJ1QPqEYZvtk_0uT3n-8QByf8LR7A43ah8QvDA&gid=2' | \
    perl -pe 's%(.*google.visualization.Query.setResponse\(|\);)%%gm' | \
    tail -n -1 | \
    jq -c '.table.rows[].c' | \
    tail -n +3 | \
    grep -i "$1" | \
    head -n 25)
    # check if results found
    if [[ -z "${results[@]}" ]]; then
        # results not found; set json to error message and return
        export json="$(jq -n --arg tit "Is ${1^} Supported in Discord Linux?" --arg res "No results found for '${1^}'." '{ "embeds": [ { "title": $tit, "url": "https://kutt.it/supported", "description": $res, "color": "13458524" } ] }')"
        return
    fi
    # results found; set initial json with title, url, color, and empty fields array
    json="$(jq -n --arg tit "Is ${1^} Supported in Discord Linux?" '{ "embeds": [ { "type": "rich", "title": $tit, "url": "https://kutt.it/supported", "color": "5793266", "fields": [] } ] }')"
    # run a for loop on the results to populate the fields
    for result in "${results[@]}"; do
        # distro 1st column
        distro="__$(echo "$result" | jq -r '.[0].v')__"
        # supported status 2nd column
        supd="**Supported**: $(echo "$result" | jq -r '.[1].v')"
        # experience level 3rd column
        exp="**Experience Level**: $(echo "$result" | jq -r '.[2].v')"
        # recommended status 4th column
        recd="**Recommended**: $(echo "$result" | jq -r '.[3].v')"
        # if notes exist, 5th column
        notes="$(echo "$result" | jq -r '.[4].v')"
        # if notes not found, do not include it in value
        if [[ "$notes" == "null" ]]; then
            value="$(echo -e "$supd\n$exp\n$recd")"
        # else format notes var and add to value
        else
            notes="**Notes**: $notes"
            value="$(echo -e "$supd\n$exp\n$recd\n$notes")"
        fi
        # add the values above to the existing fields array in the embed
        json="$(echo "$json" | jq --arg dist "$distro" --arg val "$value" '.embeds[0].fields += [ { "name": $dist, "value": $val, "inline": true } ]')"
        # unset any vars that might cause problems
        unset distro supd exp recd notes value
    done
    export json
}

# function to handle all other info queries
info_other() {
    # try to get embed from firebase real time database
    embed="$(curl -sL "https://discord-fde27-default-rtdb.firebaseio.com/discord/info/$1.json")"
    if [[ "$embed" == "null" ]]; then
        # set embed to error if no entry in firebase exists
        # TODO: check wikipedia for results here and then set embed to error if no wikipedia results
        embed="$(jq -n --arg tit "Info for '$1'" --arg res "No results found for '$1'." '{"embed":{"title":$tit,"description":$res,"color":"13458524"}}')"
    fi
    # setup json using embed var from above
    json="$(printf "%s\n" "$embed" | jq '{ "embeds": [ .embed ] }')"
}

# get value of first option
opt_value="$(printf "%s\n" "$@" | jq -r '.options[0].value')"
# get interaction ID
int_id="$(printf "%s\n" "$@" | jq -r '.id')"
# get interaction token
int_token="$(printf "%s\n" "$@" | jq -r '.token')"
# respond to interaction with type 5 to tell user we're thinking and to prevent interaction timeout
jq -cn '{ "type": 5 }' | curl -sSLX POST -d @- -H 'content-type: application/json' "https://discord.com/api/v8/interactions/$int_id/$int_token/callback"

# check opt_value
case "$opt_value" in
    supported)
        # set q to value of second option and run info_supported function
        q="$(printf "%s\n" "$@" | jq -r '.options[1].value')"
        info_supported "$q"
        ;;
    search)
        # set q to lowercase uri encoded value of second option and run info_other function
        q="$(printf "%s\n" "$@" | jq -r '.options[1].value | ascii_downcase | @uri')"
        info_other "$q"
        ;;
    *) 
        # set q to opt_value and run info_other function
        q="$opt_value"
        info_other "$q"
        ;;
esac

# send json from above as data to webhook API using client_id and int_token to edit interaction with our results
printf "%s\n" "$json" | curl -sSLX PATCH -d @- -H 'content-type: application/json' "https://discord.com/api/v8/webhooks/$client_id/$int_token/messages/@original" > /dev/null
# log command, guild, user, and time
echo -e "\ncommand: $(printf "%s\n" "$@" | jq -r '.name')\nguild: $(printf "%s\n" "$@" | jq -r '.guildId')\nuser: $(printf "%s\n" "$@" | jq -r '.member.user.id')\ntime: $(date)"
