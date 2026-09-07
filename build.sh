#!/bin/bash
# Installs the HTML wallpaper plugin directly with kpackagetool6.
# Requires neither cmake, make, ECM nor KDE headers.
set -e

PLUGIN_ID="io.github.wyllianbs.htmloverlaywallpaper"
PACKAGE_DIR="$(cd "$(dirname "$0")/package" && pwd)"

# Detect the available tool (Plasma 6 or 5)
if command -v kpackagetool6 &>/dev/null; then
    TOOL="kpackagetool6"
elif command -v kpackagetool5 &>/dev/null; then
    TOOL="kpackagetool5"
else
    echo "Error: kpackagetool6 (or kpackagetool5) not found."
    echo "Install it with:  sudo apt install plasma-framework"
    exit 1
fi

echo "Using:   $TOOL"
echo "Package: $PACKAGE_DIR"
echo ""

# Remove a previous installation if present
if $TOOL --type Plasma/Wallpaper --list 2>/dev/null | grep -q "$PLUGIN_ID"; then
    echo "-> Removing previous installation..."
    $TOOL --type Plasma/Wallpaper --remove "$PLUGIN_ID" || true
fi

# Install
echo "-> Installing plugin..."
$TOOL --type Plasma/Wallpaper --install "$PACKAGE_DIR"

# Compile and install translations into the user's locale directory.
# (No cmake/ki18n; uses gettext's msgfmt when available.)
PO_DIR="$(cd "$(dirname "$0")/po" && pwd)"
DOMAIN="plasma_wallpaper_$PLUGIN_ID"
if command -v msgfmt &>/dev/null && [ -d "$PO_DIR" ]; then
    LOCALE_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/locale"
    echo "-> Installing translations..."
    for po in "$PO_DIR"/*/"$DOMAIN.po"; do
        [ -e "$po" ] || continue
        lang="$(basename "$(dirname "$po")")"
        dest="$LOCALE_ROOT/$lang/LC_MESSAGES"
        mkdir -p "$dest"
        msgfmt "$po" -o "$dest/$DOMAIN.mo" && echo "   OK $lang"
    done
else
    echo "-> msgfmt (gettext) not found; skipping translations for this install."
    echo "   Install it with: sudo apt install gettext"
fi

echo ""
echo "Plugin installed successfully!"
echo ""
echo "   To activate, restart Plasmashell:"
echo "   kquitapp6 plasmashell && kstart plasmashell"
echo ""
echo "   Then go to: right-click the desktop -> Configure Desktop and Wallpaper"
echo "   -> Wallpaper type -> HTML Overlay Wallpaper"
