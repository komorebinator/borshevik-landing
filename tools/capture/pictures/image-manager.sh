#!/usr/bin/env bash
# makes: image-manager
# The Image Manager having checked for updates: one waiting, rollback and automatic updates below.
. "$(dirname "$0")/../lib.sh"
fresh
c launch gtk-launch org.borshevik.ImageManager; sleep 5
c center imagemanager; sleep 1
c click 718 540
sleep 10
keep image-manager
c key alt-f4
