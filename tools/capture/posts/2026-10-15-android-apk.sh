#!/usr/bin/env bash
# The APK installer's picture of posts/2026-10-15-android, in the session's language
# (capture.sh prepare <en|ru> first for the other): F-Droid's client, pinned as borshevik's
# android scenario pins it, downloaded into Downloads and opened from there as a double click
# opens it, the installer asking whether to install it over the folder in Files. Kept in the
# post's folder as apk-install.<lang>, taken once for the post. Added to the post on
# 2026-10-27, apart from the post's other pictures, which this script does not take again.
# Android is installed for it and removed after.
. "$(dirname "$0")/../lib.sh"
post="$root/posts/2026-10-15-android"
fresh
android_installed
c session 'curl -sfL -o "$(xdg-user-dir DOWNLOAD)/F-Droid.apk" https://f-droid.org/repo/org.fdroid.fdroid_1023052.apk'
c launch sh -c 'exec nautilus "$(xdg-user-dir DOWNLOAD)"'; sleep 4
c launch sh -c 'exec gio open "$(xdg-user-dir DOWNLOAD)/F-Droid.apk"'; sleep 6
keep apk-install "$post/apk-install.$lang.webp"
c close org.borshevik.ApkInstaller
c close org.gnome.Nautilus
c session 'rm -f "$(xdg-user-dir DOWNLOAD)/F-Droid.apk"'
android_removed
