<?php
// Header links per language: the Telegram channel and X are Russian-speaking,
// GitHub is shared. Each id names its icon in icons/.
$github = ['id' => 'github', 'label' => 'GitHub', 'url' => 'https://github.com/komorebinator/borshevik'];

return [
    'en' => [
        $github,
    ],
    'ru' => [
        ['id' => 'telegram', 'label' => 'Telegram', 'url' => 'https://t.me/borsheviklinux'],
        ['id' => 'x', 'label' => 'X', 'url' => 'https://x.com/borsheviklinux'],
        $github,
    ],
];
