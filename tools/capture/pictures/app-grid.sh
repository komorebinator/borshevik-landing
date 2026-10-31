#!/usr/bin/env bash
# makes: app-grid
# The app grid, with the apps the App Manager installs by default.
. "$(dirname "$0")/../lib.sh"
fresh
c key meta_l-a; sleep 2
keep app-grid
c key esc
