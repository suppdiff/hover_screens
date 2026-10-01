// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

Item {
    id: root

    required property var tasksModel
    required property var screenData
    required property string layoutMode
    required property bool liveActive
    required property bool clipSpatialWindows

    property bool closeOnActivate: false
    property int stackingRevision: 0

    signal requestClose()

    clip: true

    Connections {
        target: root.tasksModel

        function onDataChanged(topLeft, bottomRight, roles) {
            root.stackingRevision += 1
        }

        function onModelReset() {
            root.stackingRevision += 1
        }
    }

    Loader {
        anchors {
            fill: parent

            leftMargin:
                root.layoutMode === "spatial"
                    ? 0
                    : Kirigami.Units.smallSpacing / 2

            rightMargin:
                root.layoutMode === "spatial"
                    ? 0
                    : Kirigami.Units.smallSpacing / 2

            topMargin:
                root.layoutMode === "spatial"
                    ? 0
                    : Kirigami.Units.smallSpacing / 2

            bottomMargin:
                root.layoutMode === "spatial"
                    ? 0
                    : Kirigami.Units.smallSpacing / 2
        }

        clip: true

        sourceComponent:
            root.layoutMode === "spatial"
                ? spatialComponent
                : packedComponent
    }

    Component {
        id: packedComponent

        OverviewWindowLayout {
            tasksModel: root.tasksModel
            layoutMode: root.layoutMode
            liveActive: root.liveActive

            closeOnActivate:
                root.closeOnActivate

            onRequestClose:
                root.requestClose()
        }
    }

    Component {
        id: spatialComponent

        Item {
            id: spatialArea

            clip: true

            readonly property real contentScaleX:
                Math.max(
                    0.001,
                    width
                        / Math.max(
                            1,
                            root.screenData.width
                        )
                )

            readonly property real contentScaleY:
                Math.max(
                    0.001,
                    height
                        / Math.max(
                            1,
                            root.screenData.height
                        )
                )

            Rectangle {
                anchors.fill: parent

                radius:
                    Kirigami.Units.smallSpacing / 2

                color:
                    Kirigami.Theme.alternateBackgroundColor

                opacity: 0.25
            }

            Repeater {
                model: root.tasksModel

                delegate: Item {
                    id: spatialRoleAdapter

                    required property var model
                    required property int index

                    readonly property real actualStackingOrder: {
                        const revision =
                            root.stackingRevision

                        const modelIndex =
                            root.tasksModel.makeModelIndex(
                                spatialRoleAdapter.index
                            )

                        const value =
                            root.tasksModel.data(
                                modelIndex,
                                TaskManager.AbstractTasksModel.StackingOrder
                            )

                        const numeric =
                            Number(value)

                        return Number.isFinite(numeric)
                            ? numeric
                            : spatialRoleAdapter.index
                    }

                    anchors.fill: parent
                    z: actualStackingOrder

                    ScreenSpatialWindow {
                        taskIndex:
                            spatialRoleAdapter.index

                        tasksModel:
                            root.tasksModel

                        isWindow:
                            Boolean(
                                spatialRoleAdapter.model.IsWindow
                            )

                        isActive:
                            Boolean(
                                spatialRoleAdapter.model.IsActive
                            )

                        isMinimized:
                            Boolean(
                                spatialRoleAdapter.model.IsMinimized
                            )

                        isExcludedFromCapture:
                            Boolean(
                                spatialRoleAdapter.model.IsExcludedFromCapture
                            )

                        geometry:
                            spatialRoleAdapter.model.Geometry

                        stackingOrder:
                            spatialRoleAdapter.actualStackingOrder

                        winIdList:
                            spatialRoleAdapter.model.WinIdList

                        decoration:
                            spatialRoleAdapter.model.decoration

                        displayText:
                            String(
                                spatialRoleAdapter.model.display ?? ""
                            )

                        screenData:
                            root.screenData

                        liveActive:
                            root.liveActive

                        clipToScreenBounds:
                            root.clipSpatialWindows

                        contentScaleX:
                            spatialArea.contentScaleX

                        contentScaleY:
                            spatialArea.contentScaleY

                        onActivated: {
                            if (root.closeOnActivate) {
                                root.requestClose()
                            }
                        }
                    }
                }
            }
        }
    }
}
