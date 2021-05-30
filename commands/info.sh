#!/bin/bash

info_supported() {
    mapfile -t results < <(curl -sL 'https://spreadsheets.google.com/tq?&tq=&key=124ayAVJ1QPqEYZvtk_0uT3n-8QByf8LR7A43ah8QvDA&gid=2' | \
    perl -pe 's%(.*google.visualization.Query.setResponse\(|\);)%%gm' | \
    tail -n -1 | \
    jq -c '.table.rows[].c' | \
    tail -n +3 | \
    grep -i "$q" | \
    head -n 25)
    if [[ -z "${results[@]}" ]]; then
        export json="$(jq -n --arg tit "Is ${q^} Supported in Discord Linux?" --arg res "No results found for '$q'." '{ "embeds": [ { "title": $tit, "url": "https://kutt.it/supported", "description": $res, "color": "13458524" } ] }')"
        return
    fi
    json="$(jq -n --arg tit "Is ${q^} Supported in Discord Linux?" '{ "embeds": [ { "type": "rich", "title": $tit, "url": "https://kutt.it/supported", "color": "5793266", "fields": [] } ] }')"
    for result in "${results[@]}"; do
        distro="__$(echo "$result" | jq -r '.[0].v')__"
        supd="**Supported**: $(echo "$result" | jq -r '.[1].v')"
        exp="**Experience Level**: $(echo "$result" | jq -r '.[2].v')"
        recd="**Recommended**: $(echo "$result" | jq -r '.[3].v')"
        notes="$(echo "$result" | jq -r '.[4].v')"
        if [[ "$notes" == "null" ]]; then
            value="$(echo -e "$supd\n$exp\n$recd")"
        else
            notes="**Notes**: $notes"
            value="$(echo -e "$supd\n$exp\n$recd\n$notes")"
        fi
        json="$(echo "$json" | jq --arg dist "$distro" --arg val "$value" '.embeds[0].fields += [ { "name": $dist, "value": $val, "inline": true } ]')"
        unset distro supd exp recd notes value
    done
    export json
}

info_other() {
    embed="$(curl -sL "https://discord-fde27-default-rtdb.firebaseio.com/discord/info/$1.json")"
    if [[ "$embed" == "null" ]]; then
        embed="$(jq -n --arg tit "Info for '$1'" --arg res "No results found for '$1'." '{"embed":{"title":$tit,"description":$res,"color":"13458524"}}')"
    fi
    json="$(printf "%s\n" "$embed" | jq '{ "embeds": [ .embed ] }')"
}

subcmd="$(printf "%s\n" "$@" | jq -r '.options[0].name')"
q="$(printf "%s\n" "$@" | jq -r '.options[0].options[0].value')"
int_id="$(printf "%s\n" "$@" | jq -r '.id')"
int_token="$(printf "%s\n" "$@" | jq -r '.token')"
jq -cn '{ "type": 5 }' | curl -sSLX POST -d @- -H 'content-type: application/json' "https://discord.com/api/v8/interactions/$int_id/$int_token/callback"

case "$subcmd" in
    supported) info_supported "$q";;
    *) 
        if [[ "$subcmd" == "search" ]]; then
            q="$(echo "$q" | jq -Rr '@uri')"
        fi
        info_other "$q"
        ;;
esac

printf "%s\n" "$json" | curl -sSLX PATCH -d @- -H 'content-type: application/json' "https://discord.com/api/v8/webhooks/$client_id/$int_token/messages/@original" > /dev/null
echo -e "\ncommand: $(printf "%s\n" "$@" | jq -r '.name')\nguild: $(printf "%s\n" "$@" | jq -r '.guildId')\nuser: $(printf "%s\n" "$@" | jq -r '.member.user.id')\ntime: $(date)"
