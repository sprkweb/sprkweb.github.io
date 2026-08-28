# Agent Instructions

Personal Hugo Extended blog. Default language is **Russian**, but **every page must have an English translation** (`*.ru.md` + `*.en.md`).

The blog is based on principles of simplicity, minimalism, and user-friendliness. UI is simple yet pleasing. Codebase is simple and straightforward. Therefore, it is statically generated in HTML and CSS, which is delivered to the user quickly and without any unnecessary imports.

Preview: `make serve` → http://localhost:1313/. Verify: `make check` (production build, same as PR CI and deploy: `hugo --minify`) and `make lighthouse` (Lighthouse on key pages; needs Chrome or Chromium). Uses local Hugo Extended if installed (`make install`), otherwise Docker `klakegg/hugo:ext-alpine`.

After theme, layout, markup, or asset changes, run `make lighthouse` and keep category scores at the budgets in `lighthouserc.json` (currently ≥ 0.9). HTML reports land in `.lighthouseci/reports/` (gitignored).

## Homepage

The homepage is a short bio plus a chronological **feed** of posts and apps. App titles open in a new tab; posts stay on the site.

## Posts

Each post is a **leaf bundle**: `content/posts/<slug>/index.ru.md` **and** `index.en.md`, plus shared assets in that folder. RU URL has no prefix; EN is `/en/...`. Do not use the default archetype (`hugo new` emits a monolingual file without a language suffix). The `/posts/` list still exists (RSS, breadcrumbs, old links) but is not in the main menu.

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

## Apps

External apps use the same **leaf bundle** shape in a headless section: `content/works/<slug>/index.ru.md` **and** `index.en.md`. They appear only in the homepage feed (no HTML page, no menu item). Missing `externalURL` → build error.

```yaml
---
title: "..."
date: 2026-07-28
externalURL: https://example.com/app/
---
```

One-sentence description in the body (no `<!--more-->` needed). Language-specific URLs go in the matching `index.*.md`.

## Theme

- SCSS in `assets/sass/`, **4-space** indent. Light/dark via `prefers-color-scheme` CSS variables; content column is `70ch`.
- New UI strings go in both `i18n/ru.yaml` and `i18n/en.yaml`.
- Nav is `sectionPagesMenu: main` plus Contacts (`#contacts`) in `config.yaml`, minus `posts` and `works`. Section `_index.*.md` `weight` orders remaining items. A new visible section shows up in the menu automatically.
- Icons: `assets/images/<name>.svg`, referenced by name without extension.
