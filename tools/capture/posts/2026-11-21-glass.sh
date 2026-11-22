#!/usr/bin/env bash
# The pictures and the video of posts/2026-11-21-glass, in the session's language (capture.sh
# prepare <en|ru> first for the other), taken once for the post on 2026-11-21 on :stable, the
# first with Borshevik Glass, with the purple accent, which the post's pictures share. The
# wallpaper is the one Borshevik is to ship, not yet in the image: copied into the machine
# with `capture.sh put` and set as picture-uri and picture-uri-dark before this script runs.
#
# overview-dark.<lang>.webp, the post's first picture: the overview with Files open on the
# first workspace, the whole screen, in the dark style.
#
# calendar.<lang>.webp: the calendar with two notifications in it — sent with Do Not Disturb
# on, as it is in the test machine, so they go straight to the list — cropped to 16:10 around
# it. quick-settings.<lang>.webp: Quick Settings, cropped to 16:10 at the screen's top right.
# Two pictures, not one: the two menus overlap on the screen.
#
# accents.<lang>.mp4: the app grid with Quick Settings open over it, one still for each of
# eight of GNOME's accents, the dark style and the light taking turns — purple dark, blue light,
# teal dark and so on; slate is left out, as a ninth would put two dark stills side by side
# where the loop closes. The shell changes the accent at once, with nothing to watch, so the
# stills are joined afterwards by a wave from left to right, eased and soft-edged, which the
# change between dark and light makes plain; the last still waves into the first, so it loops.
# The panel's clock is stopped while they are taken, as film stops it, so a minute turning over
# does not show.
. "$(dirname "$0")/../lib.sh"
post="$root/posts/2026-11-21-glass"
M() { c eval "import('resource:///org/gnome/shell/ui/main.js').then(Main => { $1 }); true" >/dev/null; }
scheme() { c session "gsettings set org.gnome.desktop.interface color-scheme $1"; sleep 4; }

fresh
c session 'gsettings set org.gnome.desktop.interface accent-color purple'
scheme prefer-dark
c launch nautilus --new-window; sleep 5

overview() { # out.webp
    c key meta_l; sleep 3
    keep overview "$1"
    c key esc; sleep 2
}

overview "$post/overview-dark.$lang.webp"

if [[ $lang == ru ]]; then
    c session 'notify-send -a Telegram -i org.telegram.desktop "Морошка" "Собрали первую корзину, завтра варим варенье"
        notify-send -a "Image Manager" -i org.borshevik.ImageManager "Обновление загружено" "Новая версия Borshevik установится после перезагрузки"'
else
    c session 'notify-send -a Telegram -i org.telegram.desktop "Cloudberry" "We picked the first basket, jam tomorrow"
        notify-send -a "Image Manager" -i org.borshevik.ImageManager "Update downloaded" "The new version of Borshevik is installed when you restart"'
fi
sleep 2
c move 1439 899
M 'Main.panel.statusArea.dateMenu.menu.open();'; sleep 2
c shot "$work/$lang-calendar.png" >/dev/null
magick "$work/$lang-calendar.png" -crop 1045x653+198+0 +repage "$work/$lang-calendar.png"
c still "$work/$lang-calendar.png" "$post/calendar.$lang.webp"
M 'Main.panel.statusArea.dateMenu.menu.close(); Main.panel.statusArea.quickSettings.menu.open();'; sleep 2
c shot "$work/$lang-quick-settings.png" >/dev/null
magick "$work/$lang-quick-settings.png" -crop 576x360+864+0 +repage "$work/$lang-quick-settings.png"
c still "$work/$lang-quick-settings.png" "$post/quick-settings.$lang.webp"
M 'Main.panel.statusArea.quickSettings.menu.close(); Main.messageTray.getSources().forEach(s => s.destroy());'; sleep 1

# the accents: stills, the clock stopped
accents=(purple blue teal green yellow orange red pink)
stills="$work/$lang-accents"; rm -rf "$stills"; mkdir -p "$stills"
M 'const l = Main.panel.statusArea.dateMenu._clockDisplay;
    globalThis._captureClock?.destroy();
    globalThis._captureClock = new imports.gi.St.Label({ text: l.text, style_class: l.style_class, y_align: l.y_align });
    l.get_parent().insert_child_above(globalThis._captureClock, l); l.hide();'
c key meta_l-a; sleep 3
c move 1439 899
M 'Main.panel.statusArea.quickSettings.menu.open();'; sleep 2
for n in "${!accents[@]}"; do
    s=prefer-dark; (( n % 2 )) && s=default
    c session "gsettings set org.gnome.desktop.interface color-scheme $s; gsettings set org.gnome.desktop.interface accent-color ${accents[$n]}"
    sleep 2.5
    c shot "$stills/$n.png" >/dev/null
done
M 'Main.panel.statusArea.quickSettings.menu.close();
    Main.panel.statusArea.dateMenu._clockDisplay.show();
    globalThis._captureClock?.destroy(); delete globalThis._captureClock;'
c session 'gsettings set org.gnome.desktop.interface accent-color purple; gsettings set org.gnome.desktop.interface color-scheme prefer-dark'
c key esc

# the stills waved one into the next, each held 2 s
python3 - "$stills" "${#accents[@]}" "$post/accents.$lang.mp4" <<'PY'
import subprocess, sys
stills, n, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
hold, dur, soft = 2.0, 0.45, 90
seq = list(range(n)) + [0]
args = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
for i in seq:
    args += ["-loop", "1", "-t", f"{hold + dur}", "-framerate", "60", "-i", f"{stills}/{i}.png"]
# eased (smoothstep) and soft-edged; no st()/ld() in the expression, whose registers xfade's
# slice threads share, which scattered noise over the frame
s = "((1-P)*(1-P)*(1+2*P))"
m = f"clip(((W+{2 * soft})*{s}-{soft}-X)/{soft}+0.5,0,1)"
f, prev, off = [], "[0:v]", 0.0
for j in range(1, len(seq)):
    off += hold
    f.append(f"{prev}[{j}:v]xfade=transition=custom:expr='B*{m}+A*(1-{m})':duration={dur}:offset={off:.3f}[x{j}]")
    prev = f"[x{j}]"
# to the end of the last wave, into the first still, which the loop then holds
f.append(f"{prev}trim=0:{off + dur:.3f},format=yuv420p[v]")
args += ["-filter_complex", ";".join(f), "-map", "[v]", "-c:v", "libx264", "-preset", "slow", "-crf", "26",
         "-movflags", "+faststart", out]
subprocess.run(args, check=True)
print(out)
PY
