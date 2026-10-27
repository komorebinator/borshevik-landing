# Sourced by pictures/*.sh: what the picture scripts share. See @LandingPage#capture in spec/.
# A picture script stages a scene in the test machine and keeps what it shows as the site's
# picture in the session's language; its `# makes:` line names the pictures it produces.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
work="${XDG_CACHE_HOME:-$HOME/.cache}/landing-capture"
mkdir -p "$work"

c() { bash "$here/capture.sh" "$@"; }

lang="$(c session 'echo "${LANG%%_*}"')"
img="$root/media/$lang"

# The screen as it is now, kept as media/<lang>/<name>.webp, or where a post's script says;
# the pointer out of the way.
keep() { # name [out.webp]
    c move 1439 899
    sleep 0.5
    c shot "$work/$lang-$1.png" >/dev/null
    c still "$work/$lang-$1.png" "${2:-$img/$1.webp}"
}

# A scene filmed and cut to media/<lang>/<name>.mp4, or where a post's script says, from
# <start> to <end> seconds. A scene is one of scenes/ by name, or a file by its path.
film() { # scene name start end [out.mp4]
    local scene="$1"
    [[ $scene == */* ]] || scene="$here/scenes/$scene.txt"
    c film "$scene" "$work/$lang-$2.mkv" 4
    c clip "$work/$lang-$2.mkv" "$3" "$4" "${5:-$img/$2.mp4}"
}

chrome() {
    c launch google-chrome --password-store=basic --no-first-run --no-default-browser-check \
        --hide-crash-restore-bubble "$@"
}
editor() { c launch sh -c 'exec flatpak run org.gnome.TextEditor "$(xdg-user-dir DOCUMENTS)/note.txt"'; }
papers() { c launch sh -c "exec flatpak run org.gnome.Papers \"\$(xdg-user-dir DOCUMENTS)/$1\""; }

# An empty desktop, and the apps the scenes use set to start the same way every time.
fresh() {
    c reset
    c session 'd=$(xdg-user-dir DOCUMENTS); mkdir -p "$d"
        # the Workspace Manager without window rules but its own, and with no float size learnt
        # from an earlier scene
        bwm="gsettings --schemadir /usr/share/gnome-shell/extensions/borshevik-workspace-manager@komorebinator/schemas"
        $bwm reset org.gnome.shell.extensions.borshevik-workspace-manager window-rules
        $bwm reset org.gnome.shell.extensions.borshevik-workspace-manager float-sizes
        # the dock as Borshevik ships it, with Calculator, which some scenes open from it
        gsettings reset org.gnome.shell favorite-apps
        fav=$(gsettings get org.gnome.shell favorite-apps)
        gsettings set org.gnome.shell favorite-apps "${fav%]*}, '"'org.gnome.Calculator.desktop'"']"
        printf "%s\n" "Cloudberry is a northern berry that grows in swamps and tundra." \
            "It is picked at the end of July and made into jam." >"$d/note.txt"
        # Calculator opens small and floating, not at the size it last had
        f=~/.var/app/org.gnome.Calculator/config/glib-2.0/settings/keyfile
        [ -f "$f" ] && sed -i "s/^window-size=.*/window-size=(360, 560)/" "$f"
        # Papers opens a document without its sidebar
        flatpak run --command=gsettings org.gnome.Papers set org.gnome.Papers.Default show-sidebar false
        # Chrome never offers to translate the page, which it would over every scene
        f=~/.config/google-chrome/Default/Preferences
        [ -f "$f" ] && python3 - "$f" <<EOF
import json, sys
d = json.load(open(sys.argv[1]))
d.setdefault("translate", {})["enabled"] = False
d["translate_blocked_languages"] = ["en", "ru"]
# and opens as tall as the screen on its right half, so it is tiled there, whatever a scene
# before set (shaped makes it open maximized)
d.setdefault("browser", {})["window_placement"] = {"left": 700, "top": 32, "right": 1440, "bottom": 900,
    "maximized": False, "work_area_left": 0, "work_area_top": 32, "work_area_right": 1440, "work_area_bottom": 900}
d.setdefault("session", {})["restore_on_startup"] = 5
json.dump(d, open(sys.argv[1], "w"))
EOF
        true'
    c key esc
    # the Workspace Manager's Window Rules closed, if a scene left them open: Esc does not
    # close them, Super+R does
    [[ "$(c eval "const open = a => (a.style_class || '').includes?.('bwm-rules-overlay') || a.get_children().some(open); open(global.stage)")" == true ]] \
        && c key meta_l-r
    sleep 1
}

# Files on the left half and Chrome on the right, as they tile when opened.
side_by_side() {
    c launch nautilus --new-window; sleep 4
    chrome https://github.com/komorebinator/borshevik; sleep 9
}

# Cloudberry.pdf and Морошка.pdf in tester's documents, printed from scenes/cloudberry-*.html.
pdfs() {
    local l docs
    for l in en ru; do
        [[ -f "$work/cloudberry-$l.pdf" ]] || google-chrome --headless=new --disable-gpu \
            --user-data-dir="$work/pdf-profile" --no-pdf-header-footer \
            --print-to-pdf="$work/cloudberry-$l.pdf" "file://$here/scenes/cloudberry-$l.html" >/dev/null 2>&1
    done
    docs="$(c session 'xdg-user-dir DOCUMENTS')"
    c root "mkdir -p '$docs' && cat >'$docs/Cloudberry.pdf'" <"$work/cloudberry-en.pdf"
    c root "cat >'$docs/Морошка.pdf'" <"$work/cloudberry-ru.pdf"
    c root "chown -R tester: '$docs'"
}

# The dock with these apps added at its end, for a scene that opens them from it.
dock() { # desktop-file...
    local add="" a
    for a in "$@"; do add+=", '$a'"; done
    c session "fav=\$(gsettings get org.gnome.shell favorite-apps); gsettings set org.gnome.shell favorite-apps \"\${fav%]*}$add]\""
}

# The apps the Workspace Manager's scenes open, set to open at the sizes those scenes need.
shaped() {
    # the editor, Files and Settings open as tall as the screen and narrower than half of it, so
    # each is tiled as it opens. The editor keeps the size it was closed at: it is opened once
    # and closed at that size.
    editor; sleep 5
    c place texteditor 0 32 700 868; sleep 1
    c session 'gsettings set org.gnome.nautilus.window-state initial-size "(740, 868)"
        gsettings set org.gnome.nautilus.window-state maximized false
        gsettings set org.gnome.Settings window-state "(700, 868, false)"
        gsettings set org.gnome.Ptyxis restore-session false
        gsettings set org.gnome.Ptyxis restore-window-size false'
    c close texteditor; sleep 2
    # Chrome opens maximized, as it does for anyone who last closed it so, on Borshevik's page
    chrome about:blank; sleep 8
    c close chrome; sleep 2
    c session 'f=~/.config/google-chrome/Default/Preferences
        python3 - "$f" <<EOF
import json, sys
d = json.load(open(sys.argv[1]))
d.setdefault("browser", {})["window_placement"] = {"left": 0, "top": 32, "right": 1440, "bottom": 900,
    "maximized": True, "work_area_left": 0, "work_area_top": 32, "work_area_right": 1440, "work_area_bottom": 900}
d.setdefault("session", {}).update(restore_on_startup=4,
    startup_urls=["https://github.com/komorebinator/borshevik"])
json.dump(d, open(sys.argv[1], "w"))
EOF'
}

# Android, for the pictures that show it. The test machine has no GPU Android can render on,
# and the Image Manager says so above its button, in a warning a machine with one never
# shows: until the next boot, the Image Manager, asking as tester, is told the machine has
# one. root is told the truth, so Android is still installed to render in software, the one
# way it starts here.
android_control=/usr/libexec/borshevik/borshevik-waydroid
android_stamp=/var/lib/borshevik/waydroid-installed
gpu_shown() {
    c root "set -e
        mountpoint -q $android_control && umount $android_control
        cp $android_control /run/borshevik-waydroid-real
        cat >/run/borshevik-waydroid-capture <<'EOF2'
#!/usr/bin/env bash
if [[ \"\${1:-}\" == rendering && \$EUID -ne 0 ]]; then echo hardware; exit 0; fi
exec /run/borshevik-waydroid-real \"\$@\"
EOF2
        chmod 755 /run/borshevik-waydroid-real /run/borshevik-waydroid-capture
        chcon --reference=$android_control /run/borshevik-waydroid-real /run/borshevik-waydroid-capture
        mount --bind /run/borshevik-waydroid-capture $android_control"
}

# Installed, if it is not, as the Image Manager installs it for tester (PKEXEC_UID), which
# starts the sync of GNOME's colours to Android in tester's session too
android_installed() {
    c root "[ -f $android_stamp ] || PKEXEC_UID=\$(id -u tester) $android_control install >/dev/null"
}

# Removed after the pictures, with tester's launchers of its apps, which every other picture's
# app grid would show, and the Image Manager told the truth again
android_removed() {
    c session "waydroid session stop >/dev/null 2>&1; true"; sleep 3
    c root "PKEXEC_UID=\$(id -u tester) $android_control remove >/dev/null
        mountpoint -q $android_control && umount $android_control; true"
}

# The Image Manager on its Android tab, centred; the tab's place moves with the language
android_tab() {
    local x=782; [[ $lang == en ]] && x=790
    c launch gtk-launch org.borshevik.ImageManager; sleep 5
    c center imagemanager; sleep 1
    c click "$x" 198; sleep 3
    c center imagemanager; sleep 1
}
