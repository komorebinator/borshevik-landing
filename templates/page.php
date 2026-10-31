<article class="prose card">
    <?php if ($tabs): ?>
        <nav class="tabs" aria-label="<?= e($title) ?>">
            <?php foreach ($tabs as $tab): ?>
                <a href="<?= e($tab['href']) ?>"<?= $tab['current'] ? ' aria-current="page"' : '' ?>><?= e($tab['label']) ?></a>
            <?php endforeach; ?>
        </nav>
    <?php endif; ?>
    <h1><?= e($title) ?></h1>
<?= $text ?>
</article>
