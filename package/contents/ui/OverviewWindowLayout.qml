// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var tasksModel
    required property string layoutMode
    required property bool liveActive

    property bool closeOnActivate: false

    signal requestClose()

    clip: true

    readonly property real gap:
        Math.max(
            2,
            Kirigami.Units.smallSpacing
        )

    readonly property real padding:
        Math.max(
            2,
            Kirigami.Units.smallSpacing / 2
        )

    property bool relayoutQueued: false

    function scheduleRelayout() {
        if (relayoutQueued) {
            return
        }

        relayoutQueued = true

        Qt.callLater(function() {
            root.relayoutQueued = false
            root.relayout()
        })
    }

    function activeItems() {
        const result = []

        for (let i = 0; i < tileRepeater.count; ++i) {
            const item = tileRepeater.itemAt(i)

            if (item && item.isWindow) {
                result.push(item)
            }
        }

        return result
    }

    function setRect(item, x, y, width, height) {
        item.layoutX = Math.round(x)
        item.layoutY = Math.round(y)
        item.layoutWidth = Math.max(1, Math.round(width))
        item.layoutHeight = Math.max(1, Math.round(height))
    }

    function effectiveLayout(count) {
        if (layoutMode !== "adaptive") {
            return layoutMode
        }

        if (count <= 1) {
            return "natural"
        }

        const ratio =
            Math.max(0.01, width)
            / Math.max(0.01, height)

        if (count <= 5 && ratio >= 2.25) {
            return "horizontal"
        }

        if (count <= 5 && ratio <= 0.72) {
            return "vertical"
        }

        if (count >= 7) {
            return "reflow"
        }

        return "natural"
    }

    function layoutReflow(items) {
        const count = items.length

        if (count === 0) {
            return
        }

        const contentWidth =
            Math.max(
                1,
                width - padding * 2
            )

        const contentHeight =
            Math.max(
                1,
                height - padding * 2
            )

        const aspect =
            contentWidth
            / Math.max(1, contentHeight)

        const columns =
            Math.max(
                1,
                Math.ceil(
                    Math.sqrt(
                        count * aspect
                    )
                )
            )

        const rows =
            Math.max(
                1,
                Math.ceil(
                    count / columns
                )
            )

        const cellWidth =
            Math.max(
                1,
                (
                    contentWidth
                    - gap * (columns - 1)
                ) / columns
            )

        const cellHeight =
            Math.max(
                1,
                (
                    contentHeight
                    - gap * (rows - 1)
                ) / rows
            )

        for (let i = 0; i < count; ++i) {
            const column = i % columns
            const row = Math.floor(i / columns)

            setRect(
                items[i],
                padding
                    + column
                        * (cellWidth + gap),
                padding
                    + row
                        * (cellHeight + gap),
                cellWidth,
                cellHeight
            )
        }
    }

    function layoutHorizontal(items) {
        const count = items.length

        if (count === 0) {
            return
        }

        const contentWidth =
            Math.max(
                1,
                width - padding * 2
            )

        const contentHeight =
            Math.max(
                1,
                height - padding * 2
            )

        const cellWidth =
            Math.max(
                1,
                (
                    contentWidth
                    - gap * (count - 1)
                ) / count
            )

        for (let i = 0; i < count; ++i) {
            setRect(
                items[i],
                padding
                    + i
                        * (cellWidth + gap),
                padding,
                cellWidth,
                contentHeight
            )
        }
    }

    function layoutVertical(items) {
        const count = items.length

        if (count === 0) {
            return
        }

        const contentWidth =
            Math.max(
                1,
                width - padding * 2
            )

        const contentHeight =
            Math.max(
                1,
                height - padding * 2
            )

        const cellHeight =
            Math.max(
                1,
                (
                    contentHeight
                    - gap * (count - 1)
                ) / count
            )

        for (let i = 0; i < count; ++i) {
            setRect(
                items[i],
                padding,
                padding
                    + i
                        * (cellHeight + gap),
                contentWidth,
                cellHeight
            )
        }
    }

    function balancedRows(items, rowCount) {
        const rows = []

        let cursor = 0
        let remainingAspect = 0

        for (let i = 0; i < items.length; ++i) {
            remainingAspect += items[i].windowAspect
        }

        for (let rowIndex = 0;
                rowIndex < rowCount;
                ++rowIndex) {
            const remainingRows =
                rowCount - rowIndex

            const row = []

            if (remainingRows === 1) {
                while (cursor < items.length) {
                    row.push(items[cursor])
                    ++cursor
                }

                rows.push(row)
                break
            }

            const target =
                remainingAspect
                / remainingRows

            let rowAspect = 0

            while (
                cursor
                    < items.length
                        - (remainingRows - 1)
            ) {
                const next =
                    items[cursor]

                const withNext =
                    rowAspect
                    + next.windowAspect

                if (
                    row.length > 0
                    && Math.abs(
                        rowAspect - target
                    ) <= Math.abs(
                        withNext - target
                    )
                ) {
                    break
                }

                row.push(next)
                rowAspect = withNext
                ++cursor
            }

            if (row.length === 0
                    && cursor < items.length) {
                row.push(items[cursor])
                rowAspect =
                    items[cursor].windowAspect
                ++cursor
            }

            rows.push(row)
            remainingAspect -= rowAspect
        }

        return rows
    }

    function naturalCandidate(items, rowCount) {
        const rows =
            balancedRows(
                items,
                rowCount
            )

        const contentWidth =
            Math.max(
                1,
                width - padding * 2
            )

        const contentHeight =
            Math.max(
                1,
                height - padding * 2
            )

        const verticalGapTotal =
            gap * Math.max(0, rows.length - 1)

        const availableHeight =
            Math.max(
                1,
                contentHeight
                    - verticalGapTotal
            )

        const baseHeights = []
        let totalBaseHeight = 0

        for (let r = 0; r < rows.length; ++r) {
            const row = rows[r]

            let aspectSum = 0

            for (let i = 0; i < row.length; ++i) {
                aspectSum +=
                    row[i].windowAspect
            }

            const availableRowWidth =
                Math.max(
                    1,
                    contentWidth
                        - gap
                            * Math.max(
                                0,
                                row.length - 1
                            )
                )

            const rowHeight =
                availableRowWidth
                / Math.max(
                    0.01,
                    aspectSum
                )

            baseHeights.push(rowHeight)
            totalBaseHeight += rowHeight
        }

        const scale =
            Math.min(
                1,
                availableHeight
                    / Math.max(
                        1,
                        totalBaseHeight
                    )
            )

        let area = 0

        for (let r = 0; r < rows.length; ++r) {
            const rowHeight =
                baseHeights[r] * scale

            for (let i = 0;
                    i < rows[r].length;
                    ++i) {
                area +=
                    rows[r][i].windowAspect
                    * rowHeight
                    * rowHeight
            }
        }

        return {
            "rows": rows,
            "baseHeights": baseHeights,
            "scale": scale,
            "area": area
        }
    }

    function naturalOrder(items) {
        const ordered = items.slice()

        // Preserve a rough relationship with the real window positions while
        // repacking enough to remove overlap.
        ordered.sort(function(a, b) {
            const verticalDelta =
                a.windowCenterY
                - b.windowCenterY

            if (Math.abs(verticalDelta) > 48) {
                return verticalDelta
            }

            const horizontalDelta =
                a.windowCenterX
                - b.windowCenterX

            if (Math.abs(horizontalDelta) > 1) {
                return horizontalDelta
            }

            return a.taskIndex - b.taskIndex
        })

        return ordered
    }

    function layoutNatural(sourceItems) {
        const count = sourceItems.length

        if (count === 0) {
            return
        }

        const items =
            naturalOrder(sourceItems)

        let best = null

        for (let rowCount = 1;
                rowCount <= count;
                ++rowCount) {
            const candidate =
                naturalCandidate(
                    items,
                    rowCount
                )

            if (!best
                    || candidate.area
                        > best.area) {
                best = candidate
            }
        }

        if (!best) {
            layoutReflow(items)
            return
        }

        const contentWidth =
            Math.max(
                1,
                width - padding * 2
            )

        const contentHeight =
            Math.max(
                1,
                height - padding * 2
            )

        let packedHeight =
            gap
            * Math.max(
                0,
                best.rows.length - 1
            )

        for (let r = 0;
                r < best.rows.length;
                ++r) {
            packedHeight +=
                best.baseHeights[r]
                * best.scale
        }

        let y =
            padding
            + Math.max(
                0,
                (
                    contentHeight
                    - packedHeight
                ) / 2
            )

        for (let r = 0;
                r < best.rows.length;
                ++r) {
            const row =
                best.rows[r]

            const rowHeight =
                best.baseHeights[r]
                * best.scale

            let rowWidth =
                gap
                * Math.max(
                    0,
                    row.length - 1
                )

            for (let i = 0;
                    i < row.length;
                    ++i) {
                rowWidth +=
                    row[i].windowAspect
                    * rowHeight
            }

            let x =
                padding
                + Math.max(
                    0,
                    (
                        contentWidth
                        - rowWidth
                    ) / 2
                )

            for (let i = 0;
                    i < row.length;
                    ++i) {
                const item = row[i]

                const itemWidth =
                    item.windowAspect
                    * rowHeight

                setRect(
                    item,
                    x,
                    y,
                    itemWidth,
                    rowHeight
                )

                x += itemWidth + gap
            }

            y += rowHeight + gap
        }
    }

    function relayout() {
        const items =
            activeItems()

        if (items.length === 0) {
            return
        }

        const mode =
            effectiveLayout(
                items.length
            )

        if (mode === "horizontal") {
            layoutHorizontal(items)
            return
        }

        if (mode === "vertical") {
            layoutVertical(items)
            return
        }

        if (mode === "reflow") {
            layoutReflow(items)
            return
        }

        layoutNatural(items)
    }

    onWidthChanged:
        scheduleRelayout()

    onHeightChanged:
        scheduleRelayout()

    onLayoutModeChanged:
        scheduleRelayout()

    Component.onCompleted:
        scheduleRelayout()

    Repeater {
        id: tileRepeater

        model: root.tasksModel

        onItemAdded:
            (index, item) =>
                root.scheduleRelayout()

        onItemRemoved:
            (index, item) =>
                root.scheduleRelayout()

        delegate: Item {
            id: tileAdapter

            required property var model
            required property int index

            readonly property bool isWindow:
                Boolean(model.IsWindow)

            readonly property rect sourceGeometry: {
                const geometry =
                    model.Geometry

                return geometry === undefined
                        || geometry === null
                    ? Qt.rect(0, 0, 0, 0)
                    : geometry
            }

            readonly property real windowAspect: {
                const geometry =
                    sourceGeometry

                if (!geometry
                        || geometry.width <= 0
                        || geometry.height <= 0) {
                    return 1.6
                }

                return Math.max(
                    0.55,
                    Math.min(
                        2.6,
                        geometry.width
                            / geometry.height
                    )
                )
            }

            readonly property real windowCenterX:
                sourceGeometry
                    ? sourceGeometry.x
                        + sourceGeometry.width / 2
                    : index

            readonly property real windowCenterY:
                sourceGeometry
                    ? sourceGeometry.y
                        + sourceGeometry.height / 2
                    : 0

            readonly property int taskIndex:
                index

            property real layoutX: 0
            property real layoutY: 0
            property real layoutWidth: 1
            property real layoutHeight: 1

            x: layoutX
            y: layoutY
            width: layoutWidth
            height: layoutHeight

            visible: isWindow

            onWindowAspectChanged:
                root.scheduleRelayout()

            onWindowCenterXChanged:
                root.scheduleRelayout()

            onWindowCenterYChanged:
                root.scheduleRelayout()

            LiveWindowTile {
                anchors.fill: parent

                taskIndex:
                    tileAdapter.index

                tasksModel:
                    root.tasksModel

                isWindow:
                    tileAdapter.isWindow

                isActive:
                    Boolean(
                        tileAdapter.model.IsActive
                    )

                isMinimized:
                    Boolean(
                        tileAdapter.model.IsMinimized
                    )

                isExcludedFromCapture:
                    Boolean(
                        tileAdapter.model.IsExcludedFromCapture
                    )

                winIdList:
                    tileAdapter.model.WinIdList

                decoration:
                    tileAdapter.model.decoration

                displayText:
                    String(
                        tileAdapter.model.display
                            ?? ""
                    )

                liveActive:
                    root.liveActive

                showTitle: true

                onActivated: {
                    if (root.closeOnActivate) {
                        root.requestClose()
                    }
                }
            }
        }
    }
}
