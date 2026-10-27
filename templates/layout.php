<?php $other = $lang === 'ru' ? 'en' : 'ru'; ?>
<!doctype html>
<html lang="<?= e($lang) ?>">

<head>
    <meta charset="utf-8">
    <title><?= $title !== '' ? e($title) . ' — ' : '' ?>Borshevik Linux</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="<?= e($preview['description']) ?>">
    <?php
    // the link preview: absolute addresses, and the page's language named in its address, since
    // a preview's fetcher sends no language of its own and would get the English page
    $origin = site_origin();
    $full_title = ($title !== '' ? $title . ' — ' : '') . 'Borshevik Linux';
    ?>
    <meta property="og:site_name" content="Borshevik Linux">
    <meta property="og:type" content="<?= e($preview['type']) ?>">
    <meta property="og:title" content="<?= e($full_title) ?>">
    <meta property="og:description" content="<?= e($preview['description']) ?>">
    <meta property="og:url" content="<?= e($origin . url($path === '' ? '/' : $path, $lang)) ?>">
    <meta property="og:image" content="<?= e($origin . $preview['image']) ?>">
    <meta property="og:locale" content="<?= $lang === 'ru' ? 'ru_RU' : 'en_US' ?>">
    <meta name="twitter:card" content="summary_large_image">
    <link rel="icon" type="image/svg+xml" href="/borshevik_logo.svg">
    <link rel="stylesheet" href="/style.css">
</head>

<body>
<?php require __DIR__ . '/backdrop.php'; ?>
    <header class="site-header">
        <div class="site-header-inner">
            <a class="brand" href="<?= e($link('/')) ?>">
                <span class="logo-glow"><img src="/borshevik_logo.svg" alt="" width="32" height="32"></span>
                <span>Borshevik</span>
            </a>
            <nav class="menu" aria-label="<?= e($t['menu_label']) ?>">
                <?php foreach (['home' => '/', 'news' => '/news', 'install' => '/install'] as $id => $href): ?>
                    <a href="<?= e($link($href)) ?>"<?= $id === 'install' ? ' class="menu-install"' : '' ?><?= $section === $id ? ' aria-current="page"' : '' ?>><?= e($t['nav_' . $id]) ?></a>
                <?php endforeach; ?>
            </nav>
            <div class="header-end">
                <?php foreach ($header_links as $l): ?>
                    <a class="icon-link" href="<?= e($l['url']) ?>" target="_blank" rel="noopener noreferrer" title="<?= e($l['label']) ?>" aria-label="<?= e($l['label']) ?>">
                        <?= file_get_contents(__DIR__ . '/../icons/' . $l['id'] . '.svg') ?>
                    </a>
                <?php endforeach; ?>
                <a class="lang-switch" href="<?= e(url($path === '' ? '/' : $path, $other)) ?>" lang="<?= e($other) ?>" hreflang="<?= e($other) ?>"><?= e($t['other_language']) ?></a>
            </div>
        </div>
    </header>

    <main class="site-main site-main-<?= e($section) ?>">
<?= $body ?>
    </main>
<?php if (str_contains($body, 'data-play-in-view')): ?>

    <script>
        // A walk-through video: the browser's controls swapped for the site's own - a play
        // button, a bar to scrub, the time - and the video started once half of it is
        // scrolled into view and paused when it leaves; once its viewer has paused it, or it
        // has ended, starting it is theirs.
        const words = document.documentElement.lang === 'ru'
            ? { play: 'Воспроизвести', pause: 'Пауза', seek: 'Перемотка' }
            : { play: 'Play', pause: 'Pause', seek: 'Seek' };
        const clock = s => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;
        document.querySelectorAll('video[data-play-in-view]').forEach(video => {
            video.controls = false;
            const bar = document.createElement('div');
            bar.className = 'player-bar';
            bar.innerHTML = '<button type="button" class="player-toggle">'
                + '<svg class="icon-play" viewBox="0 0 16 16" aria-hidden="true"><path d="M4 2.5v11l9.5-5.5z"/></svg>'
                + '<svg class="icon-pause" viewBox="0 0 16 16" aria-hidden="true"><path d="M3.5 2.5h3v11h-3zM9.5 2.5h3v11h-3z"/></svg>'
                + '</button><input type="range" class="player-seek" min="0" max="1000" step="1" value="0">'
                + '<span class="player-time"></span>';
            video.after(bar);
            const toggle = bar.querySelector('.player-toggle');
            const seek = bar.querySelector('.player-seek');
            const time = bar.querySelector('.player-time');
            seek.setAttribute('aria-label', words.seek);
            const show = () => {
                const length = video.duration || 0;
                toggle.classList.toggle('playing', !video.paused);
                toggle.setAttribute('aria-label', video.paused ? words.play : words.pause);
                seek.value = length ? video.currentTime / length * 1000 : 0;
                seek.style.setProperty('--played', `${seek.value / 10}%`);
                time.textContent = `${clock(video.currentTime)} / ${clock(length)}`;
            };
            // the bar moves every frame while playing, not only on the browser's few time updates
            const tick = () => { show(); if (!video.paused) requestAnimationFrame(tick); };
            ['loadedmetadata', 'pause', 'ended', 'seeked'].forEach(e => video.addEventListener(e, show));
            video.addEventListener('play', () => requestAnimationFrame(tick));
            toggle.addEventListener('click', () => { if (video.paused) video.play(); else video.pause(); });
            video.addEventListener('click', () => toggle.click());
            seek.addEventListener('input', () => {
                if (video.duration) video.currentTime = seek.value / 1000 * video.duration;
                show();
            });
            show();

            let page = true, pausing = false;
            video.addEventListener('pause', () => { if (!pausing) page = false; pausing = false; });
            video.addEventListener('ended', () => { page = false; });
            new IntersectionObserver(([entry]) => {
                if (!page) return;
                if (entry.isIntersecting) video.play().catch(() => {});
                else if (!video.paused) { pausing = true; video.pause(); }
            }, { threshold: 0.5 }).observe(video);
        });
    </script>
<?php endif; ?>

</body>

</html>
