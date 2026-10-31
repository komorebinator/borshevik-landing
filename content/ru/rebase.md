# Переход с Fedora Atomic или uBlue

У вас уже стоит **Fedora Silverblue**, **Kinoite** или другая **Fedora Atomic** — или образ **uBlue**, например **Bluefin**, **Aurora** или **Bazzite**? Тогда переустанавливать систему не нужно: перейти на **Borshevik** можно двумя командами. Файлы и настройки в домашней папке останутся на месте.

Шагов два, потому что ваша система пока не знает ключа, которым подписан **Borshevik**, — он приходит вместе с самим образом. Поэтому сначала вы переходите на образ без проверки подписи, а уже из **Borshevik** — на подписанный.

## 1. Перейдите на образ Borshevik

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/komorebinator/borshevik:stable
```

Для видеокарт **NVIDIA**:

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/komorebinator/borshevik-nvidia:stable
```

Когда команда закончит, перезагрузитесь:

```
systemctl reboot
```

При первом запуске **Borshevik** компьютер может один раз перезагрузиться сам, чтобы применить настройки, а на образе **NVIDIA** с включённым **Secure Boot** попросит подтвердить ключ драйвера — так же, как [при новой установке](/install). При первом входе откроется **App Manager** с подборкой приложений.

## 2. Перейдите на подписанный образ

Уже в **Borshevik**:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/komorebinator/borshevik:stable
```

Для видеокарт **NVIDIA**:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/komorebinator/borshevik-nvidia:stable
```

И снова перезагрузитесь:

```
systemctl reboot
```

Готово: обновления и откат — в **Image Manager**.

## 3. Если Borshevik не подошёл

Вернуться можно той же командой `rpm-ostree rebase`.

На **Fedora Silverblue** — в том виде, в каком она ставится с ISO, с проверкой подписи каждого обновления. Сначала добавьте репозиторий **Fedora**, затем перейдите на него:

```
sudo ostree remote add --set=gpgkeypath=/etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-44-primary --set=contenturl=mirrorlist=https://ostree.fedoraproject.org/mirrorlist fedora https://ostree.fedoraproject.org
```

```
sudo rpm-ostree rebase fedora:fedora/44/x86_64/silverblue
```

Для **Kinoite** — `kinoite` вместо `silverblue`. 44 — номер версии **Fedora**: если вышла новее, подставьте её в обе команды.

На образ **uBlue**, например **Bluefin**:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bluefin:stable
```

Для **Aurora** и **Bazzite** — `aurora` или `bazzite` вместо `bluefin`, а для видеокарт **NVIDIA** — с `-nvidia-open` в конце, например `bluefin-nvidia-open`. Были на другом варианте, например `bazzite-gnome`, — подставьте его имя. Затем перезагрузитесь:

```
systemctl reboot
```

Файлы и настройки в домашней папке останутся на месте: **Borshevik** меняет только настройки по умолчанию, а ваши не трогает. Могут остаться параметры ядра, которые выставил **Borshevik** (`preempt=full`, а на образе **NVIDIA** ещё `nvidia-drm.modeset=1`, `modprobe.blacklist=nouveau`, `modprobe.blacklist=nova_core` и `rd.driver.blacklist=nova_core`).

Переход с **Borshevik** не удаляет **Android**: его приложения и данные остаются на диске, но запустить их можно только в системе, где установлен **Waydroid**.
