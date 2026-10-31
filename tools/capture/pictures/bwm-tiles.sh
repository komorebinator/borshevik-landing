#!/usr/bin/env bash
# makes: bwm-tiles
# The Workspace Manager's video: scenes/bwm-tiles.txt says what it shows. It starts and ends
# on an empty desktop, every app opened by search: Files and Terminal floating, apart enough
# that Hiddify, once it lands over them, leaves a piece of each title bar to drag them by;
# Chrome and the PDF maximized.
. "$(dirname "$0")/../lib.sh"
fresh
shaped
pdfs
# the PDF of the session's language alone in the documents, first in Files' grid whatever
# its name
if [[ $lang == ru ]]; then other=Cloudberry.pdf; else other=Морошка.pdf; fi
c session "cd \"\$(xdg-user-dir DOCUMENTS)\" && rm -f '$other' note.txt
    gsettings set org.gnome.nautilus.window-state initial-size '(760, 520)'
    flatpak run --command=gsettings org.gnome.Papers set org.gnome.Papers.Default window-maximized true
    # Hiddify's close button quits it, without asking, and leaves no icon in the panel the
    # first frame did not have
    f=~/.local/share/app.hiddify.com/shared_preferences.json
    mkdir -p \$(dirname \$f); [ -f \"\$f\" ] || echo '{}' >\"\$f\"
    python3 - \"\$f\" <<PY
import json, sys
d = json.load(open(sys.argv[1]))
d.update({'flutter.locale': '$lang', 'flutter.theme_mode': 'dark', 'flutter.intro_completed': True,
          'flutter.enable_analytics': False, 'flutter.action_at_close': 'exit'})
json.dump(d, open(sys.argv[1], 'w'))
PY
    true"
c opens-at nautilus 660 44
c opens-at ptyxis 40 330
c move 720 450
film bwm-tiles bwm-tiles 0.1 60.8
