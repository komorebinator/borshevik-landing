# A system that doesn't break

## Ready for everyday work

![The app grid with the recommended apps installed](en/app-grid.webp)

On the first login, the **App Manager** offers a recommended set of apps grouped by use — work, media, development, communication and more — so you get a solid starter pack without hunting for apps one by one.

**Chrome** is already there, from **Google**'s official package, running natively on **Wayland** with smooth touchpad gestures, and common multimedia codecs are included, so video and audio work right after installation. There is also a separate image for **NVIDIA** graphics with the proprietary driver preinstalled.

## Moving from another computer

![The From another PC tab of the App Manager](en/app-manager-other-pc.webp)

The **App Manager**'s **From another PC** tab carries your setup over in one go. Copy the configuration on the old machine — with the **App Manager** if it runs **Borshevik**, or with a short script it gives you on any other **Linux** — and paste it here: the same apps and modules get installed.

Pair the two computers with **GSConnect** and they share one clipboard, so the configuration goes straight from one to the other.

## One image, safe updates

![The Image Manager: updates, rollback and automatic updates](en/image-manager.webp)

**Borshevik** is built on **Fedora Atomic** with help from the **uBlue** ecosystem and is delivered as a single, read-only system image. An update is a whole new image: it downloads in the background and takes effect at the next restart, and if something goes wrong you simply boot back into the previous version.

Updates, rollback and automatic updates are all in one window, the **Image Manager**. The image is built in the open from [its public repository](https://github.com/komorebinator/borshevik).

## Android apps

![The Android tab of the Image Manager](en/android.webp)

**Borshevik** runs **Android** apps in windows of their own, next to your desktop apps. **Android** support is optional and installed on demand, from the **Image Manager** or the **App Manager**. Apps install from **Google Play** and keep themselves up to date; **Google** asks for the device to be registered with your account once, and the **Image Manager** walks you through it.

## Games

![Steam on Borshevik](en/steam.webp)

**Steam** is preinstalled, so you can play right away, and many games work out of the box. Install **PortProton** via the **App Manager** to get any other launcher — **Battle.net**, **EA app**, **Epic Games Store** and the rest.

## VPN

![Hiddify with a connected profile](en/hiddify.webp)

**Hiddify** comes preinstalled — a desktop VPN client that supports **VLESS** + **Reality** and the other modern censorship-resistant protocols: **VLESS** over TLS, **VMess**, **Hysteria**, **TUIC**, **WireGuard** and **SSH** tunnels. Import a share link or a subscription and connect.

# GNOME, tuned

## Workspaces on the panel

![How workspaces work](en/bwm-panel.mp4)

::exclusive

Workspaces become tabs on the top panel. Each tab shows its windows' icons, so you see at a glance what is open where, and you switch with a click or with **Super+1**, **Super+2** and so on. Drag a tab to reorder workspaces, as you would tabs in a browser: its windows move along. Workspaces come and go by themselves: there is always an empty one at the end, the **+** tab, which opens it in the overview to start something there — or drag the **+** between two tabs for a new workspace right there. Close the last window on a workspace, and it goes away, taking you back to the one on its left.

## Every window in its place

![Hybrid auto-tiling at work](en/bwm-tiles.mp4)

::exclusive

Tiling and ordinary floating windows, side by side, laid out over workspaces by themselves, so no window is ever lost: to reach any of them, just move between workspaces.

- Drag a window to the left or right edge, and it takes that half.
- A maximized window, or one with no room left, gets a workspace of its own instead of covering others.
- A window that ends up hidden behind others moves out to a workspace on the left.

## Window rules

![A window rule: Calculator always on top](en/bwm-rules.mp4)

::exclusive

Some windows need a place of their own. Press **Super+R**, pick an open window and give it a rule: show it on every workspace, keep it above the others, open it at a given size and place, and so on. A rule is picked by the window's class or title, and takes effect as soon as it is saved. **Borshevik** comes with a few — **Steam** opens on its own workspace, and a picture-in-picture video stays on top in the corner of every workspace.

## Translate the selected text

![Translating a selected paragraph](en/translate.mp4)

::exclusive

Select text in any app and press **Super+T**: the translation opens under its icon on the panel — no copying, no browser, no separate app. The languages are taken from your keyboard layouts, so there is nothing to set up.

## App search in any keyboard layout

![Terminal found though typed in the wrong layout](en/app-search.mp4)

::exclusive

App search finds an app even when its name was typed in the wrong keyboard layout.

## Useful extensions out of the box

![The extensions Borshevik ships, listed in Extension Manager](en/extensions.webp)

The desktop is the **GNOME** of **Fedora** with a small set of proven extensions, already set up:

- clipboard history and an emoji picker;
- **GSConnect** — your phone's notifications, files and a shared clipboard;
- a colour picker for anywhere on the screen;
- the weather next to the clock, and battery time left;
- the battery of **Bluetooth** headphones and other devices;
- **Caffeine**, to keep the screen from turning off.
