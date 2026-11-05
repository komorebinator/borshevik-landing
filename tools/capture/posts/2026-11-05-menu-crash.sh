#!/usr/bin/env bash
# The picture and the video of posts/2026-11-05-menu-crash, in the session's language
# (capture.sh prepare <en|ru> first for the other), taken once for the post on 2026-11-05.
#
# menu.<lang>.webp: Files on the home folder with the context menu of its Documents folder open,
# the pointer where it was right-clicked, cropped to 16:10 around the window, so the panel is not
# in it.
#
# crash.<lang>.mp4: the crash the post tells how to bring about, played from
# 2026-11-05-menu-crash.txt — Files' view menu opened, a press in the window outside it held,
# Super pressed, GNOME going down to GDM's greeter. Borshevik's own mutter carries the fix, so
# Fedora's build of the same version is put in its place first, for this machine and this boot
# alone (usroverlay), and tester logged in again on it; it stays until the machine reboots.
# Filmed two times slower than real, so the menu and the overview's first frames are whole;
# what comes after the crash plays twice as fast. A walk-through, not a loop: the post shows it
# with ::video. Taken after the picture, since it ends tester's session.
. "$(dirname "$0")/../lib.sh"
post="$root/posts/2026-11-05-menu-crash"

open_files() {
    fresh
    c launch nautilus --new-window; sleep 5
    c place nautilus 300 130 840 600; sleep 3
}

open_files
# Documents is the second folder of the first row in both languages, the folders sorted by name.
# The pointer is brought there first and left a moment: a click sent sooner after the window was
# placed went unheard.
c move 700 400; sleep 1
c move 737 262; sleep 2
c click 737 262 right; sleep 1.5
c shot "$work/$lang-menu.png" >/dev/null
magick "$work/$lang-menu.png" -crop 1040x650+200+105 +repage "$work/$lang-menu.png"
c still "$work/$lang-menu.png" "$post/menu.$lang.webp"
c key esc
c close nautilus

if c root 'rpm -q mutter | grep -q borshevik'; then
    c root 'set -e
        rpm-ostree usroverlay >/dev/null 2>&1 || true
        v=$(rpm -q --qf "%{VERSION}-%{RELEASE}" mutter.x86_64 | sed "s/\.borshevik$//")
        d=$(mktemp -d); cd "$d"
        dnf -q -y download "mutter-$v.x86_64" "mutter-common-$v" "mutter-devkit-$v.x86_64"
        rpm -U --oldpackage --nodeps --replacefiles ./*.rpm
        rm -rf "$d"'
    bash "$here/capture.sh" prepare "$lang"
fi
# GDM's greeter at the session's 1440x900, not its own 1280x800: film takes a screen of another
# size for a black frame, and the greeter is where the video ends
c root 'install -d -o gdm -g gdm /var/lib/gdm/seat0/config
    install -o gdm -g gdm -m 644 ~tester/.config/monitors.xml /var/lib/gdm/seat0/config/monitors.xml'
open_files
c move 990 175; sleep 2
c film "$here/posts/2026-11-05-menu-crash.txt" "$work/$lang-crash.mkv" 2 || true
c clip "$work/$lang-crash.mkv" 0 4.6 "$post/crash.$lang.mp4"
# tester logged in again, the session the crash ended being gone
c root 'systemctl restart gdm; for i in $(seq 60); do pgrep -u tester -x gnome-shell >/dev/null && exit 0; sleep 5; done; exit 1'
sleep 30
