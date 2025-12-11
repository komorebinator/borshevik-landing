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

$checksum_standard = read_checksum('borshevik-stable.iso-CHECKSUM');
$checksum_nvidia   = read_checksum('borshevik-nvidia-stable.iso-CHECKSUM');

$size_standard = read_iso_size_gb('borshevik-stable.iso');
$size_nvidia   = read_iso_size_gb('borshevik-nvidia-stable.iso');
?>
<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <title>Borshevik Linux</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="icon" type="image/svg+xml" href="borshevik_logo.svg">
    <meta name="description"
        content="Borshevik is a Fedora Atomic–based immutable desktop image with sane defaults, codecs, Chrome, a curated app set, and small GNOME tweaks baked in.">
    <style>
        :root {
            --bg: #050513;
            --card-inner: #15151f;
            --text: #f4f4ff;
            --muted: #9ca3af;
            --border-grad-1: #7de0c9;
            --border-grad-2: #c9a8ff;
            --border-grad-3: #ff9ad5;
            --border-grad-4: #deb8ce
        }

        * {
            box-sizing: border-box;
        }

        html,
        body {
            height: 100%;
        }

        body {
            margin: 0;
            font-family: system-ui, -apple-system, BlinkMacSystemFont,
                "SF Pro Text", "Segoe UI", sans-serif;
            background: radial-gradient(circle at top, #17172b 0, #050513 55%, #020208 100%);
            color: var(--text);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }

        .shell {
            max-width: 640px;
            width: 100%;
        }

        @media (min-width: 640px) {
            .card-inner {
                padding: 32px 34px 24px;
            }
        }

        .logo-wrap {
            display: flex;
            justify-content: center;
            margin-bottom: 20px;
        }

        .logo-circle {
            width: 132px;
            height: 132px;
            border-radius: 999px;
            background: radial-gradient(circle at 30% 20%,
                    rgba(255, 154, 213, 0.45) 0,
                    transparent 65%);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .logo-circle img {
            display: block;
            max-width: 100%;
            max-height: 100%;
        }

        .title {
            text-align: center;
            margin-bottom: 40px;
        }

        h1 {
            margin: 0;
            font-size: 26px;
            letter-spacing: 0.2em;
            text-transform: uppercase;
        }

        p {
            margin: 46px 0 0;
            font-size: 16px;
            color: var(--muted);
            line-height: 1.5;
        }

        .downloads {
            display: grid;
            gap: 20px;
            margin-top: 6px;
        }

        .download-block {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .download-button {
            display: flex;
            align-items: center;
            justify-content: center;
            text-decoration: none;
            border-radius: 999px;
            padding: 14px 18px;
            border: 2px solid transparent;
            color: var(--text);
            position: relative;
            overflow: hidden;
            background: transparent;
            transition: color 0.25s ease;
        }

        .download-button::before {
            content: "";
            position: absolute;
            inset: 0;
            border-radius: inherit;
            padding: 2px;
            background: linear-gradient(135deg,
                    var(--border-grad-1),
                    var(--border-grad-2),
                    var(--border-grad-3),
                    var(--border-grad-4));
            mask:
                linear-gradient(#000 0 0) content-box,
                linear-gradient(#000 0 0);
            mask-composite: exclude;
            z-index: 1;
        }

        .download-button::after {
            content: "";
            position: absolute;
            inset: 0px;
            border-radius: calc(999px - 2px);
            background: linear-gradient(135deg,
                    var(--border-grad-1),
                    var(--border-grad-2),
                    var(--border-grad-3),
                    var(--border-grad-4));
            transform: scaleX(0);
            transform-origin: left center;
            transition: transform 0.35s ease-out;
            z-index: 0;
        }

        .download-content {
            position: relative;
            text-align: center;
            z-index: 2;
        }

        .download-title {
            font-size: 16px;
            font-weight: 600;
        }

        .download-subtitle {
            margin-top: 3px;
            font-size: 14px;
            color: #b8b8d9;
            transition: color 0.25s ease;
        }

        .download-button:hover::after {
            transform: scaleX(1);
        }

        .download-button:hover {
            color: #050513;
        }

        .download-button:hover .download-subtitle {
            color: #111827;
        }

        .checksum {
            font-size: 12px;
            color: var(--muted);
            word-break: break-all;
        }

        .checksum-label {
            opacity: 0.8;
            margin-right: 4px;
        }

        .checksum code {
            border-radius: 6px;
            padding: 2px 6px;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas,
                "Liberation Mono", "Courier New", monospace;
        }

        .footer {
            margin-top: 40px;
            font-size: 14px;
            color: #7a7f9a;
            display: flex;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            align-items: center;
        }

        .link {
            color: #c9a8ff;
            text-decoration: none;
        }

        .link:hover {
            text-decoration: underline;
        }

        .wmv-list {
            font-size: 14px;
        }

        @media (max-width: 480px) {
            .footer {
                flex-direction: column;
                align-items: flex-start;
            }
        }
    </style>
</head>

<body>
    <div class="shell">
        <div class="card">
            <main class="card-inner">
                <div class="logo-wrap">
                    <div class="logo-circle">
                        <img src="borshevik_logo.svg" alt="Borshevik logo">
                    </div>
                </div>

                <header class="title">
                    <h1>Borshevik</h1>
                    <p>
                        Borshevik is an immutable desktop image built on top of
                        <a href="https://www.fedoraproject.org/atomic-desktops/" class="link" target="_blank" rel="noopener noreferrer">
                            Fedora Atomic
                        </a>
                        and the
                        <a href="https://universal-blue.org/" target="_blank" class="link" rel="noopener noreferrer">
                            uBlue ecosystem
                        </a>.
                        It ships as a single read-only system image with atomic updates and simple rollbacks, a mostly
                        upstream GNOME desktop, multimedia support, Chrome and a curated Flatpak set, plus a few small tweaks
                        so you can install it, log in and start working instead of spending the evening on first-boot setup.
                    </p>
                </header>

                <section class="downloads" aria-label="Downloads">
                    <div class="download-block">
                        <a class="download-button" href="/iso/borshevik-stable.iso">
                            <div class="download-content">
                                <div class="download-title">
                                    Download<?= $size_standard !== '' ? ' · ' . $size_standard : '' ?>
                                </div>
                                <div class="download-subtitle">
                                    Standard image · AMD / Intel graphics
                                </div>
                            </div>
                        </a>
                        <div class="checksum">
                            <span class="checksum-label">Checksum:</span>
                            <code><?= $checksum_standard ?></code>
                        </div>
                    </div>

                    <div class="download-block">
                        <a class="download-button" href="/iso/borshevik-nvidia-stable.iso">
                            <div class="download-content">
                                <div class="download-title">
                                    Download (NVIDIA)<?= $size_nvidia !== '' ? ' · ' . $size_nvidia : '' ?>
                                </div>
                                <div class="download-subtitle">
                                    NVIDIA image · proprietary drivers included
                                </div>
                            </div>
                        </a>
                        <div class="checksum">
                            <span class="checksum-label">Checksum:</span>
                            <code><?= $checksum_nvidia ?></code>
                        </div>
                    </div>
                </section>

                <p>
                    You may also need <b>Fedora Media Writer</b> to write the image to a USB drive
                </p>
                <ul class="wmv-list">
                    <li>
                        <a class="link"
                            href="https://github.com/FedoraQt/MediaWriter/releases/latest"
                            target="_blank" rel="noopener noreferrer">
                            MacOS / Windows
                        </a>
                    </li>
                    <li>
                        <a class="link"
                            href="https://flathub.org/en/apps/org.fedoraproject.MediaWriter"
                            target="_blank" rel="noopener noreferrer">
                            Linux (Flathub)
                        </a>
                    </li>
                </ul>


                <footer class="footer">
                    <div>© <?= date('Y') ?> Borshevik project</div>
                    <div>
                        <a class="link" href="https://github.com/komorebinator/borshevik"
                            target="_blank" rel="noopener noreferrer">
                            View source on GitHub
                        </a>
                    </div>
                </footer>
            </main>
        </div>
    </div>
</body>

</html>