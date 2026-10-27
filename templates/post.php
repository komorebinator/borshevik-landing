<article class="prose post card">
    <a class="back link" href="<?= e($link('/news')) ?>">← <?= e($t['back_to_news']) ?></a>
    <time datetime="<?= e($entry['date']) ?>"><?= e($entry['date']) ?></time>
    <h1><?= e($entry['title']) ?></h1>
<?= $text ?>
</article>
