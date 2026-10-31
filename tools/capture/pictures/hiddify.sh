#!/usr/bin/env bash
# makes: hiddify
# Hiddify's main window, in the dark style and the session's language, which Hiddify keeps
# in its own settings rather than taking from the system.
. "$(dirname "$0")/../lib.sh"
fresh
# made if Hiddify never ran, or its first-run screens show instead
c session "f=~/.local/share/app.hiddify.com/shared_preferences.json
    mkdir -p \$(dirname \$f); [ -f \"\$f\" ] || echo '{}' >\"\$f\"
    python3 - \"\$f\" <<PY
import json, sys
d = json.load(open(sys.argv[1]))
d.update({'flutter.locale': '$lang', 'flutter.theme_mode': 'dark', 'flutter.intro_completed': True,
          'flutter.enable_analytics': False})
json.dump(d, open(sys.argv[1], 'w'))
PY
    true"
c launch gtk-launch Hiddify; sleep 12
c center hiddify; sleep 1
keep hiddify
