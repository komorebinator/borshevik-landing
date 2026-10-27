<section class="hero">
    <div class="logo-circle">
        <img src="/borshevik_logo.svg" alt="<?= e($t['logo_alt']) ?>">
    </div>
    <h1>Borshevik</h1>
    <p class="slogan"><?= e($t['slogan']) ?></p>
</section>

<section class="hero-row card">
    <figure class="hero-shot">
        <img src="/media/<?= e($lang) ?>/hero.webp" alt="<?= e($t['hero_screenshot_alt']) ?>" width="1600" height="1000">
    </figure>
    <div class="tagline">
        <h2><?= e($t['tagline_title']) ?></h2>
        <?php foreach (preg_split('~\n\s*\n~', $t['tagline']) as $para): ?>
            <p><?= e(trim($para)) ?></p>
        <?php endforeach; ?>
    </div>
</section>

<div class="features">
    <?php foreach ($sections as $part): ?>
        <?php if ($part['type'] === 'group'): ?>
            <h2 class="group-title"><?= e($part['title']) ?></h2>
        <?php else: ?>
            <section class="feature card<?= $part['media'] === '' ? ' feature-text-only' : '' ?>">
                <?php if ($part['media'] !== ''): ?>
                    <div class="feature-media prose"><?= $part['media'] ?></div>
                <?php endif; ?>
                <div class="feature-text prose">
                    <?php if ($part['exclusive']): ?>
                        <span class="badge"><?= e($t['exclusive']) ?></span>
                    <?php endif; ?>
                    <?php if ($part['heading'] !== ''): ?>
                        <h3><?= $part['heading'] ?></h3>
                    <?php endif; ?>
                    <?= $part['body'] ?>
                </div>
            </section>
        <?php endif; ?>
    <?php endforeach; ?>
</div>
