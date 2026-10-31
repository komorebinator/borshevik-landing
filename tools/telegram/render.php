<?php
// A post as the Telegram channel gets it: its text in Telegram's HTML and its pictures and
// videos, as JSON. See @LandingPage#announce#render in spec/.
// usage: php render.php <post folder> <en|ru>

require __DIR__ . '/../../lib/site.php';
require __DIR__ . '/../../lib/markdown.php';

const TELEGRAM_ORIGIN = 'https://borshevik.org'; // for a link to one of the site's pages
const TELEGRAM_TEXT_MAX = 4096;
const TELEGRAM_ALBUM_MAX = 10;

function fail(string $message): never
{
    fwrite(STDERR, $message . "\n");
    exit(1);
}

// markdown_inline's HTML with what Telegram does not take dropped: the attributes of a link
// other than href, and a link to the site's own page made absolute
function telegram_inline(string $text): string
{
    $html = markdown_inline($text, '');
    return preg_replace_callback('~<a href="([^"]*)"[^>]*>~', function ($m) {
        $href = str_starts_with($m[1], '/') ? TELEGRAM_ORIGIN . $m[1] : $m[1];
        return '<a href="' . $href . '">';
    }, $html);
}

// The length Telegram counts: the text as it shows, in UTF-16 code units.
function telegram_length(string $html): int
{
    $shown = html_entity_decode(strip_tags($html), ENT_QUOTES | ENT_HTML5, 'UTF-8');
    // without mbstring, which neither runner nor container is sure to have: a character beyond
    // the Basic Multilingual Plane, an emoji, is two units
    return preg_match_all('~.~su', $shown) + preg_match_all('~[\x{10000}-\x{10FFFF}]~u', $shown);
}

[$dir, $lang] = [rtrim($argv[1] ?? '', '/'), $argv[2] ?? ''];
$file = "$dir/$lang.md";
if (!is_file($file)) {
    fail("no $file");
}

$lines = explode("\n", str_replace(["\r\n", "\r"], "\n", file_get_contents($file)));
$n = count($lines);
$blocks = [];
$media = [];

// a paragraph that leads into a picture ends with a colon, which in the message, the picture
// gone to the album, would point at nothing: it ends with a full stop instead
$add_media = function (string $src) use ($dir, &$media, &$blocks) {
    if ($blocks && str_ends_with($blocks[count($blocks) - 1], ':')) {
        $blocks[count($blocks) - 1] = substr($blocks[count($blocks) - 1], 0, -1) . '.';
    }
    $type = preg_match('~\.(mp4|webm)$~i', $src) ? 'video' : 'photo';
    if (!markdown_safe_url($src) || preg_match('~^(https?:|/)~i', $src) || !is_file("$dir/$src")) {
        fail("$dir: $src is not a file of the post");
    }
    $media[] = ['type' => $type, 'file' => "$dir/$src"];
};

for ($i = 0; $i < $n;) {
    $line = rtrim($lines[$i]);

    if (trim($line) === '') {
        $i++;
        continue;
    }

    if (str_starts_with($line, '```')) {
        $code = [];
        for ($i++; $i < $n && !str_starts_with(rtrim($lines[$i]), '```'); $i++) {
            $code[] = $lines[$i];
        }
        $i++;
        $blocks[] = '<pre>' . e(implode("\n", $code)) . '</pre>';
        continue;
    }

    if (preg_match('~^#{1,3}\s+(.*)$~', $line, $m)) {
        $blocks[] = '<b>' . telegram_inline(trim($m[1])) . '</b>';
        $i++;
        continue;
    }

    if (preg_match('~^---+\s*$~', $line)) {
        $blocks[] = '———';
        $i++;
        continue;
    }

    if (preg_match('~^::video\s+(\S+)~', $line, $m)) {
        $add_media($m[1]);
        $i++;
        continue;
    }

    if (preg_match('~^::~', $line)) {
        $i++;
        continue;
    }

    if (preg_match('~^(- |\d+\. )~', $line, $m)) {
        $ordered = $m[1] !== '- ';
        $marker = $ordered ? '~^\d+\. ~' : '~^- ~';
        $items = [];
        while ($i < $n) {
            $cur = rtrim($lines[$i]);
            if (preg_match($marker, $cur)) {
                $items[] = preg_replace($marker, '', $cur);
            } elseif ($cur !== '' && preg_match('~^\s+\S~', $cur) && $items) {
                $items[count($items) - 1] .= ' ' . trim($cur);
            } elseif ($cur === '' && $i + 1 < $n && preg_match($marker, $lines[$i + 1])) {
                // a blank line between two items keeps the list going
            } else {
                break;
            }
            $i++;
        }
        $out = [];
        foreach ($items as $k => $item) {
            $out[] = ($ordered ? ($k + 1) . '. ' : '• ') . telegram_inline(trim($item));
        }
        $blocks[] = implode("\n", $out);
        continue;
    }

    if (str_starts_with($line, '>')) {
        $quote = [];
        for (; $i < $n && str_starts_with(rtrim($lines[$i]), '>'); $i++) {
            $quote[] = trim(substr(rtrim($lines[$i]), 1));
        }
        $blocks[] = '<blockquote>' . telegram_inline(implode(' ', array_filter($quote, 'strlen'))) . '</blockquote>';
        continue;
    }

    $para = [trim($line)];
    for ($i++; $i < $n && trim($lines[$i]) !== '' && !markdown_starts_block(rtrim($lines[$i])); $i++) {
        $para[] = trim($lines[$i]);
    }
    $text = implode(' ', $para);
    if (preg_match('~^!\[[^\]]*\]\(([^)\s]+)\)$~', $text, $m)) {
        $add_media($m[1]);
    } else {
        $blocks[] = telegram_inline($text);
    }
}

$text = implode("\n\n", $blocks);

if (($length = telegram_length($text)) > TELEGRAM_TEXT_MAX) {
    fail("$file: $length characters, Telegram takes " . TELEGRAM_TEXT_MAX);
}
if (count($media) > TELEGRAM_ALBUM_MAX) {
    fail("$file: " . count($media) . ' pictures and videos, an album holds ' . TELEGRAM_ALBUM_MAX);
}

echo json_encode(['text' => $text, 'media' => $media], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT), "\n";
