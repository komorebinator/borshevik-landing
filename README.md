# Borshevik Landing

The Borshevik Linux website, [borshevik.org](https://borshevik.org) — a small PHP site in English and Russian, picked by Accept-Language: a home page that shows Borshevik and offers the standard and NVIDIA ISOs with their size and checksum, step-by-step installation instructions, and news.

## Goals

- Explain and show what Borshevik is, and let a visitor download the right ISO in one click
- Take a newcomer from the download to a working desktop, step by step
- Keep the project's news in one place, each post written once in Markdown in both languages, so the site, the Telegram channel and X carry the same announcement
- What is on main is what is live — no manual uploads of the site; work waits on `experimental` until its pull request into main is merged

## Where things are

- `content/<lang>/` — the text of the home and installation pages, in Markdown
- `posts/YYYY-MM-DD-<slug>/` — one folder per news post: `ru.md`, `en.md` and its screenshots
- `i18n/` — the interface strings; `links.php` — the header links per language
- `templates/`, `lib/`, `index.php` — the layout and the small engine that renders it all
- `tests/check.sh` — the checks every deploy runs first

The site and its conventions are described in full in [`spec/`](spec/).
