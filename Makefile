.DEFAULT_GOAL := help

HUGO_IMAGE ?= klakegg/hugo:ext-alpine
HUGO_VERSION ?= 0.165.0
HUGO := $(shell command -v hugo 2>/dev/null)

ifeq ($(HUGO),)
run = docker run --rm -v "$(CURDIR)":/src $(HUGO_IMAGE)
run-server = docker run --rm -v "$(CURDIR)":/src -p 1313:1313 $(HUGO_IMAGE)
else
run = $(HUGO)
run-server = $(HUGO)
endif

.PHONY: help install serve build check clean

help:
	@printf '%s\n' \
		'make install  install Hugo Extended v$(HUGO_VERSION) + npm deps' \
		'make serve    live preview → http://localhost:1313/' \
		'make build    production build (hugo --minify), same as CI' \
		'make check    verify the production build succeeds' \
		'make clean    remove public/ and resources/_gen/'

# Idempotent: install pinned Hugo Extended (if missing) and npm deps.
# Linux downloads the prebuilt binary; macOS uses Homebrew.
install:
	@if command -v hugo >/dev/null 2>&1 && hugo version | grep -q 'v$(HUGO_VERSION).*extended'; then \
		echo "Hugo Extended v$(HUGO_VERSION) already installed"; \
	else \
		os=$$(uname -s); \
		if [ "$$os" = "Darwin" ]; then \
			echo "Installing Hugo Extended via Homebrew..."; \
			brew install hugo; \
		elif [ "$$os" = "Linux" ]; then \
			case "$$(uname -m)" in \
				x86_64) asset=linux-amd64;; \
				aarch64|arm64) asset=linux-arm64;; \
				*) echo "Unsupported Linux arch $$(uname -m); install Hugo Extended manually." >&2; exit 1;; \
			esac; \
			echo "Installing Hugo Extended v$(HUGO_VERSION) ($$asset)..."; \
			tmp=$$(mktemp -d); \
			curl -sSL -o "$$tmp/hugo.tar.gz" "https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_extended_$(HUGO_VERSION)_$$asset.tar.gz"; \
			tar -xzf "$$tmp/hugo.tar.gz" -C "$$tmp" hugo; \
			sudo install -m 0755 "$$tmp/hugo" /usr/local/bin/hugo; \
			rm -rf "$$tmp"; \
		else \
			echo "Unsupported OS $$os; install Hugo Extended manually or use Docker." >&2; exit 1; \
		fi; \
	fi
	@hugo version
	npm install --production=false

# Live reload. --bind 0.0.0.0 is required when Hugo runs inside Docker.
serve:
	$(run-server) server --bind 0.0.0.0 --disableFastRender

# Matches GitHub Actions: hugo --minify
build:
	$(run) --minify

check: build
	@echo "Build OK"

clean:
	rm -rf public resources/_gen .hugo_build.lock
