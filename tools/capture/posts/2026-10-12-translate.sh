#!/usr/bin/env bash
# The pictures of posts/2026-10-12-translate, in the session's language (capture.sh prepare
# <en|ru> first for the other): a paragraph of a PDF in the other language selected and
# translated with Super+T, filmed from the pages' own translate-<lang> scene; a still of the
# translation open over the selection, taken from that take and cropped to 16:10 around the
# translation, the panel's icon above it and the selection's right half, tight enough for the
# translator to read in the news list's thumbnail (the author, 2026-10-27), the post's first
# picture; and the translator's settings with the languages it took from the keyboard layouts.
# Kept in the post's folder as <name>.<lang>, taken once for the post and not again with the
# pages' pictures. The post is dated 2026-10-12, when the translator shipped; its pictures were
# taken on 2026-10-27.
. "$(dirname "$0")/../lib.sh"
post="$root/posts/2026-10-12-translate"
pdfs
fresh
if [[ $lang == ru ]]; then papers Cloudberry.pdf; else papers Морошка.pdf; fi
sleep 7
c click 700 750
film "translate-$lang" translate 0.1 9.6 "$post/translate.$lang.mp4"
# the translation is open from 3.3 s to 7.3 s of the scene
ffmpeg -hide_banner -loglevel error -y -ss 6 -i "$work/$lang-translate.mkv" -frames:v 1 "$work/$lang-translate-open.png"
magick "$work/$lang-translate-open.png" -crop 960x600+480+0 +repage "$work/$lang-translate-open.png"
c still "$work/$lang-translate-open.png" "$post/translate-open.$lang.webp"
c key esc
c close org.gnome.Papers; sleep 1

c launch gnome-extensions prefs borshevik-translate@komorebinator; sleep 5
keep translate-settings "$post/translate-settings.$lang.webp"
c close org.gnome.Shell.Extensions
