#!/usr/bin/env bash
# Sends one post to one Telegram chat: its text, then its pictures and videos as an album
# replying to it, so the album shows which post it belongs to.
# See @LandingPage#announce#send in spec/. Needs php, curl, jq and ffprobe.
# usage: TELEGRAM_BOT_TOKEN=... send.sh <post folder> <chat id or @channel> [en|ru]
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
post="${1:?usage: send.sh <post folder> <chat> [lang]}"
chat="${2:?usage: send.sh <post folder> <chat> [lang]}"
lang="${3:-ru}"
# TELEGRAM_API, to try it against something other than Telegram
api="${TELEGRAM_API:-https://api.telegram.org}/bot${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is not set}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# a call that fails stops here, with Telegram's own words for why, else prints its answer;
# values given with --form-string, since -F reads one starting with @, as a channel's name
# does, as a file
call() { # method, curl args...
    local answer
    answer="$(curl -sS "$api/$1" "${@:2}")"
    if [[ "$(jq -r .ok <<<"$answer")" != true ]]; then
        echo "$1 failed: $(jq -r '.description // .' <<<"$answer")" >&2
        exit 1
    fi
    printf '%s\n' "$answer"
}

php "$here/render.php" "$post" "$lang" >"$work/post.json"
count="$(jq '.media | length' "$work/post.json")"

text="$(call sendMessage -H 'Content-Type: application/json' -d "$(jq -c --arg chat "$chat" \
    '{chat_id: $chat, text: .text, parse_mode: "HTML", link_preview_options: {is_disabled: true}}' \
    "$work/post.json")" | jq .result.message_id)"
reply="{\"message_id\":$text}"

# the files as the post has them; each video with its own shape
items=() files=() paths=()
for (( i = 0; i < count; i++ )); do
    type="$(jq -r ".media[$i].type" "$work/post.json")"
    file="$(jq -r ".media[$i].file" "$work/post.json")"
    if [[ "$type" == photo ]]; then
        paths+=("$file")
        files+=(-F "f$i=@$file")
        items+=("$(jq -nc --arg m "attach://f$i" '{type: "photo", media: $m}')")
    else
        read -r width height duration < <(ffprobe -v error -select_streams v:0 \
            -show_entries stream=width,height:format=duration -of default=nw=1:nk=1 "$file" | tr '\n' ' '; echo)
        paths+=("$file")
        files+=(-F "f$i=@$file")
        items+=("$(jq -nc --arg m "attach://f$i" --argjson w "$width" --argjson h "$height" \
            --argjson d "${duration%.*}" \
            '{type: "video", media: $m, width: $w, height: $h, duration: $d, supports_streaming: true}')")
    fi
done

if (( count == 1 )); then
    type="$(jq -r '.type' <<<"${items[0]}")"
    extra=()
    [[ "$type" == video ]] && extra=(-F "width=$(jq .width <<<"${items[0]}")" \
        -F "height=$(jq .height <<<"${items[0]}")" -F "duration=$(jq .duration <<<"${items[0]}")" \
        -F supports_streaming=true)
    call "send${type^}" --form-string "chat_id=$chat" --form-string "reply_parameters=$reply" \
        -F "$type=@${paths[0]}" "${extra[@]}" >/dev/null
elif (( count > 1 )); then
    call sendMediaGroup --form-string "chat_id=$chat" --form-string "reply_parameters=$reply" \
        --form-string "media=$(printf '%s\n' "${items[@]}" | jq -sc .)" "${files[@]}" >/dev/null
fi
echo "sent $(basename "$post") to $chat"
