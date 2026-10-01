// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.taskmanager as TaskManager

Item {
    id: root

    required property var screenData
    required property real headerExtent
    required property bool compactHeader
    required property bool liveActive
    required property int currentDesktopNumber
    required property string layoutMode
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

    readonly property real headerHeight:
        Kirigami.Units.gridUnit * 1.55

    readonly property real headerGap:
        Math.max(
            0,
            headerExtent - headerHeight
        )

    readonly property real surfaceHeight:
        compactHeader
            ? Math.max(
                1,
                height
            )
            : Math.max(
                1,
                height - headerExtent
            )

    readonly property bool floatingHeader:
        !compactHeader
        && width >= Kirigami.Units.gridUnit * 9
        && surfaceHeight >= Kirigami.Units.gridUnit * 7

    clip: false

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    TaskManager.TasksModel {
        id: screenTasks

        activity:
            activityInfo.currentActivity

        filterByActivity: true

        screenGeometry: Qt.rect(
            root.screenData.virtualX,
            root.screenData.virtualY,
            root.screenData.width,
            root.screenData.height
        )

        filterByScreen: true
        filterByCurrentVirtualDesktop: true
        filterHidden: true

        groupMode:
            TaskManager.TasksModel.GroupDisabled

        separateLaunchers: false

        sortMode:
            root.layoutMode === "spatial"
                || root.layoutMode === "natural"
                || root.layoutMode === "adaptive"
                ? TaskManager.TasksModel.SortWindowPositionHorizontal
                : TaskManager.TasksModel.SortLastActivated
    }

    Rectangle {
        id: screenPane

        x: 0

        y:
            root.compactHeader
                ? 0
                : root.headerExtent

        width: root.width
        height: root.surfaceHeight

        radius:
            Math.max(
                1,
                Kirigami.Units.smallSpacing / 2
            )

        color:
            Kirigami.Theme.backgroundColor

        clip: true

        ScreenLayoutSurface {
            anchors.fill: parent

            tasksModel:
                screenTasks

            screenData:
                root.screenData

            layoutMode:
                root.layoutMode

            liveActive:
                root.liveActive

            clipSpatialWindows:
                root.clipSpatialWindows

            closeOnActivate:
                root.closeOnActivate

            onRequestClose:
                root.requestClose()
        }

        Rectangle {
            anchors.fill: parent

            radius:
                parent.radius

            color: "transparent"

            border.width: 1

            border.color:
                Kirigami.Theme.textColor

            opacity: 0.25
            z: 40
        }

        WheelHandler {
            target: null

            acceptedDevices:
                PointerDevice.Mouse
                | PointerDevice.TouchPad

            onWheel: function(event) {
                if (event.angleDelta.y === 0
                        || (
                            event.modifiers
                            & Qt.ShiftModifier
                        ) !== 0) {
                    return
                }

                desktopStrip.requestStep(
                    event.angleDelta.y > 0
                        ? -1
                        : 1
                )

                event.accepted = true
            }
        }
    }

    Rectangle {
        id: headerSurface

        x: 0
        y: 0

        width: root.width
        height: root.headerHeight

        visible:
            !root.compactHeader

        enabled:
            visible

        radius:
            Kirigami.Units.smallSpacing

        color:
            root.floatingHeader
                ? Kirigami.Theme.backgroundColor
                : Kirigami.Theme.alternateBackgroundColor

        opacity:
            root.floatingHeader
                ? 0.94
                : 0.86

        border.width:
            root.floatingHeader
                ? 1
                : 0

        border.color:
            Kirigami.Theme.textColor

        z: 60

        RowLayout {
            anchors {
                fill: parent

                leftMargin:
                    Kirigami.Units.smallSpacing

                rightMargin:
                    Kirigami.Units.smallSpacing
            }

            spacing:
                Kirigami.Units.smallSpacing

            DesktopStrip {
                id: desktopStrip

                Layout.fillWidth: true

                Layout.minimumHeight:
                    root.headerHeight
                        - Kirigami.Units.smallSpacing

                Layout.preferredHeight:
                    root.headerHeight
                        - Kirigami.Units.smallSpacing

                Layout.maximumHeight:
                    root.headerHeight
                        - Kirigami.Units.smallSpacing

                screenName:
                    String(root.screenData.name)

                authoritativeDesktopNumber:
                    root.currentDesktopNumber

                wrapDesktopScrolling:
                    root.wrapDesktopScrolling

                onDesktopRequested:
                    (screenName, desktopNumber) =>
                        root.requestScreenDesktopActivate(
                            screenName,
                            desktopNumber
                        )

                onDesktopStepRequested:
                    (screenName, direction) =>
                        root.requestScreenDesktopStep(
                            screenName,
                            direction
                        )
            }
        }
    }

    Rectangle {
        id: compactDesktopStatus

        visible:
            root.compactHeader

        enabled: false

        x:
            Kirigami.Units.smallSpacing / 2

        y:
            Kirigami.Units.smallSpacing / 2

        height:
            Math.min(
                Kirigami.Units.gridUnit * 1.2,
                Math.max(
                    Kirigami.Units.gridUnit * 0.9,
                    root.height * 0.18
                )
            )

        width:
            Math.min(
                Math.max(
                    compactDesktopLabel.implicitWidth
                        + Kirigami.Units.smallSpacing * 2,
                    Kirigami.Units.gridUnit * 2.6
                ),
                Math.max(
                    1,
                    root.width
                        - Kirigami.Units.smallSpacing
                )
            )

        radius:
            Kirigami.Units.smallSpacing

        color:
            Kirigami.Theme.backgroundColor

        opacity: 0.82
        z: 60

        PlasmaComponents3.Label {
            id: compactDesktopLabel

            anchors {
                fill: parent

                leftMargin:
                    Kirigami.Units.smallSpacing

                rightMargin:
                    Kirigami.Units.smallSpacing
            }

            verticalAlignment:
                Text.AlignVCenter

            horizontalAlignment:
                Text.AlignHCenter

            text:
                desktopStrip.selectedDesktopLabel

            elide:
                Text.ElideRight

            maximumLineCount: 1
        }
    }
}
