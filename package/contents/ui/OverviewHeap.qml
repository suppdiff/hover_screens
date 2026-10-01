// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property bool presentationActive
    required property string livePreviewMode
    required property int previewStartDelay
    required property int previewStopDelay

    required property string layoutMode
    required property string arrangementMode
    required property var screenDesktopState
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

    clip: true

    property bool hoverLive: false

    readonly property bool streamsActive:
        presentationActive
        && livePreviewMode !== "off"
        && (
            livePreviewMode === "always"
            || hoverLive
        )

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

        onTriggered: {
            if (!hoverHandler.hovered
                    || !root.presentationActive) {
                root.hoverLive = false
            }
        }
    }

    onPresentationActiveChanged: {
        if (!presentationActive) {
            startTimer.stop()
            stopTimer.stop()
            hoverLive = false
        } else if (livePreviewMode === "hover"
                && hoverHandler.hovered) {
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

    function screenBounds() {
        const screens = Application.screens

        if (!screens || screens.length === 0) {
            return {
                "x": 0,
                "y": 0,
                "width": 1,
                "height": 1
            }
        }

        let left = screens[0].virtualX
        let top = screens[0].virtualY
        let right =
            left + screens[0].width
        let bottom =
            top + screens[0].height

        for (let i = 1; i < screens.length; ++i) {
            const screen = screens[i]

            left =
                Math.min(
                    left,
                    screen.virtualX
                )

            top =
                Math.min(
                    top,
                    screen.virtualY
                )

            right =
                Math.max(
                    right,
                    screen.virtualX + screen.width
                )

            bottom =
                Math.max(
                    bottom,
                    screen.virtualY + screen.height
                )
        }

        return {
            "x": left,
            "y": top,
            "width": Math.max(1, right - left),
            "height": Math.max(1, bottom - top)
        }
    }

    function minimumPhysicalScreenHeight() {
        const screens =
            Application.screens

        if (!screens || screens.length === 0) {
            return 1
        }

        let minimum =
            Math.max(
                1,
                screens[0].height
            )

        for (let i = 1; i < screens.length; ++i) {
            minimum =
                Math.min(
                    minimum,
                    Math.max(
                        1,
                        screens[i].height
                    )
                )
        }

        return minimum
    }

    readonly property var virtualBounds:
        screenBounds()

    readonly property real minimumScreenHeight:
        minimumPhysicalScreenHeight()

    Item {
        id: viewport

        anchors.fill: parent
        clip: true

        readonly property real padding:
            Kirigami.Units.smallSpacing * 2

        readonly property real screenGap:
            Kirigami.Units.smallSpacing * 2

        readonly property real screenHeaderHeight:
            Kirigami.Units.gridUnit * 1.55

        readonly property real screenHeaderGap:
            Kirigami.Units.smallSpacing / 2

        readonly property real screenHeaderExtent:
            screenHeaderHeight
            + screenHeaderGap

        readonly property bool spatialMode:
            root.layoutMode === "spatial"

        readonly property bool adaptiveScreens:
            !spatialMode
            && root.arrangementMode === "adaptive"

        readonly property bool preservePhysicalAspect:
            spatialMode

        readonly property real availableWidth:
            Math.max(
                1,
                width - padding * 2
            )

        readonly property real rawAvailableHeight:
            Math.max(
                1,
                height - padding * 2
            )

        function screenAspect(screen) {
            return Math.max(
                0.05,
                Number(screen.width)
                    / Math.max(
                        1,
                        Number(screen.height)
                    )
            )
        }

        function adaptiveCandidate(
            columns,
            headerExtent
        ) {
            const screens =
                root.orderedScreens

            const count =
                screens.length

            if (count <= 0) {
                return {
                    "columns": 1,
                    "rows": 1,
                    "rowHeights": [1],
                    "minSurfaceHeight": 1,
                    "totalArea": 1,
                    "orientationMixes": 0,
                    "emptySlots": 0
                }
            }

            const safeColumns =
                Math.max(
                    1,
                    Math.min(
                        count,
                        columns
                    )
                )

            const rows =
                Math.max(
                    1,
                    Math.ceil(
                        count / safeColumns
                    )
                )

            const rowHeights = []
            const rowAspectSums = []

            let totalUnscaledHeight = 0
            let orientationMixes = 0

            // Fit rows independently so different monitor orientations can
            // use different heights.
            for (let row = 0; row < rows; ++row) {
                const first =
                    row * safeColumns

                const last =
                    Math.min(
                        count,
                        first + safeColumns
                    )

                let aspectSum = 0
                let previousLandscape = null

                for (let i = first; i < last; ++i) {
                    const aspect =
                        screenAspect(
                            screens[i]
                        )

                    aspectSum +=
                        aspect

                    const landscape =
                        aspect >= 1

                    if (previousLandscape !== null
                            && previousLandscape
                                !== landscape) {
                        orientationMixes += 1
                    }

                    previousLandscape =
                        landscape
                }

                const rowCount =
                    Math.max(
                        1,
                        last - first
                    )

                const horizontalSpace =
                    Math.max(
                        1,
                        availableWidth
                            - Math.max(
                                0,
                                rowCount - 1
                            ) * screenGap
                    )

                const rowHeight =
                    Math.max(
                        1,
                        horizontalSpace
                            / Math.max(
                                0.05,
                                aspectSum
                            )
                    )

                rowAspectSums.push(
                    aspectSum
                )

                rowHeights.push(
                    rowHeight
                )

                totalUnscaledHeight +=
                    rowHeight
            }

            const verticalSpace =
                Math.max(
                    1,
                    rawAvailableHeight
                        - rows * headerExtent
                        - Math.max(
                            0,
                            rows - 1
                        ) * screenGap
                )

            // Width fitting is row-local. Only when the combined rows are too
            // tall do they scale together, preserving their relative fitted
            // heights rather than equalizing them.
            const verticalScale =
                totalUnscaledHeight
                    > verticalSpace
                ? Math.max(
                    0.001,
                    verticalSpace
                        / totalUnscaledHeight
                )
                : 1

            let minSurfaceHeight =
                Number.POSITIVE_INFINITY

            let totalArea = 0

            for (let row = 0; row < rows; ++row) {
                rowHeights[row] =
                    Math.max(
                        1,
                        rowHeights[row]
                            * verticalScale
                    )

                minSurfaceHeight =
                    Math.min(
                        minSurfaceHeight,
                        rowHeights[row]
                    )

                // Every screen in the row shares rowHeight, while preserving
                // its own width = aspect * rowHeight.
                totalArea +=
                    rowAspectSums[row]
                    * rowHeights[row]
                    * rowHeights[row]
            }

            return {
                "columns": safeColumns,
                "rows": rows,
                "rowHeights": rowHeights,
                "minSurfaceHeight":
                    Number.isFinite(
                        minSurfaceHeight
                    )
                        ? minSurfaceHeight
                        : 1,
                "totalArea": totalArea,
                "orientationMixes":
                    orientationMixes,
                "emptySlots":
                    safeColumns * rows
                    - count
            }
        }

        function candidateIsBetter(
            candidate,
            best
        ) {
            // Area is the main objective. Only when candidates are within 2%
            // do we lightly prefer keeping like orientations in the same row.
            const tolerance =
                Math.max(
                    1,
                    best.totalArea * 0.02
                )

            if (candidate.totalArea
                    > best.totalArea
                        + tolerance) {
                return true
            }

            if (best.totalArea
                    > candidate.totalArea
                        + tolerance) {
                return false
            }

            if (candidate.orientationMixes
                    !== best.orientationMixes) {
                return candidate.orientationMixes
                    < best.orientationMixes
            }

            if (candidate.emptySlots
                    !== best.emptySlots) {
                return candidate.emptySlots
                    < best.emptySlots
            }

            if (candidate.minSurfaceHeight
                    !== best.minSurfaceHeight) {
                return candidate.minSurfaceHeight
                    > best.minSurfaceHeight
            }

            return candidate.totalArea
                > best.totalArea
        }

        function bestAdaptiveCandidate(
            headerExtent
        ) {
            const count =
                root.orderedScreens.length

            if (count <= 0) {
                return adaptiveCandidate(
                    1,
                    headerExtent
                )
            }

            let best =
                adaptiveCandidate(
                    1,
                    headerExtent
                )

            for (let columns = 2;
                    columns <= count;
                    ++columns) {
                const candidate =
                    adaptiveCandidate(
                        columns,
                        headerExtent
                    )

                if (candidateIsBetter(
                        candidate,
                        best
                    )) {
                    best =
                        candidate
                }
            }

            return best
        }

        readonly property var fullHeaderAdaptiveCandidate:
            bestAdaptiveCandidate(
                screenHeaderExtent
            )

        // Evaluate compact headers against the full-header geometry.
        readonly property real fullHeaderAvailableHeight:
            Math.max(
                1,
                height
                    - padding * 2
                    - screenHeaderExtent
            )

        readonly property real fullHeaderPhysicalScale:
            Math.max(
                0.001,
                Math.min(
                    availableWidth
                        / root.virtualBounds.width,
                    fullHeaderAvailableHeight
                        / root.virtualBounds.height
                )
            )

        readonly property real fullHeaderScaleY:
            preservePhysicalAspect
                ? fullHeaderPhysicalScale
                : Math.max(
                    0.001,
                    fullHeaderAvailableHeight
                        / root.virtualBounds.height
                )

        readonly property real fullHeaderMinimumSurfaceHeight:
            adaptiveScreens
                ? fullHeaderAdaptiveCandidate.minSurfaceHeight
                : root.minimumScreenHeight
                    * fullHeaderScaleY

        readonly property bool compactHeaders:
            fullHeaderMinimumSurfaceHeight
                < Kirigami.Units.gridUnit * 6.25

        readonly property real activeHeaderExtent:
            compactHeaders
                ? 0
                : screenHeaderExtent

        readonly property real availableHeight:
            Math.max(
                1,
                height
                    - padding * 2
                    - activeHeaderExtent
            )

        // Spatial/Fill topology geometry.
        readonly property real physicalTopologyScale:
            Math.max(
                0.001,
                Math.min(
                    availableWidth
                        / root.virtualBounds.width,
                    availableHeight
                        / root.virtualBounds.height
                )
            )

        readonly property real topologyScaleX:
            preservePhysicalAspect
                ? physicalTopologyScale
                : Math.max(
                    0.001,
                    availableWidth
                        / root.virtualBounds.width
                )

        readonly property real topologyScaleY:
            preservePhysicalAspect
                ? physicalTopologyScale
                : Math.max(
                    0.001,
                    availableHeight
                        / root.virtualBounds.height
                )

        readonly property real topologyWidth:
            root.virtualBounds.width
            * topologyScaleX

        readonly property real topologyHeight:
            root.virtualBounds.height
            * topologyScaleY

        readonly property real topologyX:
            preservePhysicalAspect
                ? (width - topologyWidth) / 2
                : padding

        readonly property real topologyY:
            preservePhysicalAspect
                ? activeHeaderExtent
                    + padding
                    + (
                        availableHeight
                        - topologyHeight
                    ) / 2
                : activeHeaderExtent
                    + padding

        // Adaptive Overview packs physical-screen cards while preserving every
        // monitor's own aspect. It deliberately does not preserve the monitors'
        // physical x/y offsets; Spatial remains the truthful topology mode.
        readonly property var adaptiveLayout:
            bestAdaptiveCandidate(
                activeHeaderExtent
            )

        readonly property int adaptiveColumns:
            adaptiveLayout.columns

        function adaptiveColumn(index) {
            return index
                % adaptiveColumns
        }

        function adaptiveRow(index) {
            return Math.floor(
                index
                / adaptiveColumns
            )
        }

        function adaptiveRowHeight(row) {
            const heights =
                adaptiveLayout.rowHeights

            if (!heights
                    || row < 0
                    || row >= heights.length) {
                return 1
            }

            return Math.max(
                1,
                Number(
                    heights[row]
                )
            )
        }

        function adaptiveX(index) {
            const screens =
                root.orderedScreens

            const row =
                adaptiveRow(index)

            const first =
                row * adaptiveColumns

            const rowHeight =
                adaptiveRowHeight(
                    row
                )

            let position =
                padding

            for (let i = first; i < index; ++i) {
                position +=
                    screenAspect(
                        screens[i]
                    ) * rowHeight
                    + screenGap
            }

            return position
        }

        function adaptiveY(index) {
            const row =
                adaptiveRow(index)

            let position =
                padding

            for (let previous = 0;
                    previous < row;
                    ++previous) {
                position +=
                    activeHeaderExtent
                    + adaptiveRowHeight(
                        previous
                    )
                    + screenGap
            }

            return position
        }

        Repeater {
            model:
                viewport.adaptiveScreens
                    ? root.orderedScreens
                    : Application.screens

            delegate: OverviewScreen {
                required property var modelData
                required property int index

                x:
                    viewport.adaptiveScreens
                        ? viewport.adaptiveX(index)
                        : viewport.topologyX
                            + (
                                modelData.virtualX
                                - root.virtualBounds.x
                            ) * viewport.topologyScaleX

                y:
                    viewport.adaptiveScreens
                        ? viewport.adaptiveY(index)
                        : viewport.topologyY
                            + (
                                modelData.virtualY
                                - root.virtualBounds.y
                            ) * viewport.topologyScaleY
                            - viewport.activeHeaderExtent

                width:
                    viewport.adaptiveScreens
                        ? Math.max(
                            1,
                            viewport.screenAspect(
                                modelData
                            ) * viewport.adaptiveRowHeight(
                                viewport.adaptiveRow(index)
                            )
                        )
                        : Math.max(
                            1,
                            modelData.width
                                * viewport.topologyScaleX
                        )

                height:
                    viewport.activeHeaderExtent
                    + (
                        viewport.adaptiveScreens
                            ? Math.max(
                                1,
                                viewport.adaptiveRowHeight(
                                    viewport.adaptiveRow(index)
                                )
                            )
                            : Math.max(
                                1,
                                modelData.height
                                    * viewport.topologyScaleY
                            )
                    )

                headerExtent:
                    viewport.activeHeaderExtent

                compactHeader:
                    viewport.compactHeaders

                screenData:
                    modelData

                liveActive:
                    root.streamsActive

                currentDesktopNumber: {
                    const key =
                        String(
                            modelData.name
                        )

                    const value =
                        root.screenDesktopState[
                            key
                        ]

                    return value === undefined
                        ? 0
                        : Number(value)
                }

                layoutMode:
                    root.layoutMode

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
        }
    }
}
