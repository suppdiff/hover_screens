// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

Rectangle {
    id: root

    required property var screenData
    required property var desktopId
    required property int desktopNumber
    required property string layoutMode
    required property bool liveActive
    required property bool clipSpatialWindows

    signal requestScreenDesktopActivate(
        string screenName,
        int desktopNumber
    )

    radius:
        Math.max(
            1,
            Kirigami.Units.smallSpacing / 2
        )

    color:
        Kirigami.Theme.backgroundColor

    clip: true

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
        filterByCurrentVirtualDesktop: false

        virtualDesktop:
            root.desktopId

        filterByVirtualDesktop:
            String(root.desktopId).length > 0

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

    // Empty screen/background clicks switch only this exact physical output.
    // Window previews sit above this MouseArea and keep their own activation.
    MouseArea {
        anchors.fill: parent

        acceptedButtons:
            Qt.LeftButton

        cursorShape:
            Qt.PointingHandCursor

        onClicked:
            root.requestScreenDesktopActivate(
                String(root.screenData.name),
                root.desktopNumber
            )
    }

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

        closeOnActivate: false
    }

    Rectangle {
        anchors.fill: parent

        radius:
            parent.radius

        color: "transparent"

        border.width: 1

        border.color:
            Kirigami.Theme.textColor

        opacity: 0.22
        z: 40
    }
}
