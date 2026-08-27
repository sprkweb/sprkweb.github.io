# Agent Instructions

Personal Hugo Extended blog. Default language is **Russian**, but **every page must have an English translation** (`*.ru.md` + `*.en.md`).

Preview: `make serve` → http://localhost:1313/. Verify: `make check` (same as CI: `hugo --minify`). Uses local Hugo Extended if installed, otherwise Docker `klakegg/hugo:ext-alpine`.

## Posts

Each post is a **leaf bundle**: `content/posts/<slug>/index.ru.md` **and** `index.en.md`, plus shared assets in that folder. RU URL has no prefix; EN is `/en/...`. Do not use the default archetype (`hugo new` emits a monolingual file without a language suffix).

```yaml
---
title: "..."
date: 2026-08-26
lastmod: 2026-08-26
tags: ["История разработки", "Кейс"]
---
```

- `lastmod` is shown only if it differs from `date`.
- Put `<!--more-->` after the opening paragraph; otherwise the whole post is the list summary.
- Long posts: `{{< table-of-contents >}}` after the intro.
- Raw HTML is allowed (`goldmark.renderer.unsafe`)

### Images

Not Markdown `![]()`. File must be a **page resource** in the post folder:

```
{{< img "screenshot.png" "Подпись" >}}
```

Fits to 674px WebP and renders a full-viewport `<figure class="full-width">`. Missing file → build error. Caption/alt is per-language: translate it in `index.en.md`, keep the same filename.

## Theme

- SCSS in `assets/sass/`, **4-space** indent. Light/dark via `prefers-color-scheme` CSS variables; content column is `70ch`.
- New UI strings go in both `i18n/ru.yaml` and `i18n/en.yaml`.
- Nav is `sectionPagesMenu: main` plus Contacts (`#contacts`) in `config.yaml`. Section `_index.*.md` `weight` orders items (posts = 100). A new section shows up in the menu automatically.
- Icons: `assets/images/<name>.svg`, referenced by name without extension.
