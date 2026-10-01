// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: root

    readonly property string primaryAction:
        plasmoid.configuration.primaryAction === "Grid View"
            ? "Grid View"
            : "Overview"

    readonly property string overviewLayout: {
        const configured =
            String(
                plasmoid.configuration.overviewLayout
            )

        const allowed = [
            "natural",
            "reflow",
            "horizontal",
            "vertical",
            "spatial",
            "adaptive"
        ]

        return allowed.indexOf(configured) >= 0
            ? configured
            : "natural"
    }

    readonly property string overviewArrangement:
        String(
            plasmoid.configuration.overviewArrangement
        ) === "adaptive"
            ? "adaptive"
            : "fill"

    readonly property string gridLayout: {
        const configured =
            String(
                plasmoid.configuration.gridLayout
            )

        const allowed = [
            "natural",
            "reflow",
            "horizontal",
            "vertical",
            "spatial",
            "adaptive"
        ]

        return allowed.indexOf(configured) >= 0
            ? configured
            : "spatial"
    }

    readonly property string gridGrouping: {
        const configured =
            String(
                plasmoid.configuration.gridGrouping
            )

        return configured === "screen"
            ? "screen"
            : "desktop"
    }

    readonly property string gridArrangement:
        String(
            plasmoid.configuration.gridArrangement
        ) === "adaptive"
            ? "adaptive"
            : "kde"

    readonly property string actionIcon:
        primaryAction === "Grid View"
            ? "view-grid"
            : "activities"

    readonly property bool usePopup:
        plasmoid.configuration.usePopup

    readonly property string livePreviewMode: {
        const mode = plasmoid.configuration.livePreviewMode
        return mode === "always" || mode === "off"
            ? mode
            : "hover"
    }

    readonly property int previewStartDelay:
        Math.max(
            0,
            Math.min(
                1000,
                plasmoid.configuration.previewStartDelay
            )
        )

    readonly property int previewStopDelay:
        Math.max(
            0,
            Math.min(
                2000,
                plasmoid.configuration.previewStopDelay
            )
        )

    readonly property bool clipSpatialWindows:
        plasmoid.configuration.clipSpatialWindows

    readonly property bool wrapDesktopScrolling:
        plasmoid.configuration.wrapDesktopScrolling

    // Authoritative per-output desktop state from the KWin companion.
    property var screenDesktopState: ({})

    readonly property int buttonSize:
        Kirigami.Units.gridUnit * 2

    readonly property int inlineMinWidth:
        Kirigami.Units.gridUnit * 18

    readonly property int inlineMinHeight:
        Kirigami.Units.gridUnit * 11

    readonly property int inlinePreferredWidth:
        Kirigami.Units.gridUnit * 34

    readonly property int inlinePreferredHeight:
        Kirigami.Units.gridUnit * 21

    readonly property bool horizontalPanel:
        Plasmoid.formFactor === PlasmaCore.Types.Horizontal

    readonly property bool verticalPanel:
        Plasmoid.formFactor === PlasmaCore.Types.Vertical

    readonly property bool inlineRequested:
        !usePopup

    readonly property bool inlineEnoughSpace:
        inlineRequested
        && width >= inlineMinWidth
        && height >= inlineMinHeight

    implicitWidth: {
        if (!inlineRequested) {
            return buttonSize
        }

        if (!horizontalPanel && !verticalPanel) {
            return inlinePreferredWidth
        }

        return buttonSize
    }

    implicitHeight: {
        if (!inlineRequested) {
            return buttonSize
        }

        if (!horizontalPanel && !verticalPanel) {
            return inlinePreferredHeight
        }

        return buttonSize
    }

    Layout.minimumWidth: buttonSize
    Layout.minimumHeight: buttonSize

    Layout.preferredWidth: {
        if (!inlineRequested) {
            return buttonSize
        }

        if (horizontalPanel) {
            return height >= inlineMinHeight
                ? inlinePreferredWidth
                : buttonSize
        }

        if (verticalPanel) {
            return buttonSize
        }

        return inlinePreferredWidth
    }

    Layout.preferredHeight: {
        if (!inlineRequested) {
            return buttonSize
        }

        if (verticalPanel) {
            return width >= inlineMinWidth
                ? inlinePreferredHeight
                : buttonSize
        }

        if (horizontalPanel) {
            return buttonSize
        }

        return inlinePreferredHeight
    }

    activationTogglesExpanded: false
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: actionIcon

    toolTipMainText: i18n("Hover Screens")

    toolTipSubText: {
        if (!usePopup && inlineEnoughSpace) {
            return primaryAction === "Overview"
                ? i18n(
                    "Inline Overview (%1)",
                    overviewLayoutLabel()
                )
                : i18n("Inline Grid View")
        }

        const middle = primaryAction === "Overview"
            ? "Grid View"
            : "Overview"

        return plasmoid.configuration.middleClickEnabled
            ? i18n(
                "Left click: %1\nMiddle click: native %2",
                primaryAction,
                middle
            )
            : i18n("Left click: %1", primaryAction)
    }

    function overviewLayoutLabel() {
        switch (overviewLayout) {
        case "reflow":
            return i18n("Reflow")
        case "horizontal":
            return i18n("Horizontal")
        case "vertical":
            return i18n("Vertical")
        case "spatial":
            return i18n("Spatial")
        case "adaptive":
            return i18n("Adaptive")
        default:
            return i18n("Natural")
        }
    }

    function isAllowedKWinAction(action) {
        return action === "Overview"
            || action === "Grid View"
    }

    function triggerKWinAction(action) {
        if (!isAllowedKWinAction(action)) {
            console.warn(
                "Hover Screens refused unsupported KWin action:",
                action
            )
            return
        }

        invokeKWinShortcut(action)
    }

    function invokeKWinShortcut(action) {
        const pendingReply = DBus.SessionBus.asyncCall({
            "service": "org.kde.kglobalaccel",
            "path": "/component/kwin",
            "iface": "org.kde.kglobalaccel.Component",
            "member": "invokeShortcut",
            "signature": "(s)",
            "arguments": [action]
        })

        pendingReply.finished.connect(() => {
            if (pendingReply.isError) {
                console.warn(
                    "Hover Screens could not invoke " + action + ":",
                    pendingReply.error.message
                )
            }

            pendingReply.destroy()
        })
    }

    function knownScreenName(screenName) {
        const screens = Application.screens

        for (let i = 0; i < screens.length; ++i) {
            if (String(screens[i].name) === String(screenName)) {
                return true
            }
        }

        return false
    }

    function companionOutputKey(screenName) {
        return encodeURIComponent(String(screenName))
    }

    function companionDesktopAction(screenName, desktopNumber) {
        return "HoverScreens.Output."
            + companionOutputKey(screenName)
            + ".Desktop."
            + desktopNumber
    }

    function companionStepAction(screenName, direction) {
        return "HoverScreens.Output."
            + companionOutputKey(screenName)
            + (direction < 0
                ? ".PreviousDesktop"
                : ".NextDesktop")
    }

    function switchScreenToDesktop(screenName, desktopNumber) {
        const number = Number(desktopNumber)

        if (!knownScreenName(screenName)
                || !Number.isInteger(number)
                || number < 1
                || number > 99) {
            console.warn(
                "Hover Screens refused invalid per-screen desktop request:",
                screenName,
                desktopNumber
            )
            return
        }

        // Optimistic UI update; companion state confirms or corrects it.
        updateScreenDesktopState(
            screenName,
            number
        )

        invokeKWinShortcut(
            companionDesktopAction(screenName, number)
        )
    }

    function stepScreenDesktop(screenName, direction) {
        if (!knownScreenName(screenName)
                || (direction !== -1 && direction !== 1)) {
            console.warn(
                "Hover Screens refused invalid per-screen step request:",
                screenName,
                direction
            )
            return
        }

        invokeKWinShortcut(
            companionStepAction(screenName, direction)
        )
    }

    function updateScreenDesktopState(
        screenName,
        desktopNumber
    ) {
        if (!knownScreenName(screenName)) {
            return
        }

        const number = Number(desktopNumber)

        if (!Number.isInteger(number)
                || number < 1) {
            return
        }

        const next = Object.assign(
            {},
            screenDesktopState
        )

        next[String(screenName)] = number
        screenDesktopState = next
    }

    function handleCompanionStateAction(
        shortcutUnique
    ) {
        const text = String(shortcutUnique)

        const match =
            /^HoverScreens\.Output\.(.+)\.Desktop\.([1-9][0-9]*)$/
                .exec(text)

        if (!match) {
            return
        }

        let screenName = ""

        try {
            screenName =
                decodeURIComponent(match[1])
        } catch (error) {
            console.warn(
                "Hover Screens could not decode companion output:",
                match[1]
            )
            return
        }

        updateScreenDesktopState(
            screenName,
            Number(match[2])
        )
    }

    function requestCompanionState() {
        invokeKWinShortcut(
            "HoverScreens.State.Refresh"
        )
    }

    function nativeOtherAction() {
        return primaryAction === "Overview"
            ? "Grid View"
            : "Overview"
    }

    function handlePrimaryClick() {
        if (usePopup) {
            previewPopup.visible = !previewPopup.visible
            return
        }

        if (!inlineEnoughSpace) {
            triggerKWinAction(
                primaryAction === "Grid View"
                    ? "Grid View"
                    : "Overview"
            )
        }
    }

    onPrimaryActionChanged:
        previewPopup.visible = false

    onOverviewLayoutChanged:
        previewPopup.visible = false

    onOverviewArrangementChanged:
        previewPopup.visible = false

    onUsePopupChanged: {
        if (!usePopup) {
            previewPopup.visible = false
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Use Overview")
            checkable: true
            checked: root.primaryAction === "Overview"

            // Disable the active check item so it behaves as a radio choice.
            enabled:
                root.primaryAction !== "Overview"

            onTriggered:
                plasmoid.configuration.primaryAction = "Overview"
        },
        PlasmaCore.Action {
            text: i18n("Use Grid View")
            checkable: true
            checked: root.primaryAction === "Grid View"

            enabled:
                root.primaryAction !== "Grid View"

            onTriggered:
                plasmoid.configuration.primaryAction = "Grid View"
        }
    ]

    // Companion state arrives through KGlobalAccel shortcut signals.
    DBus.SignalWatcher {
        busType: DBus.BusType.Session
        service: "org.kde.kglobalaccel"
        path: "/component/kwin"
        iface: "org.kde.kglobalaccel.Component"

        // SignalWatcher requires the lowercase raw D-Bus member name.
        function dbusglobalShortcutPressed(
            componentUnique,
            shortcutUnique,
            timestamp
        ) {
            root.handleCompanionStateAction(
                shortcutUnique
            )
        }

        // Explicit no-op handlers avoid SignalWatcher warnings.
        function dbusglobalShortcutRepeated(
            componentUnique,
            shortcutUnique,
            timestamp
        ) {
        }

        function dbusglobalShortcutReleased(
            componentUnique,
            shortcutUnique,
            timestamp
        ) {
        }
    }

    Component.onCompleted: {
        Qt.callLater(
            root.requestCompanionState
        )
    }

    PlasmaCore.AppletPopup {
        id: previewPopup

        appletInterface: root
        visualParent: root
        hideOnWindowDeactivate: true
        animated: true

        onVisibleChanged: {
            if (visible) {
                root.requestCompanionState()
            }
        }

        popupDirection: {
            switch (Plasmoid.location) {
            case PlasmaCore.Types.TopEdge:
                return Qt.BottomEdge
            case PlasmaCore.Types.LeftEdge:
                return Qt.RightEdge
            case PlasmaCore.Types.RightEdge:
                return Qt.LeftEdge
            case PlasmaCore.Types.BottomEdge:
            default:
                return Qt.TopEdge
            }
        }

        mainItem: PreviewSurface {
            mode: root.primaryAction
            overviewLayout: root.overviewLayout
            overviewArrangement: root.overviewArrangement
            gridLayout: root.gridLayout
            gridGrouping: root.gridGrouping
            gridArrangement: root.gridArrangement
            screenDesktopState: root.screenDesktopState

            presentationActive: previewPopup.visible
            livePreviewMode: root.livePreviewMode
            previewStartDelay: root.previewStartDelay
            previewStopDelay: root.previewStopDelay
            clipSpatialWindows: root.clipSpatialWindows
            wrapDesktopScrolling: root.wrapDesktopScrolling
            closeOnActivate: true

            onRequestClose:
                previewPopup.visible = false

            onRequestScreenDesktopActivate:
                (screenName, number) =>
                    root.switchScreenToDesktop(
                        screenName,
                        number
                    )

            onRequestScreenDesktopStep:
                (screenName, direction) =>
                    root.stepScreenDesktop(
                        screenName,
                        direction
                    )
        }
    }

    PreviewSurface {
        id: inlineSurface

        anchors.fill: parent
        visible: root.inlineEnoughSpace

        mode: root.primaryAction
        overviewLayout: root.overviewLayout
        overviewArrangement: root.overviewArrangement
        gridLayout: root.gridLayout
        gridGrouping: root.gridGrouping
        gridArrangement: root.gridArrangement
        screenDesktopState: root.screenDesktopState

        presentationActive: visible
        livePreviewMode: root.livePreviewMode
        previewStartDelay: root.previewStartDelay
        previewStopDelay: root.previewStopDelay
        clipSpatialWindows: root.clipSpatialWindows
        wrapDesktopScrolling: root.wrapDesktopScrolling
        closeOnActivate: false

        onRequestScreenDesktopActivate:
            (screenName, number) =>
                root.switchScreenToDesktop(
                    screenName,
                    number
                )

        onRequestScreenDesktopStep:
            (screenName, direction) =>
                root.stepScreenDesktop(
                    screenName,
                    direction
                )
    }

    Item {
        anchors.fill: parent
        visible: !root.inlineEnoughSpace

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.smallSpacing
            color: Kirigami.Theme.highlightColor

            opacity: mouseArea.pressed
                ? 0.24
                : (
                    mouseArea.containsMouse
                    || previewPopup.visible
                        ? 0.10
                        : 0
                )
        }

        Kirigami.Icon {
            anchors.centerIn: parent

            width:
                Math.min(parent.width, parent.height) * 0.68

            height: width
            source: root.actionIcon
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            acceptedButtons:
                Qt.LeftButton | Qt.MiddleButton

            onClicked: function(mouse) {
                if (mouse.button === Qt.MiddleButton) {
                    previewPopup.visible = false

                    if (plasmoid.configuration.middleClickEnabled) {
                        root.triggerKWinAction(
                            root.nativeOtherAction()
                        )
                    }

                    return
                }

                root.handlePrimaryClick()
            }
        }
    }
}
