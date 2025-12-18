<?php
function read_checksum(string $filename): string
{
    $path = __DIR__ . '/iso/' . $filename;

    if (!is_readable($path)) {
        return '';
    }

    $content = trim(file_get_contents($path));
    if ($content === '') {
        return '';
    }

    $parts = preg_split('/\s+/', $content);
    $hash  = $parts[0] ?? '';

    return htmlspecialchars($hash, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function read_iso_size_gb(string $filename): string
{
    $path = __DIR__ . '/iso/' . $filename;

    if (!is_readable($path)) {
        return '';
    }

    $bytes = filesize($path);
    if ($bytes === false || $bytes <= 0) {
        return '';
    }

    $gb = $bytes / (1024 * 1024 * 1024);
    $formatted = number_format($gb, 1, '.', '');

    return $formatted . ' GB';
}

function pick_locale(array $supported, string $default = 'en'): string
{
    $q = $_GET['lang'] ?? '';
    if (is_string($q)) {
        $q = strtolower(trim($q));
        $qBase = explode('-', $q, 2)[0];
        if (in_array($qBase, $supported, true)) {
            return $qBase;
        }
    }

    $header = $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? '';
    if ($header === '') {
        return $default;
    }

    $candidates = [];
    foreach (explode(',', $header) as $part) {
        $part = trim($part);
        if ($part === '') continue;

        $qv = 1.0;
        if (strpos($part, ';q=') !== false) {
            [$tag, $qstr] = explode(';q=', $part, 2);
            $part = trim($tag);
            $qv = (float)trim($qstr);
        }
        $candidates[] = ['tag' => strtolower($part), 'q' => $qv];
    }

    usort($candidates, fn($a, $b) => $b['q'] <=> $a['q']);

    foreach ($candidates as $c) {
        $tag = $c['tag'];
        $base = explode('-', $tag, 2)[0];
        if (in_array($base, $supported, true)) {
            return $base;
        }
    }

    return $default;
}

$checksum_standard = read_checksum('borshevik-stable.iso-CHECKSUM');
$checksum_nvidia   = read_checksum('borshevik-nvidia-stable.iso-CHECKSUM');

$size_standard = read_iso_size_gb('borshevik-stable.iso');
$size_nvidia   = read_iso_size_gb('borshevik-nvidia-stable.iso');

$templateMap = [
    'en' => __DIR__ . '/templates/en.html',
    'ru' => __DIR__ . '/templates/ru.html',
];

$supported = array_keys($templateMap);
$lang = pick_locale($supported, 'en');

$tplPath = $templateMap[$lang] ?? $templateMap['en'];
if (!is_readable($tplPath)) {
    $tplPath = $templateMap['en'];
}

$tpl = file_get_contents($tplPath);
if ($tpl === false) {
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    echo "Template load error";
    exit;
}

$year = date('Y');

$repl = [
    '{{LANG}}' => htmlspecialchars($lang, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'),
    '{{YEAR}}' => $year,

    '{{SIZE_STANDARD_PART}}' => $size_standard !== '' ? ' · ' . htmlspecialchars($size_standard, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') : '',
    '{{SIZE_NVIDIA_PART}}'   => $size_nvidia   !== '' ? ' · ' . htmlspecialchars($size_nvidia,   ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') : '',

    '{{CHECKSUM_STANDARD}}' => $checksum_standard,
    '{{CHECKSUM_NVIDIA}}'   => $checksum_nvidia,
];

$out = strtr($tpl, $repl);

header('Content-Type: text/html; charset=utf-8');
header('Vary: Accept-Language');
header('Content-Language: ' . $lang);

echo $out;
