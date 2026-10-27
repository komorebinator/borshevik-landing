<?php
// The one entry point for every page; .htaccess sends here whatever names no existing file.
require __DIR__ . '/lib/site.php';
require __DIR__ . '/lib/markdown.php';
require __DIR__ . '/lib/news.php';

const LANGUAGES = ['en', 'ru'];

function route(string $path): array
{
    $path = rtrim($path, '/');
    if ($path === '') return ['home', null];
    if ($path === '/install') return ['install', 'install'];
    if ($path === '/install/rebase') return ['install', 'rebase'];
    if ($path === '/news') return ['news', null];
    if (preg_match('~^/news/([^/]+)$~', $path, $m)) return ['post', $m[1]];
    return ['notfound', null];
}

$path = rawurldecode((string)parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH));

// Under php -S this script is the router: existing files go out as they are,
// and the folders .htaccess refuses in production are refused here too.
if (PHP_SAPI === 'cli-server') {
    if (preg_match('~^/(lib|templates|i18n|content)(/|$)~', $path)) {
        http_response_code(403);
        exit;
    }
    if ($path !== '/' && is_file(__DIR__ . $path)) {
        return false;
    }
}

$lang = pick_locale(LANGUAGES);
$explicit = explicit_locale(LANGUAGES);
$t = load_strings($lang);

$isos = [];
foreach (require __DIR__ . '/iso.php' as $variant => $file) {
    $isos[$variant] = [
        'file' => $file,
        'size' => read_iso_size_gb($file),
        'checksum' => read_checksum($file . '-CHECKSUM'),
    ];
}
$link = fn(string $p) => url($p, $explicit);
$directive = function (string $name) use ($t, $isos) {
    return match ($name) {
        'downloads' => render('downloads', ['t' => $t, 'isos' => $isos]),
        'media-writer' => render('media-writer', ['t' => $t]),
        default => '',
    };
};

[$page, $slug] = route($path);
$title = '';
// what a link to the page shows in Telegram, X and the like: a few words and a picture
$preview = ['description' => $t['meta_description'], 'image' => "/media/$lang/hero.webp", 'type' => 'website'];
$section = $page;
$status = 200;

switch ($page) {
    case 'home':
        $sections = [];
        foreach (markdown_sections((string)file_get_contents(__DIR__ . "/content/$lang/home.md")) as $part) {
            if ($part['type'] === 'section') {
                $part['heading'] = markdown_inline($part['heading'], '/media/');
                $part['media'] = markdown_to_html($part['media'], '/media/');
                $part['body'] = markdown_to_html($part['body'], '/media/', $directive);
            }
            $sections[] = $part;
        }
        $body = render('home', ['t' => $t, 'lang' => $lang, 'sections' => $sections]);
        break;

    case 'install':
        [$title, $md] = split_title((string)file_get_contents(__DIR__ . "/content/$lang/$slug.md"));
        $tabs = [];
        foreach (['install' => '/install', 'rebase' => '/install/rebase'] as $id => $href) {
            $tabs[] = ['label' => $t['tab_' . $id], 'href' => $link($href), 'current' => $id === $slug];
        }
        $preview['description'] = markdown_excerpt($md);
        $body = render('page', [
            'title' => $title,
            'tabs' => $tabs,
            'text' => markdown_to_html($md, '/media/', $directive),
        ]);
        break;

    case 'news':
        $title = $t['news_title'];
        $body = render('news', ['t' => $t, 'items' => news_list($lang), 'link' => $link]);
        break;

    case 'post':
        $post = news_post((string)$slug, $lang);
        if ($post !== null) {
            $section = 'news';
            $title = $post['title'];
            $first = markdown_first_image($post['body'], '/posts/' . $post['slug'] . '/');
            $preview = [
                'description' => markdown_excerpt($post['body']),
                'image' => $first !== '' && $first[0] === '/' ? $first : $preview['image'],
                'type' => 'article',
            ];
            $body = render('post', [
                't' => $t,
                'entry' => $post,
                'text' => markdown_to_html($post['body'], '/posts/' . $post['slug'] . '/'),
                'link' => $link,
            ]);
            break;
        }
        // a post that does not exist is not found like any other path
    default:
        $section = 'none';
        $status = 404;
        $title = $t['notfound_title'];
        $body = render('page', ['title' => $title, 'tabs' => [], 'text' => '<p>' . e($t['notfound_text']) . '</p>']);
}

http_response_code($status);
header('Content-Type: text/html; charset=utf-8');
header('Vary: Accept-Language');
header('Content-Language: ' . $lang);

echo render('layout', [
    'lang' => $lang,
    't' => $t,
    'title' => $title,
    'preview' => $preview,
    'section' => $section,
    'path' => $path,
    'body' => $body,
    'link' => $link,
    'header_links' => (require __DIR__ . '/links.php')[$lang] ?? [],
]);
