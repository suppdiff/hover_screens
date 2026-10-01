// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property string cfg_primaryAction
    property string cfg_primaryActionDefault

    property string cfg_overviewLayout
    property string cfg_overviewLayoutDefault

    property string cfg_overviewArrangement
    property string cfg_overviewArrangementDefault

    property string cfg_gridLayout
    property string cfg_gridLayoutDefault

    property string cfg_gridGrouping
    property string cfg_gridGroupingDefault

    property string cfg_gridArrangement
    property string cfg_gridArrangementDefault

    property bool cfg_usePopup
    property bool cfg_usePopupDefault

    property string cfg_livePreviewMode
    property string cfg_livePreviewModeDefault

    property int cfg_previewStartDelay
    property int cfg_previewStartDelayDefault

    property int cfg_previewStopDelay
    property int cfg_previewStopDelayDefault

    property bool cfg_clipSpatialWindows
    property bool cfg_clipSpatialWindowsDefault

    property bool cfg_wrapDesktopScrolling
    property bool cfg_wrapDesktopScrollingDefault

    property bool cfg_middleClickEnabled
    property bool cfg_middleClickEnabledDefault

    readonly property var overviewLayoutValues: [
        "natural",
        "reflow",
        "horizontal",
        "vertical",
        "spatial",
        "adaptive"
    ]

    readonly property var gridLayoutValues: [
        "natural",
        "reflow",
        "horizontal",
        "vertical",
        "spatial",
        "adaptive"
    ]

    readonly property bool overviewActive:
        cfg_primaryAction !== "Grid View"

    readonly property bool gridActive:
        cfg_primaryAction === "Grid View"

    readonly property bool activeSpatial:
        overviewActive
            ? cfg_overviewLayout === "spatial"
            : cfg_gridLayout === "spatial"

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Primary view:")

            model: [
                i18n("Overview"),
                i18n("Grid View")
            ]

            currentIndex:
                root.gridActive
                    ? 1
                    : 0

            onActivated:
                cfg_primaryAction =
                    currentIndex === 1
                        ? "Grid View"
                        : "Overview"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true

            level: 4

            text:
                root.overviewActive
                    ? i18n("Overview layout")
                    : i18n("Grid View layout")
        }

        QQC2.ComboBox {
            visible:
                root.overviewActive

            Kirigami.FormData.label:
                i18n("Window layout:")

            model: [
                i18n("Natural"),
                i18n("Reflow"),
                i18n("Horizontal"),
                i18n("Vertical"),
                i18n("Spatial"),
                i18n("Adaptive")
            ]

            currentIndex: {
                const index =
                    root.overviewLayoutValues.indexOf(
                        cfg_overviewLayout
                    )

                return index >= 0
                    ? index
                    : 0
            }

            onActivated:
                cfg_overviewLayout =
                    root.overviewLayoutValues[
                        currentIndex
                    ]
        }

        QQC2.ComboBox {
            visible:
                root.overviewActive

            Kirigami.FormData.label:
                i18n("Screen arrangement:")

            model: [
                i18n("Fill topology"),
                i18n("Adaptive")
            ]

            enabled:
                cfg_overviewLayout !== "spatial"

            currentIndex:
                cfg_overviewArrangement === "adaptive"
                    ? 1
                    : 0

            onActivated:
                cfg_overviewArrangement =
                    currentIndex === 1
                        ? "adaptive"
                        : "fill"
        }

        QQC2.ComboBox {
            visible:
                root.gridActive

            Kirigami.FormData.label:
                i18n("Window layout:")

            model: [
                i18n("Natural"),
                i18n("Reflow"),
                i18n("Horizontal"),
                i18n("Vertical"),
                i18n("Spatial"),
                i18n("Adaptive")
            ]

            currentIndex: {
                const index =
                    root.gridLayoutValues.indexOf(
                        cfg_gridLayout
                    )

                return index >= 0
                    ? index
                    : 4
            }

            onActivated:
                cfg_gridLayout =
                    root.gridLayoutValues[
                        currentIndex
                    ]
        }

        QQC2.ComboBox {
            visible:
                root.gridActive

            Kirigami.FormData.label:
                i18n("Grouping:")

            model: [
                i18n("By desktop"),
                i18n("By screen")
            ]

            currentIndex:
                cfg_gridGrouping === "screen"
                    ? 1
                    : 0

            onActivated:
                cfg_gridGrouping =
                    currentIndex === 1
                        ? "screen"
                        : "desktop"
        }

        QQC2.ComboBox {
            visible:
                root.gridActive

            Kirigami.FormData.label:
                i18n("Desktop arrangement:")

            model: [
                i18n("Follow KDE layout"),
                i18n("Adaptive")
            ]

            currentIndex:
                cfg_gridArrangement === "adaptive"
                    ? 1
                    : 0

            onActivated:
                cfg_gridArrangement =
                    currentIndex === 1
                        ? "adaptive"
                        : "kde"
        }

        QQC2.CheckBox {
            visible:
                root.activeSpatial

            Kirigami.FormData.label:
                i18n("Spatial:")

            text:
                i18n("Clip windows to screen bounds")

            checked:
                cfg_clipSpatialWindows

            onToggled:
                cfg_clipSpatialWindows =
                    checked
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true

            level: 4
            text: i18n("Presentation & previews")
        }

        QQC2.CheckBox {
            Kirigami.FormData.label:
                i18n("Presentation:")

            text:
                i18n("Use popup")

            checked:
                cfg_usePopup

            onToggled:
                cfg_usePopup =
                    checked
        }

        QQC2.ComboBox {
            Kirigami.FormData.label:
                i18n("Live previews:")

            model: [
                i18n("On hover"),
                i18n("Always"),
                i18n("Off")
            ]

            currentIndex:
                cfg_livePreviewMode === "always"
                    ? 1
                    : (
                        cfg_livePreviewMode === "off"
                            ? 2
                            : 0
                    )

            onActivated:
                cfg_livePreviewMode =
                    currentIndex === 1
                        ? "always"
                        : (
                            currentIndex === 2
                                ? "off"
                                : "hover"
                        )
        }

        QQC2.SpinBox {
            visible:
                cfg_livePreviewMode === "hover"

            Kirigami.FormData.label:
                i18n("Start delay (ms):")

            from: 0
            to: 1000
            stepSize: 10
            editable: true
            value: cfg_previewStartDelay

            onValueModified:
                cfg_previewStartDelay =
                    value
        }

        QQC2.SpinBox {
            visible:
                cfg_livePreviewMode === "hover"

            Kirigami.FormData.label:
                i18n("Stop delay (ms):")

            from: 0
            to: 2000
            stepSize: 10
            editable: true
            value: cfg_previewStopDelay

            onValueModified:
                cfg_previewStopDelay =
                    value
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true

            level: 4
            text: i18n("Interaction")
        }

        QQC2.CheckBox {
            visible:
                root.overviewActive

            Kirigami.FormData.label:
                i18n("Desktop scrolling:")

            text:
                i18n("Wrap around at first/last desktop")

            checked:
                cfg_wrapDesktopScrolling

            onToggled:
                cfg_wrapDesktopScrolling =
                    checked
        }

        QQC2.CheckBox {
            Kirigami.FormData.label:
                i18n("Middle click:")

            text:
                i18n("Open the other native KWin view")

            checked:
                cfg_middleClickEnabled

            onToggled:
                cfg_middleClickEnabled =
                    checked
        }
    }
}
