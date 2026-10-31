#!/usr/bin/env bash
# makes: hero app-manager app-manager-other-pc
# The App Manager as a new user meets it, in the middle of the screen, Android support ticked
# to show the module; then its From another PC tab.
. "$(dirname "$0")/../lib.sh"
fresh
c launch gtk-launch org.borshevik.AppManager; sleep 8
c center appmanager; sleep 1
c click 230 682; sleep 0.6
keep hero
cp "$img/hero.webp" "$img/app-manager.webp"
if [[ $lang == ru ]]; then c click 826 146; else c click 805 146; fi
sleep 1.5
c center appmanager; sleep 1
keep app-manager-other-pc
c key alt-f4
