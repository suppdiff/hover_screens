// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property int taskIndex
    required property var tasksModel

    required property bool isWindow
    required property bool isActive
    required property bool isMinimized
    required property bool isExcludedFromCapture

    required property var geometry
    required property real stackingOrder
    required property var winIdList
    required property var decoration
    required property string displayText

    required property var screenData

    required property bool liveActive
    required property bool clipToScreenBounds

    required property real contentScaleX
    required property real contentScaleY

    signal activated()

    function effectiveGeometry() {
        const screenRect = Qt.rect(
            screenData.virtualX,
            screenData.virtualY,
            screenData.width,
            screenData.height
        )

        if (geometry
                && geometry.width > 0
                && geometry.height > 0) {
            if (clipToScreenBounds) {
                const left =
                    Math.max(
                        geometry.x,
                        screenRect.x
                    )

                const top =
                    Math.max(
                        geometry.y,
                        screenRect.y
                    )

                const right =
                    Math.min(
                        geometry.x + geometry.width,
                        screenRect.x + screenRect.width
                    )

                const bottom =
                    Math.min(
                        geometry.y + geometry.height,
                        screenRect.y + screenRect.height
                    )

                if (right > left && bottom > top) {
                    return Qt.rect(
                        left,
                        top,
                        right - left,
                        bottom - top
                    )
                }
            }

            return geometry
        }

        return Qt.rect(
            screenRect.x + screenRect.width * 0.30,
            screenRect.y + screenRect.height * 0.30,
            Math.max(1, screenRect.width * 0.40),
            Math.max(1, screenRect.height * 0.40)
        )
    }

    readonly property var previewGeometry:
        effectiveGeometry()

    visible: isWindow
    enabled: visible

    readonly property real mappedLeft:
        Math.round(
            (
                previewGeometry.x
                - screenData.virtualX
            ) * contentScaleX
        )

    readonly property real mappedTop:
        Math.round(
            (
                previewGeometry.y
                - screenData.virtualY
            ) * contentScaleY
        )

    readonly property real mappedRight:
        Math.round(
            (
                previewGeometry.x
                + previewGeometry.width
                - screenData.virtualX
            ) * contentScaleX
        )

    readonly property real mappedBottom:
        Math.round(
            (
                previewGeometry.y
                + previewGeometry.height
                - screenData.virtualY
            ) * contentScaleY
        )

    x: mappedLeft
    y: mappedTop

    width:
        Math.max(
            1,
            mappedRight - mappedLeft
        )

    height:
        Math.max(
            1,
            mappedBottom - mappedTop
        )

    // Actual compositor/task-model stacking order, not the model's
    // horizontal-position sort order.
    z: stackingOrder

    LiveWindowTile {
        anchors.fill: parent

        taskIndex: root.taskIndex
        tasksModel: root.tasksModel

        isWindow: root.isWindow
        isActive: root.isActive
        isMinimized: root.isMinimized

        isExcludedFromCapture:
            root.isExcludedFromCapture

        winIdList: root.winIdList
        decoration: root.decoration
        displayText: root.displayText

        liveActive: root.liveActive
        showTitle: true

        onActivated:
            root.activated()
    }
}
