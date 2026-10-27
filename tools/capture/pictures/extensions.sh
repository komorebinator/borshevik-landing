#!/usr/bin/env bash
# makes: extensions
# Extension Manager at its usual size, listing the extensions Borshevik ships.
. "$(dirname "$0")/../lib.sh"
fresh
c launch flatpak run com.mattjakeman.ExtensionManager; sleep 7
c center extensionmanager; sleep 1.5
keep extensions
c key ctrl-q
