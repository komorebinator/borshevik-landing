#!/usr/bin/env bash
# Screenshots and videos for the site, taken in the VM borshevik's test-image-in-vm.sh
# leaves running (--keep). See @LandingPage#capture and #recipes#take_screenshots in spec/.
# `take` makes the site's pictures from the scripts in pictures/; the other commands are
# the steps those scripts are made of.
# Runs on the host: needs python3, ssh, ImageMagick (magick) and ffmpeg with libx264.
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/borshevik-vm"
key="$cache/id_ed25519"
# the screen's size, which installer.sh's machine has its own of
W=${CAPTURE_W:-1440} H=${CAPTURE_H:-900}

usage() {
    cat >&2 <<'EOF'
usage: capture.sh take <picture|all>... [en|ru]   makes pictures with pictures/<picture>.sh,
                                          in the session's language or, given one, in that
       capture.sh prepare <en|ru>         set tester's session up in a language
       capture.sh mode                    the display at 1440x900
       capture.sh reset                   closes every app window tester has open
       capture.sh place <class> <x> <y> <w> <h>   puts a window there, floating
       capture.sh center <class>          puts a window in the middle of the screen, floating
       capture.sh opens-at <class> <x> <y>   puts the next window of the class to open there
       capture.sh close <class>           closes a window as its close button does
       capture.sh shot <out.png>          the screen as it is now
       capture.sh still <in.png> <out.webp>
       capture.sh key <combo>...          qemu key names joined by '-': meta_l-t, ctrl-alt-shift-r
       capture.sh type <text>             presses the keys of the text, one by one
       capture.sh move <x> <y> | click <x> <y> [left|right] | dclick <x> <y> | tclick <x> <y>
       capture.sh drag <x1> <y1> <x2> <y2>
       capture.sh eval <javascript>       runs it in GNOME Shell and prints what it returns
       capture.sh session <command>       runs a command in tester's graphical session
       capture.sh windows                 where each window is, and which workspace is shown
       capture.sh launch <program> [args] starts an app the way GNOME Shell would
       capture.sh root <command>          runs a command as root in the machine
       capture.sh film <scene> <out.mkv> [factor]   a scene played <factor> times slower
                                          and filmed from the host (see cmd_film)
       capture.sh clip <in> <start> <end> <out.mp4> [crop w:h:x:y]   and how far its last frame
                                          is from its first, since the site loops it
       capture.sh cut <scene> <take.mkv> <out.mp4> [crop w:h:x:y]   a take of a scene with a
                                          wait in it, clipped with the wait's length cut out
       capture.sh stick                   a USB stick plugged into the machine, and empty
       capture.sh put <file> <path>       copies a file of the host's into the machine
EOF
    exit 2
}

die() { echo "$*" >&2; exit 1; }

# The newest run directory whose QMP socket answers, and the SSH port its qemu forwards; or
# the machine in $CAPTURE_VM, one with no SSH such as installer.sh's, for the commands that
# need only its screen, keyboard and pointer.
find_vm() {
    local d
    if [[ -n "${CAPTURE_VM:-}" ]]; then
        [[ -S "$CAPTURE_VM/qmp.sock" ]] || die "no machine at $CAPTURE_VM"
        dir="$CAPTURE_VM" port=
        return 0
    fi
    for d in $(ls -1dt "$cache"/runs/*/ 2>/dev/null); do
        d="${d%/}"
        [[ -S "$d/qmp.sock" ]] || continue
        if python3 -c 'import socket,sys; s=socket.socket(socket.AF_UNIX); s.connect(sys.argv[1])' "$d/qmp.sock" 2>/dev/null; then
            dir="$d"
            port="$(pgrep -af qemu-system | grep -F "$d/" | grep -oE 'hostfwd=tcp:127\.0\.0\.1:[0-9]+' | head -1 | cut -d: -f3)"
            [[ -n "$port" ]] || die "no SSH port forwarded for $d"
            return 0
        fi
    done
    die "no running test machine; start one with borshevik's tests/test-image-in-vm.sh run --keep"
}

qmp() { # command [json arguments]
    python3 - "$dir/qmp.sock" "$@" <<'PY'
import json, socket, sys
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); f = s.makefile("rw")
f.readline()
f.write(json.dumps({"execute": "qmp_capabilities"}) + "\n"); f.flush(); f.readline()
cmd = {"execute": sys.argv[2]}
if len(sys.argv) > 3:
    cmd["arguments"] = json.loads(sys.argv[3])
f.write(json.dumps(cmd) + "\n"); f.flush()
while True:
    r = json.loads(f.readline())
    if "error" in r:
        sys.exit("qmp: " + json.dumps(r["error"]))
    if "return" in r:
        break
PY
}

guest() {
    ssh -i "$key" -p "$port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes -o LogLevel=ERROR -o ConnectTimeout=10 root@127.0.0.1 "$@"
}

# A command in tester's graphical session: its D-Bus, its Wayland display, its language and
# its desktop (Settings will not start without XDG_CURRENT_DESKTOP), taken from GNOME Shell's
# own environment, since apps read LANG and SSH does not carry it; and its X display, which
# Steam, an X11 app, needs, from the user manager's, since GNOME Shell starts Xwayland on
# demand and its own environment has none.
in_session() {
    guest "uid=\$(id -u tester); shell=\$(pgrep -u tester -x gnome-shell | head -1)
        langenv=\$(tr '\\0' '\\n' </proc/\$shell/environ | grep -E '^(LANG|LANGUAGE|LC_[A-Z]+|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE)=' | tr '\\n' ' ')
        xenv=\$(systemctl --user -M tester@ show-environment 2>/dev/null | grep -E '^(DISPLAY|XAUTHORITY)=' | tr '\\n' ' ')
        runuser -u tester -- env \$langenv \$xenv XDG_RUNTIME_DIR=/run/user/\$uid \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$uid/bus WAYLAND_DISPLAY=wayland-0 \
        HOME=\$(getent passwd tester | cut -d: -f6) bash -c $(printf '%q' "$1")"
}

send_keys() { # qcode...
    local json="" k
    for k in "$@"; do json+="{\"type\":\"qcode\",\"data\":\"$k\"},"; done
    qmp send-key "{\"keys\":[${json%,}],\"hold-time\":60}"
}

abs() { # x y -> the tablet's 0..32767 coordinates
    echo "$(( $1 * 32767 / (W - 1) )) $(( $2 * 32767 / (H - 1) ))"
}

pointer() { # x y: moves the pointer there
    local ax ay
    read -r ax ay <<<"$(abs "$1" "$2")"
    qmp input-send-event "{\"events\":[{\"type\":\"abs\",\"data\":{\"axis\":\"x\",\"value\":$ax}},{\"type\":\"abs\",\"data\":{\"axis\":\"y\",\"value\":$ay}}]}"
}

button() { # left|right down|up
    local down=true
    [[ "$2" == up ]] && down=false
    qmp input-send-event "{\"events\":[{\"type\":\"btn\",\"data\":{\"button\":\"$1\",\"down\":$down}}]}"
}

char_keys() { # one character -> qcodes
    local c="$1"
    case "$c" in
        [a-z0-9]) echo "$c" ;;
        [A-Z]) echo "shift ${c,,}" ;;
        ' ') echo spc ;;
        '-') echo minus ;;
        '_') echo "shift minus" ;;
        '=') echo equal ;;
        '.') echo dot ;;
        ',') echo comma ;;
        '/') echo slash ;;
        ':') echo "shift semicolon" ;;
        *) die "cannot type '$c'" ;;
    esac
}

# A small extension of tester's own that runs JavaScript in GNOME Shell for this script, over
# its own D-Bus name: what org.gnome.Shell.Eval does, without GNOME's unsafe mode, which would
# put its warning icon in the panel of every screenshot. Test machines only.
install_helper() {
    local ext='$(getent passwd tester | cut -d: -f6)/.local/share/gnome-shell/extensions'
    guest "rm -rf $ext/unsafe-mode@borshevik-capture; mkdir -p $ext/capture-helper@borshevik
        cat >$ext/capture-helper@borshevik/metadata.json" <<'EOF'
{"uuid": "capture-helper@borshevik", "name": "Capture helper",
 "description": "Lets the site's screenshot tooling slow animations down and place windows. Test machines only.",
 "shell-version": ["49", "50"]}
EOF
    guest "cat >$ext/capture-helper@borshevik/extension.js
        chown -R tester: $ext/capture-helper@borshevik" <<'EOF'
import Gio from 'gi://Gio';

const IFACE = `<node><interface name="org.borshevik.Capture">
  <method name="Eval"><arg type="s" direction="in" name="code"/><arg type="s" direction="out" name="result"/></method>
</interface></node>`;

export default class {
    enable() {
        this._object = Gio.DBusExportedObject.wrapJSObject(IFACE, {
            Eval: code => {
                try { return String((0, eval)(code)); } catch (e) { return `error: ${e}`; }
            },
        });
        this._object.export(Gio.DBus.session, '/org/borshevik/Capture');
        this._name = Gio.bus_own_name_on_connection(Gio.DBus.session, 'org.borshevik.Capture',
            Gio.BusNameOwnerFlags.NONE, null, null);
    }

    disable() {
        Gio.bus_unown_name(this._name);
        this._object.unexport();
    }
}
EOF
}

# The language of tester's running session, as its two-letter code.
session_lang() {
    guest 'tr "\0" "\n" </proc/$(pgrep -u tester -x gnome-shell | head -1)/environ' | sed -n 's/^LANG=\(..\).*/\1/p'
}

# JavaScript run in GNOME Shell through the helper; prints what it returns.
shell_eval() {
    in_session "gdbus call --session --dest org.borshevik.Capture --object-path /org/borshevik/Capture \
        --method org.borshevik.Capture.Eval $(printf '%q' "$1")" | sed -E "s/^\('(.*)',\)$/\1/"
}

cmd_prepare() {
    local lang="$1" locale apps
    case "$lang" in en) locale=en_US.UTF-8 ;; ru) locale=ru_RU.UTF-8 ;; *) usage ;; esac
    # the apps the App Manager installs on a first login, which the test machine's tester
    # skipped: the scenes open the editor, Calculator, Papers and others from them
    apps="$(python3 -c 'import json, sys
print(" ".join(a for g in json.load(open(sys.argv[1])) if g.get("default") for a in g["applications"]))' \
        "$(dirname "${BASH_SOURCE[0]}")/../../share/applications.json")"
    # the language is the account's, read at login: set it, then log tester in afresh
    # an administrator, as a user who installed the system is, or the Image Manager cannot
    # check for updates; and Flatpak apps' translations in both languages, which Flatpak
    # otherwise fetches only for the languages in use when an app is installed
    guest "set -e
        uid=\$(id -u tester)
        usermod -aG wheel tester
        # no update downloaded in the background while pictures are taken: its icon in the
        # panel, and Restart & Update in the power menu, would be in every one of them. The
        # timer stays enabled, as on any Borshevik, so the Image Manager shows automatic
        # updates on; it is only stopped until the next boot. An update already downloaded
        # goes, its image too, or the Image Manager offers it as a download of 0 bytes.
        systemctl enable rpm-ostreed-automatic.timer >/dev/null 2>&1 || true
        systemctl stop rpm-ostreed-automatic.timer
        rpm-ostree cleanup -p >/dev/null 2>&1 || true
        unshare -m sh -c 'mount -o remount,rw /sysroot
            for ref in \$(ostree container image list --repo=/sysroot/ostree/repo); do
                ostree container image remove --repo=/sysroot/ostree/repo \$ref
            done
            ostree container image prune-layers --repo=/sysroot/ostree/repo' >/dev/null 2>&1 || true
        flatpak config --system --set languages 'en;ru'
        flatpak update -y --noninteractive >/dev/null 2>&1 || true
        flatpak install -y --noninteractive --or-update --system flathub $apps >/dev/null 2>&1 || true
        busctl call org.freedesktop.Accounts /org/freedesktop/Accounts/User\$uid \
            org.freedesktop.Accounts.User SetLanguage s $locale
        rm -f /etc/systemd/system/gdm.service.d/zz-test-late-login.conf
        systemctl daemon-reload
        # the pointer drawn into the picture itself, where a screen dump sees it, instead of
        # on a hardware cursor plane
        home=\$(getent passwd tester | cut -d: -f6)
        runuser -u tester -- mkdir -p \$home/.config/environment.d
        echo MUTTER_DEBUG_DISABLE_HW_CURSORS=1 | runuser -u tester -- tee \$home/.config/environment.d/90-capture.conf >/dev/null
        # the home folders renamed for the language beforehand, or xdg-user-dirs asks about it
        # in a dialog over the first screenshots
        runuser -u tester -- env LANG=$locale LC_ALL=$locale HOME=\$(getent passwd tester | cut -d: -f6) \
            xdg-user-dirs-update --force
        # GTK's bookmarks, the folders in the Files sidebar, pointed at the renamed folders
        runuser -u tester -- env HOME=\$home sh -c '. ~/.config/user-dirs.dirs
            for d in \"\$XDG_DOCUMENTS_DIR\" \"\$XDG_MUSIC_DIR\" \"\$XDG_PICTURES_DIR\" \"\$XDG_VIDEOS_DIR\" \"\$XDG_DOWNLOAD_DIR\"; do
                echo \"file://\$d\"; done >~/.config/gtk-3.0/bookmarks'
        echo ${locale%%.*} | runuser -u tester -- tee \$(getent passwd tester | cut -d: -f6)/.config/user-dirs.locale >/dev/null"
    # The other language's home folders folded into this one's: xdg-user-dirs-update renames
    # a folder only when the new name is free, and leaves both otherwise.
    guest "runuser -u tester -- env HOME=\$(getent passwd tester | cut -d: -f6) LANGSEL=$lang bash -s" <<'EOF'
for pair in "Desktop:Рабочий стол" "Downloads:Загрузки" "Templates:Шаблоны" "Public:Общедоступные" \
            "Documents:Документы" "Music:Музыка" "Pictures:Изображения" "Videos:Видео"; do
    en=${pair%%:*} ru=${pair#*:}
    if [ "$LANGSEL" = ru ]; then from=$en to=$ru; else from=$ru to=$en; fi
    [ -d "$HOME/$from" ] || continue
    mkdir -p "$HOME/$to"
    cp -a "$HOME/$from/." "$HOME/$to/"
    rm -rf "$HOME/$from"
done
EOF
    install_helper
    in_session "gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        gsettings set org.gnome.desktop.input-sources sources \"[('xkb', 'us'), ('xkb', 'ru')]\"
        gsettings set org.gnome.desktop.notifications show-banners false
        gsettings set org.gnome.system.locale region $locale
        gsettings set org.gnome.desktop.session idle-delay 0
        gsettings set org.gnome.desktop.screensaver lock-enabled false
        # Chrome opened from the dock as lib.sh opens it: no first-run questions, no keyring
        mkdir -p ~/.local/share/applications
        sed 's#^Exec=/usr/bin/google-chrome-stable#& --password-store=basic --no-first-run --no-default-browser-check --hide-crash-restore-bubble#' \
            /usr/share/applications/google-chrome.desktop >~/.local/share/applications/google-chrome.desktop
        fav=\$(gsettings get org.gnome.shell favorite-apps)
        case \"\$fav\" in *org.gnome.Calculator*) ;; *)
            gsettings set org.gnome.shell favorite-apps \"\${fav%]*}, 'org.gnome.Calculator.desktop']\" ;; esac
        systemctl --user set-environment MUTTER_DEBUG_DISABLE_HW_CURSORS=1
        list=\$(gsettings get org.gnome.shell enabled-extensions | sed \"s/, 'unsafe-mode@borshevik-capture'//\")
        case \"\$list\" in *capture-helper@borshevik*) ;; *) list=\"\${list%]*}, 'capture-helper@borshevik']\" ;; esac
        gsettings set org.gnome.shell enabled-extensions \"\$list\""
    echo "logging tester in again in $lang"
    local old new="" i
    old="$(guest 'pgrep -u tester -x gnome-shell || true')"
    # the old session ended first: restarted with it still closing, GDM finds its login worker
    # not dead after five seconds, fails the display and logs nobody in
    guest "loginctl terminate-user tester; for i in \$(seq 30); do loginctl show-user tester >/dev/null 2>&1 || break; sleep 1; done
        systemctl restart gdm"
    for i in $(seq 60); do
        new="$(guest 'pgrep -u tester -x gnome-shell || true')"
        [[ -n "$new" && "$new" != "$old" ]] && break
        sleep 3
    done
    [[ -n "$new" && "$new" != "$old" ]] || die "tester was not logged in again"
    sleep 15
    # GNOME Shell turns animations off where rendering is not hardware-accelerated, as in this
    # machine; the site's videos are there to show them
    [[ "$(shell_eval 'imports.gi.St.Settings.get().uninhibit_animations(); true')" == true ]] \
        || die "the capture helper extension does not answer"
    set_mode
    echo "ready: $(guest "tr '\\0' '\\n' </proc/$new/environ | grep ^LANG=")"
}

# 1440x900 through mutter's DisplayConfig, persistently, for the session's one monitor.
set_mode() {
    guest "cat >/tmp/capture-mode.js && chmod 644 /tmp/capture-mode.js" <<EOF
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import System from 'system';
const bus = Gio.DBus.session;
const call = (method, params) => bus.call_sync('org.gnome.Mutter.DisplayConfig',
    '/org/gnome/Mutter/DisplayConfig', 'org.gnome.Mutter.DisplayConfig', method, params,
    null, Gio.DBusCallFlags.NONE, -1, null);
const [serial, monitors] = call('GetCurrentState', null).recursiveUnpack();
const [spec, modes] = monitors[0];
const mode = modes.find(m => m[1] === $W && m[2] === $H);
if (!mode) { print('no ${W}x${H} mode; modes: ' + modes.map(m => m[0]).join(' ')); System.exit(1); }
call('ApplyMonitorsConfig', new GLib.Variant('(uua(iiduba(ssa{sv}))a{sv})', [serial, 2,
    [[0, 0, 1.0, 0, true, [[spec[0], mode[0], {}]]]], {}]));
print('mode ' + mode[0]);
EOF
    in_session "gjs -m /tmp/capture-mode.js 2>/dev/null" | grep -q '^mode' || die "the display mode was not set"
    # GNOME asks whether to keep a persistent change; its default answer is to keep it
    sleep 1.5
    send_keys ret
}

cmd_shot() {
    local out="$1" tmp="$dir/capture-shot.ppm"
    qmp screendump "{\"filename\": \"$tmp\"}"
    magick "$tmp" "$out"
    rm -f "$tmp"
    echo "$out"
}

# A video taken from the host, frame by frame, while a scene plays out at <factor> times
# slower than real: GNOME Shell's animations are slowed by the same factor, the scene's
# keys and pointer are sent on its slowed timeline, and the frames, taken at a steady rate,
# are encoded as if at <factor> times that rate - so the result runs at normal speed with
# every animation complete. GNOME's own recorder cannot do this here: in a machine with no
# graphics acceleration it keeps one or two frames a second.
#
# The scene file has one step per line, its time in seconds of the finished video first:
#   <t> key <combo>            <t> type <text>
#   <t> move <x> <y>           <t> glide <x> <y> <seconds>     the pointer travels there
#   <t> click <x> <y>          <t> tclick <x> <y>               triple click
#   <t> drag <x1> <y1> <x2> <y2> <seconds>
#   <t> pace <seconds>         how long typing spends on each key from here on, 0.12 until
#                              a scene says otherwise
#   <t> wait <x> <y> <rrggbb>  the steps after it held, the filming going on, until that
#                              pixel has that colour: for what takes as long as it takes,
#                              and cut out of the video by cut
#   <t> hold <x> <y> <rrggbb>  the same, the time held kept in the video; !rrggbb in either
#                              waits for the pixel to have any colour but that one, ~rrggbb
#                              for one within 12 of it in each channel
#   <t> still <seconds>        the steps after it held, as by wait and cut out the same way,
#                              until the screen has not changed for that long: for what
#                              settles bit by bit, such as icons loading
#   <t> speed <factor>         the video from here played that many times faster by cut, up
#                              to the next speed step (speed 1) or the end: for a stretch
#                              the machine cannot be driven faster through, such as typing
#                              into a window that falls behind keys sent quicker
#   <t> link <up|down>         the machine's network cable plugged in or pulled out, a
#                              machine's started as installer.sh starts it, its netdev net0
#   <t> find <text>            the first button after the label reading <text> in GNOME
#                              Shell's own interface, looked up as the scene plays; '@' in
#                              place of <x> <y> in the steps after it is that button's middle
#   <t> end
cmd_film() {
    local scene="$1" out="$2" factor="${3:-4}" rate=15
    # a machine with no SSH and no GNOME Shell, such as installer.sh's, is filmed as it plays,
    # in real time, at 30 frames a second: nothing there to slow down
    if [[ -z "$port" ]]; then
        film_frames "$scene" "$out" 1 30
        return
    fi
    [[ "$(shell_eval "imports.gi.St.Settings.get().slow_down_factor = $factor; true")" == true ]] \
        || die "the capture helper extension does not answer: log tester in again with prepare first"
    # the panel's clock stopped, a still copy of it shown in its place: filmed slowed down, a
    # scene lasts minutes, and a minute turning over would make its last frame differ from its
    # first, which it must not
    shell_eval "import('resource:///org/gnome/shell/ui/main.js').then(Main => {
        const l = Main.panel.statusArea.dateMenu._clockDisplay;
        globalThis._captureClock?.destroy();
        globalThis._captureClock = new imports.gi.St.Label({ text: l.text, style_class: l.style_class, y_align: l.y_align });
        l.get_parent().insert_child_above(globalThis._captureClock, l);
        l.hide();
    }); true" >/dev/null
    sleep 1
    film_frames "$scene" "$out" "$factor" "$rate"
    shell_eval 'imports.gi.St.Settings.get().slow_down_factor = 1; true' >/dev/null
    shell_eval "import('resource:///org/gnome/shell/ui/main.js').then(Main => {
        Main.panel.statusArea.dateMenu._clockDisplay.show();
        globalThis._captureClock?.destroy(); delete globalThis._captureClock;
    }); true" >/dev/null
}

# The scene played and filmed: its steps sent on a timeline <factor> times slower than its
# own, frames taken <rate> times a second and encoded as if taken <factor> times faster.
film_frames() { # scene out factor rate
    local scene="$1" out="$2" factor="$3" rate="$4"
    python3 - "$dir/qmp.sock" "$dir" "$scene" "$out" "$factor" "$rate" "$W" "$H" "$0" <<'PY'
import json, os, socket, subprocess, sys, threading, time
sock, workdir, scene, out = sys.argv[1:5]
me = sys.argv[9]
factor, rate, W, H = float(sys.argv[5]), float(sys.argv[6]), int(sys.argv[7]), int(sys.argv[8])
s = socket.socket(socket.AF_UNIX); s.connect(sock); f = s.makefile("rw")
f.readline(); f.write(json.dumps({"execute": "qmp_capabilities"}) + "\n"); f.flush(); f.readline()
def call(cmd, args):
    f.write(json.dumps({"execute": cmd, "arguments": args}) + "\n"); f.flush()
    while True:
        r = json.loads(f.readline())
        if "error" in r: sys.exit("qmp: " + json.dumps(r["error"]))
        if "return" in r: return
def keys(combo): call("send-key", {"keys": [{"type": "qcode", "data": k} for k in combo.split("-")], "hold-time": 60})
def at(x, y): call("input-send-event", {"events": [
    {"type": "abs", "data": {"axis": "x", "value": int(float(x) * 32767 / (W - 1))}},
    {"type": "abs", "data": {"axis": "y", "value": int(float(y) * 32767 / (H - 1))}}]})
def btn(down): call("input-send-event", {"events": [{"type": "btn", "data": {"button": "left", "down": down}}]})
CHARS = {" ": "spc", "-": "minus", ".": "dot", ",": "comma", "/": "slash"}
# A point found as the scene plays (find): looked up in a thread, so filming goes on meanwhile,
# and waited for by the first step that needs it.
FIND = """const St = imports.gi.St; let seen = false, hit = null;
const walk = a => { if (hit || !a.visible) return;
    if (!seen && a instanceof St.Label && a.text === %s) seen = true;
    else if (seen && a instanceof St.Button && a.reactive) { hit = a; return; }
    for (const c of a.get_children()) walk(c); };
walk(global.stage);
if (!hit) 'none'; else { const [x, y] = hit.get_transformed_position(), [w, h] = hit.get_transformed_size();
    `${Math.round(x + w / 2)} ${Math.round(y + h / 2)}`; }"""
found = {}
def find(text):
    def look():
        r = subprocess.run(["bash", me, "eval", FIND % json.dumps(text)], capture_output=True, text=True).stdout.strip()
        found["point"] = None if r in ("", "none") or r.startswith("error") else tuple(map(float, r.split()))
    found["thread"] = threading.Thread(target=look); found["thread"].start()
def found_point():
    found["thread"].join()
    if found.get("point") is None: sys.exit("film: find matched nothing")
    return found["point"]
# every step becomes events at real times: (time, function); a point is a function giving x, y
def point(a):
    if a[0] == "@": return found_point, a[1:]
    x, y = float(a[0]), float(a[1])
    return (lambda: (x, y)), a[2:]
events, end = [], None
pace = 0.12
pointer = lambda: (W - 1, H - 1)
for line in open(scene):
    parts = line.split()
    if not parts or parts[0].startswith("#"): continue
    t, op, a = float(parts[0]) * factor, parts[1], parts[2:]
    if op == "key": events.append((t, lambda c=a[0]: keys(c)))
    elif op == "type":
        text = " ".join(a)
        for i, ch in enumerate(text):
            k = ("shift-" + ch.lower()) if ch.isupper() else CHARS.get(ch, ch)
            events.append((t + i * pace * factor, lambda k=k: keys(k)))
    elif op == "find": events.append((t, lambda text=" ".join(a): find(text)))
    elif op == "move":
        p, _ = point(a); events.append((t, lambda p=p: at(*p()))); pointer = p
    elif op in ("glide", "drag"):
        # a drag may go on through more points, each with its own duration, before it is
        # released: a window carried about rather than moved once
        if op == "drag":
            p0, rest = point(a)
            events.append((t, lambda p=p0: at(*p())))
            events.append((t + 0.1 * factor, lambda: btn(True)))
            t0 = t + 0.2 * factor
        else:
            p0 = pointer; rest = a
            t0 = t
        while rest:
            p1, rest = point(rest); d = float(rest[0]); rest = rest[1:]
            n = max(2, int(d * 60))
            for i in range(1, n + 1):
                def step(p0=p0, p1=p1, k=i / n):
                    (x0, y0), (x1, y1) = p0(), p1()
                    at(x0 + (x1 - x0) * k, y0 + (y1 - y0) * k)
                events.append((t0 + d * factor * i / n, step))
            t0 += d * factor
            p0 = p1
            if op == "glide": break
        if op == "drag": events.append((t0 + 0.1 * factor, lambda: btn(False)))
        pointer = p0
    elif op in ("click", "dclick", "tclick"):
        p, _ = point(a)
        events.append((t, lambda p=p: at(*p())))
        # pressed and released as a hand would, at the speed of real time, not the scene's: a
        # double click's second press comes after its first is released, within GTK's interval
        for i in range({"click": 1, "dclick": 2, "tclick": 3}[op]):
            events.append((t + 0.08 * factor + i * 0.15, lambda: btn(True)))
            events.append((t + 0.08 * factor + i * 0.15 + 0.06, lambda: btn(False)))
        pointer = p
    elif op == "pace": pace = float(a[0])
    elif op in ("wait", "hold"): events.append((t, (op, int(a[0]), int(a[1]), a[2].lower())))
    elif op == "still": events.append((t, ("still", float(a[0]))))
    elif op == "speed": events.append((t, ("speed", float(a[0]))))
    elif op == "link": events.append((t, lambda up=a[0] == "up": call("set_link", {"name": "net0", "up": up})))
    elif op == "end": end = t
    else: sys.exit(f"unknown step: {line.strip()}")
events.sort(key=lambda e: e[0])
if end is None: sys.exit("the scene has no end step")
# frames go straight into an encoder, as if taken at factor x rate
enc = subprocess.Popen(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "rawvideo",
    "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-framerate", str(rate * factor), "-i", "-",
    "-c:v", "libx264", "-preset", "ultrafast", "-crf", "8", "-pix_fmt", "yuv444p", out], stdin=subprocess.PIPE)
frame = os.path.join(workdir, "capture-frame.ppm")
start = time.time(); n = 0
# a wait or hold step holds the steps after it, filming on, until the pixel it names has its
# colour, then moves them, and the end, on by as long as it held them; where in the take each
# wait began and ended is written next to it, for cut
waiting, cuts, last, speeding = None, [], None, None
def fire():
    global waiting, settled, speeding
    e = events.pop(0)[1]
    if isinstance(e, tuple) and e[0] == "speed":
        if speeding: cuts.append(speeding + (n / (rate * factor),))
        speeding = (n / (rate * factor), e[1]) if e[1] != 1 else None
    elif isinstance(e, tuple): waiting = (e, time.time() - start, n / (rate * factor)); settled = time.time()
    else: e()
def matches(pixel, colour):
    if colour[0] == "~":
        return all(abs(a - b) <= 12 for a, b in zip(pixel, bytes.fromhex(colour[1:])))
    return (pixel.hex() == colour.lstrip("!")) != colour.startswith("!")
while True:
    now = time.time() - start
    while events and not waiting and events[0][0] <= now:
        fire()
    if not waiting and now >= end: break
    call("screendump", {"filename": frame})
    data = open(frame, "rb").read()
    # a screen of another size, the firmware's for a moment as a machine restarts, goes in black
    data = data[-W * H * 3:] if data.split(None, 3)[1:3] == [b"%d" % W, b"%d" % H] else bytes(W * H * 3)
    enc.stdin.write(data)
    if waiting:
        step, since, began = waiting
        held = time.time() - start - since
        if step[0] == "still":
            if data != last: settled = time.time()
            done = time.time() - settled >= step[1]
        else:
            x, y, colour = step[1:]
            done = matches(data[(y * W + x) * 3:(y * W + x) * 3 + 3], colour)
        if done:
            events = [(t + held, e) for t, e in events]; end += held; waiting = None
            if step[0] != "hold": cuts.append((began, n / (rate * factor)))
        elif held > 720: sys.exit(f"film: {' '.join(map(str, step))} not seen after 12 minutes")
    last = data
    n += 1
    nxt = start + n / rate
    while events and not waiting and start + events[0][0] < nxt:
        time.sleep(max(0, start + events[0][0] - time.time()))
        fire()
    time.sleep(max(0, nxt - time.time()))
enc.stdin.close(); enc.wait(); os.remove(frame)
# a cut as its beginning and end in the take, a stretch sped up as its beginning, end and factor
if speeding: cuts.append(speeding + (n / (rate * factor),))
cuts = sorted((c[0], c[2], c[1]) if len(c) == 3 else c for c in cuts)
if cuts: open(out + ".cut", "w").write("".join(" ".join("%.3f" % v for v in c) + "\n" for c in cuts))
print(f"{out}: {n} frames, {n / (rate * factor):.1f} s")
PY
}

# A walk-through whose scene waits for what takes as long as it takes (wait steps): the take
# with every wait cut out, and every stretch its speed steps name sped up, where film wrote
# them next to the take, then clipped. Such a video does not loop; the site plays it with
# controls.
cmd_cut() {
    local scene="$1" take="$2" out="$3" crop="${4:-}" cut="${2%.*}-cut.mkv" began ended speed from=0 parts= n=0
    [[ -f "$take.cut" ]] || die "$take has no wait of $scene recorded next to it ($take.cut)"
    while read -r began ended speed; do
        parts+="[0:v]trim=$from:$began,setpts=PTS-STARTPTS[p$n];"; n=$((n + 1)); from=$ended
        [[ -n "$speed" ]] && { parts+="[0:v]trim=$began:$ended,setpts=(PTS-STARTPTS)/$speed[p$n];"; n=$((n + 1)); }
    done <"$take.cut"
    parts+="[0:v]trim=start=$from,setpts=PTS-STARTPTS[p$n];"; n=$((n + 1))
    ffmpeg -hide_banner -loglevel error -y -i "$take" -filter_complex \
        "$parts$(for ((i = 0; i < n; i++)); do printf '[p%d]' $i; done)concat=n=$n:v=1[v]" \
        -map '[v]' -c:v libx264 -preset ultrafast -crf 8 -pix_fmt yuv444p "$cut"
    cmd_clip "$cut" 0 "$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$cut")" "$out" $crop
}

cmd_clip() {
    local in="$1" start="$2" end="$3" out="$4" crop="${5:-}"
    ffmpeg -hide_banner -loglevel error -y -ss "$start" -to "$end" -i "$in" -an \
        -vf "${crop:+crop=$crop,}scale='min(1600,iw)':-2:flags=lanczos,fps=60,format=yuv420p" \
        -c:v libx264 -preset slow -crf 26 -movflags +faststart "$out"
    ls -la "$out"
    # every video loops on the site, so its last frame must be its first: how far apart they are
    local a b
    a="$(mktemp --suffix=.png)" b="$(mktemp --suffix=.png)"
    ffmpeg -hide_banner -loglevel error -y -i "$out" -frames:v 1 "$a"
    ffmpeg -hide_banner -loglevel error -y -sseof -0.1 -i "$out" -update 1 "$b"
    # pixels more than 8% apart, so the encoder's noise is mostly not counted: a few hundred are nothing,
    # a moved window or pointer is thousands
    echo "loop: $(magick compare -metric AE -fuzz 8% "$a" "$b" null: 2>&1 | cut -d' ' -f1 | cut -d. -f1) pixels differ between the first and last frames (a few hundred scattered over text are the encoder; a moved window or pointer is thousands)"
    rm -f "$a" "$b"
}

[[ $# -ge 1 ]] || usage
case "$1" in
    still)
        [[ $# -eq 3 ]] || usage
        magick "$2" -resize '1600x>' -quality 82 "$3"
        echo "$3"
        exit 0
        ;;
    clip)
        [[ $# -ge 5 ]] || usage
        shift; cmd_clip "$@"
        exit 0
        ;;
    cut)
        [[ $# -ge 4 ]] || usage
        shift; cmd_cut "$@"
        exit 0
        ;;
esac

find_vm
case "$1" in
    prepare) [[ $# -eq 2 ]] || usage; cmd_prepare "$2" ;;
    mode) set_mode ;;
    shot) [[ $# -eq 2 ]] || usage; cmd_shot "$2" ;;
    place)
        # place <wm class> <x> <y> <w> <h>: a window put where a scene expects it to start
        [[ $# -eq 6 ]] || usage
        js="const w = global.display.list_all_windows().find(w => (w.get_wm_class() || '').toLowerCase().includes('${2,,}'));
            if (w) { delete w._bwmJustMoved; w.unmaximize(Meta.MaximizeFlags ? Meta.MaximizeFlags.BOTH : undefined); w.move_resize_frame(true, $3, $4, $5, $6); w.activate(global.get_current_time()); }
            !!w"
        [[ "$(shell_eval "const Meta = imports.gi.Meta; $js")" == true ]] || die "no window of class $2"
        ;;
    close)
        # close <wm class>: closes a window as its close button does, so the app saves its state
        [[ $# -eq 2 ]] || usage
        js="const w = global.display.list_all_windows().find(w => (w.get_wm_class() || '').toLowerCase().includes('${2,,}'));
            if (w) w.delete(global.get_current_time());
            !!w"
        [[ "$(shell_eval "$js")" == true ]] || die "no window of class $2"
        ;;
    center)
        [[ $# -eq 2 ]] || usage
        js="const w = global.display.list_all_windows().find(w => (w.get_wm_class() || '').toLowerCase().includes('${2,,}'));
            if (w) { delete w._bwmJustMoved; if (w.maximized_horizontally || w.maximized_vertically) w.unmaximize(Meta.MaximizeFlags ? Meta.MaximizeFlags.BOTH : undefined);
                const r = w.get_frame_rect(), a = w.get_work_area_current_monitor();
                w.move_frame(true, a.x + Math.round((a.width - r.width) / 2), a.y + Math.round((a.height - r.height) / 2));
                w.activate(global.get_current_time()); }
            !!w"
        [[ "$(shell_eval "const Meta = imports.gi.Meta; $js")" == true ]] || die "no window of class $2"
        ;;
    opens-at)
        # opens-at <wm class> <x> <y>: the next window of that class to open is put there as soon
        # as it shows, at the size it opened at, for a scene whose windows must not open over one
        # another's title bars, as GNOME's centring would put them
        [[ $# -eq 4 ]] || usage
        js="const GLib = imports.gi.GLib;
            globalThis._captureOpensAt ??= {};
            globalThis._captureOpensAt['${2,,}'] = [$3, $4];
            globalThis._captureOpensAtId ??= global.display.connect('window-created', (d, w) => {
                w.get_compositor_private()?.connect('first-frame', () => {
                    const at = globalThis._captureOpensAt, k = Object.keys(at).find(k => (w.get_wm_class() || '').toLowerCase().includes(k));
                    if (!k) return;
                    const [x, y] = at[k]; delete at[k];
                    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 100, () => { w.move_frame(true, x, y); return GLib.SOURCE_REMOVE; });
                });
            });
            true"
        [[ "$(shell_eval "$js")" == true ]] || die "could not watch for $2"
        ;;
    take)
        shift
        lang=""
        case "${!#}" in en|ru) lang="${!#}"; set -- "${@:1:$#-1}" ;; esac
        [[ $# -ge 1 ]] || usage
        here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [[ -n "$lang" ]]; then
            [[ "$(session_lang)" == "$lang" ]] || bash "$0" prepare "$lang"
        fi
        if [[ "$1" == all ]]; then set -- $(ls "$here/pictures" | sed 's/\.sh$//'); fi
        for p in "$@"; do
            [[ -f "$here/pictures/$p.sh" ]] || die "no pictures/$p.sh"
            echo "== $p"
            bash "$here/pictures/$p.sh"
        done
        ;;
    reset)
        # every app window of tester's closed, so a scene starts from an empty desktop
        guest "pkill -u tester -f 'chrome|nautilus|gnome-calculator|gnome-text-editor|papers|extension-manager|borshevik-(image|app)-manager|hiddify|gnome-weather|gnome-contacts|gnome-calendar|/app/bin/secrets|gnome-software|gnome-control-center|ptyxis|/app/bin/Telegram|/Steam/|PortProton|\.exe|mediawriter' || true"
        sleep 2
        ;;
    key)
        shift
        for combo in "$@"; do
            IFS=- read -r -a parts <<<"$combo"
            send_keys "${parts[@]}"
            sleep "${CAPTURE_KEY_GAP:-0.2}"
        done
        ;;
    type)
        [[ $# -eq 2 ]] || usage
        text="$2"
        for (( i = 0; i < ${#text}; i++ )); do
            read -r -a ks <<<"$(char_keys "${text:i:1}")"
            send_keys "${ks[@]}"
            sleep 0.08
        done
        ;;
    move) [[ $# -eq 3 ]] || usage; pointer "$2" "$3" ;;
    click)
        [[ $# -ge 3 ]] || usage
        pointer "$2" "$3"; sleep 0.1
        button "${4:-left}" down; sleep 0.08; button "${4:-left}" up
        ;;
    dclick|tclick)
        [[ $# -eq 3 ]] || usage
        pointer "$2" "$3"; sleep 0.1
        n=2; [[ "$1" == tclick ]] && n=3
        for (( k = 0; k < n; k++ )); do button left down; sleep 0.05; button left up; sleep 0.08; done
        ;;
    drag)
        [[ $# -eq 5 ]] || usage
        pointer "$2" "$3"; sleep 0.15
        button left down; sleep 0.15
        for s in 1 2 3 4 5 6 7 8 9 10 11 12; do
            pointer $(( $2 + ($4 - $2) * s / 12 )) $(( $3 + ($5 - $3) * s / 12 ))
            sleep 0.04
        done
        sleep 0.2; button left up
        ;;
    windows)
        # where each window is: what a scene's coordinates are worked out from
        shell_eval "const wm = global.workspace_manager;
            global.display.list_all_windows().filter(w => !w.skip_taskbar).map(w => {
                const r = w.get_frame_rect();
                return \`\${w.get_wm_class()} ws\${w.get_workspace()?.index()} \${r.x},\${r.y} \${r.width}x\${r.height}\${w.maximized_horizontally && w.maximized_vertically ? ' maximized' : ''}\${w.minimized ? ' minimized' : ''}\${w.has_focus() ? ' focused' : ''}\`;
            }).join(' ;; ') + \` ;; workspace \${wm.get_active_workspace_index() + 1} of \${wm.n_workspaces} shown\`" | sed 's/ ;; /\n/g'
        ;;
    eval) [[ $# -eq 2 ]] || usage; shell_eval "$2" ;;
    session) [[ $# -eq 2 ]] || usage; in_session "$2" ;;
    launch)
        # In a scope of tester's user manager, as GNOME Shell starts apps, not in the SSH
        # session the command arrives through: polkit takes an app in an SSH session for a
        # remote one, and refuses what the Image Manager asks rpm-ostree for.
        [[ $# -ge 2 ]] || usage
        shift
        in_session "systemd-run --user --scope --quiet --collect -- $(printf '%q ' "$@") >/dev/null 2>&1 </dev/null &"
        ;;
    root) [[ $# -eq 2 ]] || usage; guest "$2" ;;
    put)
        [[ $# -eq 3 ]] || usage
        scp -q -i "$key" -P "$port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o IdentitiesOnly=yes -o LogLevel=ERROR "$2" "root@127.0.0.1:$3"
        ;;
    stick)
        # A 16 GB USB stick, which the machine takes for a SanDisk Ultra rather than QEMU's
        # own disk: a file next to the machine's disk, plugged in through QMP the first time -
        # a usb-bot plugged in while the machine runs stays detached until told otherwise -
        # and wiped every time, as Fedora Media Writer offers to restore a stick it has
        # written rather than just to write it.
        [[ -n "$port" ]] || die "stick needs the test machine"
        if ! guest 'lsblk -dno VENDOR | grep -q SanDisk'; then
            [[ -f "$dir/stick.img" ]] || truncate -s 16G "$dir/stick.img"
            qmp blockdev-add "{\"driver\": \"raw\", \"node-name\": \"stick\", \"file\": {\"driver\": \"file\", \"filename\": \"$dir/stick.img\"}}"
            qmp device_add '{"driver": "usb-bot", "id": "stickbot"}'
            qmp device_add '{"driver": "scsi-hd", "bus": "stickbot.0", "drive": "stick", "vendor": "SanDisk", "product": "Ultra", "removable": true}'
            qmp qom-set '{"path": "/machine/peripheral/stickbot", "property": "attached", "value": true}'
            sleep 3
        fi
        guest 'd=$(lsblk -dnpo NAME,VENDOR | awk "\$2 == \"SanDisk\" { print \$1 }"); [ -n "$d" ] || exit 1
            # GNOME mounts what was written on it once its partitions show
            lsblk -lnpo NAME "$d" | tail -n +2 | xargs -r -n 1 umount 2>/dev/null
            wipefs -aq "$d" >/dev/null 2>&1; dd if=/dev/zero of="$d" bs=1M count=16 conv=fsync status=none
            # what the kernel holds of its partitions dropped too, which outlives the wipe
            partx -d "$d" 2>/dev/null; blockdev --rereadpt "$d"; udevadm settle' \
            || die "the stick did not show up in the machine"
        ;;
    film) [[ $# -ge 3 ]] || usage; cmd_film "$2" "$3" "${4:-4}" ;;
    *) usage ;;
esac
