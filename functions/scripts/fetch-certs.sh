#!/usr/bin/env sh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="$ROOT/certs"
mkdir -p "$CERT_DIR"
curl -fsSL -o "$CERT_DIR/AppleRootCA-G3.cer" \
  https://www.apple.com/certificateauthority/AppleRootCA-G3.cer
echo "Apple root cert saved to $CERT_DIR/AppleRootCA-G3.cer"
