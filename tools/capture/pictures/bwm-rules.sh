#!/usr/bin/env bash
# makes: bwm-rules
# A window rule made from the Window Rules' Windows tab (Super+R): Calculator always on top.
# The editor and Calculator float on one workspace apart, the editor focused; the editor is
# carried over Calculator before the rule and after it: scenes/bwm-rules.txt. fresh removes
# the rule again before the next take.
. "$(dirname "$0")/../lib.sh"
fresh
c launch flatpak run org.gnome.Calculator; sleep 6
c place calculator 940 180 360 616; sleep 1
# the editor opened at a floating size: one earlier scenes left it at, the height of the
# screen, would have it tiled as it opens, and a drag would treat it as a tile. Closed at
# that size it opens at it again, judged floating, and is put in its place as it shows.
editor; sleep 5
c place texteditor 120 200 640 480; sleep 1
c close texteditor; sleep 2
c opens-at texteditor 120 200
editor; sleep 5
c move 720 820
film bwm-rules bwm-rules 0.1 15
# the rule saved must be Calculator's, or the scene clicked the wrong window's button
rules="$(c session 'gsettings --schemadir /usr/share/gnome-shell/extensions/borshevik-workspace-manager@komorebinator/schemas get org.gnome.shell.extensions.borshevik-workspace-manager window-rules')"
[[ "$rules" == *Calculator* ]] || { echo "bwm-rules: the rule was not made for Calculator; the scene clicked another window" >&2; exit 1; }
