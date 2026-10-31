<section class="downloads" aria-label="<?= e($t['downloads_label']) ?>">
    <?php foreach (['standard', 'nvidia'] as $variant): $iso = $isos[$variant]; ?>
        <div class="download-block">
            <a class="download-button" href="/iso/<?= e(rawurlencode($iso['file'])) ?>">
                <span class="download-content">
                    <span class="download-title"><?= e($t['download_' . $variant]) ?><?= $iso['size'] !== '' ? ' · ' . e($iso['size']) : '' ?></span>
                    <span class="download-subtitle"><?= e($t['subtitle_' . $variant]) ?></span>
                </span>
            </a>
            <?php if ($iso['checksum'] !== ''): ?>
                <div class="checksum">
                    <span class="checksum-label">Checksum:</span>
                    <code><?= e($iso['checksum']) ?></code>
                </div>
            <?php endif; ?>
        </div>
    <?php endforeach; ?>
</section>

