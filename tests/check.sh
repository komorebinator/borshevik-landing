#!/usr/bin/env bash
# Checks for what breaks silently: see @LandingPage#tests#checks in spec/.
# Needs php-cli and jq. Never writes into the repository.
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

failed=0
ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

# 1. index.php parses
if out="$(php -l index.php 2>&1)"; then
    ok php-syntax
else
    fail php-syntax "$out"
fi

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
expected="CHECKSUM_NVIDIA CHECKSUM_STANDARD LANG SIZE_NVIDIA_PART SIZE_STANDARD_PART YEAR"
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

# 4. the page renders: language choice, ISO size and checksum, nothing left unreplaced
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -r index.php templates "$tmp/"
mkdir "$tmp/iso"
truncate -s 2G "$tmp/iso/borshevik-stable.iso"
checksum="$(printf 'a%.0s' {1..64})"
printf '%s  borshevik-stable.iso\n' "$checksum" > "$tmp/iso/borshevik-stable.iso-CHECKSUM"

render() { # lang, accept-language
    (cd "$tmp" && php -r '$_GET = $argv[1] === "" ? [] : ["lang" => $argv[1]];
        $_SERVER["HTTP_ACCEPT_LANGUAGE"] = $argv[2];
        include "index.php";' -- "$1" "$2" 2>&1)
}

check_render() { # name, lang, accept-language, expected html lang
    local page
    page="$(render "$2" "$3")"
    local problems=""
    grep -q "<html lang=\"$4\">" <<<"$page" || problems+="not rendered in $4; "
    grep -q " · 2.0 GB" <<<"$page" || problems+="no standard ISO size; "
    grep -q "$checksum" <<<"$page" || problems+="no standard ISO checksum; "
    [ "$(grep -o ' · [0-9.]* GB' <<<"$page" | wc -l)" -le 1 ] || problems+="a size shown for the absent NVIDIA ISO; "
    ! grep -q '{{' <<<"$page" || problems+="unreplaced placeholder; "
    if [ -z "$problems" ]; then ok "render $1"; else fail "render $1" "$problems"; fi
}

check_render "lang=ru"                   ru ""                          ru
check_render "Accept-Language ru-RU"     "" "ru-RU,ru;q=0.9,en;q=0.8"   ru
check_render "Accept-Language de -> en"  "" "de"                        en

if [ "$failed" -eq 0 ]; then
    echo "all checks pass"
fi
exit "$failed"
