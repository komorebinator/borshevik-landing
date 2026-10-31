#!/usr/bin/env bash
# makes: media-writer
# Fedora Media Writer writing the ISO to a USB stick, from its first screen to Finished: the
# ISO as borshevik.org serves it, picked in Downloads, a 16 GB stick plugged into the
# machine (capture.sh stick), the administrator's password the write asks for. The writing
# and its check take minutes, so the scene waits for them and the video is cut (capture.sh
# cut): a few seconds of writing, then Finished. A walk-through, played with controls, not a
# loop, and cropped to the app.
. "$(dirname "$0")/../lib.sh"
fresh

# the newest ISO downloaded the way borshevik's tests/try-iso.sh downloads it
iso="$(ls -t "${XDG_CACHE_HOME:-$HOME/.cache}"/borshevik-iso/*/borshevik/borshevik-*.iso 2>/dev/null | head -1)"
[[ -n "$iso" ]] || { echo "media-writer.sh: no ISO in ~/.cache/borshevik-iso; download one as tests/try-iso.sh does" >&2; exit 1; }
downloads="$(c session 'xdg-user-dir DOWNLOAD')"
c root "rm -f '$downloads'/*.iso"
c put "$iso" "$downloads/"
c root "chown tester: '$downloads/$(basename "$iso")'"

c root 'flatpak info org.fedoraproject.MediaWriter >/dev/null 2>&1 \
    || flatpak install -y --noninteractive --system flathub org.fedoraproject.MediaWriter >/dev/null 2>&1'
c stick
# the file chooser as at a first start: GNOME's file chooser portal remembers the last folder
# an app chose from, which after a run in the other language is a folder renamed since
c session 'dconf reset -f /org/gnome/portal/filechooser/'
c launch flatpak run org.fedoraproject.MediaWriter
until c windows | grep -q '^org.fedoraproject.MediaWriter '; do sleep 1; done
sleep 3

c film "$here/scenes/media-writer.txt" "$work/$lang-media-writer.mkv" 4
# cropped to the app and its dialogs, 16:10 as the screen is, which leave the rest of the
# screen to the wallpaper: the file chooser, the widest, at 276-1166 x 192-741
c cut "$here/scenes/media-writer.txt" "$work/$lang-media-writer.mkv" "$img/media-writer.mp4" 912:570:264:181
c reset
c root "rm -f '$downloads'/*.iso"
