#!/usr/bin/env bash
# makes: android
# The Image Manager's Android tab with Android installed: its updates and Google Play
# registration. Android is installed for it and removed after.
. "$(dirname "$0")/../lib.sh"
fresh
c session "gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings reset org.gnome.desktop.interface accent-color"
gpu_shown
android_installed
android_tab
keep android
c close imagemanager; sleep 1
android_removed
