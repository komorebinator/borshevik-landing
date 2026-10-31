#!/usr/bin/env bash
# makes: app-search
# "terminal" typed with the Russian layout on, as "еуктштфд", still finding Terminal, which
# Enter starts: the test machine has no Steam account to start Steam with.
. "$(dirname "$0")/../lib.sh"
fresh
side_by_side
film app-search app-search 0.1 8.5
