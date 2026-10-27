<?php
// Reads the posts in posts/: one folder per post, YYYY-MM-DD-<slug>, with en.md and ru.md.

const NEWS_DIR = __DIR__ . '/../posts';
const NEWS_SLUG = '~^(\d{4}-\d{2}-\d{2})-[a-z0-9]+(?:-[a-z0-9]+)*$~';

function split_title(string $md): array
{
    $md = ltrim(str_replace(["\r\n", "\r"], "\n", $md), "\n");
    if (preg_match('~^#\s+(.*)\n?~', $md, $m)) {
        return [trim($m[1]), substr($md, strlen($m[0]))];
    }
    return ['', $md];
}

function news_post(string $slug, string $lang): ?array
{
    // Matched before it touches the filesystem, so a request path never leaves posts/.
    if (!preg_match(NEWS_SLUG, $slug, $m)) {
        return null;
    }
    $path = NEWS_DIR . '/' . $slug . '/' . $lang . '.md';
    if (!is_readable($path)) {
        return null;
    }
    [$title, $body] = split_title((string)file_get_contents($path));
    return ['slug' => $slug, 'date' => $m[1], 'title' => $title, 'body' => $body];
}

function news_list(string $lang): array
{
    $posts = [];
    foreach (scandir(NEWS_DIR) ?: [] as $slug) {
        $post = news_post($slug, $lang);
        if ($post !== null) {
            $post['excerpt'] = markdown_excerpt($post['body']);
            $post['image'] = markdown_first_image($post['body'], '/posts/' . $slug . '/');
            $posts[] = $post;
        }
    }
    usort($posts, fn($a, $b) => [$b['date'], $b['slug']] <=> [$a['date'], $a['slug']]);
    return $posts;
}
