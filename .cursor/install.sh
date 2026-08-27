#!/usr/bin/env bash
# Idempotent install for the Hugo Extended blog Cloud Agent environment.
set -euo pipefail

HUGO_VERSION="0.165.0"

if ! command -v hugo >/dev/null 2>&1 || ! hugo version | grep -q "v${HUGO_VERSION}.*extended"; then
    echo "Installing Hugo Extended v${HUGO_VERSION}..."
    tmp="$(mktemp -d)"
    curl -sSL -o "${tmp}/hugo.tar.gz" \
        "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
    tar -xzf "${tmp}/hugo.tar.gz" -C "${tmp}" hugo
    sudo install -m 0755 "${tmp}/hugo" /usr/local/bin/hugo
    rm -rf "${tmp}"
fi

hugo version

# Match CI (npm install --production=false); currently no runtime deps.
npm install --production=false
