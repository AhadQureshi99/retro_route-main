#!/bin/bash
# Workaround for Stripe CocoaPods git clone failures (RPC failed, curl 18).
# Run this when on a stable connection (e.g. mobile hotspot), then run pod install.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENDOR_DIR="$SCRIPT_DIR/../vendor"
STRIPE_DIR="$VENDOR_DIR/stripe-ios"
TAG="25.0.1"

mkdir -p "$VENDOR_DIR"
cd "$VENDOR_DIR"

if [ -d "$STRIPE_DIR" ]; then
  echo "Stripe vendor already exists at $STRIPE_DIR"
  exit 0
fi

echo "Downloading stripe-ios $TAG..."

# Method 1: Try zip download (often more reliable than git clone)
ZIP_FILE="$VENDOR_DIR/stripe-ios.zip"
if curl -fL -o "$ZIP_FILE" "https://github.com/stripe/stripe-ios/archive/refs/tags/$TAG.zip" 2>/dev/null; then
  echo "Extracting..."
  unzip -q "$ZIP_FILE" -d "$VENDOR_DIR"
  mv "$VENDOR_DIR/stripe-ios-$TAG" "$STRIPE_DIR"
  rm "$ZIP_FILE"
  echo "Done! Run 'pod install' in ios/"
  exit 0
fi

# Method 2: Git clone (try a few times)
for i in 1 2 3; do
  echo "Attempt $i: git clone..."
  if git clone --depth 1 --branch "$TAG" https://github.com/stripe/stripe-ios.git "$STRIPE_DIR" 2>/dev/null; then
    echo "Done! Run 'pod install' in ios/"
    exit 0
  fi
  rm -rf "$STRIPE_DIR" 2>/dev/null || true
  sleep 2
done

echo "Failed. Try: 1) Use mobile hotspot  2) Run this script again"
exit 1
