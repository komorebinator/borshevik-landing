#!/usr/bin/env bash
# makes: bwm-panel
# The workspace buttons on the panel: scenes/bwm-panel.txt says what the video shows. Weather,
# Calendar and Contacts float on the first workspace, Files and Terminal are tiled on the
# second, Chrome is maximized on the third; the first is shown.
. "$(dirname "$0")/../lib.sh"
fresh
shaped
# Weather showing Yerevan, not its first-run screen; Calendar
# floating, not maximized as it last was; Contacts past its first-run setup
city="('Yerevan', 'UDYZ', true, [(0.70125, 0.77665)], [(0.70070, 0.77485)])"
c session "flatpak run --command=gsettings org.gnome.Weather set org.gnome.Weather locations \"[<(uint32 2, <$city>)>]\"
    flatpak run --command=gsettings org.gnome.Weather set org.gnome.Weather window-maximized false
    flatpak run --command=gsettings org.gnome.Calendar set org.gnome.calendar window-maximized false
    flatpak run --command=gsettings org.gnome.Calendar set org.gnome.calendar window-size '(760, 540)'
    flatpak run --command=gsettings org.gnome.Contacts set org.gnome.Contacts did-initial-setup true
    flatpak run --command=gsettings org.gnome.Contacts set org.gnome.Contacts window-maximized false
    flatpak run --command=gsettings org.gnome.Contacts set org.gnome.Contacts window-width 640
    flatpak run --command=gsettings org.gnome.Contacts set org.gnome.Contacts window-height 500"
# the three scattered over the first workspace, overlapping a little, as windows left floating do
c opens-at calendar 40 64
c opens-at weather 770 90
c opens-at contacts 420 360
c launch flatpak run org.gnome.Calendar; sleep 5
c launch flatpak run org.gnome.Weather; sleep 6
c launch flatpak run org.gnome.Contacts; sleep 5
# Files and Terminal tiled on the second: the empty workspace shown opens the overview, which
# Esc closes; Files opens tile-shaped and is tiled as it opens, Terminal is tiled beside it
c key meta_l-2; sleep 1.5
c key esc; sleep 1
c launch nautilus --new-window; sleep 4
c launch ptyxis --new-window; sleep 4
c key meta_l-right; sleep 2
# Chrome, maximized, takes a workspace of its own, the third
chrome; sleep 9
c key meta_l-1; sleep 1.5
c move 720 450
film bwm-panel bwm-panel 0.1 18.2
