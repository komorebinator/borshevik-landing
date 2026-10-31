<?php
// The page's background, after the logo: gears like its own held up on stems, as hogweed
// holds its umbels — a meadow of such plants along the
// bottom edge, each different, near and large at the window's sides, far, small and out of
// focus towards its middle — and small gears drifting in the air above them like seeds. The
// gears turn slowly and the seeds rise and sink a little; the stems stand still; the logo's
// colours drift beneath it all as a soft glow the outlines take up. Laid out by a generator
// with a fixed seed, so the page looks the same at every visit. Each gear is a layer of its
// own that the browser turns and moves without redrawing the page, and nothing needs a
// script. See @LandingPage#layout#backdrop.

// The outline of a gear in the logo's style, centred on 0,0: near-square teeth a little
// narrower at the tip, as wide as the gaps between them, around a body with a wide hole.
$gear_path = function (float $r, int $teeth): string {
    $depth = $r * 0.16;
    $step = 2 * M_PI / $teeth;
    $points = [];
    for ($i = 0; $i < $teeth; $i++) {
        $a = $i * $step;
        foreach ([[-0.27, $r - $depth], [-0.19, $r], [0.19, $r], [0.27, $r - $depth]] as [$f, $rad]) {
            $points[] = sprintf('%.1f %.1f', $rad * cos($a + $f * $step), $rad * sin($a + $f * $step));
        }
    }
    $hole = $r * 0.5;
    return 'M' . implode(' L', $points) . ' Z'
        . sprintf(' M%.1f 0 A%.1f %.1f 0 1 0 %.1f 0 A%.1f %.1f 0 1 0 %.1f 0 Z', $hole, $hole, $hole, -$hole, $hole, $hole, $hole);
};
// broad teeth whatever the size, as the logo's: 8 to 14
$teeth_for = fn(float $r) => max(8, min(14, (int) round(6 + $r / 9)));

// One turning gear centred on left, top (CSS lengths), wrapped so that it can also drift.
$gear = function (string $left, string $top, float $r, float $period, int $dir, string $drift = '') use ($gear_path, $teeth_for): string {
    $size = ceil($r * 2 + 4);
    return sprintf('<div class="backdrop-gear" style="left: %s; top: %s; width: %dpx; height: %dpx%s">'
        . '<svg viewBox="%s %s %d %d" focusable="false" style="animation-duration: %ss%s"><path d="%s" fill-rule="evenodd" /></svg></div>',
        $left, $top, $size, $size, $drift, -$size / 2, -$size / 2, $size, $size,
        $period, $dir < 0 ? '; animation-direction: reverse' : '', $gear_path($r, $teeth_for($r)));
};
// the logo's colours
$tints = ['#8dd3c7', '#80b1d3', '#bebada', '#bc80bd', '#e2b8ce'];
$rand = fn(float $from, float $to) => $from + ($to - $from) * mt_rand() / mt_getrandmax();

// The stems' randomness is a hash of where they are, not the generator's, so changing them
// leaves the layout of everything else as it was.
$hash = fn(string $key, float $from, float $to) => $from + ($to - $from) * (crc32($key) % 10007) / 10007;
// A hogweed as it grows: a main stem rising, a little bent, to its highest gear, and
// straight rays leaving it at heights of their own for its other gears — only the stem bends
// (the author, 2026-10-22).
$plant = function (array $heads, string $key, array $extra = []) use ($hash): array {
    usort($heads, fn($p, $q) => $p[1] <=> $q[1]);         // the highest first
    [$tx, $ty, $tr] = $heads[0];
    $root = [$tx + $hash("$key root", -60, 60), 0];
    $top = [$tx, $ty + $tr + 3];
    $bend = $hash("$key bend", -0.08, 0.08) * $ty;
    $trunk_at = fn(float $y) => $root[0] + ($top[0] - $root[0]) * ($y / $top[1]) + $bend * sin(M_PI * $y / $top[1]);
    $paths = [[sprintf('M%d %d C%d %d %d %d %d %d', $root[0], 0, $root[0] + $bend, $top[1] * 0.35,
        $top[0] + $bend, $top[1] * 0.7, $top[0], $top[1]), 1.3 + 0.3 * count($heads)]];
    foreach (array_slice($heads, 1) as $i => [$x, $y, $r]) {
        // where it leaves the stem: some way below its gear, never above the stem's top; and
        // from there a straight ray to its gear's rim, as an umbel's rays are
        $ay = min(($y + $r) * $hash("$key $i at", 0.35, 0.7), $top[1] * 0.4);
        $ax = $trunk_at($ay);
        $len = hypot($x - $ax, $y - $ay);
        $paths[] = [sprintf('M%d %d L%d %d', $ax, $ay, $x - ($x - $ax) * ($r + 3) / $len, $y - ($y - $ay) * ($r + 3) / $len), 1.3];
    }
    // gears added to a plant afterwards, below its highest: rays of their own, keyed apart,
    // so the stem and the rays already there stay as they were
    foreach ($extra as $j => [$x, $y, $r]) {
        $ay = min(($y + $r) * $hash("$key extra $j at", 0.65, 0.85), $top[1] * 0.4);
        $ax = $trunk_at($ay);
        $len = hypot($x - $ax, $y - $ay);
        $paths[] = [sprintf('M%d %d L%d %d', $ax, $ay, $x - ($x - $ax) * ($r + 3) / $len, $y - ($y - $ay) * ($r + 3) / $len), 1.3];
    }
    return $paths;
};

mt_srand(2026102201);

// One group of gears on a plant: rays from a node at $height above the root, leaning a
// little, three to five gears spread over them without touching.
$grow = function (string $depth, float $scale, float $height_from, float $height_to, float $lean_by) use ($rand): array {
    $lean = deg2rad($rand(-18, 18) + $lean_by);
    $height = $rand($height_from, $height_to) * $scale;
    $node = [$height * sin($lean), -$height * cos($lean)];
    $n = mt_rand(3, 5);
    $spread = $rand(80, 130);
    $heads = [];
    for ($tries = 0; count($heads) < $n && $tries < 300; $tries++) {
        $i = count($heads);
        $angle = deg2rad(-90 + rad2deg($lean) - $spread / 2 + $spread * $i / max(1, $n - 1) + $rand(-8, 8));
        $length = $rand(120, 250) * $scale;
        $r = $rand(28, 82) * $scale;
        $x = $node[0] + $length * cos($angle);
        $y = $node[1] + $length * sin($angle);
        foreach ($heads as $h) {
            if (hypot($h[0] - $x, $h[1] - $y) < $h[2] + $r + 14 * $scale) continue 2;
        }
        $heads[] = [$x, $y, $r, $angle, $rand(60, 180), mt_rand(0, 1) ? 1 : -1];
    }
    return $heads;
};
$scales = ['near' => 1, 'mid' => 0.72, 'far' => 0.48];

// The meadow along the bottom edge: seven groups spread across it, near and large at the
// window's sides. The three in the middle are replaced below; they are still grown here, so
// that everything after them comes out of the generator as it did.
$bouquets = [];
$count = 7;
for ($k = 0; $k < $count; $k++) {
    $left = ($k + 0.5) / $count * 100 + $rand(-4, 4);
    $edge = abs($left - 50) / 50;                     // 0 in the middle, 1 at a side
    $depth = $edge > 0.75 ? 'near' : ($edge > 0.4 ? 'mid' : 'far');
    $heads = $grow($depth, $scales[$depth], 250, 420, $left < 50 ? -6 : 6);
    $bouquets[] = [$left, $rand(0, 40), $depth, $heads];
}

// Seeds in the air: small gears anywhere above the meadow, most of them far and hazy.
$seeds = ['near' => [], 'far' => [], 'haze' => []];
for ($k = 0; $k < 26; $k++) {
    $layer = $k < 4 ? 'near' : ($k < 12 ? 'far' : 'haze');
    $r = $layer === 'near' ? $rand(34, 64) : ($layer === 'far' ? $rand(14, 34) : $rand(6, 16));
    $seeds[$layer][] = [round($rand(2, 98), 1), round($rand(4, 70), 1), $r, $rand(40, 120), mt_rand(0, 1) ? 1 : -1,
        round($rand(-28, -10)), round($rand(10, 22), 1), round($rand(0, 20), 1)];
}

// The middle of the meadow, grown apart so the seeds above stay where they were: four groups
// of every depth, small among large, rather than the sides large and the middle small; one
// of them tall, its highest gears beside the logo (the author, 2026-10-22).
mt_srand(2026102202);
$middle = [];
foreach ([[31, 'mid', 250, 420], [41, 'mid', 900, 980], [53, 'near', 200, 300], [66, 'mid', 560, 660]] as [$left, $depth, $from, $to]) {
    $left += $rand(-2, 2);
    $middle[] = [$left, $rand(0, 40), $depth, $grow($depth, $scales[$depth], $from, $to, 0)];
}
// the one right of the middle carries two more gears than it grew with, in its crown beside
// the ones it has, as large as they are (the author, 2026-10-22)
$extra = [];
$host = &$middle[3];
for ($tries = 0; count($extra) < 2 && $tries < 400; $tries++) {
    $top = min(array_column($host[3], 1));
    $r = $rand(28, 40);
    $x = $rand(20, 200);
    $y = $rand($top + 10, $top + 130);
    foreach (array_merge($host[3], $extra) as $h) {
        if (hypot($h[0] - $x, $h[1] - $y) < $h[2] + $r + 12) continue 2;
    }
    $extra[] = [$x, $y, $r, 0, $rand(60, 160), mt_rand(0, 1) ? 1 : -1];
}
$host[] = $extra;
unset($host);
array_splice($bouquets, 2, 3, $middle);
?>
<div class="backdrop" aria-hidden="true">
    <div class="backdrop-glow backdrop-glow-1"></div>
    <div class="backdrop-glow backdrop-glow-2"></div>
    <div class="backdrop-glow backdrop-glow-3"></div>
    <?php foreach ($seeds as $layer => $list): ?>
        <div class="backdrop-layer backdrop-<?= $layer ?>">
            <?php foreach ($list as [$x, $y, $r, $period, $dir, $rise, $float, $delay]): ?>
                <?= $gear("$x%", "$y%", $r, $period, $dir,
                    sprintf('; --rise: %dpx; animation-duration: %ss; animation-delay: -%ss', $rise, $float, $delay)) ?>
            <?php endforeach; ?>
        </div>
    <?php endforeach; ?>
    <?php foreach ($bouquets as $bouquet):
        [$left, $below, $depth, $heads] = $bouquet;
        $extra = $bouquet[4] ?? [];
        // four or five gears are two plants, with roots apart, not one bush
        $sorted = $heads;
        usort($sorted, fn($p, $q) => $p[0] <=> $q[0]);
        $groups = count($sorted) >= 4 ? [array_slice($sorted, 0, 2), array_slice($sorted, 2)] : [$sorted];
        $stems = [];
        foreach ($groups as $g => $group) {
            $stems = array_merge($stems, $plant($group, "plant $left $g", $g === 0 ? $extra : []));
        }
    ?>
        <?php
        // colour, as the logo's gears have: one or two umbels of each near or middle plant in
        // one of the logo's colours, drawn apart so that they keep it — blended as the outlines
        // are, the dark background swallowed it
        $tinted = [];
        if ($depth !== 'far') {
            foreach (array_merge($heads, $extra) as $i => $h) {
                if (count($tinted) < 2 && $hash("tint $left $i", 0, 1) < 0.45) {
                    $tinted[$i] = $tints[(int) $hash("tint colour $left $i", 0, count($tints) - 0.01)];
                }
            }
        }
        ?>
        <div class="backdrop-bouquet backdrop-<?= $depth ?>" style="left: <?= round($left, 1) ?>%; bottom: <?= -round($below) ?>px">
            <svg class="backdrop-stems" viewBox="-600 -1000 1200 1100" focusable="false"><?php foreach ($stems as [$d, $width]): ?><path d="<?= $d ?>" style="stroke-width: <?= $width ?>" /><?php endforeach; ?></svg>
            <?php foreach (array_merge($heads, $extra) as $i => [$x, $y, $r, , $period, $dir]):
                if (isset($tinted[$i])) continue; ?>
                <?= $gear(round($x) . 'px', round($y) . 'px', $r, $period, $dir) ?>
            <?php endforeach; ?>
        </div>
        <?php if ($tinted): ?>
            <div class="backdrop-bouquet backdrop-tint backdrop-<?= $depth ?>" style="left: <?= round($left, 1) ?>%; bottom: <?= -round($below) ?>px">
                <?php foreach ($tinted as $i => $colour):
                    [$x, $y, $r, , $period, $dir] = array_merge($heads, $extra)[$i]; ?>
                    <?= $gear(round($x) . 'px', round($y) . 'px', $r, $period, $dir, "; --colour: $colour") ?>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    <?php endforeach; ?>
</div>
