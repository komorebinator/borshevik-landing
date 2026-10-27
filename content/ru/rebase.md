# Переход с Fedora Atomic или uBlue

Уже стоит Fedora Silverblue, Kinoite или другая Fedora Atomic, либо образ uBlue — Bluefin, Aurora, Bazzite? Тогда переустанавливать ничего не нужно: систему можно перевести на Borshevik двумя командами. Ваши файлы и настройки в домашней папке останутся на месте.

Переход идёт в два шага, потому что ваша система ещё не знает ключа, которым подписан Borshevik: он приходит вместе с самим образом. Поэтому сначала переходим на образ без проверки подписи, а уже из Borshevik — на подписанный, и с этого момента каждое обновление проверяется.

## 1. Перейдите на образ Borshevik

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/komorebinator/borshevik:stable
```

Для видеокарт NVIDIA:

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/komorebinator/borshevik-nvidia:stable
```

Когда команда закончит, перезагрузитесь:

```
systemctl reboot
```

При первом запуске Borshevik компьютер может один раз перезагрузиться сам, чтобы применить настройки, а на образе NVIDIA с включённым Secure Boot попросит подтвердить ключ драйвера — так же, как [при новой установке](/install).

## 2. Перейдите на подписанный образ

Уже в Borshevik:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/komorebinator/borshevik:stable
```

Для видеокарт NVIDIA:

```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/komorebinator/borshevik-nvidia:stable
```

И снова перезагрузитесь:

```
systemctl reboot
```

Готово. При следующем входе откроется **App Manager** с подборкой приложений, а обновления и откат — в **Image Manager**. Прежняя система остаётся в меню загрузки, пока её не вытеснят обновления: если что-то не понравится, можно вернуться командой `rpm-ostree rollback`.
