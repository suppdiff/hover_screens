// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

Item {
    id: root

    required property bool presentationActive
    required property string livePreviewMode
    required property int previewStartDelay
    required property int previewStopDelay
    required property bool clipSpatialWindows
    required property string layoutMode
    required property string groupingMode
    required property string arrangementMode

    property bool closeOnActivate: false

    signal requestClose()

    signal requestScreenDesktopActivate(
        string screenName,
        int desktopNumber
    )

    clip: true

    TaskManager.VirtualDesktopInfo {
        id: desktopInfo
    }

    property bool hoverLive: false

    readonly property bool streamsActive:
        presentationActive
        && livePreviewMode !== "off"
        && (livePreviewMode === "always" || hoverLive)

    HoverHandler {
        id: hoverHandler

        onHoveredChanged: {
            if (hovered) {
                stopTimer.stop()

                if (root.livePreviewMode === "hover"
                        && root.presentationActive) {
                    startTimer.restart()
                }
            } else {
                startTimer.stop()

                if (root.livePreviewMode === "hover") {
                    stopTimer.restart()
                }
            }
        }
    }

    Timer {
        id: startTimer
        interval: root.previewStartDelay
        repeat: false

        onTriggered: {
            if (hoverHandler.hovered
                    && root.presentationActive
                    && root.livePreviewMode === "hover") {
                root.hoverLive = true
            }
        }
    }

    Timer {
        id: stopTimer
        interval: root.previewStopDelay
        repeat: false
        onTriggered: root.hoverLive = false
    }

    onPresentationActiveChanged: {
        if (!presentationActive) {
            startTimer.stop()
            stopTimer.stop()
            hoverLive = false
        } else if (livePreviewMode === "hover" && hoverHandler.hovered) {
            startTimer.restart()
        }
    }

    onLivePreviewModeChanged: {
        startTimer.stop()
        stopTimer.stop()
        hoverLive = false

        if (livePreviewMode === "hover"
                && presentationActive
                && hoverHandler.hovered) {
            startTimer.restart()
        }
    }

    function sortedScreens() {
        const screens =
            Application.screens

        if (!screens
                || screens.length === 0) {
            return []
        }

        const ordered = []

        for (let i = 0; i < screens.length; ++i) {
            ordered.push(
                screens[i]
            )
        }

        // QScreen enumeration order is not guaranteed to match the physical
        // desktop layout. Present By-screen groups in real left-to-right
        // topology order, then top-to-bottom for equal X positions.
        ordered.sort(
            function(a, b) {
                const ax =
                    Number(a.virtualX)

                const bx =
                    Number(b.virtualX)

                if (ax !== bx) {
                    return ax - bx
                }

                const ay =
                    Number(a.virtualY)

                const by =
                    Number(b.virtualY)

                if (ay !== by) {
                    return ay - by
                }

                return String(a.name)
                    .localeCompare(
                        String(b.name)
                    )
            }
        )

        return ordered
    }

    readonly property var orderedScreens:
        sortedScreens()

    function adaptiveColumns(
        count,
        availableWidth,
        availableHeight
    ) {
        if (count <= 1) {
            return 1
        }

        const width =
            Math.max(
                1,
                availableWidth
            )

        const height =
            Math.max(
                1,
                availableHeight
            )

        const targetAspect = 1.35

        let bestColumns = 1
        let bestScore = Number.POSITIVE_INFINITY

        for (let columns = 1; columns <= count; ++columns) {
            const rows =
                Math.ceil(
                    count / columns
                )

            const cellAspect =
                (width / columns)
                / (height / rows)

            const emptySlots =
                columns * rows - count

            const score =
                Math.abs(
                    Math.log(
                        Math.max(
                            0.01,
                            cellAspect
                        ) / targetAspect
                    )
                )
                + emptySlots * 0.08

            if (score < bestScore) {
                bestScore = score
                bestColumns = columns
            }
        }

        return bestColumns
    }

    Loader {
        id: groupingLoader

        anchors.fill: parent

        sourceComponent:
            root.groupingMode === "screen"
                ? screenGroupingComponent
                : desktopGroupingComponent
    }

    Component {
        id: desktopGroupingComponent

        GridView {
            id: desktopGrid

            clip: true
            cacheBuffer: 0

            model:
                desktopInfo.desktopIds

            boundsBehavior:
                Flickable.StopAtBounds

            flow:
                GridView.FlowLeftToRight

            interactive: false

            readonly property int desktopCount:
                Math.max(
                    1,
                    desktopInfo.desktopIds.length
                )

            readonly property int configuredRows:
                Math.max(
                    1,
                    Math.min(
                        desktopCount,
                        desktopInfo.desktopLayoutRows > 0
                            ? desktopInfo.desktopLayoutRows
                            : 1
                    )
                )

            readonly property int configuredColumns:
                Math.max(
                    1,
                    Math.ceil(
                        desktopCount
                        / configuredRows
                    )
                )

            readonly property int effectiveColumns:
                root.arrangementMode === "adaptive"
                    ? root.adaptiveColumns(
                        desktopCount,
                        width,
                        height
                    )
                    : configuredColumns

            readonly property int effectiveRows:
                Math.max(
                    1,
                    Math.ceil(
                        desktopCount
                        / effectiveColumns
                    )
                )

            cellWidth:
                Math.max(
                    1,
                    Math.floor(
                        width
                        / effectiveColumns
                    )
                )

            cellHeight:
                Math.max(
                    1,
                    Math.floor(
                        height
                        / effectiveRows
                    )
                )

            delegate: Item {
                id: desktopRoleAdapter

                required property var modelData
                required property int index

                width:
                    desktopGrid.cellWidth

                height:
                    desktopGrid.cellHeight

                GridDesktopTile {
                    anchors.fill: parent

                    anchors.margins:
                        Kirigami.Units.smallSpacing

                    desktopId:
                        desktopRoleAdapter.modelData

                    desktopNumber:
                        desktopRoleAdapter.index + 1

                    desktopName: {
                        const names =
                            desktopInfo.desktopNames

                        return desktopRoleAdapter.index < names.length
                            ? names[desktopRoleAdapter.index]
                            : i18n(
                                "Desktop %1",
                                desktopRoleAdapter.index + 1
                            )
                    }

                    layoutMode:
                        root.layoutMode

                    liveActive:
                        root.streamsActive

                    clipSpatialWindows:
                        root.clipSpatialWindows

                    onRequestScreenDesktopActivate:
                        (screenName, desktopNumber) => {
                            root.requestScreenDesktopActivate(
                                screenName,
                                desktopNumber
                            )

                            if (root.closeOnActivate) {
                                root.requestClose()
                            }
                        }
                }
            }
        }
    }

    Component {
        id: screenGroupingComponent

        GridView {
            id: screenGrid

            clip: true
            cacheBuffer: 0

            model:
                root.orderedScreens

            boundsBehavior:
                Flickable.StopAtBounds

            flow:
                GridView.FlowLeftToRight

            interactive: false

            readonly property int screenCount:
                Math.max(
                    1,
                    root.orderedScreens.length
                )

            // Screen groups themselves are presentation-only containers, so
            // adapt their outer packing to the current widget shape.
            readonly property int screenColumns:
                root.adaptiveColumns(
                    screenCount,
                    width,
                    height
                )

            readonly property int screenRows:
                Math.max(
                    1,
                    Math.ceil(
                        screenCount
                        / screenColumns
                    )
                )

            cellWidth:
                Math.max(
                    1,
                    Math.floor(
                        width
                        / screenColumns
                    )
                )

            cellHeight:
                Math.max(
                    1,
                    Math.floor(
                        height
                        / screenRows
                    )
                )

            delegate: Item {
                id: screenRoleAdapter

                required property var modelData
                required property int index

                width:
                    screenGrid.cellWidth

                height:
                    screenGrid.cellHeight

                GridScreenGroup {
                    anchors.fill: parent

                    anchors.margins:
                        Kirigami.Units.smallSpacing / 2

                    screenData:
                        screenRoleAdapter.modelData

                    desktopIds:
                        desktopInfo.desktopIds

                    desktopNames:
                        desktopInfo.desktopNames

                    configuredRows:
                        Math.max(
                            1,
                            desktopInfo.desktopLayoutRows > 0
                                ? desktopInfo.desktopLayoutRows
                                : 1
                        )

                    arrangementMode:
                        root.arrangementMode

                    layoutMode:
                        root.layoutMode

                    liveActive:
                        root.streamsActive

                    clipSpatialWindows:
                        root.clipSpatialWindows

                    onRequestScreenDesktopActivate:
                        (screenName, desktopNumber) => {
                            root.requestScreenDesktopActivate(
                                screenName,
                                desktopNumber
                            )

                            if (root.closeOnActivate) {
                                root.requestClose()
                            }
                        }
                }
            }
        }
    }
}
