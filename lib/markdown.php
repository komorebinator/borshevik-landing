<?php
// The site's own renderer for the subset of Markdown pages and posts are written in.
// Raw HTML is not part of it: all text is escaped. See @LandingPage#markdown in spec/.

function markdown_safe_url(string $url): bool
{
    // http(s), mailto, a path, a fragment, or a relative name with no scheme at all
    return (bool)preg_match('~^(https?://|mailto:|/|#)~i', $url)
        || !preg_match('~^[a-z][a-z0-9+.-]*:~i', $url);
}

function markdown_src(string $src, string $base): string
{
    if (preg_match('~^(https?://|/)~i', $src)) {
        return $src;
    }
    return $base . $src;
}

function markdown_media(string $alt, string $src, string $base): string
{
    if (!markdown_safe_url($src)) {
        return e($alt);
    }
    $src = markdown_src($src, $base);
    // a looping video, which the page's script starts once it is scrolled to: autoplay would
    // have the browser download every video of the page as it opens (@LandingPage#layout)
    if (preg_match('~\.(mp4|webm)$~i', $src)) {
        return '<video muted loop playsinline preload="metadata" data-loop src="' . e($src) . '"'
            . ($alt !== '' ? ' aria-label="' . e($alt) . '"' : '') . '></video>';
    }
    return '<img src="' . e($src) . '" alt="' . e($alt) . '" loading="lazy">';
}

// A video to watch rather than one that loops by itself: a walk-through such as the
// installer's, played with controls to scrub and pause, from its first frame: the browser's
// own, which the page's script swaps for the site's (@LandingPage#layout). Muted, so the
// script may start it once it is scrolled to.
function markdown_player(string $caption, string $src, string $base): string
{
    if (!markdown_safe_url($src) || !preg_match('~\.(mp4|webm)$~i', $src)) {
        return e($caption);
    }
    return '<figure class="player"><video controls muted playsinline preload="metadata" data-play-in-view src="' . e(markdown_src($src, $base)) . '"'
        . ($caption !== '' ? ' aria-label="' . e($caption) . '"' : '') . '></video>'
        . ($caption !== '' ? '<figcaption>' . e($caption) . '</figcaption>' : '') . '</figure>';
}

function markdown_emphasis(string $escaped): string
{
    $escaped = preg_replace('~\*\*(?=\S)(.+?)(?<=\S)\*\*~u', '<strong>$1</strong>', $escaped);
    return preg_replace('~\*(?=\S)(.+?)(?<=\S)\*~u', '<em>$1</em>', $escaped);
}

function markdown_inline(string $text, string $base): string
{
    $out = '';
    // Odd parts are code spans: nothing inside them is interpreted.
    $parts = preg_split('~`([^`]+)`~', $text, -1, PREG_SPLIT_DELIM_CAPTURE);
    foreach ($parts as $i => $part) {
        if ($i % 2 === 1) {
            $out .= '<code>' . e($part) . '</code>';
            continue;
        }

        $held = [];
        $hold = function (string $html) use (&$held): string {
            $held[] = $html;
            return "\x00" . (count($held) - 1) . "\x00";
        };

        $part = preg_replace_callback('~!\[([^\]]*)\]\(([^)\s]+)\)~', function ($m) use ($hold, $base) {
            return $hold(markdown_media($m[1], $m[2], $base));
        }, $part);

        $part = preg_replace_callback('~\[([^\]]+)\]\(([^)\s]+)\)~', function ($m) use ($hold) {
            $label = markdown_emphasis(e($m[1]));
            if (!markdown_safe_url($m[2])) {
                return $hold($label);
            }
            $external = (bool)preg_match('~^https?://~i', $m[2]);
            return $hold('<a href="' . e($m[2]) . '"'
                . ($external ? ' target="_blank" rel="noopener noreferrer"' : '')
                . '>' . $label . '</a>');
        }, $part);

        $part = markdown_emphasis(e($part));
        $out .= preg_replace_callback("~\x00(\d+)\x00~", fn($m) => $held[(int)$m[1]], $part);
    }
    return $out;
}

// A page as group titles (# ) and sections (## ), each section with its first
// standalone image or video set apart, for the home page's rows. Still Markdown.
function markdown_sections(string $md): array
{
    $parts = [];
    $section = null;

    $flush = function () use (&$parts, &$section) {
        if ($section === null) {
            return;
        }
        $body = trim(implode("\n", $section['lines']));
        $media = '';
        $blocks = preg_split('~\n\s*\n~', $body);
        foreach ($blocks as $i => $block) {
            if (preg_match('~^!\[[^\]]*\]\([^)\s]+\)$~', trim($block))) {
                $media = trim($block);
                unset($blocks[$i]);
                break;
            }
        }
        $body = implode("\n\n", $blocks);
        $exclusive = (bool)preg_match('~^::exclusive\s*$~m', $body);
        $body = trim(preg_replace('~^::exclusive\s*$~m', '', $body));
        if ($section['heading'] !== '' || $body !== '' || $media !== '') {
            $parts[] = [
                'type' => 'section',
                'heading' => $section['heading'],
                'media' => $media,
                'body' => $body,
                'exclusive' => $exclusive,
            ];
        }
        $section = null;
    };

    foreach (explode("\n", str_replace(["\r\n", "\r"], "\n", $md)) as $line) {
        if (preg_match('~^#\s+(.*)$~', $line, $m)) {
            $flush();
            $parts[] = ['type' => 'group', 'title' => trim($m[1])];
        } elseif (preg_match('~^##\s+(.*)$~', $line, $m)) {
            $flush();
            $section = ['heading' => trim($m[1]), 'lines' => []];
        } else {
            $section ??= ['heading' => '', 'lines' => []];
            $section['lines'][] = $line;
        }
    }
    $flush();

    return $parts;
}

// Whether a line opens a block other than a paragraph, and so ends one.
function markdown_starts_block(string $line): bool
{
    return (bool)preg_match('~^(#{1,3}\s|```|---+\s*$|::[a-z0-9-]+\s*$|::video\s|- |\d+\. |>)~', $line);
}

function markdown_to_html(string $md, string $base = '', ?callable $directive = null): string
{
    $lines = explode("\n", str_replace(["\r\n", "\r"], "\n", $md));
    $n = count($lines);
    $blocks = [];
    $i = 0;

    while ($i < $n) {
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
            $i++; // the closing fence
            $blocks[] = '<pre><code>' . e(implode("\n", $code)) . '</code></pre>';
            continue;
        }

        if (preg_match('~^(#{1,3})\s+(.*)$~', $line, $m)) {
            $level = strlen($m[1]);
            $blocks[] = "<h$level>" . markdown_inline(trim($m[2]), $base) . "</h$level>";
            $i++;
            continue;
        }

        if (preg_match('~^---+\s*$~', $line)) {
            $blocks[] = '<hr>';
            $i++;
            continue;
        }

        if (preg_match('~^::video\s+(\S+)(?:\s+(.*))?$~', $line, $m)) {
            $blocks[] = markdown_player(trim($m[2] ?? ''), $m[1], $base);
            $i++;
            continue;
        }

        if (preg_match('~^::([a-z0-9-]+)\s*$~', $line, $m)) {
            $blocks[] = $directive !== null ? (string)$directive($m[1]) : '';
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
            $tag = $ordered ? 'ol' : 'ul';
            $html = array_map(fn($item) => '<li>' . markdown_inline(trim($item), $base) . '</li>', $items);
            $blocks[] = "<$tag>" . implode('', $html) . "</$tag>";
            continue;
        }

        if (str_starts_with($line, '>')) {
            $paras = [[]];
            for (; $i < $n && str_starts_with(rtrim($lines[$i]), '>'); $i++) {
                $text = trim(substr(rtrim($lines[$i]), 1));
                if ($text === '') {
                    $paras[] = [];
                } else {
                    $paras[count($paras) - 1][] = $text;
                }
            }
            $html = '';
            foreach ($paras as $p) {
                if ($p) {
                    $html .= '<p>' . markdown_inline(implode(' ', $p), $base) . '</p>';
                }
            }
            $blocks[] = '<blockquote>' . $html . '</blockquote>';
            continue;
        }

        $para = [trim($line)];
        for ($i++; $i < $n && trim($lines[$i]) !== '' && !markdown_starts_block(rtrim($lines[$i])); $i++) {
            $para[] = trim($lines[$i]);
        }
        $text = implode(' ', $para);

        if (preg_match('~^!\[([^\]]*)\]\(([^)\s]+)\)$~', $text, $m)) {
            $blocks[] = '<figure>' . markdown_media($m[1], $m[2], $base)
                . ($m[1] !== '' ? '<figcaption>' . e($m[1]) . '</figcaption>' : '') . '</figure>';
        } else {
            $blocks[] = '<p>' . markdown_inline($text, $base) . '</p>';
        }
    }

    return implode("\n", $blocks);
}

// The first paragraph of a document as plain text, for the news list.
function markdown_excerpt(string $md): string
{
    $paras = preg_split('~\n\s*\n~', trim(str_replace(["\r\n", "\r"], "\n", $md)));
    foreach ($paras as $p) {
        $p = trim($p);
        if ($p === '' || markdown_starts_block($p) || str_starts_with($p, '![')) {
            continue;
        }
        $p = preg_replace('~!\[[^\]]*\]\([^)]*\)~', '', $p);
        $p = preg_replace('~\[([^\]]+)\]\([^)]*\)~', '$1', $p);
        $p = str_replace(['**', '`'], '', $p);
        $p = preg_replace('~\*(\S(?:.*?\S)?)\*~', '$1', $p);
        return trim(preg_replace('~\s+~', ' ', $p));
    }
    return '';
}

// The first image a document shows (videos skipped), for the news list's thumbnails.
function markdown_first_image(string $md, string $base): string
{
    preg_match_all('~!\[[^\]]*\]\(([^)\s]+)\)~', $md, $m);
    foreach ($m[1] as $src) {
        if (markdown_safe_url($src) && !preg_match('~\.(mp4|webm)$~i', $src)) {
            return markdown_src($src, $base);
        }
    }
    return '';
}
