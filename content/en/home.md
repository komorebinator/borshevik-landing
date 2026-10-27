# A system that doesn't break

## One image, safe updates

![The Image Manager: updates, rollback and automatic updates](en/image-manager.webp)

Borshevik is built on [Fedora Atomic](https://fedoraproject.org/atomic-desktops/) with help from the [uBlue](https://universal-blue.org/) ecosystem and is delivered as a single, read-only system image. An update is a whole new image: it downloads in the background and takes effect at the next restart, and if something goes wrong you simply boot back into the previous version.

Updates, rollback and automatic updates are all in one window, the **Image Manager**. The image is built in the open from [its public repository](https://github.com/komorebinator/borshevik), with no telemetry beyond Fedora's and no online accounts required.

## Ready for everyday work

![The app grid of a fresh Borshevik install](en/app-grid.webp)

On the first login, the **App Manager** offers a recommended set of apps grouped by use — work, media, development, communication and more — so you get a solid starter pack without hunting for apps one by one.

Chrome is already there, from Google's official package, running natively on Wayland with smooth touchpad gestures, and common multimedia codecs are included, so video and audio work right after installation. There is also a separate image for NVIDIA graphics with the proprietary driver preinstalled.

## Moving from another computer

![The From another PC tab of the App Manager](en/app-manager-other-pc.webp)

The App Manager's **From another PC** tab carries your setup over in one go. Copy the configuration on the old machine — with the App Manager if it runs Borshevik, or with a short script it gives you on any other Linux — and paste it here: the same apps and modules get installed.

Pair the two computers with GSConnect and they share one clipboard, so the configuration goes straight from one to the other.

## Android apps

![The Android tab of the Image Manager](en/android.webp)

Borshevik runs Android apps in windows of their own, next to your desktop apps. Android support is optional and installed on demand, from the Image Manager or the App Manager. Apps install from Google Play and keep themselves up to date; Google asks for the device to be registered with your account once, and the Image Manager walks you through it.

## Games

![Steam on Borshevik](en/steam.webp)

Steam is preinstalled, so you can play right away. Many games work out of the box, and other game stores are available to install.

## VPN

![Hiddify with a connected profile](en/hiddify.webp)

[Hiddify](https://github.com/hiddify/hiddify-app) comes preinstalled — a desktop VPN client that supports VLESS + Reality and the other modern censorship-resistant protocols: VLESS over TLS, VMess, Hysteria, TUIC, WireGuard and SSH tunnels. Import a share link or a subscription and connect.

# GNOME, tuned

## Workspaces on the panel

![The workspace buttons on the top panel clicked one by one; the first workspace dragged past Chrome's, becoming the third; the empty workspace at the end clicked opens the overview, and Secrets started from it takes that workspace while a new empty one appears on the panel; back on the moved workspace, it is dragged to the front again](en/bwm-panel.mp4)

::exclusive

Instead of the Activities button, the top panel has a button for every workspace showing its windows' icons: you see at a glance what is open where, and switch with one click — or with **Super+1**, **Super+2** and so on, by the workspace's number. Drag a button to put its workspace elsewhere in the row: its windows move along with it. Click the empty workspace at the end of the row, and the overview opens to start something there.

## Every window in its place

![Files and Terminal open floating; Chrome, maximized, gets a workspace of its own, and Hiddify floats over it; once behind Chrome, Hiddify moves onto the floating workspace, and once Files and Terminal take its halves, further left; the PDF opens maximized on a workspace of its own and, dragged out by its title bar, takes Terminal's half, sending Terminal to a workspace of its own, and Terminal comes back when the PDF closes; Chrome dragged into the free half goes to a workspace of its own when maximized and back to its half when restored](en/bwm-tiles.mp4)

::exclusive

**Borshevik Workspace Manager** is our own extension, replacing how GNOME's workspaces behave: it puts every window where it belongs, by itself.

- Every workspace has two halves, left and right. A window shaped like a half takes one as it opens; drag any window to an edge — or press Super+← / Super+→ — and it takes that half.
- When both halves are taken, a new window goes to the next workspace instead of piling up on top.
- A maximized window gets a workspace of its own, and goes back to its place when you restore it — or simply drag it out by its title bar.
- Drop a window on a half that is taken, and the window that was there makes room on a workspace next door; it comes back as soon as its half is free.
- Unlike on a Mac, a maximized window does not lock its workspace: another window can float over it. And a window that ends up hidden behind it is not lost: it moves to a workspace of its own.

## Window rules

![The editor dragged over Calculator covers it; Super+R, and a new rule for Calculator from the Windows tab: Always on top. Once saved, Calculator comes to the front at once, and the editor dragged over it again stays beneath it, then goes back to its place](en/bwm-rules.mp4)

::exclusive

Some windows need a place of their own. Press **Super+R**, pick an open window and give it a rule: show it on every workspace, keep it above the others, open it at a given size and place, or on a workspace of its own. A rule is picked by the window's class or title, and takes effect as soon as it is saved. Borshevik comes with a few — Steam opens on its own workspace, and a picture-in-picture video stays on top in the corner of every workspace.

## Translate the selected text

![Selecting a paragraph of a Russian PDF and pressing Super+T opens its English translation under the panel icon](en/translate.mp4)

::exclusive

Select text in any app and press **Super+T**: the translation opens under its icon on the panel — no copying, no browser, no separate app. Your languages default to those of your keyboard layouts, so with English and Russian layouts, English text is translated into Russian and Russian into English.

## App search in any keyboard layout

![Typing “terminal” with the Russian layout on, which reads “еуктштфд”, still finds Terminal, and Enter starts it](en/app-search.mp4)

::exclusive

Forgot to switch the layout? No matter: app search reads what you typed in all of your keyboard layouts at once, so a name typed in the wrong one still finds the app.

## Useful extensions out of the box

![The extensions Borshevik ships, listed in Extension Manager](en/extensions.webp)

The desktop is the GNOME of Fedora with a small set of proven extensions, already set up:

- clipboard history and an emoji picker;
- GSConnect — your phone's notifications, files and a shared clipboard;
- a colour picker for anywhere on the screen;
- the weather next to the clock, and battery time left;
- the battery of Bluetooth headphones and other devices;
- Caffeine, to keep the screen from turning off;
- tray icons for background apps, and a soft blur on the panel and overview.
