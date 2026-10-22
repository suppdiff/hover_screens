// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.taskmanager as TaskManager

Item {
    id: root

    required property string screenName
    required property int authoritativeDesktopNumber
    required property bool wrapDesktopScrolling

    signal desktopRequested(
        string screenName,
        int desktopNumber
    )

    signal desktopStepRequested(
        string screenName,
        int direction
    )

    readonly property int desktopCount:
        desktopInfo.desktopIds.length

    readonly property string selectedDesktopLabel: {
        const number =
            selectedDesktopNumber

        if (number >= 1
                && number <= desktopInfo.desktopNames.length) {
            const name =
                String(
                    desktopInfo.desktopNames[
                        number - 1
                    ]
                )

            if (name.length > 0) {
                return name
            }
        }

        return number >= 1
            ? i18n(
                "Desktop %1",
                number
            )
            : i18n("Desktop")
    }


    readonly property int targetVisibleButtons: 3

    readonly property real buttonSpacing:
        Kirigami.Units.smallSpacing / 2

    readonly property real targetButtonWidth:
        Math.max(
            Kirigami.Units.gridUnit * 2.35,
            Math.min(
                Kirigami.Units.gridUnit * 5.4,
                (
                    width
                    - buttonSpacing
                        * (targetVisibleButtons - 1)
                ) / targetVisibleButtons
            )
        )

    readonly property bool hasOverflow:
        desktopFlick.contentWidth
            > desktopFlick.width + 1

    readonly property bool hasTrailingOverflow:
        hasOverflow
        && desktopFlick.contentX
            < desktopFlick.contentWidth
                - desktopFlick.width - 1

    property int selectedDesktopNumber: 0

    implicitHeight:
        Kirigami.Units.gridUnit * 1.45

    TaskManager.VirtualDesktopInfo {
        id: desktopInfo
    }

    function applyAuthoritativeSelection() {
        const number =
            Number(authoritativeDesktopNumber)

        if (Number.isInteger(number)
                && number >= 1
                && number <= desktopCount) {
            selectedDesktopNumber = number
            Qt.callLater(ensureSelectedVisible)
            return
        }

        if (selectedDesktopNumber > desktopCount) {
            selectedDesktopNumber = 0
        }
    }

    function setLocalSelection(number) {
        if (desktopCount <= 0) {
            return
        }

        const clamped =
            Math.max(
                1,
                Math.min(desktopCount, number)
            )

        selectedDesktopNumber = clamped

        Qt.callLater(ensureSelectedVisible)
    }

    function requestDesktop(number) {
        if (desktopCount <= 0) {
            return
        }

        setLocalSelection(number)

        desktopRequested(
            screenName,
            selectedDesktopNumber
        )
    }

    function requestStep(direction) {
        if (desktopCount <= 0
                || (direction !== -1
                    && direction !== 1)) {
            return
        }

        // Prefer the authoritative KWin-reported state when available. The
        // selected value is only the immediate optimistic display state.
        let base =
            Number(
                authoritativeDesktopNumber
            )

        if (!Number.isInteger(base)
                || base < 1
                || base > desktopCount) {
            base = selectedDesktopNumber
        }

        if (base < 1 || base > desktopCount) {
            base = 1
        }

        let next = base + direction

        if (next < 1) {
            if (!wrapDesktopScrolling) {
                return
            }

            next = desktopCount
        } else if (next > desktopCount) {
            if (!wrapDesktopScrolling) {
                return
            }

            next = 1
        }

        setLocalSelection(next)

        desktopStepRequested(
            screenName,
            direction
        )
    }

    function ensureSelectedVisible() {
        if (selectedDesktopNumber < 1) {
            return
        }

        const item =
            desktopRepeater.itemAt(
                selectedDesktopNumber - 1
            )

        if (!item) {
            return
        }

        const left = item.x
        const right = item.x + item.width
        const viewLeft = desktopFlick.contentX
        const viewRight =
            desktopFlick.contentX
            + desktopFlick.width

        if (left < viewLeft) {
            desktopFlick.contentX =
                Math.max(0, left)
        } else if (right > viewRight) {
            desktopFlick.contentX =
                Math.min(
                    Math.max(
                        0,
                        desktopFlick.contentWidth
                            - desktopFlick.width
                    ),
                    right - desktopFlick.width
                )
        }
    }

    Component.onCompleted:
        applyAuthoritativeSelection()

    onAuthoritativeDesktopNumberChanged:
        applyAuthoritativeSelection()

    Connections {
        target: desktopInfo

        function onDesktopIdsChanged() {
            root.applyAuthoritativeSelection()
        }
    }

    Flickable {
        id: desktopFlick

        anchors.fill: parent

        contentWidth: desktopRow.implicitWidth
        contentHeight: height

        clip: true
        interactive: contentWidth > width

        boundsBehavior:
            Flickable.StopAtBounds

        Row {
            id: desktopRow

            height: desktopFlick.height
            spacing: root.buttonSpacing

            Repeater {
                id: desktopRepeater

                model: desktopInfo.desktopIds

                delegate: Rectangle {
                    id: desktopButton

                    required property var modelData
                    required property int index

                    readonly property int desktopNumber:
                        index + 1

                    readonly property bool selected:
                        root.selectedDesktopNumber
                            === desktopNumber

                    height:
                        Math.max(
                            Kirigami.Units.gridUnit * 1.15,
                            desktopRow.height
                                - Kirigami.Units.smallSpacing / 2
                        )

                    width: root.targetButtonWidth

                    // Bind to the stable row id, not the transient delegate
                    // parent (which can become null during model teardown).
                    anchors.verticalCenter: desktopRow.verticalCenter

                    radius:
                        Kirigami.Units.smallSpacing

                    color: selected
                        ? Kirigami.Theme.highlightColor
                        : (
                            pointer.hovered
                                ? Kirigami.Theme.alternateBackgroundColor
                                : "transparent"
                        )

                    border.width:
                        selected || pointer.hovered
                            ? 1
                            : 0

                    border.color: selected
                        ? Kirigami.Theme.highlightedTextColor
                        : Kirigami.Theme.textColor

                    PlasmaComponents3.Label {
                        id: desktopLabel

                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter:
                                parent.verticalCenter
                            margins:
                                Kirigami.Units.smallSpacing
                        }

                        text: {
                            const names =
                                desktopInfo.desktopNames

                            if (desktopButton.index
                                    < names.length
                                    && String(
                                        names[
                                            desktopButton.index
                                        ]
                                    ).length > 0) {
                                return names[
                                    desktopButton.index
                                ]
                            }

                            return i18n(
                                "Desktop %1",
                                desktopButton.desktopNumber
                            )
                        }

                        color: desktopButton.selected
                            ? Kirigami.Theme.highlightedTextColor
                            : Kirigami.Theme.textColor

                        horizontalAlignment:
                            Text.AlignHCenter

                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    HoverHandler {
                        id: pointer
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton

                        onTapped:
                            root.requestDesktop(
                                desktopButton.desktopNumber
                            )
                    }

                    QQC2.ToolTip.visible:
                        pointer.hovered
                        && desktopLabel.truncated

                    QQC2.ToolTip.text:
                        desktopLabel.text

                    QQC2.ToolTip.delay: 500
                }
            }
        }

        // No visible scrollbar. Dragging still pans this Flickable.
        QQC2.ScrollBar.horizontal:
            QQC2.ScrollBar {
                policy: QQC2.ScrollBar.AlwaysOff
            }

        WheelHandler {
            target: null

            acceptedDevices:
                PointerDevice.Mouse
                | PointerDevice.TouchPad

            onWheel: function(event) {
                const horizontal =
                    event.angleDelta.x !== 0

                const panModifier =
                    (event.modifiers
                        & Qt.ShiftModifier) !== 0

                // Shift+wheel and horizontal wheel are exclusively strip-pan
                // gestures. If there is nothing to pan, consume them as a
                // no-op instead of falling through to desktop switching.
                if (horizontal || panModifier) {
                    if (desktopFlick.contentWidth
                            > desktopFlick.width) {
                        const delta = horizontal
                            ? event.angleDelta.x
                            : event.angleDelta.y

                        desktopFlick.contentX =
                            Math.max(
                                0,
                                Math.min(
                                    desktopFlick.contentWidth
                                        - desktopFlick.width,
                                    desktopFlick.contentX
                                        - delta
                                )
                            )
                    }

                    event.accepted = true
                    return
                }

                if (event.angleDelta.y === 0) {
                    return
                }

                root.requestStep(
                    event.angleDelta.y > 0
                        ? -1
                        : 1
                )

                event.accepted = true
            }
        }
    }

    // Quiet trailing hint rather than a scrollbar.
    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }

        width:
            Kirigami.Units.gridUnit * 1.05

        visible: root.hasTrailingOverflow

        color: Kirigami.Theme.backgroundColor
        opacity: 0.88
        z: 20

        PlasmaComponents3.Label {
            anchors.centerIn: parent
            text: "…"
            font.bold: true
            opacity: 0.68
        }
    }
}
