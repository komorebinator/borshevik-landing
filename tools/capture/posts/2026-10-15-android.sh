#!/usr/bin/env bash
# The pictures of posts/2026-10-15-android, in the session's language (capture.sh prepare
# <en|ru> first for the other): the Image Manager's Android tab before Android is installed
# and after, and an Android window following GNOME's accent colour and style, filmed from
# 2026-10-15-android-theme.txt. Kept in the post's folder as <name>.<lang>, taken once for the
# post and not again with the pages' pictures: a post shows Borshevik as it was when it came
# out. Android is installed for them and removed after. Look at the video before keeping it:
# once in four takes Android's window, recreated as the style turned light, did not come back,
# and the take was made again.
. "$(dirname "$0")/../lib.sh"
post="$root/posts/2026-10-15-android"
fresh
# the style dark and the accent Borshevik's, for the tab and as the video starts and ends
c session "gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings reset org.gnome.desktop.interface accent-color"
gpu_shown

# before: an installed Android's stamp put aside meanwhile, the one thing the tab goes by
c root "[ -f $android_stamp ] && mv $android_stamp $android_stamp.capture || true"
android_tab
keep install-android "$post/install-android.$lang.webp"
c close imagemanager; sleep 1
c root "[ -f $android_stamp.capture ] && mv $android_stamp.capture $android_stamp || true"

# after
android_installed
android_tab
keep android-tab "$post/android-tab.$lang.webp"
c close imagemanager; sleep 1

# Android started and booted; Settings started as its launcher starts it — an activity
# Android starts by itself gets no window on the desktop — then its list of all apps, which
# opens as a task of its own, and the first one, Settings' main page, removed. The list is
# placed from inside Android, whose windows GNOME sees as one surface the size of the screen:
# Android's coordinates are the screen's below the panel. GNOME's Settings on its Appearance
# page on the right, floating, the two apart.
c session "gsettings set org.gnome.Settings window-state '(780, 720, false)'"
c launch waydroid session start
for _ in $(seq 60); do
    [[ "$(c root 'waydroid shell -- getprop sys.boot_completed 2>/dev/null' 2>/dev/null)" == 1* ]] && break
    sleep 5
done
c launch waydroid app launch com.android.settings; sleep 10
c root "waydroid shell -- am start -a android.settings.MANAGE_ALL_APPLICATIONS_SETTINGS >/dev/null 2>&1"; sleep 6
task_of() { # the activity, as dumpsys names it
    c root "waydroid shell -- dumpsys activity recents 2>/dev/null | grep -m1 'A=1000:$1}' | sed 's/.*#\([0-9]*\) .*/\1/'" 2>/dev/null
}
c root "waydroid shell -- am stack remove $(task_of com.android.settings.root) >/dev/null 2>&1"
c root "waydroid shell -- am task resize $(task_of com.android.settings) 60 90 520 830 >/dev/null 2>&1"; sleep 3
c opens-at org.gnome.settings 610 100
c launch gnome-control-center; sleep 6
c click 705 455; sleep 2
c move 1000 700
film "$(dirname "$0")/2026-10-15-android-theme.txt" android-theme 0.1 12.4 "$post/android-theme.$lang.mp4"

c close org.gnome.settings
android_removed
