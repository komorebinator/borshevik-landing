#!/usr/bin/env bash
# Checks for what breaks silently: see @LandingPage#tests#checks in spec/.
# Needs php-cli, jq and curl. Never writes into the repository.
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

failed=0
ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

tmp="$(mktemp -d)"
server_pid=""
cleanup() {
    [ -n "$server_pid" ] && kill "$server_pid" 2>/dev/null
    rm -rf "$tmp"
}
trap cleanup EXIT

# 1. the PHP parses
for f in index.php download.php iso.php; do
    if out="$(php -l "$f" 2>&1)"; then
        ok "php-syntax $f"
    else
        fail "php-syntax $f" "$out"
    fi
done

# 2. applications.json is what the App Manager accepts
if jq -e '
    type == "array" and length > 0 and all(.[];
        (.name | type == "string" and length > 0)
        and (.applications | type == "array" and length > 0
             and all(.[]; type == "string" and length > 0))
        and ((has("default") | not) or (.default | type == "boolean")))
' share/applications.json >/dev/null 2>&1; then
    ok applications-json
else
    fail applications-json "share/applications.json is not an array of {name, applications[, default]} categories"
fi

# 3. every template carries exactly the placeholders index.php replaces
expected="CHECKSUM_NVIDIA CHECKSUM_STANDARD ISO_NVIDIA_FILE ISO_STANDARD_FILE LANG SIZE_NVIDIA_PART SIZE_STANDARD_PART YEAR"
for tpl in templates/*.html; do
    found="$(grep -o '{{[A-Za-z_]*}}' "$tpl" | tr -d '{}' | sort -u | tr '\n' ' ' | sed 's/ $//')"
    if [ "$found" = "$expected" ]; then
        ok "placeholders $tpl"
    else
        missing="$(comm -23 <(tr ' ' '\n' <<<"$expected") <(tr ' ' '\n' <<<"$found") | tr '\n' ' ')"
        unknown="$(comm -13 <(tr ' ' '\n' <<<"$expected") <(tr ' ' '\n' <<<"$found") | tr '\n' ' ')"
        fail "placeholders $tpl" "missing: ${missing:-none}; unknown: ${unknown:-none}"
    fi
done

# 4. the offered names are well-formed, and never a permanent link's own name
offered="$(php -r '$i = require "iso.php"; ksort($i); echo implode(" ", array_keys($i)), "\n", $i["standard"] ?? "", "\n", $i["nvidia"] ?? "", "\n";' 2>&1)"
keys="$(sed -n 1p <<<"$offered")"
standard="$(sed -n 2p <<<"$offered")"
nvidia="$(sed -n 3p <<<"$offered")"
problems=""
[ "$keys" = "nvidia standard" ] || problems+="keys are '$keys', not 'nvidia standard'; "
[[ "$standard" =~ ^borshevik-[0-9]{8}(-[0-9]+)?\.iso$ ]] || problems+="standard name '$standard' is malformed; "
[[ "$nvidia" =~ ^borshevik-nvidia-[0-9]{8}(-[0-9]+)?\.iso$ ]] || problems+="nvidia name '$nvidia' is malformed; "
if [ -z "$problems" ]; then ok offered-isos; else fail offered-isos "$problems"; fi

# 5. the permanent links are rewritten to download.php
problems=""
for rule in \
    'RewriteRule ^iso/borshevik-stable\.iso$ download.php?variant=standard [L]' \
    'RewriteRule ^iso/borshevik-stable\.iso-CHECKSUM$ download.php?variant=standard&file=checksum [L]' \
    'RewriteRule ^iso/borshevik-nvidia-stable\.iso$ download.php?variant=nvidia [L]' \
    'RewriteRule ^iso/borshevik-nvidia-stable\.iso-CHECKSUM$ download.php?variant=nvidia&file=checksum [L]'; do
    grep -qxF "$rule" .htaccess || problems+="missing: $rule; "
done
grep -qx 'RewriteEngine On' .htaccess || problems+="missing: RewriteEngine On; "
if [ -z "$problems" ]; then ok htaccess; else fail htaccess "$problems"; fi

# 6. the page renders: language, links, ISO size and checksum, nothing left unreplaced
mkdir "$tmp/site"
cp -r index.php iso.php download.php templates "$tmp/site/"
mkdir "$tmp/site/iso"
checksum="$(printf 'a%.0s' {1..64})"
if [ -n "$standard" ]; then
    truncate -s 2G "$tmp/site/iso/$standard"
    printf '%s  %s\n' "$checksum" "$standard" > "$tmp/site/iso/$standard-CHECKSUM"
fi

render() { # lang, accept-language
    (cd "$tmp/site" && php -r '$_GET = $argv[1] === "" ? [] : ["lang" => $argv[1]];
        $_SERVER["HTTP_ACCEPT_LANGUAGE"] = $argv[2];
        include "index.php";' -- "$1" "$2" 2>&1)
}

check_render() { # name, lang, accept-language, expected html lang
    local page problems=""
    page="$(render "$2" "$3")"
    grep -q "<html lang=\"$4\">" <<<"$page" || problems+="not rendered in $4; "
    grep -qF "href=\"/iso/$standard\"" <<<"$page" || problems+="no link to the offered standard ISO; "
    grep -qF "href=\"/iso/$nvidia\"" <<<"$page" || problems+="no link to the offered NVIDIA ISO; "
    grep -q " · 2.0 GB" <<<"$page" || problems+="no standard ISO size; "
    grep -q "$checksum" <<<"$page" || problems+="no standard ISO checksum; "
    [ "$(grep -o ' · [0-9.]* GB' <<<"$page" | wc -l)" -le 1 ] || problems+="a size shown for the absent NVIDIA ISO; "
    ! grep -q '{{' <<<"$page" || problems+="unreplaced placeholder; "
    if [ -z "$problems" ]; then ok "render $1"; else fail "render $1" "$problems"; fi
}

check_render "lang=ru"                   ru ""                          ru
check_render "Accept-Language ru-RU"     "" "ru-RU,ru;q=0.9,en;q=0.8"   ru
check_render "Accept-Language de -> en"  "" "de"                        en

# 7. download.php redirects to the offered files
port="$(php -r '$s = stream_socket_server("tcp://127.0.0.1:0"); echo explode(":", stream_socket_get_name($s, false))[1];')"
php -S "127.0.0.1:$port" -t "$tmp/site" >/dev/null 2>&1 &
server_pid=$!
for _ in $(seq 50); do curl -s -o /dev/null "http://127.0.0.1:$port/iso.php" && break; sleep 0.1; done

check_download() { # query, expected "code location-path"
    local got
    got="$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "http://127.0.0.1:$port/download.php?$1")"
    got="${got/http:\/\/127.0.0.1:$port/}"
    if [ "$got" = "$2" ]; then ok "download $1"; else fail "download $1" "got '$got', expected '$2'"; fi
}

check_download "variant=standard"               "302 /iso/$standard"
check_download "variant=nvidia"                 "302 /iso/$nvidia"
check_download "variant=standard&file=checksum" "302 /iso/$standard-CHECKSUM"
check_download "variant=bogus"                  "404 "

if [ "$failed" -eq 0 ]; then
    echo "all checks pass"
fi
exit "$failed"
