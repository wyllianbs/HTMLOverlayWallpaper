/*
 * HTML Wallpaper Overlay — KDE Plasma 6 / Wayland
 *
 * Fundo: slideshow nativo via org.kde.plasma.wallpapers.image (ImageBackend)
 * Overlay: página HTML em região configurável da tela (WebEngineView)
 */

import QtQuick
import QtWebEngine
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.wallpapers.image as Wallpaper
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    // ── Configurações — slideshow de fundo ───────────────────────────────────
    readonly property int    cfg_fillMode:            wallpaper.configuration.FillMode
    readonly property color  cfg_color:               wallpaper.configuration.Color
    readonly property bool   cfg_blur:                wallpaper.configuration.Blur
    readonly property int    cfg_slideInterval:       wallpaper.configuration.SlideInterval
    readonly property var    cfg_slidePaths:          wallpaper.configuration.SlidePaths
    readonly property int    cfg_slideshowMode:       wallpaper.configuration.SlideshowMode
    readonly property bool   cfg_slideshowFolders:    wallpaper.configuration.SlideshowFoldersFirst
    readonly property var    cfg_uncheckedSlides:     wallpaper.configuration.UncheckedSlides

    // ── Configurações — overlay HTML ─────────────────────────────────────────
    readonly property string cfg_url:          wallpaper.configuration.DisplayPage
    // cfg_pageParams removido — parâmetros incluídos diretamente na URL
    readonly property double cfg_zoom:         wallpaper.configuration.ZoomFactor
    readonly property bool   cfg_insecure:     wallpaper.configuration.InsecureHTTPS
    readonly property int    cfg_width:        wallpaper.configuration.OverlayWidth
    readonly property int    cfg_height:       wallpaper.configuration.OverlayHeight
    readonly property string cfg_position:     wallpaper.configuration.Position
    readonly property int    cfg_marginTop:    wallpaper.configuration.MarginTop
    readonly property int    cfg_marginBottom: wallpaper.configuration.MarginBottom
    readonly property int    cfg_marginLeft:   wallpaper.configuration.MarginLeft
    readonly property int    cfg_marginRight:  wallpaper.configuration.MarginRight
    readonly property int    cfg_refreshSec:   wallpaper.configuration.RefreshSeconds

    // ── URL final com parâmetros injetados ───────────────────────────────────
    readonly property string finalUrl: cfg_url.trim()

    // ── Ações de contexto (igual ao slideshow oficial) ───────────────────────
    contextualActions: [
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_org.kde.image", "Open Wallpaper Image")
            icon.name: "document-open"
            onTriggered: imageView.mediaProxy.openModelImage()
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_org.kde.image", "Next Wallpaper Image")
            icon.name: "user-desktop"
            onTriggered: imageWallpaper.nextSlide()
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_io.github.wyllianbs.htmloverlaywallpaper", "Reload HTML Page")
            icon.name: "view-refresh"
            onTriggered: webView.reload()
        }
    ]

    // Salva posição do slide ao sair
    Connections {
        target: Qt.application
        function onAboutToQuit() { root.configuration.writeConfig() }
    }

    Component.onCompleted: {
        root.configuration.PreviewImage = "null"
        root.loading = true
    }

    // ── Fundo: ImageStackView + ImageBackend (igual ao org.kde.slideshow) ────
    ImageStackView {
        id: imageView
        anchors.fill: parent

        fillMode:    root.cfg_fillMode
        configColor: root.cfg_color
        blur:        root.cfg_blur
        source:      imageWallpaper.image
        sourceSize:  Qt.size(root.width * Screen.devicePixelRatio,
                             root.height * Screen.devicePixelRatio)
        wallpaperInterface: root

        Wallpaper.ImageBackend {
            id: imageWallpaper
            configMap:              root.configuration
            usedInConfig:           false
            renderingMode:          Wallpaper.ImageBackend.SlideShow
            targetSize:             imageView.sourceSize
            slidePaths:             root.cfg_slidePaths
            slideTimer:             root.cfg_slideInterval
            slideshowMode:          root.cfg_slideshowMode
            slideshowFoldersFirst:  root.cfg_slideshowFolders
            uncheckedSlides:        root.cfg_uncheckedSlides

            function writeImageConfig(newImage) {
                root.configuration.Image = newImage
            }
        }
    }

    Component.onDestruction: {
        root.configuration.writeConfig()
    }

    // ── Posição do overlay HTML ───────────────────────────────────────────────
    function computeGeometry() {
        var sw = width, sh = height
        var ow = cfg_width  > 0 ? cfg_width  : sw
        var oh = cfg_height > 0 ? cfg_height : sh
        var ax = 0.5, ay = 0.5
        switch (cfg_position) {
            case "top-left":     ax = 0.0; ay = 0.0; break
            case "top":          ax = 0.5; ay = 0.0; break
            case "top-right":    ax = 1.0; ay = 0.0; break
            case "left":         ax = 0.0; ay = 0.5; break
            case "center":       ax = 0.5; ay = 0.5; break
            case "right":        ax = 1.0; ay = 0.5; break
            case "bottom-left":  ax = 0.0; ay = 1.0; break
            case "bottom":       ax = 0.5; ay = 1.0; break
            case "bottom-right": ax = 1.0; ay = 1.0; break
        }
        return {
            x: Math.round(ax * sw - ax * ow) + cfg_marginLeft - cfg_marginRight,
            y: Math.round(ay * sh - ay * oh) + cfg_marginTop  - cfg_marginBottom,
            w: ow, h: oh
        }
    }

    // ── Overlay HTML ──────────────────────────────────────────────────────────
    Item {
        id: overlay

        function reposition() {
            var g = parent.computeGeometry()
            x = g.x; y = g.y; width = g.w; height = g.h
        }

        Component.onCompleted: reposition()

        Connections {
            target: root
            function onWidthChanged()  { overlay.reposition() }
            function onHeightChanged() { overlay.reposition() }
        }
        Connections {
            target: wallpaper.configuration
            function onValueChanged() { overlay.reposition() }
        }

        WebEngineView {
            id:              webView
            anchors.fill:    parent
            url:             finalUrl
            zoomFactor:      cfg_zoom
            backgroundColor: "transparent"

            onCertificateError: function (err) {
                cfg_insecure ? err.acceptCertificate() : err.rejectCertificate()
            }

            settings.playbackRequiresUserGesture: false
            settings.javascriptEnabled:           true
            settings.localStorageEnabled:         true
        }
    }

    // Reload manual disparado pelo botão "Reload now" da configuração.
    // Usa o sinal genérico do QQmlPropertyMap (o notify por-chave não é
    // confiável aqui) e filtra pela chave ReloadNonce.
    Connections {
        target: wallpaper.configuration
        function onValueChanged(key, value) {
            if (key === "ReloadNonce")
                webView.reload()
        }
    }

    // Reload automático do overlay
    Timer {
        interval:    cfg_refreshSec > 0 ? cfg_refreshSec * 1000 : 60000
        running:     cfg_refreshSec > 0
        repeat:      true
        onTriggered: webView.reload()
    }
}
