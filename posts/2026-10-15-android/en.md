# Android apps on Borshevik

Borshevik now runs Android apps — in windows of their own, next to your desktop apps. Apps install from Google Play and keep themselves up to date, and notifications, Google sign-in and everything else that relies on Google's services work.

## How to turn it on

Android is not part of the default setup; you install it when you want it:

- on the first login, by checking **Android applications support** in the App Manager;
- at any time, on the **Android** tab of the Image Manager, with **Install Android**.

It downloads about 1.4 GB: Android with Google Play and Google's services, and support for apps built only for ARM.

![The Android tab of the Image Manager before installing](install-android.en.webp)

## Registering with Google Play

Google asks for the device to be registered with your account once. The Android tab shows the device ID and opens the registration page: paste the ID there, restart Android and sign in to Google Play.

![Google Play registration on the Android tab](android-tab.en.webp)

## Installing APKs

An APK downloaded from somewhere other than Google Play installs with a double click: the installer shows the package and its version and asks whether to install or update it. If Android is off or asleep, the installer starts it and waits for it to boot, and at the end shows the app's icon and an Open button.

![The APK installer asking whether to install F-Droid into Android](apk-install.en.webp)

## Feels like part of the system

Android follows GNOME's dark style and accent colour:

![Android changing its theme along with GNOME](android-theme.en.mp4)

Android updates separately from the system, once a day and never over a metered connection, and rolling Borshevik back brings back the earlier Android too. On NVIDIA graphics, Android draws in software and runs slower.
