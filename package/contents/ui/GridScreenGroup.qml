// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: root

    required property var screenData
    required property var desktopIds
    required property var desktopNames
    required property int configuredRows
    required property string arrangementMode
    required property string layoutMode
    required property bool liveActive
    required property bool clipSpatialWindows

    signal requestScreenDesktopActivate(
        string screenName,
        int desktopNumber
    )

    clip: true

    readonly property int desktopCount:
        Math.max(
            1,
            desktopIds.length
        )

    readonly property real screenAspect:
        Math.max(
            0.05,
            Number(screenData.width)
                / Math.max(
                    1,
                    Number(screenData.height)
                )
        )

    readonly property real cellGap:
        Kirigami.Units.smallSpacing

    readonly property real labelHeight:
        Math.max(
            14,
            Kirigami.Units.gridUnit
        )

    readonly property real outerInset:
        Kirigami.Units.smallSpacing / 2

    readonly property int followRows:
        Math.max(
            1,
            Math.min(
                desktopCount,
                configuredRows
            )
        )

    readonly property int followColumns:
        Math.max(
            1,
            Math.ceil(
                desktopCount
                / followRows
            )
        )

    function candidatePreview(
        columns,
        availableWidth,
        availableHeight
    ) {
        const safeColumns =
            Math.max(
                1,
                columns
            )

        const rows =
            Math.max(
                1,
                Math.ceil(
                    root.desktopCount
                    / safeColumns
                )
            )

        const width =
            Math.max(
                1,
                availableWidth
                    - root.outerInset * 2
                    - root.cellGap
                        * Math.max(
                            0,
                            safeColumns - 1
                        )
            )

        const height =
            Math.max(
                1,
                availableHeight
                    - root.outerInset * 2
                    - root.cellGap
                        * Math.max(
                            0,
                            rows - 1
                        )
                    - root.labelHeight * rows
            )

        const maxPreviewWidth =
            width / safeColumns

        const maxPreviewHeight =
            height / rows

        const previewWidth =
            Math.max(
                1,
                Math.min(
                    maxPreviewWidth,
                    maxPreviewHeight
                        * root.screenAspect
                )
            )

        return {
            "columns": safeColumns,
            "rows": rows,
            "previewWidth": previewWidth,
            "previewHeight":
                previewWidth
                    / root.screenAspect
        }
    }

    function adaptiveColumns(
        availableWidth,
        availableHeight
    ) {
        if (desktopCount <= 1) {
            return 1
        }

        let bestColumns = 1
        let bestArea = -1
        let bestEmptySlots =
            Number.POSITIVE_INFINITY

        for (let columns = 1;
                columns <= desktopCount;
                ++columns) {
            const candidate =
                candidatePreview(
                    columns,
                    availableWidth,
                    availableHeight
                )

            const area =
                candidate.previewWidth
                * candidate.previewHeight
                * desktopCount

            const emptySlots =
                candidate.columns
                * candidate.rows
                - desktopCount

            if (area > bestArea + 0.5
                    || (
                        Math.abs(
                            area - bestArea
                        ) <= 0.5
                        && emptySlots
                            < bestEmptySlots
                    )) {
                bestArea = area
                bestEmptySlots =
                    emptySlots
                bestColumns =
                    columns
            }
        }

        return bestColumns
    }

    readonly property int effectiveColumns:
        arrangementMode === "adaptive"
            ? adaptiveColumns(
                width,
                height
            )
            : followColumns

    readonly property var previewGeometry:
        candidatePreview(
            effectiveColumns,
            width,
            height
        )

    readonly property int effectiveRows:
        previewGeometry.rows

    readonly property real previewWidth:
        previewGeometry.previewWidth

    readonly property real previewHeight:
        previewGeometry.previewHeight

    readonly property real cellWidth:
        previewWidth

    readonly property real cellHeight:
        labelHeight
        + previewHeight

    readonly property real packedWidth:
        effectiveColumns
        * cellWidth
        + Math.max(
            0,
            effectiveColumns - 1
        ) * cellGap

    readonly property real packedHeight:
        effectiveRows
        * cellHeight
        + Math.max(
            0,
            effectiveRows - 1
        ) * cellGap

    Item {
        id: packedCluster

        // Keep each monitor's desktops visually together. Any surplus space
        // belongs outside the group rather than between desktop miniatures.
        x:
            root.outerInset

        y:
            root.outerInset

        width:
            root.packedWidth

        height:
            root.packedHeight

        Repeater {
            model:
                root.desktopIds

            delegate: Item {
                id: desktopRoleAdapter

                required property var modelData
                required property int index

                readonly property int column:
                    desktopRoleAdapter.index
                    % root.effectiveColumns

                readonly property int row:
                    Math.floor(
                        desktopRoleAdapter.index
                        / root.effectiveColumns
                    )

                x:
                    column
                    * (
                        root.cellWidth
                        + root.cellGap
                    )

                y:
                    row
                    * (
                        root.cellHeight
                        + root.cellGap
                    )

                width:
                    root.cellWidth

                height:
                    root.cellHeight

                PlasmaComponents3.Label {
                    id: desktopLabel

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }

                    height:
                        root.labelHeight

                    verticalAlignment:
                        Text.AlignVCenter

                    text: {
                        const names =
                            root.desktopNames

                        return desktopRoleAdapter.index
                                < names.length
                            ? names[
                                desktopRoleAdapter.index
                            ]
                            : i18n(
                                "Desktop %1",
                                desktopRoleAdapter.index + 1
                            )
                    }

                    elide:
                        Text.ElideRight
                }

                GridScreenSurface {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: desktopLabel.bottom
                    }

                    height:
                        root.previewHeight

                    screenData:
                        root.screenData

                    desktopId:
                        desktopRoleAdapter.modelData

                    desktopNumber:
                        desktopRoleAdapter.index + 1

                    layoutMode:
                        root.layoutMode

                    liveActive:
                        root.liveActive

                    clipSpatialWindows:
                        root.clipSpatialWindows

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
}
