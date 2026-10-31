# Switching from Fedora Atomic or uBlue

Already running **Fedora Silverblue**, **Kinoite** or another **Fedora Atomic** desktop, or a **uBlue** image such as **Bluefin**, **Aurora** or **Bazzite**? Then there is nothing to reinstall: two commands switch the system to **Borshevik**. Your files and settings in your home folder stay where they are.

It takes two steps because your system does not yet know the key **Borshevik** is signed with: the key comes with the image itself. So you first switch to the image without checking its signature, and then, from **Borshevik**, to the signed one.

## 1. Switch to the Borshevik image

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/komorebinator/borshevik:stable
```

For **NVIDIA** graphics:

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/komorebinator/borshevik-nvidia:stable
```

When it finishes, restart:

```
systemctl reboot
```

On **Borshevik**'s first start the computer may restart once by itself to apply its settings, and the **NVIDIA** image with **Secure Boot** on asks you to confirm the driver's key — just as [on a fresh installation](/install). On your first login the **App Manager** opens with its selection of apps.

## 2. Switch to the signed image

Now on **Borshevik**:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/komorebinator/borshevik:stable
```

For **NVIDIA** graphics:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/komorebinator/borshevik-nvidia:stable
```

And restart again:

```
systemctl reboot
```

That's it: updates and rollback are in the **Image Manager**.

## 3. If Borshevik is not for you

You can go back with the same `rpm-ostree rebase`.

To **Fedora Silverblue** — as it is after installing from the ISO, with every update's signature checked. First add **Fedora**'s repository, then switch to it:

```
sudo ostree remote add --set=gpgkeypath=/etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-44-primary --set=contenturl=mirrorlist=https://ostree.fedoraproject.org/mirrorlist fedora https://ostree.fedoraproject.org
```

```
sudo rpm-ostree rebase fedora:fedora/44/x86_64/silverblue
```

For **Kinoite**, `kinoite` instead of `silverblue`. 44 is the **Fedora** version: if a newer one is out, put it in both commands.

To a **uBlue** image, such as **Bluefin**:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bluefin:stable
```

For **Aurora** or **Bazzite**, `aurora` or `bazzite` instead of `bluefin`, and for **NVIDIA** graphics, with `-nvidia-open` at the end, such as `bluefin-nvidia-open`. Were you on another variant, such as `bazzite-gnome`? Put its name in. Then restart:

```
systemctl reboot
```

Your files and settings in your home folder stay where they are: **Borshevik** changes only the defaults and leaves your own settings alone. The kernel arguments **Borshevik** set may stay (`preempt=full`, and on the **NVIDIA** image also `nvidia-drm.modeset=1`, `modprobe.blacklist=nouveau`, `modprobe.blacklist=nova_core` and `rd.driver.blacklist=nova_core`).

Leaving **Borshevik** does not remove **Android**: its apps and data stay on the disk, but they only run on a system with **Waydroid** installed.
