#!/usr/bin/env bash
# makes: installer mok grub
# The installer's video, and the NVIDIA key's enrollment on the first start, from the ISO as
# borshevik.org serves it, booted in a machine of its own: no SSH there, only its screen,
# keyboard and pointer, through capture.sh with CAPTURE_VM. See @LandingPage#capture#installer
# in spec/.
# usage: installer.sh take <iso> <en|ru>   boots the ISO in that language, films
#                                          scenes/installer-<lang>.txt to media/<lang>/installer.mp4
#                                          and powers the machine off
#        installer.sh mok <nvidia-iso> <en|ru>
#                                          installs the NVIDIA image with Secure Boot on, films
#                                          scenes/mok.txt at its first start to media/<lang>/mok.mp4
#                                          and powers the machine off
#        installer.sh grub <iso>          takes GRUB's menu to media/<lang>/grub.webp, both
#                                          languages, and powers the machine off
#        installer.sh boot <iso> <en|ru> [secure]
#                                          only starts it, up to the installer's first screen,
#                                          to work a scene out in
#        installer.sh stop                 powers it off and drops its disk
# Runs on the host: needs the GNOME Boxes flatpak, whose qemu and UEFI firmware it uses,
# python3, ImageMagick (magick) and ffmpeg with libx264.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
work="${XDG_CACHE_HOME:-$HOME/.cache}/landing-capture"
vm="$work/installer-vm"
export CAPTURE_VM="$vm" CAPTURE_W=1440 CAPTURE_H=900

die() { echo "$*" >&2; exit 1; }
c() { bash "$here/capture.sh" "$@"; }
boxes() { flatpak run --filesystem="$work" --filesystem="$(dirname "$iso")" --command="$1" org.gnome.Boxes "${@:2}"; }

qmp_quit() {
    python3 - "$vm/qmp.sock" <<'PY' 2>/dev/null || true
import socket, sys
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); s.recv(4096)
s.sendall(b'{"execute":"qmp_capabilities"}'); s.recv(4096)
s.sendall(b'{"execute":"quit"}')
PY
}

# The machine with the ISO in it, up to the installer's first screen in a language: GRUB's
# first entry, Install, rather than its default, which checks the medium first, with the
# language on its command line and the installer's guess by the network's location off - it
# would pick the language and time zone of wherever the machine filming it is. Given the
# language, it picks the time zone that goes with it, as it would have for someone there.
# The display is a standard VGA: with virtio-vga the pointer is drawn on a plane of its own
# that screendump leaves out, and asked for 1440x900 the ISO hung switching to its root.
# The network is net0, which a scene's link step unplugs and plugs back in. Given grub for a
# language, it stops at GRUB's menu.
cmd_boot() { # iso lang|grub [secure]
    iso="$(realpath "$1")"
    [[ -f "$iso" ]] || die "no ISO at $1"
    local locale
    case "$2" in en) locale=en_US.UTF-8 ;; ru) locale=ru_RU.UTF-8 ;; grub) locale= ;; *) die "no language $2" ;; esac
    mkdir -p "$vm"
    rm -f "$vm/disk.qcow2" "$vm/vars.fd" "$vm/qmp.sock"
    boxes qemu-img create -q -f qcow2 "$vm/disk.qcow2" 40G
    # With Secure Boot, Fedora's own firmware and variables, Microsoft's keys enrolled, which
    # the Boxes flatpak does not ship: taken from Fedora's edk2-ovmf package, once, into the
    # cache. Its firmware wants SMM and its flash kept from the guest.
    local code=/app/share/qemu/edk2-x86_64-code.fd machine=q35 secure=()
    if [[ "${3:-}" == secure ]]; then
        local ovmf="$work/ovmf"
        [[ -f "$ovmf/OVMF_VARS.secboot.fd" ]] || { mkdir -p "$ovmf"; podman run --rm -v "$ovmf:/out:Z" \
            registry.fedoraproject.org/fedora-minimal:44 sh -c 'microdnf -y -q install edk2-ovmf >/dev/null 2>&1
                cp /usr/share/edk2/ovmf/OVMF_CODE.secboot.fd /usr/share/edk2/ovmf/OVMF_VARS.secboot.fd /out/'; }
        cp "$ovmf/OVMF_VARS.secboot.fd" "$vm/vars.fd"
        code="$ovmf/OVMF_CODE.secboot.fd" machine=q35,smm=on
        secure=(-global driver=cfi.pflash01,property=secure,value=on)
    else
        boxes cp /app/share/qemu/edk2-i386-vars.fd "$vm/vars.fd"
    fi
    boxes qemu-system-x86_64 \
        -name borshevik-installer \
        -enable-kvm -machine "$machine" -cpu host -smp 4 -m 6144 "${secure[@]}" \
        -drive "if=pflash,format=raw,readonly=on,file=$code" \
        -drive "if=pflash,format=raw,file=$vm/vars.fd" \
        -drive "file=$vm/disk.qcow2,if=virtio" \
        -drive "file=$iso,media=cdrom,readonly=on" \
        -device VGA,xres=1440,yres=900 -display none \
        -qmp "unix:$vm/qmp.sock,server=on,wait=off" \
        -device qemu-xhci -device usb-tablet \
        -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
        >"$vm/qemu.log" 2>&1 &
    local i
    for (( i = 0; i < 100; i++ )); do [[ -S "$vm/qmp.sock" ]] && break; sleep 0.1; done
    [[ -S "$vm/qmp.sock" ]] || die "the machine did not start: $(cat "$vm/qemu.log")"
    # GRUB's entry edited: its kernel line is the third
    sleep 8
    [[ -n "$locale" ]] || return 0
    c key up; c key e; sleep 1
    c key down; c key down; c key end
    c type " inst.geoloc=0 inst.lang=$locale"; sleep 1
    c key ctrl-x
    # the boot's text screens have a handful of colours, the installer hundreds
    for (( i = 0; i < 120; i++ )); do
        sleep 5
        c shot "$work/installer-wait.png" >/dev/null
        (( $(magick identify -format %k "$work/installer-wait.png") > 200 )) && { sleep 10; return 0; }
    done
    die "the installer did not come up in 10 minutes"
}

# Waits up to <seconds> for the screen to pass a test: a pixel's colour, or plymouth's white
# text in a part of the screen.
pixel_is() { # x y rrggbb
    [[ "$(magick "$work/installer-wait.png" -format "%[hex:p{$1,$2}]" info:)" == "${3^^}" ]]
}
text_in() { # crop
    (( $(magick "$work/installer-wait.png" -crop "$1" -threshold 80% -format '%[fx:int(mean*w*h)]' info:) > 200 ))
}
until_seen() { # seconds test args...
    local i
    for (( i = 0; i < $1 * 2; i++ )); do
        c shot "$work/installer-wait.png" >/dev/null
        "${@:2}" && return 0
        sleep 0.2
    done
    die "not on the screen after $1 s: ${*:2}"
}

cmd_stop() {
    qmp_quit
    sleep 2
    # one that outlived its quit, as one did once, ended all the same
    pkill -f -- '-name borshevik-installer ' || true
    rm -f "$vm/disk.qcow2" "$vm/vars.fd" "$vm/qmp.sock"
}

# Filmed in real time, as it plays (@LandingPage#capture#film), from the installer's first
# screen through the first start's GNOME Initial Setup to the desktop, and cut
# (@LandingPage#capture#cut): what only takes time - the installation's middle, the restart,
# the boot after the passphrase, the session starting - goes.
cmd_take() { # iso lang
    cmd_boot "$1" "$2"
    trap cmd_stop EXIT
    c film "$here/scenes/installer-$2.txt" "$work/$2-installer.mkv"
    c cut "$here/scenes/installer-$2.txt" "$work/$2-installer.mkv" "$root/media/$2/installer.mp4"
    # forty seconds in all (the author, 2026-10-29): the desktop at rest past them goes
    c clip "$work/$2-installer-cut.mkv" 0 40 "$root/media/$2/installer.mp4"
}

# The NVIDIA image's first start with Secure Boot on: the ISO installed by the installer's
# scene, played and filmed only to be thrown away; the disk unlocked with the scene's
# passphrase, and from the moment the boot screen shows its message - the box of the
# passphrase's prompt drawn in its blue, the message's white text below the spinner - the
# enrollment filmed and cut (@LandingPage#capture#cut), the restart into the blue screen
# going. Needs an ISO with the message (borshevik's issue #76): one that asks for a PIN
# instead never shows it.
cmd_mok() { # iso lang
    cmd_boot "$1" "$2" secure
    trap cmd_stop EXIT
    # the installer's scene up to its first start, which is the MOK's here
    awk '/^# the first start/ { print last + 1, "end"; exit } $1 ~ /^[0-9.]+$/ { last = $1 } { print }' \
        "$here/scenes/installer-$2.txt" >"$work/$2-mok-install.txt"
    c film "$work/$2-mok-install.txt" "$work/$2-mok-install.mkv"
    rm -f "$work/$2-mok-install.mkv" "$work/$2-mok-install.txt"
    until_seen 300 pixel_is 551 346 1b6acb
    c type cloudberry-42; c key ret
    until_seen 300 text_in 700x90+370+650
    c film "$here/scenes/mok.txt" "$work/$2-mok.mkv"
    c cut "$here/scenes/mok.txt" "$work/$2-mok.mkv" "$root/media/$2/mok.mp4"
}

# GRUB's menu as the ISO opens it, its default highlighted, cropped to the menu, its title and
# its help; in English in both languages, as GRUB has no other.
cmd_grub() { # iso
    cmd_boot "$1" grub
    trap cmd_stop EXIT
    c shot "$work/grub.png" >/dev/null
    magick "$work/grub.png" -crop 680x450+380+215 +repage -define webp:lossless=true "$root/media/en/grub.webp"
    cp "$root/media/en/grub.webp" "$root/media/ru/grub.webp"
}

case "${1:-}" in
    mok) [[ $# -eq 3 ]] || die "usage: installer.sh mok <nvidia-iso> <en|ru>"; cmd_mok "$2" "$3" ;;
    take) [[ $# -eq 3 ]] || die "usage: installer.sh take <iso> <en|ru>"; cmd_take "$2" "$3" ;;
    grub) [[ $# -eq 2 ]] || die "usage: installer.sh grub <iso>"; cmd_grub "$2" ;;
    boot) [[ $# -ge 3 ]] || die "usage: installer.sh boot <iso> <en|ru> [secure]"; cmd_boot "$2" "$3" "${4:-}" ;;
    stop) cmd_stop ;;
    *) die "usage: installer.sh take <iso> <en|ru> | mok <nvidia-iso> <en|ru> | grub <iso> | boot <iso> <en|ru> [secure] | stop" ;;
esac
