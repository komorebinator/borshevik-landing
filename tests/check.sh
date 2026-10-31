#!/usr/bin/env bash
# Checks for what breaks silently: see @LandingPage#tests#checks in spec/.
# Needs php-cli, jq and curl. Never writes into the repository.
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

failed=0
ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

tmp="$(mktemp -d)"
server_pid=""
cleanup() {
    [ -n "$server_pid" ] && kill "$server_pid" 2>/dev/null
    rm -rf "$tmp"
}
trap cleanup EXIT

php() { command php -d display_errors=1 -d error_reporting=-1 "$@"; }

# 1. the PHP parses
for f in index.php download.php iso.php links.php lib/*.php i18n/*.php templates/*.php tools/telegram/*.php; do
    if out="$(php -l "$f" 2>&1)"; then
        ok "php-syntax $f"
    else
        fail "php-syntax $f" "$out"
    fi
done

# 2. applications.json is what the App Manager accepts
if jq -e '
    type == "array" and length > 0 and all(.[];
        (.name | type == "string" and length > 0)
        and (.applications | type == "array" and length > 0
             and all(.[]; type == "string" and length > 0))
        and ((has("default") | not) or (.default | type == "boolean")))
' share/applications.json >/dev/null 2>&1; then
    ok applications-json
else
    fail applications-json "share/applications.json is not an array of {name, applications[, default]} categories"
fi

# 3-6. strings, pages, posts, the pictures and videos they name, the header links
# Each check prints "ok <name>" or "FAIL <name>: <why>".
cat > "$tmp/content.php" <<'PHP'
<?php
$langs = ['en', 'ru'];
$report = function (string $name, array $problems) {
    echo $problems ? "FAIL $name: " . implode('; ', $problems) . "\n" : "ok $name\n";
};

// both string files carry the same keys, none empty
$strings = [];
foreach ($langs as $l) $strings[$l] = require "i18n/$l.php";
$p = [];
foreach ($langs as $a) foreach ($langs as $b) {
    foreach (array_diff(array_keys($strings[$a]), array_keys($strings[$b])) as $k) $p[] = "'$k' in $a, not in $b";
}
foreach ($langs as $l) foreach ($strings[$l] as $k => $v) {
    if (!is_string($v) || trim($v) === '') $p[] = "'$k' empty in $l";
}
$report('strings', $p);

// both languages have the same pages, the installation ones with a title
$p = [];
$pages = [];
foreach ($langs as $l) $pages[$l] = array_map('basename', glob("content/$l/*.md"));
if ($pages['en'] !== $pages['ru']) $p[] = 'en has ' . implode(',', $pages['en']) . ', ru has ' . implode(',', $pages['ru']);
foreach ($langs as $l) {
    foreach (['home.md', 'install.md', 'rebase.md'] as $f) if (!is_file("content/$l/$f")) $p[] = "content/$l/$f missing";
    foreach (['install.md', 'rebase.md'] as $f) {
        if (is_file("content/$l/$f") && !preg_match('~^# \S~', file_get_contents("content/$l/$f"))) $p[] = "content/$l/$f has no '# ' title";
    }
}
$report('pages', $p);

// every post folder is well named and has both languages, each with a title and a picture
// that is not a video, which the news list shows as its thumbnail
$p = [];
foreach (glob('posts/*', GLOB_ONLYDIR) as $dir) {
    $slug = basename($dir);
    if (!preg_match('~^\d{4}-\d{2}-\d{2}-[a-z0-9]+(-[a-z0-9]+)*$~', $slug)) $p[] = "$slug is not YYYY-MM-DD-<slug>";
    foreach ($langs as $l) {
        if (!is_file("$dir/$l.md")) { $p[] = "$slug has no $l.md"; continue; }
        $md = file_get_contents("$dir/$l.md");
        if (!preg_match('~^# \S~', $md)) $p[] = "$slug/$l.md has no '# ' title";
        preg_match_all('~!\[[^\]]*\]\(([^)\s]+)\)~', $md, $m);
        if (!preg_grep('~\.(mp4|webm)$~i', $m[1], PREG_GREP_INVERT)) $p[] = "$slug/$l.md has no picture for the news list";
    }
}
$report('posts', $p);

// every image or video a page or post names is there, a walk-through's ::video line included
$p = [];
$docs = [];
foreach (glob('content/*/*.md') as $f) $docs[$f] = 'media/';
foreach (glob('posts/*/*.md') as $f) $docs[$f] = dirname($f) . '/';
foreach ($docs as $f => $base) {
    $md = file_get_contents($f);
    preg_match_all('~!\[[^\]]*\]\(([^)\s]+)\)~', $md, $m);
    preg_match_all('~^::video\s+(\S+)~m', $md, $v);
    foreach (array_merge($m[1], $v[1]) as $src) {
        if (preg_match('~^https?://~', $src)) continue;
        $path = $src[0] === '/' ? ltrim($src, '/') : $base . $src;
        if (!is_file($path)) $p[] = "$f names $src, which is not there";
    }
}
$report('media-references', $p);

// both languages have the same pictures, and the pages' and posts' videos stay small
$p = [];
$names = [];
foreach ($langs as $l) $names[$l] = array_map('basename', glob("media/$l/*"));
foreach ($langs as $a) foreach ($langs as $b) {
    foreach (array_diff($names[$a], $names[$b]) as $f) $p[] = "media/$a/$f has no media/$b/$f";
}
foreach (glob('{media,posts}/*/*.{mp4,webm}', GLOB_BRACE) as $f) {
    if (filesize($f) >= 5 * 1024 * 1024) $p[] = "$f is 5 MB or more";
}
$report('media', $p);

// every picture is made by a script of tools/capture/pictures/ or installer.sh, or is listed as taken by hand
$p = [];
$made = [];
foreach (glob('tools/capture/{pictures/*,installer}.sh', GLOB_BRACE) as $f) {
    if (preg_match('~^# makes: (.*)$~m', file_get_contents($f), $m)) {
        foreach (preg_split('~\s+~', trim($m[1])) as $n) $made[$n] = true;
    }
}
foreach (file('tools/capture/by-hand.txt', FILE_IGNORE_NEW_LINES) ?: [] as $line) {
    if (preg_match('~^([a-z0-9-]+)~', $line, $m)) $made[$m[1]] = true;
}
foreach (glob('media/*/*') as $f) {
    $n = pathinfo($f, PATHINFO_FILENAME);
    if (!isset($made[$n])) $p[] = "$f is made by no script of tools/capture/pictures/ nor installer.sh and not listed in tools/capture/by-hand.txt";
}
$report('pictures-made', array_unique($p));

// header links are https and have their icons
$p = [];
$links = require 'links.php';
foreach ($langs as $l) {
    if (!isset($links[$l])) { $p[] = "no list for $l"; continue; }
    foreach ($links[$l] as $link) {
        if (!preg_match('~^https://~', $link['url'] ?? '')) $p[] = "$l: {$link['id']} is not https";
        if (!is_file("icons/{$link['id']}.svg")) $p[] = "$l: icons/{$link['id']}.svg missing";
        if (($link['label'] ?? '') === '') $p[] = "$l: {$link['id']} has no label";
    }
}
$report('links', $p);
PHP
while IFS= read -r line; do
    case "$line" in
        ok\ *) echo "$line" ;;
        *) echo "$line"; failed=1 ;;
    esac
done < <(php "$tmp/content.php" 2>&1)

# 6b. every post goes out to Telegram within its limits, as announce.yml will send it
problems=""
for dir in posts/*/; do
    for lang in en ru; do
        out="$(php tools/telegram/render.php "$dir" "$lang" 2>&1 >/dev/null)" || problems+="${out:-$dir$lang.md does not render}; "
    done
done
if [ -z "$problems" ]; then ok telegram; else fail telegram "$problems"; fi

# 7. the Markdown renderer makes exactly this of the syntax pages and posts rely on
cat > "$tmp/markdown.php" <<'PHP'
<?php
require 'lib/site.php';
require 'lib/markdown.php';
$cases = [
    ["# T", '<h1>T</h1>'],
    ["## A *b* **c** `d*e*`", '<h2>A <em>b</em> <strong>c</strong> <code>d*e*</code></h2>'],
    ["one\ntwo\n\nthree", "<p>one two</p>\n<p>three</p>"],
    ["- a\n- b\n  c", '<ul><li>a</li><li>b c</li></ul>'],
    ["1. a\n2. b", '<ol><li>a</li><li>b</li></ol>'],
    ["> q\n> r", '<blockquote><p>q r</p></blockquote>'],
    ["```\n<b> **x**\n```", '<pre><code>&lt;b&gt; **x**</code></pre>'],
    ["---", '<hr>'],
    ["::downloads\n\n::other", "[D]\n"],
    ["![Alt](x.webp)", '<figure><img src="/p/x.webp" alt="Alt" loading="lazy"><figcaption>Alt</figcaption></figure>'],
    ["![V](/media/en/v.mp4)", '<figure><video muted loop playsinline preload="metadata" data-loop src="/media/en/v.mp4" aria-label="V"></video><figcaption>V</figcaption></figure>'],
    ["::video en/w.mp4 How it goes\ntext", "<figure class=\"player\"><video controls muted playsinline preload=\"metadata\" data-play-in-view src=\"/p/en/w.mp4\" aria-label=\"How it goes\"></video><figcaption>How it goes</figcaption></figure>\n<p>text</p>"],
    ["::video javascript:a.mp4 J", 'J'],
    ["[s](/install) and [e](https://x.org)", '<p><a href="/install">s</a> and <a href="https://x.org" target="_blank" rel="noopener noreferrer">e</a></p>'],
    ["<script>alert(1)</script>", '<p>&lt;script&gt;alert(1)&lt;/script&gt;</p>'],
    ["[x](javascript:void)", '<p>x</p>'],
    ['"q" & a', '<p>&quot;q&quot; &amp; a</p>'],
];
$directive = fn($name) => $name === 'downloads' ? '[D]' : '';
foreach ($cases as [$md, $want]) {
    $got = markdown_to_html($md, '/p/', $directive);
    if ($got !== $want) {
        echo 'FAIL markdown ' . json_encode($md) . ': got ' . json_encode($got) . ', expected ' . json_encode($want) . "\n";
    }
}
$sections = markdown_sections("# G\n\n## A\n\n![i](x.webp)\n\n::exclusive\n\nText\n\n## B\n\nOnly text");
$want = [
    ['type' => 'group', 'title' => 'G'],
    ['type' => 'section', 'heading' => 'A', 'media' => '![i](x.webp)', 'body' => 'Text', 'exclusive' => true],
    ['type' => 'section', 'heading' => 'B', 'media' => '', 'body' => 'Only text', 'exclusive' => false],
];
if ($sections !== $want) echo 'FAIL markdown sections: got ' . json_encode($sections) . "\n";
$first = markdown_first_image("![v](/media/en/a.mp4)\n\n![x](javascript:a)\n\n![i](b.webp)", '/p/');
if ($first !== '/p/b.webp') echo 'FAIL markdown first image: got ' . json_encode($first) . "\n";
$excerpt = markdown_excerpt("![i](x.webp)\n\nPara **b** [l](/u) `c` *d*\n\n## H");
if ($excerpt !== 'Para b l c d') echo 'FAIL markdown excerpt: got ' . json_encode($excerpt) . "\n";
PHP
if out="$(php "$tmp/markdown.php" 2>&1)" && [ -z "$out" ]; then
    ok markdown
else
    echo "$out"
    failed=1
fi

# 8. the offered names are well-formed, and never a permanent link's own name
offered="$(php -r '$i = require "iso.php"; ksort($i); echo implode(" ", array_keys($i)), "\n", $i["standard"] ?? "", "\n", $i["nvidia"] ?? "", "\n";' 2>&1)"
keys="$(sed -n 1p <<<"$offered")"
standard="$(sed -n 2p <<<"$offered")"
nvidia="$(sed -n 3p <<<"$offered")"
problems=""
[ "$keys" = "nvidia standard" ] || problems+="keys are '$keys', not 'nvidia standard'; "
[[ "$standard" =~ ^borshevik-[0-9]{8}(-[0-9]+)?\.iso$ ]] || problems+="standard name '$standard' is malformed; "
[[ "$nvidia" =~ ^borshevik-nvidia-[0-9]{8}(-[0-9]+)?\.iso$ ]] || problems+="nvidia name '$nvidia' is malformed; "
if [ -z "$problems" ]; then ok offered-isos; else fail offered-isos "$problems"; fi

# 9. .htaccess: the permanent links, then the refused folders, then the routing to index.php
problems=""
lineno() { grep -nxF "$1" .htaccess | head -1 | cut -d: -f1; }
last_iso=0
for rule in \
    'RewriteRule ^iso/borshevik-stable\.iso$ download.php?variant=standard [L]' \
    'RewriteRule ^iso/borshevik-stable\.iso-CHECKSUM$ download.php?variant=standard&file=checksum [L]' \
    'RewriteRule ^iso/borshevik-nvidia-stable\.iso$ download.php?variant=nvidia [L]' \
    'RewriteRule ^iso/borshevik-nvidia-stable\.iso-CHECKSUM$ download.php?variant=nvidia&file=checksum [L]'; do
    n="$(lineno "$rule")"
    if [ -z "$n" ]; then problems+="missing: $rule; "; else [ "$n" -gt "$last_iso" ] && last_iso="$n"; fi
done
grep -qx 'RewriteEngine On' .htaccess || problems+="missing: RewriteEngine On; "
refuse="$(lineno 'RewriteRule ^(lib|templates|i18n|content)(/|$) - [F,L]')"
route="$(lineno 'RewriteRule ^ index.php [L]')"
[ -n "$refuse" ] || problems+="missing: the refusal of the source folders; "
[ -n "$route" ] || problems+="missing: the routing to index.php; "
grep -qxF 'RewriteCond %{REQUEST_FILENAME} !-f' .htaccess || problems+="missing: the !-f condition of the routing; "
grep -qxF 'RewriteCond %{REQUEST_FILENAME} !-d' .htaccess || problems+="missing: the !-d condition of the routing; "
if [ -n "$refuse" ] && [ -n "$route" ] && ! { [ "$last_iso" -lt "$refuse" ] && [ "$refuse" -lt "$route" ]; }; then
    problems+="out of order: permanent links, refused folders, routing; "
fi
if [ -z "$problems" ]; then ok htaccess; else fail htaccess "$problems"; fi

# 10. every section renders in the expected language, with the download buttons where they belong
mkdir "$tmp/site"
cp -r index.php iso.php download.php links.php lib i18n templates content media icons posts "$tmp/site/"
mkdir "$tmp/site/iso"
checksum="$(printf 'a%.0s' {1..64})"
if [ -n "$standard" ]; then
    truncate -s 2G "$tmp/site/iso/$standard"
    printf '%s  %s\n' "$checksum" "$standard" > "$tmp/site/iso/$standard-CHECKSUM"
fi
newest="$(ls posts | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}-' | sort | tail -1)"

render() { # path, lang, accept-language
    (cd "$tmp/site" && php -r '$_SERVER["REQUEST_URI"] = $argv[1];
        $_GET = $argv[2] === "" ? [] : ["lang" => $argv[2]];
        $_SERVER["HTTP_ACCEPT_LANGUAGE"] = $argv[3];
        include "index.php";' -- "$1" "$2" "$3" 2>&1)
}

check_render() { # path, name, lang, accept-language, expected html lang
    local page problems=""
    page="$(render "$1" "$3" "$4")"
    grep -q "<html lang=\"$5\">" <<<"$page" || problems+="not rendered in $5; "
    grep -q 'class="site-header"' <<<"$page" || problems+="no header; "
    ! grep -qE '(Warning|Notice|Deprecated|Fatal error|Parse error):' <<<"$page" || problems+="PHP error: $(grep -m1 -E '(Warning|Notice|Deprecated|Fatal error|Parse error):' <<<"$page"); "
    if [ "$1" = "/install" ]; then
        grep -qF "href=\"/iso/$standard\"" <<<"$page" || problems+="no link to the offered standard ISO; "
        grep -qF "href=\"/iso/$nvidia\"" <<<"$page" || problems+="no link to the offered NVIDIA ISO; "
        grep -q " · 2.0 GB" <<<"$page" || problems+="no standard ISO size; "
        grep -q "$checksum" <<<"$page" || problems+="no standard ISO checksum; "
        [ "$(grep -o ' · [0-9.]* GB' <<<"$page" | wc -l)" -le 1 ] || problems+="a size shown for the absent NVIDIA ISO; "
    fi
    if [ -z "$problems" ]; then ok "render $1 $2"; else fail "render $1 $2" "$problems"; fi
}

for path in / /install /install/rebase /news "/news/$newest"; do
    check_render "$path" "lang=ru"                  ru ""                        ru
    check_render "$path" "Accept-Language ru-RU"    "" "ru-RU,ru;q=0.9,en;q=0.8" ru
    check_render "$path" "Accept-Language de -> en" "" "de"                      en
done

# 11. served for real: 404s, refused folders, and download.php's redirects
port="$(php -r '$s = stream_socket_server("tcp://127.0.0.1:0"); echo explode(":", stream_socket_get_name($s, false))[1];')"
(cd "$tmp/site" && exec php -S "127.0.0.1:$port" index.php >/dev/null 2>&1) &
server_pid=$!
for _ in $(seq 50); do curl -s -o /dev/null "http://127.0.0.1:$port/iso.php" && break; sleep 0.1; done

check_status() { # path, expected code, text the page must hold (or "")
    local code body
    body="$(curl -s -w '\n%{http_code}' "http://127.0.0.1:$port$1")"
    code="$(tail -n1 <<<"$body")"
    if [ "$code" != "$2" ]; then
        fail "status $1" "got $code, expected $2"
    elif [ -n "$3" ] && ! grep -q "$3" <<<"$body"; then
        fail "status $1" "no '$3' in the page"
    else
        ok "status $1"
    fi
}

check_status "/"                          200 ""
check_status "/install/rebase/"           200 ""
check_status "/news/$newest/"             200 ""
check_status "/no-such-page"              404 'class="site-header"'
check_status "/news/2000-01-01-nothing"   404 'class="site-header"'
check_status "/news/..%2F..%2Findex.php"  404 'class="site-header"'
check_status "/templates/layout.php"      403 ""
check_status "/lib/site.php"              403 ""

# link previews: each page names its language in og:url, and its og:image is a file that is
# there, so Telegram and X show the right language and a picture
check_preview() { # path
    local page problems="" img url
    page="$(curl -s "http://127.0.0.1:$port$1")"
    url="$(grep -o '<meta property="og:url" content="[^"]*"' <<<"$page" | sed 's/.*content="//; s/"$//')"
    img="$(grep -o '<meta property="og:image" content="[^"]*"' <<<"$page" | sed 's/.*content="//; s/"$//')"
    [[ "$url" == "http://127.0.0.1:$port/"*"lang=ru" ]] || problems+="og:url '$url' does not name the language; "
    if [[ "$img" != "http://127.0.0.1:$port/"* ]]; then
        problems+="og:image '$img' is not an absolute address of the site; "
    elif [ "$(curl -s -o /dev/null -w '%{http_code}' "$img")" != 200 ]; then
        problems+="og:image '$img' is not there; "
    fi
    grep -q '<meta property="og:description" content="[^"]' <<<"$page" || problems+="no og:description; "
    if [ -z "$problems" ]; then ok "preview $1"; else fail "preview $1" "$problems"; fi
}

check_preview "/?lang=ru"
check_preview "/install?lang=ru"
check_preview "/news/$newest?lang=ru"

check_download() { # query, expected "code location-path"
    local got
    got="$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "http://127.0.0.1:$port/download.php?$1")"
    got="${got/http:\/\/127.0.0.1:$port/}"
    if [ "$got" = "$2" ]; then ok "download $1"; else fail "download $1" "got '$got', expected '$2'"; fi
}

check_download "variant=standard"               "302 /iso/$standard"
check_download "variant=nvidia"                 "302 /iso/$nvidia"
check_download "variant=standard&file=checksum" "302 /iso/$standard-CHECKSUM"
check_download "variant=bogus"                  "404 "

if [ "$failed" -eq 0 ]; then
    echo "all checks pass"
fi
exit "$failed"
