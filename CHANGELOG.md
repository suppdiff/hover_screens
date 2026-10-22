# Changelog

## 1.0.0

- Initial public release.


## 1.0.1

### Bugfixes
- Fixed an intermittent Plasma/KWin freeze and heavy-load regression that could appear around monitor disconnects, reconnects, or other output changes.
- Heavy Overview/Grid TaskManager scenes are now created only while a Hover Screens presentation is actually visible instead of remaining instantiated for hidden popup and inline surfaces.
- Ignore repeated per-output desktop-state publications when the desktop value has not changed, avoiding unnecessary QML state invalidation and preview-tree rebinding.
- Fixed a `DesktopStrip` lifecycle error during screen/desktop model teardown by anchoring desktop buttons to the stable desktop row instead of a transient delegate parent.
- Preserved existing Overview, Grid, Spatial, Adaptive, desktop controls, and live-preview behavior.
