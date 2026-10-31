<section class="prose">
    <h1><?= e($t['news_title']) ?></h1>
    <?php if (!$items): ?>
        <p><?= e($t['news_empty']) ?></p>
    <?php endif; ?>
    <?php foreach ($items as $item): $href = $link('/news/' . $item['slug']); ?>
        <article class="news-item card<?= $item['image'] !== '' ? ' news-item-with-image' : '' ?>">
            <?php if ($item['image'] !== ''): ?>
                <div class="news-thumb">
                    <img src="<?= e($item['image']) ?>" alt="" loading="lazy">
                </div>
            <?php endif; ?>
            <div class="news-text">
                <time datetime="<?= e($item['date']) ?>"><?= e($item['date']) ?></time>
                <h2><a class="news-link" href="<?= e($href) ?>"><?= e($item['title']) ?></a></h2>
                <p><?= e($item['excerpt']) ?></p>
            </div>
        </article>
    <?php endforeach; ?>
</section>
