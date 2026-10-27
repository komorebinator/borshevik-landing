#!/usr/bin/env bash
# makes: steam
# Games: Steam's sign-in window beside Battle.net's, which PortProton installs — the test
# machine has no accounts to show a library with, and a sign-in window is what anyone sees
# first. Steam is part of Borshevik; PortProton, from the App Manager's games, is installed
# for the picture with Battle.net in it, and removed after with all its data, Battle.net's
# included, so the other pictures' app grid does not show them and the next run installs
# Battle.net again in its language, which it keeps from its installation.
# The coordinates are those of the windows as GNOME centres them; Battle.net's installer
# speaks the session's language and its buttons stay where they are.
. "$(dirname "$0")/../lib.sh"
fresh
pp=ru.linux_gaming.PortProton

# until a window of the class, at a size that matches, is there, for at most <seconds>
wait_window() { # class size-regex seconds
    local t
    for (( t = 0; t < $3; t += 5 )); do
        c windows | grep -qE "^$1 ws[0-9]+ [0-9-]+,[0-9-]+ $2" && return 0
        sleep 5
    done
    echo "steam.sh: no $1 window at $2 after $3 s" >&2
    return 1
}
# a window by its exact class: place matches classes by their beginning, and Battle.net's
# window is steam_proton, Steam's steam
move_exact() { # class x y
    c eval "const w = global.display.list_all_windows().find(w => w.get_wm_class() === '$1');
        if (w) w.move_frame(true, $2, $3); !!w" >/dev/null
}

# PortProton's data, Battle.net's prefix in it, as tester's: flatpak's --delete-data run as root
# leaves them, and a PortProton that finds Battle.net installed does not run its installer
pp_removed() {
    c session 'rm -rf ~/.var/app/'"$pp"' ~/.local/share/applications/*attle*.desktop \
        "$(xdg-user-dir DESKTOP)"/*attle*.desktop "$(xdg-user-dir DESKTOP)"/PortProton.desktop'
}
pp_removed

# PortProton and Battle.net in it. Its first start sets PortProton up, then opens its main
# window rather than the autoinstall asked for, or just ends; then Battle.net's tile there,
# or the autoinstall asked again, starts the installer.
c root "flatpak install -y --noninteractive --system flathub $pp >/dev/null 2>&1"
autoinstall() { c launch flatpak run "$pp" cli --autoinstall PW_BATTLE_NET; }
autoinstall
for _ in $(seq 180); do
    sleep 5
    w="$(c windows)"
    grep -qE '^steam_proton ' <<<"$w" && break
    # the main window, wider in Russian: Battle.net's tile from its left edge
    if m="$(grep -oE '^PortProton ws[0-9]+ [0-9-]+,[0-9-]+ 1[0-9]{3}x' <<<"$w")"; then
        x="${m#* * }"; c click $(( ${x%%,*} + 152 )) 409
    elif ! c root "pgrep -u tester -f 'PortProton/data/scripts|/app/bin/portproton' >/dev/null"; then
        autoinstall
    fi
done
# Battle.net's installer: its language, then its place, without starting with the computer
wait_window steam_proton '[0-9]+x[0-9]+' 300; sleep 5
c click 587 538; sleep 15
c click 577 315; sleep 1
c click 929 481
# installed once PortProton offers a shortcut, which is not needed: Battle.net is started
# by PortProton's command line, without its launch dialog, whose buttons move with the language
wait_window PortProton '[0-9]+x268' 1800
c root "pkill -u tester -f 'PortProton|\\.exe' ; true"; sleep 5
exe="$(c session 'cd ~ && find ~/.var/app/'"$pp"'/data/prefixes/BATTLE_NET/drive_c -name Battle.net.exe -path "*Battle.net/Battle.net.exe" | head -1')"
c launch flatpak run "$pp" cli --launch "$exe"
wait_window steam_proton '362x[0-9]+' 600; sleep 20

# Steam in the session's language, which it keeps in its own registry; on its first run it
# brings its runtime down first, which takes minutes.
# Started last: its sign-in QR code expires within minutes and greys out
steam_lang=english; [[ $lang == ru ]] && steam_lang=russian
c session "f=~/.steam/registry.vdf; [ -f \$f ] && sed -i 's/\"language\"\t\t\"[a-z]*\"/\"language\"\t\t\"$steam_lang\"/' \$f; true"
c launch steam
wait_window steam '700x440' 900

# the two side by side; Battle.net's window, moved, draws white until it is shown again
move_exact steam 169 246
move_exact steam_proton 909 135; sleep 1
c eval "const w = global.display.list_all_windows().find(w => w.get_wm_class() === 'steam_proton'); w.minimize(); true" >/dev/null; sleep 2
c eval "const w = global.display.list_all_windows().find(w => w.get_wm_class() === 'steam_proton'); w.unminimize(); w.activate(global.get_current_time()); true" >/dev/null
sleep 10
keep steam

c root "pkill -u tester -f 'PortProton|\\.exe|/Steam/' ; true"; sleep 5
c root "flatpak uninstall -y --noninteractive $pp >/dev/null 2>&1; true"
pp_removed
