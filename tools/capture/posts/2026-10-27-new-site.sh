#!/usr/bin/env bash
# The picture of posts/2026-10-27-new-site, in both languages: the home page's first screen,
# as a 1440x900 window shows it, from the site served on this machine (@LandingPage#recipes#run,
# at http://127.0.0.1:8000) and taken by Chrome without a window — no test machine needed.
# Kept in the post's folder as home.<lang>.webp, taken once for the post: a post shows the site
# as it was when it came out.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
work="${XDG_CACHE_HOME:-$HOME/.cache}/landing-capture"
post="$root/posts/2026-10-27-new-site"
mkdir -p "$work"
for lang in en ru; do
    google-chrome --headless=new --disable-gpu --user-data-dir="$work/shot-profile" --hide-scrollbars \
        --window-size=1440,900 --virtual-time-budget=4000 --screenshot="$work/$lang-home.png" \
        "http://127.0.0.1:8000/?lang=$lang" >/dev/null 2>&1
    bash "$here/../capture.sh" still "$work/$lang-home.png" "$post/home.$lang.webp"
done
