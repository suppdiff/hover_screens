// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.pipewire as PipeWire
import org.kde.plasma.components as PlasmaComponents3
import org.kde.taskmanager as TaskManager

Item {
    id: root

    required property int taskIndex
    required property var tasksModel
    required property bool isWindow
    required property bool isActive
    required property bool isMinimized
    required property bool isExcludedFromCapture
    required property var winIdList
    required property var decoration
    required property string displayText
    required property bool liveActive

    property bool showTitle: true

    signal activated()

    function idToString(value) {
        if (value === undefined || value === null) {
            return ""
        }

        if (typeof value === "string") {
            return value
        }

        if (value instanceof ArrayBuffer) {
            const bytes = new Uint8Array(value)
            let result = ""

            for (let i = 0; i < bytes.length; ++i) {
                result += String.fromCharCode(bytes[i])
            }

            return result
        }

        if (ArrayBuffer.isView
                && ArrayBuffer.isView(value)) {
            const bytes = new Uint8Array(
                value.buffer,
                value.byteOffset,
                value.byteLength
            )

            let result = ""

            for (let i = 0; i < bytes.length; ++i) {
                result += String.fromCharCode(bytes[i])
            }

            return result
        }

        return String(value)
    }

    readonly property string windowUuid:
        winIdList && winIdList.length > 0
            ? idToString(winIdList[0])
            : ""

    readonly property bool captureAllowed:
        liveActive
        && isWindow
        && !isExcludedFromCapture
        && windowUuid.length > 0

    visible: isWindow
    enabled: visible

    Rectangle {
        anchors.fill: parent

        radius:
            Math.max(
                1,
                Kirigami.Units.smallSpacing / 2
            )

        color: Kirigami.Theme.backgroundColor
        clip: true

        Loader {
            id: streamLoader

            anchors.fill: parent
            active: root.captureAllowed
            asynchronous: true

            sourceComponent: PipeWire.PipeWireSourceItem {
                anchors.fill: parent
                nodeId: screencast.nodeId

                TaskManager.ScreencastingRequest {
                    id: screencast
                    uuid: root.windowUuid
                }
            }
        }

        Kirigami.Icon {
            anchors.centerIn: parent

            width:
                Math.max(
                    Kirigami.Units.iconSizes.small,
                    Math.min(
                        parent.width,
                        parent.height
                    ) * 0.34
                )

            height: width
            source: root.decoration

            visible:
                !streamLoader.item
                || !streamLoader.item.ready

            opacity:
                root.captureAllowed ? 0.46 : 0.76
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            visible:
                root.showTitle
                && parent.width
                    >= Kirigami.Units.gridUnit * 4
                && parent.height
                    >= Kirigami.Units.gridUnit * 2.4

            height:
                Math.min(
                    Kirigami.Units.gridUnit * 1.05,
                    parent.height * 0.24
                )

            color: Kirigami.Theme.backgroundColor
            opacity: 0.91

            Row {
                anchors {
                    fill: parent

                    leftMargin:
                        Kirigami.Units.smallSpacing / 2

                    rightMargin:
                        Kirigami.Units.smallSpacing / 2
                }

                spacing:
                    Kirigami.Units.smallSpacing / 2

                Kirigami.Icon {
                    anchors.verticalCenter:
                        parent.verticalCenter

                    width:
                        Math.min(
                            Kirigami.Units.iconSizes.small,
                            parent.height * 0.66
                        )

                    height: width
                    source: root.decoration
                }

                PlasmaComponents3.Label {
                    anchors.verticalCenter:
                        parent.verticalCenter

                    width:
                        Math.max(
                            0,
                            parent.width
                                - Kirigami.Units.iconSizes.small
                                - parent.spacing
                                - Kirigami.Units.smallSpacing
                        )

                    text: root.displayText
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    font.pixelSize:
                        Math.max(
                            8,
                            Math.min(
                                Kirigami.Theme.defaultFont.pixelSize,
                                parent.height * 0.48
                            )
                        )

                    font.bold: root.isActive
                }
            }
        }

        Rectangle {
            anchors.fill: parent

            radius: parent.radius
            color: "transparent"

            border.width:
                root.isActive ? 2 : 1

            border.color:
                root.isActive
                    ? Kirigami.Theme.highlightColor
                    : Kirigami.Theme.textColor

            opacity:
                root.isActive ? 0.92 : 0.24

            z: 20
        }

        Rectangle {
            anchors.fill: parent

            radius: parent.radius
            color: Kirigami.Theme.highlightColor

            opacity:
                pointer.containsMouse
                    ? (pointer.pressed ? 0.18 : 0.09)
                    : 0

            z: 21
        }

        MouseArea {
            id: pointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: 22

            QQC2.ToolTip.visible:
                containsMouse
                && root.displayText.length > 0

            QQC2.ToolTip.text:
                root.displayText

            QQC2.ToolTip.delay: 650

            onClicked: {
                root.tasksModel.requestActivate(
                    root.tasksModel.makeModelIndex(
                        root.taskIndex
                    )
                )

                root.activated()
            }
        }
    }
}
