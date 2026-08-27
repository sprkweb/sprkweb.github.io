.DEFAULT_GOAL := help

HUGO_IMAGE ?= klakegg/hugo:ext-alpine
HUGO := $(shell command -v hugo 2>/dev/null)

ifeq ($(HUGO),)
run = docker run --rm -v "$(CURDIR)":/src $(HUGO_IMAGE)
run-server = docker run --rm -v "$(CURDIR)":/src -p 1313:1313 $(HUGO_IMAGE)
else
run = $(HUGO)
run-server = $(HUGO)
endif

.PHONY: help serve build check clean

help:
	@printf '%s\n' \
		'make serve  live preview → http://localhost:1313/' \
		'make build  production build (hugo --minify), same as CI' \
		'make check  verify the production build succeeds' \
		'make clean  remove public/ and resources/_gen/'

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
