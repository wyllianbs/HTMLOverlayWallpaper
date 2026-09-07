/*
 * HTML Wallpaper Overlay — Configuração (Plasma 6 / Wayland)
 *
 * ESTRUTURA CORRETA para Plasma 6:
 * - O elemento RAIZ deve ser um ColumnLayout (não Item).
 *   O framework injeta a largura; o ColumnLayout expande a altura naturalmente.
 * - id "root" no elemento raiz é obrigatório: SlideshowComponent,
 *   ThumbnailsComponent e WallpaperDelegate chamam root.openChooserDialog()
 *   e root.configurationChanged() via resolução de escopo QML.
 * - "imageWallpaper" e "configDialog" devem estar no escopo raiz.
 * - SlideshowComponent carregado via source (não setSource+params) para
 *   herdar o escopo QML e resolver root, imageWallpaper, cfg_* etc.
 *
 * i18n: strings de UI usam i18nd() com o domínio do próprio plugin
 * ("plasma_wallpaper_io.github.wyllianbs.htmloverlaywallpaper"). O idioma-fonte
 * é o inglês;
 * as traduções ficam em po/<lang>/ e são instaladas por ki18n_install(po).
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.plasma.wallpapers.image as PlasmaWallpaper
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

ColumnLayout {
    id: root

    // Domínio de tradução deste plugin
    readonly property string i18nDomain: "plasma_wallpaper_io.github.wyllianbs.htmloverlaywallpaper"

    // Alias para que SlideshowComponent encontre "appearanceRoot" no escopo
    property alias appearanceRoot: root

    spacing: 0

    // configDialog.currentWallpaper é lido por ThumbnailsComponent e WallpaperDelegate
    property var configDialog: ({ currentWallpaper: "org.kde.slideshow" })

    property var wallpaperConfiguration: wallpaper.configuration
    property var parentLayout: null
    property var screenSize: Qt.size(Screen.width, Screen.height)

    // ── cfg_* — slideshow de fundo ───────────────────────────────────────────
    // Devem existir no escopo raiz: componentes KDE os resolvem pelo nome.
    property color  cfg_Color
    property color  cfg_ColorDefault
    property string cfg_Image
    property string cfg_ImageDefault
    property int    cfg_FillMode
    property int    cfg_FillModeDefault
    property int    cfg_SlideshowMode
    property int    cfg_SlideshowModeDefault
    property bool   cfg_SlideshowFoldersFirst
    property bool   cfg_SlideshowFoldersFirstDefault: false
    property bool   cfg_Blur: false
    property bool   cfg_BlurDefault: false
    property var    cfg_SlidePaths:           []
    property var    cfg_SlidePathsDefault:    []
    property int    cfg_SlideInterval:        0
    property int    cfg_SlideIntervalDefault: 0
    property var    cfg_UncheckedSlides:      []
    property var    cfg_UncheckedSlidesDefault: []
    property int    cfg_SlideshowPanelHeight:        320
    property int    cfg_SlideshowPanelHeightDefault: 320

    // ── cfg_* — overlay HTML ─────────────────────────────────────────────────
    property alias cfg_DisplayPage:    urlField.text
    property string cfg_PageParams:     ""
    property alias cfg_ZoomFactor:     zoomSlider.value
    property alias cfg_InsecureHTTPS:  insecureCheck.checked
    property alias cfg_OverlayWidth:   widthSpin.value
    property alias cfg_OverlayHeight:  heightSpin.value
    property string cfg_Position:      "center"
    property alias cfg_MarginTop:      mtSpin.value
    property alias cfg_MarginBottom:   mbSpin.value
    property alias cfg_MarginLeft:     mlSpin.value
    property alias cfg_MarginRight:    mrSpin.value
    property alias cfg_RefreshSeconds: refreshSpin.value
    property int   cfg_ReloadNonce:        0
    property int   cfg_ReloadNonceDefault: 0

    // ── Sync slideshow → imageWallpaper ──────────────────────────────────────
    onCfg_SlidePathsChanged:            { if (cfg_SlidePaths)        imageWallpaper.slidePaths            = cfg_SlidePaths }
    onCfg_UncheckedSlidesChanged:       { if (cfg_UncheckedSlides)   imageWallpaper.uncheckedSlides       = cfg_UncheckedSlides }
    onCfg_SlideshowModeChanged:         { if (cfg_SlideshowMode)     imageWallpaper.slideshowMode         = cfg_SlideshowMode }
    onCfg_SlideshowFoldersFirstChanged: { imageWallpaper.slideshowFoldersFirst = cfg_SlideshowFoldersFirst }

    signal configurationChanged()
    signal wallpaperBrowseCompleted()

    function openChooserDialog() {
        const dialogComponent = Qt.createComponent("AddFileDialog.qml")
        if (dialogComponent.status === Component.Ready) {
            dialogComponent.createObject(root)
        } else {
            console.warn("AddFileDialog.qml não carregou:", dialogComponent.errorString())
        }
    }

    // imageWallpaper DEVE estar no escopo raiz
    PlasmaWallpaper.ImageBackend {
        id: imageWallpaper
        renderingMode: PlasmaWallpaper.ImageBackend.SlideShow
        targetSize:    Qt.size(root.screenSize.width  * Screen.devicePixelRatio,
                               root.screenSize.height * Screen.devicePixelRatio)
        onSlidePathsChanged:            cfg_SlidePaths            = slidePaths
        onUncheckedSlidesChanged:       cfg_UncheckedSlides       = uncheckedSlides
        onSlideshowModeChanged:         cfg_SlideshowMode         = slideshowMode
        onSlideshowFoldersFirstChanged: cfg_SlideshowFoldersFirst = slideshowFoldersFirst
        onSettingsChanged:              root.configurationChanged()
    }

    // ════════════════════════════════════════════════════
    // PAPEL DE PAREDE — SLIDESHOW
    // ════════════════════════════════════════════════════
    Label {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.topMargin: 8; Layout.bottomMargin: 4
        text: i18nd(root.i18nDomain, "Wallpaper (Slideshow)"); font.bold: true; opacity: 0.85
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.bottomMargin: 4
        columns: 2; columnSpacing: 8; rowSpacing: 6

        Label { text: i18nd(root.i18nDomain, "Positioning:"); Layout.minimumWidth: lw }
        ComboBox {
            id: fillModeBox
            Layout.fillWidth: true
            textRole: "text"; valueRole: "value"
            model: [
                { value: Image.PreserveAspectCrop, text: i18nd(root.i18nDomain, "Scaled and Cropped")       },
                { value: Image.Stretch,            text: i18nd(root.i18nDomain, "Scaled")                   },
                { value: Image.PreserveAspectFit,  text: i18nd(root.i18nDomain, "Scaled, Keep Proportions") },
                { value: Image.Pad,                text: i18nd(root.i18nDomain, "Centered")                 },
                { value: Image.Tile,               text: i18nd(root.i18nDomain, "Tiled")                    },
            ]
            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === cfg_FillMode) { currentIndex = i; break }
                }
            }
            onActivated: cfg_FillMode = currentValue
        }

        Label {
            text: i18nd(root.i18nDomain, "Background:")
            Layout.minimumWidth: lw
            visible: cfg_FillMode === Image.PreserveAspectFit || cfg_FillMode === Image.Pad
        }
        RowLayout {
            Layout.fillWidth: true
            visible: cfg_FillMode === Image.PreserveAspectFit || cfg_FillMode === Image.Pad
            CheckBox {
                    id: blurCheck
                    text: i18nd(root.i18nDomain, "Blur")
                    checked: cfg_Blur
                    onToggled: cfg_Blur = checked
                }
            Rectangle {
                width: 24; height: 24; radius: 4
                color: cfg_Color
                border.color: "#60ffffff"; border.width: 1
                visible: !cfg_Blur
                MouseArea {
                        id: colorMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: colorDialog.open()
                    }
                ToolTip.text: i18nd(root.i18nDomain, "Background color"); ToolTip.visible: colorMouseArea.containsMouse
            }
            ColorDialog {
                id: colorDialog
                selectedColor: cfg_Color
                onAccepted: cfg_Color = selectedColor
            }
        }
    }

    // SlideshowComponent — pastas, miniaturas, ordem, intervalo
    // Usa source (não setSource+params) para herdar escopo QML do pai
    // Altura ajustável pela alça de arrasto abaixo (persistida em SlideshowPanelHeight)
    readonly property int slideshowPanelMin: 200
    readonly property int slideshowPanelMax: 900

    Loader {
        id: slideshowLoader
        Layout.fillWidth: true
        Layout.preferredHeight: cfg_SlideshowPanelHeight
        Layout.minimumHeight: root.slideshowPanelMin
        Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.bottomMargin: 0
        source: "SlideshowComponent.qml"
    }

    // Alça de arrasto para redimensionar a altura da região Folders/Images
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.rightMargin: 12
        implicitHeight: 12

        Rectangle {
            anchors.centerIn: parent
            width: 48; height: 4; radius: 2
            color: (panelDrag.pressed || panelDrag.containsMouse)
                   ? Kirigami.Theme.highlightColor : "#60ffffff"
        }

        MouseArea {
            id: panelDrag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeVerCursor
            preventStealing: true

            property real startY: 0
            property int  startH: 0

            onPressed: (mouse) => {
                startY = mapToItem(root, mouse.x, mouse.y).y
                startH = cfg_SlideshowPanelHeight
            }
            onPositionChanged: (mouse) => {
                if (!pressed) return
                var curY = mapToItem(root, mouse.x, mouse.y).y
                var nh = startH + (curY - startY)
                cfg_SlideshowPanelHeight = Math.max(root.slideshowPanelMin,
                                                    Math.min(root.slideshowPanelMax, Math.round(nh)))
            }
            onDoubleClicked: cfg_SlideshowPanelHeight = cfg_SlideshowPanelHeightDefault

            ToolTip.text: i18nd(root.i18nDomain, "Drag to resize · double-click to reset")
            ToolTip.visible: containsMouse && !pressed
        }
    }

    Rectangle {
        Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12
        Layout.topMargin: 2; Layout.bottomMargin: 2; height: 1; color: "#40ffffff"
    }

    // ════════════════════════════════════════════════════
    // PÁGINA HTML
    // ════════════════════════════════════════════════════
    Label {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.topMargin: 8; Layout.bottomMargin: 4
        text: i18nd(root.i18nDomain, "HTML Page"); font.bold: true; opacity: 0.85
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.bottomMargin: 8
        columns: 2; columnSpacing: 8; rowSpacing: 6

        Label { text: i18nd(root.i18nDomain, "URL:"); Layout.minimumWidth: lw }
        TextField {
            id: urlField; Layout.fillWidth: true
            placeholderText: i18nd(root.i18nDomain, "https://example.com  or  file:///path/page.html")
        }


        Label { text: i18nd(root.i18nDomain, "Zoom:"); Layout.minimumWidth: lw }
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Slider {
                id: zoomSlider; Layout.fillWidth: true
                from: 0.1; to: 4.0; stepSize: 0.05; snapMode: Slider.SnapAlways
            }
            Label { text: zoomSlider.value.toFixed(2) + "×"; Layout.minimumWidth: 44 }
        }

        Label { text: i18nd(root.i18nDomain, "Insecure HTTPS:"); Layout.minimumWidth: lw }
        CheckBox { id: insecureCheck }

        Label { text: i18nd(root.i18nDomain, "Auto refresh:"); Layout.minimumWidth: lw }
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            SpinBox {
                id: refreshSpin; from: 0; to: 86400; stepSize: 5
                editable: true; Layout.minimumWidth: 100
            }
            Label {
                text: refreshSpin.value === 0 ? i18nd(root.i18nDomain, "disabled")
                    : refreshSpin.value < 60   ? i18ndc(root.i18nDomain, "@label short for seconds", "%1 s", refreshSpin.value)
                    : i18ndc(root.i18nDomain, "@label short for minutes", "%1 min", Math.floor(refreshSpin.value / 60))
            }
        }

        Label { text: i18nd(root.i18nDomain, "Reload:"); Layout.minimumWidth: lw }
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Button {
                icon.name: "view-refresh"
                text: i18nd(root.i18nDomain, "Reload now")
                onClicked: {
                    // Mantém o KCM em sincronia (caminho do Apply)…
                    cfg_ReloadNonce = cfg_ReloadNonce + 1
                    // …e tenta o reload imediato gravando a config na hora,
                    // sem exigir Apply. Grava só a chave ReloadNonce; edições
                    // não aplicadas (URL, zoom…) permanecem no buffer do KCM.
                    if (wallpaperConfiguration) {
                        wallpaperConfiguration.ReloadNonce = cfg_ReloadNonce
                        if (typeof wallpaperConfiguration.writeConfig === "function")
                            wallpaperConfiguration.writeConfig()
                    }
                }
                ToolTip.text: i18nd(root.i18nDomain, "Reloads the HTML overlay.")
                ToolTip.visible: hovered
            }
            Item { Layout.fillWidth: true }
        }
    }

    Rectangle {
        Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12
        Layout.topMargin: 2; Layout.bottomMargin: 2; height: 1; color: "#40ffffff"
    }

    // ════════════════════════════════════════════════════
    // POSIÇÃO E TAMANHO DO OVERLAY
    // ════════════════════════════════════════════════════
    Label {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.topMargin: 8; Layout.bottomMargin: 4
        text: i18nd(root.i18nDomain, "Overlay Position and Size"); font.bold: true; opacity: 0.85
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.bottomMargin: 8
        columns: 4; columnSpacing: 8; rowSpacing: 6

        Label { text: i18nd(root.i18nDomain, "Width (px):"); Layout.minimumWidth: lw }
        SpinBox {
            id: widthSpin; from: 0; to: 7680; stepSize: 10
            editable: true; Layout.minimumWidth: 100
            ToolTip.text: i18nd(root.i18nDomain, "0 = full screen width"); ToolTip.visible: hovered
        }
        Label { text: i18nd(root.i18nDomain, "Height (px):"); horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
        SpinBox {
            id: heightSpin; from: 0; to: 4320; stepSize: 10
            editable: true; Layout.minimumWidth: 100
            ToolTip.text: i18nd(root.i18nDomain, "0 = full screen height"); ToolTip.visible: hovered
        }

        Label { text: i18nd(root.i18nDomain, "Anchor:"); Layout.minimumWidth: lw }
        ComboBox {
            id: positionBox; Layout.columnSpan: 3; Layout.fillWidth: true
            textRole: "text"; valueRole: "value"
            model: [
                { value: "top-left",     text: "↖  " + i18nd(root.i18nDomain, "Top left")      },
                { value: "top",          text: "↑  " + i18nd(root.i18nDomain, "Top center")    },
                { value: "top-right",    text: "↗  " + i18nd(root.i18nDomain, "Top right")     },
                { value: "left",         text: "←  " + i18nd(root.i18nDomain, "Center left")   },
                { value: "center",       text: "✛  " + i18nd(root.i18nDomain, "Center")        },
                { value: "right",        text: "→  " + i18nd(root.i18nDomain, "Center right")  },
                { value: "bottom-left",  text: "↙  " + i18nd(root.i18nDomain, "Bottom left")   },
                { value: "bottom",       text: "↓  " + i18nd(root.i18nDomain, "Bottom center") },
                { value: "bottom-right", text: "↘  " + i18nd(root.i18nDomain, "Bottom right")  },
            ]
            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === cfg_Position) { currentIndex = i; break }
                }
            }
            onActivated: cfg_Position = currentValue
        }
    }

    Rectangle {
        Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12
        Layout.topMargin: 2; Layout.bottomMargin: 2; height: 1; color: "#40ffffff"
    }

    // ════════════════════════════════════════════════════
    // MARGENS
    // ════════════════════════════════════════════════════
    Label {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.topMargin: 8; Layout.bottomMargin: 4
        text: i18nd(root.i18nDomain, "Overlay Margins (px)"); font.bold: true; opacity: 0.85
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.bottomMargin: 12
        columns: 4; columnSpacing: 8; rowSpacing: 6

        Label { text: i18nd(root.i18nDomain, "Top:");     Layout.minimumWidth: lw }
        SpinBox { id: mtSpin; from: -4000; to: 4000; editable: true; Layout.minimumWidth: 100 }
        Label { text: i18nd(root.i18nDomain, "Bottom:");    horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
        SpinBox { id: mbSpin; from: -4000; to: 4000; editable: true; Layout.minimumWidth: 100 }

        Label { text: i18nd(root.i18nDomain, "Left:"); Layout.minimumWidth: lw }
        SpinBox { id: mlSpin; from: -4000; to: 4000; editable: true; Layout.minimumWidth: 100 }
        Label { text: i18nd(root.i18nDomain, "Right:");  horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
        SpinBox { id: mrSpin; from: -4000; to: 4000; editable: true; Layout.minimumWidth: 100 }
    }

    readonly property int lw: 130
}
