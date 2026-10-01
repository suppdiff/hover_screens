// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: root

    required property var desktopId
    required property int desktopNumber
    required property string desktopName
    required property string layoutMode
    required property bool liveActive
    required property bool clipSpatialWindows

    signal requestScreenDesktopActivate(
        string screenName,
        int desktopNumber
    )

    radius:
        Kirigami.Units.smallSpacing

    color:
        Kirigami.Theme.backgroundColor

    clip: true

    function screenBounds() {
        const screens =
            Application.screens

        if (!screens || screens.length === 0) {
            return {
                "x": 0,
                "y": 0,
                "width": 1,
                "height": 1
            }
        }

        let left =
            screens[0].virtualX

        let top =
            screens[0].virtualY

        let right =
            left + screens[0].width

        let bottom =
            top + screens[0].height

        for (let i = 1; i < screens.length; ++i) {
            const screen =
                screens[i]

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
            "width":
                Math.max(
                    1,
                    right - left
                ),
            "height":
                Math.max(
                    1,
                    bottom - top
                )
        }
    }

    readonly property var virtualBounds:
        screenBounds()

    Rectangle {
        anchors.fill: parent

        radius:
            parent.radius

        color: "transparent"

        border.width: 1

        border.color:
            Kirigami.Theme.textColor

        opacity: 0.24
        z: 50
    }

    PlasmaComponents3.Label {
        id: label

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top

            margins:
                Kirigami.Units.smallSpacing
        }

        text:
            root.desktopName

        elide:
            Text.ElideRight

        z: 60
    }

    Item {
        id: topologyViewport

        anchors {
            left: parent.left
            right: parent.right
            top: label.bottom
            bottom: parent.bottom

            margins:
                Kirigami.Units.smallSpacing
        }

        clip: true

        readonly property real padding:
            Kirigami.Units.smallSpacing / 2

        readonly property bool preservePhysicalAspect:
            root.layoutMode === "spatial"

        readonly property real availableWidth:
            Math.max(
                1,
                width - padding * 2
            )

        readonly property real availableHeight:
            Math.max(
                1,
                height - padding * 2
            )

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
                ? (
                    width - topologyWidth
                ) / 2
                : padding

        readonly property real topologyY:
            preservePhysicalAspect
                ? (
                    height - topologyHeight
                ) / 2
                : padding

        Repeater {
            model:
                Application.screens

            delegate: GridScreenSurface {
                required property var modelData

                x:
                    topologyViewport.topologyX
                    + (
                        modelData.virtualX
                        - root.virtualBounds.x
                    ) * topologyViewport.topologyScaleX

                y:
                    topologyViewport.topologyY
                    + (
                        modelData.virtualY
                        - root.virtualBounds.y
                    ) * topologyViewport.topologyScaleY

                width:
                    Math.max(
                        1,
                        modelData.width
                            * topologyViewport.topologyScaleX
                    )

                height:
                    Math.max(
                        1,
                        modelData.height
                            * topologyViewport.topologyScaleY
                    )

                screenData:
                    modelData

                desktopId:
                    root.desktopId

                desktopNumber:
                    root.desktopNumber

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
