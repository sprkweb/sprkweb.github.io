# Agent Instructions

Personal Hugo Extended blog. Simplicity and minimalism: static HTML and CSS, no extra JS or imports. UI is simple and pleasant; the codebase stays small and straightforward.

**Language.** Default is Russian; every page needs an English translation (`*.ru.md` + `*.en.md`). New UI strings go in both `i18n/ru.yaml` and `i18n/en.yaml`. RU URLs have no prefix; EN is `/en/...`.

**Architecture.** Homepage = short bio + chronological feed of posts and apps. Shared assets live in the bundle folder. Header is contacts plus the language switcher (no site menu). Styles: `assets/sass/`, light/dark via `prefers-color-scheme`. Do not use `hugo new` (the archetype is monolingual).

**Test.** `make serve` → http://localhost:1313/. `make check` is the production build (`hugo --minify`, same as CI). After theme, layout, markup, or asset changes, `make lighthouse` (needs Chrome/Chromium; budgets in `lighthouserc.json`). Uses local Hugo Extended if installed (`make install`), otherwise Docker.

**This file.** Keep AGENTS.md short. Record the project's spirit, architecture, how to test, and durable non-obvious pitfalls — not one-off recipes. Update it when those facts change; do not grow it with one-off instructions.

## Posts

Posts (`content/posts/<slug>/`) are leaf bundles with a real page.

```yaml
---
title: "..."
date: 2026-08-26
lastmod: 2026-08-26
description: "Одно предложение про пост."
tags: ["История разработки", "Кейс"]
---
```

- `lastmod` is shown only if it differs from `date`.
- `description` is a one-sentence blurb for the feed (and the page meta tag)
- Long posts: `{{< table-of-contents >}}` after the intro.

Images are page resources, not Markdown `![]()`:

```
{{< img "screenshot.png" "Подпись" >}}
```

Caption/alt is per-language; keep the same filename. Missing file → build error.

## Apps

Apps (`content/works/<slug>/`) use the same bundle shape but are headless: they appear only in the feed and require `externalURL`

```yaml
---
title: "..."
date: 2026-07-28
externalURL: https://example.com/app/
---
```

One-sentence body. Missing `externalURL` → build error. Language-specific URLs go in the matching `index.*.md`.
