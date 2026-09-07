#!/bin/bash
# Builds the distributable archive (.tar.gz) of HTML Overlay Wallpaper for
# uploading to the KDE Store (store.kde.org -> Plasma Wallpaper Plugins).
#
# Unlike build.sh (which installs locally), this script:
#   1. Compiles the po/<lang>/*.po catalogs INTO the package, under
#      contents/locale/<lang>/LC_MESSAGES/, so that translations ship with a
#      Store/KNewStuff install (which does not run cmake/ki18n).
#   2. Packs everything into <id>-<version>.tar.gz with the top-level folder
#      named after the plugin id.
set -e

PLUGIN_ID="io.github.wyllianbs.htmloverlaywallpaper"
DOMAIN="plasma_wallpaper_$PLUGIN_ID"
ROOT="$(cd "$(dirname "$0")" && pwd)"
PKG="$ROOT/package"
PO="$ROOT/po"

VERSION="$(grep -Po '"Version"\s*:\s*"\K[^"]+' "$PKG/metadata.json" 2>/dev/null || echo "1.0.0")"

# -- 1. Translations bundled into the package ------------------------------
if command -v msgfmt &>/dev/null; then
    echo "-> Compiling translations into the package..."
    for po in "$PO"/*/"$DOMAIN.po"; do
        [ -e "$po" ] || continue
        lang="$(basename "$(dirname "$po")")"
        dest="$PKG/contents/locale/$lang/LC_MESSAGES"
        mkdir -p "$dest"
        msgfmt "$po" -o "$dest/$DOMAIN.mo" && echo "   OK $lang"
    done
else
    echo "-> WARNING: msgfmt (gettext) not found; the package will ship WITHOUT translations."
    echo "   Install it with: sudo apt install gettext"
fi

# -- 2. .tar.gz archive for the Store --------------------------------------
OUT="$ROOT/${PLUGIN_ID}-${VERSION}.tar.gz"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp -r "$PKG" "$STAGE/$PLUGIN_ID"
# do not ship unwanted artifacts
find "$STAGE/$PLUGIN_ID" -name '*.qmlc' -o -name '*.jsc' | xargs -r rm -f

tar -czf "$OUT" -C "$STAGE" "$PLUGIN_ID"

echo ""
echo "Archive ready for the KDE Store:"
echo "   $OUT"
echo ""
echo "   Top-level contents:"
tar -tzf "$OUT" | head -12
echo ""
echo "   Upload at: https://store.kde.org  (category: Plasma Wallpaper Plugins)"
