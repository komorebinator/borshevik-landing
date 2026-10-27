<?php
// What every page needs besides its own text: language, ISO metadata, links, rendering.

function e(string $s): string
{
    return htmlspecialchars($s, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function read_checksum(string $filename): string
{
    $path = __DIR__ . '/../iso/' . $filename;

    if (!is_readable($path)) {
        return '';
    }

    $content = trim((string)file_get_contents($path));
    if ($content === '') {
        return '';
    }

    $parts = preg_split('/\s+/', $content);
    return $parts[0] ?? '';
}

function read_iso_size_gb(string $filename): string
{
    $path = __DIR__ . '/../iso/' . $filename;

    if (!is_readable($path)) {
        return '';
    }

    $bytes = filesize($path);
    if ($bytes === false || $bytes <= 0) {
        return '';
    }

    $gb = $bytes / (1024 * 1024 * 1024);
    return number_format($gb, 1, '.', '') . ' GB';
}

function explicit_locale(array $supported): ?string
{
    $q = $_GET['lang'] ?? '';
    if (!is_string($q)) {
        return null;
    }

    $base = explode('-', strtolower(trim($q)), 2)[0];
    return in_array($base, $supported, true) ? $base : null;
}

function pick_locale(array $supported, string $default = 'en'): string
{
    $explicit = explicit_locale($supported);
    if ($explicit !== null) {
        return $explicit;
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
        $base = explode('-', $c['tag'], 2)[0];
        if (in_array($base, $supported, true)) {
            return $base;
        }
    }

    return $default;
}

// A link to a path of the site; keeps ?lang= only when the visitor chose the language.
function url(string $path, ?string $explicit_lang): string
{
    return $explicit_lang === null ? $path : $path . '?lang=' . rawurlencode($explicit_lang);
}

// The address the site is reached at, for the absolute links a link preview needs: the scheme
// and host of this request, falling back to borshevik.org when the host is not a plain one.
function site_origin(): string
{
    $host = (string)($_SERVER['HTTP_HOST'] ?? '');
    if (!preg_match('~^[A-Za-z0-9.-]+(:[0-9]+)?$~', $host)) {
        $host = 'borshevik.org';
    }
    $https = ($_SERVER['HTTPS'] ?? '') !== '' && ($_SERVER['HTTPS'] ?? '') !== 'off'
        || ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https';
    return ($https ? 'https' : 'http') . '://' . $host;
}

function load_strings(string $lang): array
{
    $path = __DIR__ . '/../i18n/' . $lang . '.php';
    if (!is_readable($path)) {
        $path = __DIR__ . '/../i18n/en.php';
    }
    return require $path;
}

function render(string $template, array $vars): string
{
    extract($vars);
    ob_start();
    require __DIR__ . '/../templates/' . $template . '.php';
    return (string)ob_get_clean();
}
