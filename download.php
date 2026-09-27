<?php
// Target of the permanent ISO links (see .htaccess): redirects to the file offered now.
$isos = require __DIR__ . '/iso.php';

$variant = $_GET['variant'] ?? '';
if (!is_string($variant) || !isset($isos[$variant])) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo "Not found\n";
    exit;
}

$name = $isos[$variant];
if (($_GET['file'] ?? '') === 'checksum') {
    $name .= '-CHECKSUM';
}

header('Cache-Control: no-store');
header('Location: /iso/' . rawurlencode($name), true, 302);
