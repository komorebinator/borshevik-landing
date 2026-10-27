# Installing Borshevik

Installing asks very few questions. You need a USB drive of at least 8 GB and the computer you are installing on.

## 1. Download the image

Take the **NVIDIA** image if your computer has an NVIDIA graphics card, and the standard one otherwise — for AMD and Intel graphics.

::downloads

## 2. Write it to a USB drive

Install Fedora Media Writer:

::media-writer

Open it, choose **Select .iso file**, pick the image you downloaded and the USB drive, and write. Everything on the USB drive is erased.

::video en/media-writer.mp4 Fedora Media Writer writing the Borshevik image to a USB drive

## 3. Boot from the USB drive

Plug the drive into the computer, turn it on and open the boot menu — usually with F12, F11, F8 or Esc right after power-on, depending on the manufacturer — and choose the USB drive. Secure Boot can stay on.

## 4. Install

The installer asks only for what it cannot guess. The whole way through it:

::video en/installer.mp4 Installing Borshevik: the disk, encryption and the user

What to know on the way:

- **The whole disk is erased.** Make sure nothing you need is left on it.
- **Encryption — we recommend turning it on.** Check **Encrypt my data** and set a passphrase: it is asked for every time the computer starts. A laptop is easily lost or left unattended, and an encrypted disk cannot be read without the passphrase. Encryption can only be turned on while installing — later it takes a reinstall. Type the passphrase in the keyboard layout the installer shows next to it: at start-up only that one is available.
- **Leave the administrator box checked** when you create your user — it is checked already.

When it finishes, restart the computer and remove the USB drive.

## 5. The first start

**NVIDIA image with Secure Boot on.** On the first start, the boot screen says the NVIDIA driver's key must be confirmed, and in 10 seconds the computer restarts into a blue screen (**R** restarts right away, **S** puts it off until the next start). There, with the arrow keys and Enter — the mouse does not work on it — choose **Enroll MOK**, then **Continue**, **Yes**, type the password **borshevik** and choose **Reboot**. This lets the NVIDIA driver load under Secure Boot, and happens only once.

::video en/mok.mp4 Confirming the NVIDIA driver's key on the blue MOK Manager screen

On the first start the computer may restart once by itself to apply its settings. That is expected.

**The App Manager.** It opens by itself on your first login: check the categories of apps you want, turn on Android support if you like, and press **Install**.

![The App Manager on the first login](en/app-manager.webp)

Moving from another computer? Open the **From another PC** tab and paste the configuration you copied there: the same apps get installed.

![The From another PC tab of the App Manager](en/app-manager-other-pc.webp)

That's it. From here on, the **Image Manager** is where you update the system, turn on automatic updates and roll back.
