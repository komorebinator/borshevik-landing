# Switching from Fedora Atomic or uBlue

Already running Fedora Silverblue, Kinoite or another Fedora Atomic desktop, or a uBlue image such as Bluefin, Aurora or Bazzite? Then there is nothing to reinstall: two commands switch the system to Borshevik. Your files and settings in your home folder stay where they are.

It takes two steps because your system does not yet know the key Borshevik is signed with: the key comes with the image itself. So you first switch to the image without checking its signature, and then, from Borshevik, to the signed one — from then on every update is checked.

## 1. Switch to the Borshevik image

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/komorebinator/borshevik:stable
```

For NVIDIA graphics:

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/komorebinator/borshevik-nvidia:stable
```

When it finishes, restart:

```
systemctl reboot
```

On Borshevik's first start the computer may restart once by itself to apply its settings, and the NVIDIA image with Secure Boot on asks you to confirm the driver's key — just as [on a fresh installation](/install).

## 2. Switch to the signed image

Now on Borshevik:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/komorebinator/borshevik:stable
```

For NVIDIA graphics:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/komorebinator/borshevik-nvidia:stable
```

And restart again:

```
systemctl reboot
```

That's it. On your next login the **App Manager** opens with its selection of apps, and updates and rollback are in the **Image Manager**. Your previous system stays in the boot menu until updates push it out: if something is not to your liking, `rpm-ostree rollback` takes you back.
