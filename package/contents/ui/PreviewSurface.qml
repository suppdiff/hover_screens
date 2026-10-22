// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property string mode
    required property string overviewLayout
    required property string overviewArrangement
    required property string gridLayout
    required property string gridGrouping
    required property string gridArrangement
    required property var screenDesktopState

    required property bool presentationActive
    required property string livePreviewMode
    required property int previewStartDelay
    required property int previewStopDelay
    required property bool clipSpatialWindows
    required property bool wrapDesktopScrolling

    property bool closeOnActivate: false

    signal requestClose()

    signal requestScreenDesktopActivate(
        string screenName,
        int desktopNumber
    )

    signal requestScreenDesktopStep(
        string screenName,
        int direction
    )

    readonly property bool overviewSelected:
        mode !== "Grid View"

    readonly property bool gridSelected:
        mode === "Grid View"

    implicitWidth:
        Kirigami.Units.gridUnit * 42

    implicitHeight:
        Kirigami.Units.gridUnit * 27

    clip: true

    // Mount both views only while this surface is presented. Previously every
    // applet eagerly built the popup AND inline scene, each with Overview and
    // Grid TaskManager models, even while the popup was closed. Keeping both
    // views within the active scene preserves fast Overview/Grid switching.
    Loader {
        id: contentHost

        anchors.fill: parent
        active: root.presentationActive
        sourceComponent: presentedContent
    }

    Component {
        id: presentedContent

        Item {
            anchors.fill: parent
            clip: true

            // Keep Overview mounted even while Grid is selected. The expensive
            // live-capture path is still disabled because presentationActive is
            // gated below.
            OverviewHeap {
                id: overviewView

                anchors.fill: parent

                visible: root.overviewSelected
                enabled: visible

                presentationActive:
                    root.presentationActive
                    && root.overviewSelected

                livePreviewMode:
                    root.livePreviewMode

                previewStartDelay:
                    root.previewStartDelay

                previewStopDelay:
                    root.previewStopDelay

                layoutMode:
                    root.overviewLayout

                arrangementMode:
                    root.overviewArrangement

                screenDesktopState:
                    root.screenDesktopState

                clipSpatialWindows:
                    root.clipSpatialWindows

                wrapDesktopScrolling:
                    root.wrapDesktopScrolling

                closeOnActivate:
                    root.closeOnActivate

                onRequestClose:
                    root.requestClose()

                onRequestScreenDesktopActivate:
                    (screenName, number) =>
                        root.requestScreenDesktopActivate(
                            screenName,
                            number
                        )

                onRequestScreenDesktopStep:
                    (screenName, direction) =>
                        root.requestScreenDesktopStep(
                            screenName,
                            direction
                        )
            }

            // Grid is also kept mounted so switching back and forth does not
            // rebuild either side of the view hierarchy.
            GridViewContent {
                id: gridView

                anchors.fill: parent

                visible: root.gridSelected
                enabled: visible

                presentationActive:
                    root.presentationActive
                    && root.gridSelected

                livePreviewMode:
                    root.livePreviewMode

                previewStartDelay:
                    root.previewStartDelay

                previewStopDelay:
                    root.previewStopDelay

                clipSpatialWindows:
                    root.clipSpatialWindows

                layoutMode:
                    root.gridLayout

                groupingMode:
                    root.gridGrouping

                arrangementMode:
                    root.gridArrangement

                closeOnActivate:
                    root.closeOnActivate

                onRequestClose:
                    root.requestClose()

                onRequestScreenDesktopActivate:
                    (screenName, desktopNumber) =>
                        root.requestScreenDesktopActivate(
                            screenName,
                            desktopNumber
                        )
            }
        }
    }
}
