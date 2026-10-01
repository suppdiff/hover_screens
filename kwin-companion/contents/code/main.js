// SPDX-License-Identifier: GPL-3.0-or-later

"use strict";

// Exact per-output virtual-desktop switching and state publication.

const registeredActions = Object.create(null);

const STATE_REFRESH_ACTION =
    "HoverScreens.State.Refresh";

function outputKey(name) {
    return encodeURIComponent(String(name));
}

function desktopActionName(outputName, desktopNumber) {
    return "HoverScreens.Output."
        + outputKey(outputName)
        + ".Desktop."
        + desktopNumber;
}

function previousActionName(outputName) {
    return "HoverScreens.Output."
        + outputKey(outputName)
        + ".PreviousDesktop";
}

function nextActionName(outputName) {
    return "HoverScreens.Output."
        + outputKey(outputName)
        + ".NextDesktop";
}

function outputByName(outputName) {
    const screens = workspace.screens;

    for (let i = 0; i < screens.length; ++i) {
        if (String(screens[i].name) === String(outputName)) {
            return screens[i];
        }
    }

    return null;
}

function desktopByNumber(desktopNumber) {
    const desktops = workspace.desktops;
    const index = Number(desktopNumber) - 1;

    if (!Number.isInteger(index)
            || index < 0
            || index >= desktops.length) {
        return null;
    }

    return desktops[index];
}

function desktopIndexById(desktopId) {
    const desktops = workspace.desktops;

    for (let i = 0; i < desktops.length; ++i) {
        if (String(desktops[i].id) === String(desktopId)) {
            return i;
        }
    }

    return -1;
}

function currentDesktopNumberForOutput(output) {
    if (!output) {
        return 0;
    }

    const current =
        workspace.currentDesktopForScreen(output);

    if (!current) {
        return 0;
    }

    const index =
        desktopIndexById(current.id);

    return index >= 0 ? index + 1 : 0;
}

function invokeRegisteredAction(objectName) {
    // KGlobalAccel emits globalShortcutPressed before delivering the action
    // back to KWin. Hover Screens watches that D-Bus signal and treats these
    // exact desktop action names as authoritative state messages.
    callDBus(
        "org.kde.kglobalaccel",
        "/component/kwin",
        "org.kde.kglobalaccel.Component",
        "invokeShortcut",
        objectName
    );
}

function publishOutputState(outputName) {
    const output =
        outputByName(outputName);

    if (!output) {
        return;
    }

    const desktopNumber =
        currentDesktopNumberForOutput(output);

    if (desktopNumber < 1) {
        return;
    }

    invokeRegisteredAction(
        desktopActionName(
            outputName,
            desktopNumber
        )
    );
}

function publishAllState() {
    const screens = workspace.screens;

    for (let i = 0; i < screens.length; ++i) {
        publishOutputState(
            String(screens[i].name)
        );
    }
}

function switchOutputToDesktop(
    outputName,
    desktopNumber
) {
    const output =
        outputByName(outputName);

    const desktop =
        desktopByNumber(desktopNumber);

    if (!output || !desktop) {
        return;
    }

    const current =
        workspace.currentDesktopForScreen(output);

    // State publication invokes the already-registered desktop action. When
    // that action describes the desktop this output is already on, do nothing.
    // This prevents state-publication recursion.
    if (current
            && String(current.id)
                === String(desktop.id)) {
        return;
    }

    workspace.setCurrentDesktopForScreen(
        desktop,
        output
    );

    publishOutputState(outputName);
}

function stepOutputDesktop(
    outputName,
    direction
) {
    const output =
        outputByName(outputName);

    if (!output
            || (direction !== -1
                && direction !== 1)) {
        return;
    }

    const desktops = workspace.desktops;

    if (!desktops || desktops.length === 0) {
        return;
    }

    const current =
        workspace.currentDesktopForScreen(output);

    let currentIndex =
        current
            ? desktopIndexById(current.id)
            : -1;

    if (currentIndex < 0) {
        currentIndex = 0;
    }

    let nextIndex =
        currentIndex + direction;

    if (nextIndex < 0) {
        nextIndex = desktops.length - 1;
    } else if (nextIndex >= desktops.length) {
        nextIndex = 0;
    }

    workspace.setCurrentDesktopForScreen(
        desktops[nextIndex],
        output
    );

    publishOutputState(outputName);
}

function registerActionOnce(
    objectName,
    text,
    callback
) {
    if (registeredActions[objectName]) {
        return;
    }

    if (registerShortcut(
            objectName,
            text,
            "",
            callback
        )) {
        registeredActions[objectName] = true;
    }
}

function registerOutputActions(outputName) {
    const desktops = workspace.desktops;

    for (let i = 0; i < desktops.length; ++i) {
        const desktopNumber = i + 1;

        const objectName =
            desktopActionName(
                outputName,
                desktopNumber
            );

        registerActionOnce(
            objectName,
            "Hover Screens: "
                + outputName
                + " → Desktop "
                + desktopNumber,
            function() {
                switchOutputToDesktop(
                    outputName,
                    desktopNumber
                );
            }
        );
    }

    registerActionOnce(
        previousActionName(outputName),
        "Hover Screens: "
            + outputName
            + " → Previous Desktop",
        function() {
            stepOutputDesktop(
                outputName,
                -1
            );
        }
    );

    registerActionOnce(
        nextActionName(outputName),
        "Hover Screens: "
            + outputName
            + " → Next Desktop",
        function() {
            stepOutputDesktop(
                outputName,
                1
            );
        }
    );
}

function registerAllActions() {
    registerActionOnce(
        STATE_REFRESH_ACTION,
        "Hover Screens: Refresh per-screen desktop state",
        function() {
            publishAllState();
        }
    );

    const screens = workspace.screens;

    for (let i = 0; i < screens.length; ++i) {
        registerOutputActions(
            String(screens[i].name)
        );
    }
}

function topologyChanged() {
    registerAllActions();
    publishAllState();
}

registerAllActions();
publishAllState();

workspace.screensChanged.connect(
    topologyChanged
);

workspace.desktopsChanged.connect(
    topologyChanged
);

// Publish the complete per-output state after desktop changes.
workspace.currentDesktopChanged.connect(
    publishAllState
);
