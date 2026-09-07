/*
    SPDX-FileCopyrightText: 2013 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2014 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2019 David Redondo <kde@david-redondo.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.newstuff as NewStuff

Item {
    id: thumbnailsComponent
    anchors.fill: parent

    property alias view: wallpapersGrid.view
    property var screenSize: Qt.size(Screen.width, Screen.height)

    // Domínio de tradução local — NÃO usar root.i18nDomain aqui: o id "root"
    // do config.qml não resolve de forma confiável neste componente carregado.
    readonly property string i18nDomain: "plasma_wallpaper_io.github.wyllianbs.htmloverlaywallpaper"

    readonly property QtObject imageModel: (configDialog.currentWallpaper === "org.kde.image") ? imageWallpaper.wallpaperModel : imageWallpaper.slideFilterModel

    // Marca/desmarca todas as imagens do slideshow (grava em UncheckedSlides).
    // Usa um Instantiator não-visual para percorrer todas as linhas do modelo,
    // já que o setData da role "checked" só é acessível pelo contexto do delegate.
    Instantiator {
        id: checkAllHelper
        model: thumbnailsComponent.imageModel
        delegate: QtObject {
            function apply(value) { model.checked = value }
        }
    }

    function setAllChecked(value) {
        for (let i = 0; i < checkAllHelper.count; ++i) {
            const obj = checkAllHelper.objectAt(i);
            if (obj) {
                obj.apply(value);
            }
        }
    }

    Connections {
        target: imageWallpaper
        function onLoadingChanged(loading: bool) {
            if (loading) {
                return;
            }
            if (configDialog.currentWallpaper === "org.kde.image" && imageModel.indexOf(cfg_Image) < 0) {
                imageWallpaper.addUsersWallpaper(cfg_Image);
            }
            wallpapersGrid.resetCurrentIndex();
        }
    }

    Connections {
        target: root
        function onWallpaperBrowseCompleted() {
            // Scroll to top to view added images
            wallpapersGrid.view.positionViewAtIndex(0, GridView.Beginning);
            wallpapersGrid.resetCurrentIndex(); // BUG 455129
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // FIXME: can't make it a header of the grid view due to the lack of a
        // headerPositioning: property; see https://bugreports.qt.io/browse/QTBUG-117035.
        Kirigami.InlineViewHeader {
            Layout.fillWidth: true
            text: i18nd("plasma_wallpaper_org.kde.image", "Images")
            actions: [
                Kirigami.Action {
                    // Botão único que alterna: se tudo já está marcado, desmarca
                    // tudo; caso contrário, marca tudo. Reflete o estado atual
                    // (reage também às marcações individuais via uncheckedSlides).
                    // Sempre visível: plugin sempre slideshow (ver nota no CheckBox
                    // de WallpaperDelegate sobre configDialog.currentWallpaper).
                    readonly property bool allChecked: (imageWallpaper.uncheckedSlides || []).length === 0
                    visible: true
                    icon.name: allChecked ? "edit-select-none" : "edit-select-all"
                    text: allChecked ? i18nd(thumbnailsComponent.i18nDomain, "Deselect All")
                                     : i18nd(thumbnailsComponent.i18nDomain, "Select All")
                    onTriggered: thumbnailsComponent.setAllChecked(!allChecked)
                },
                Kirigami.Action {
                    icon.name: "list-add-symbolic"
                    text: i18ndc("plasma_wallpaper_org.kde.image", "@action:button the thing being added is an image file", "Add…")
                    Accessible.name: i18ndc("plasma_wallpaper_org.kde.image", "@action:button", "Add Wallpaper Image…")
                    visible: configDialog.currentWallpaper == "org.kde.image"
                    onTriggered: root.openChooserDialog();
                },
                NewStuff.Action {
                    configFile: Kirigami.Settings.isMobile ? "wallpaper-mobile.knsrc" : "wallpaper.knsrc"
                    text: i18ndc("plasma_wallpaper_org.kde.image", "@action:button the new things being gotten are wallpapers", "Get New…")
                    Accessible.name: i18ndc("plasma_wallpaper_org.kde.image", "@action:button", "Get New Wallpaper Images…")
                    viewMode: NewStuff.Page.ViewMode.Preview
                }
            ]
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.backgroundColor

            KCM.GridView {
                id: wallpapersGrid
                anchors.fill: parent

                framedView: false


                function resetCurrentIndex() {
                    //that min is needed as the module will be populated in an async way
                    //and only on demand so we can't ensure it already exists
                    if (configDialog.currentWallpaper === "org.kde.image") {
                        wallpapersGrid.view.currentIndex = Qt.binding(() => configDialog.currentWallpaper === "org.kde.image" ?  Math.min(imageModel.indexOf(cfg_Image), imageModel.count - 1) : 0);
                    }
                }

                //kill the space for label under thumbnails
                view.model: thumbnailsComponent.imageModel

                // Tamanho da célula responsivo à LARGURA da janela de Settings,
                // preservando a proporção da tela. Ao alargar a janela, as
                // miniaturas acompanham (e o nº de colunas se ajusta).
                readonly property real screenAspect: (screenSize.width > 0 && screenSize.height > 0)
                                                     ? screenSize.height / screenSize.width : 9 / 16
                readonly property int columns: Math.max(2, Math.floor(width / (Kirigami.Units.gridUnit * 9)))
                readonly property real cellW: Math.max(Kirigami.Units.gridUnit * 6,
                                                       width / columns - Kirigami.Units.smallSpacing * 2)

                view.implicitCellWidth: cellW
                view.implicitCellHeight: cellW * screenAspect + Kirigami.Units.gridUnit * 3

                view.reuseItems: true

                view.delegate: WallpaperDelegate {
                    color: cfg_Color
                }
            }
        }
    }

    KCM.SettingHighlighter {
        target: wallpapersGrid
        highlight: configDialog.currentWallpaper === "org.kde.image" && cfg_Image != cfg_ImageDefault
    }
}
