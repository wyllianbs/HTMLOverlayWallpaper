#! /usr/bin/env bash
# Extrai as strings marcadas com i18n*() para o template de tradução (.pot).
# Uso (dentro do checkout, com o gettext do KDE disponível):
#   $ ./Messages.sh
# Gera: po/plasma_wallpaper_io.github.wyllianbs.htmloverlaywallpaper.pot
#
# Requer as variáveis $XGETTEXT e $podir definidas pelo ambiente de
# extração do KDE (l10n). Fora dele, defina manualmente, por exemplo:
#   podir=po XGETTEXT="xgettext --from-code=UTF-8 -C -kde \
#     -ci18n -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
#     -ki18nd:2 -ki18ndc:2c,3 -ki18ndp:2,3 -ki18ndcp:2c,3,4" ./Messages.sh

$XGETTEXT `find . -name '*.qml' -o -name '*.js'` \
    -o "$podir/plasma_wallpaper_io.github.wyllianbs.htmloverlaywallpaper.pot"
