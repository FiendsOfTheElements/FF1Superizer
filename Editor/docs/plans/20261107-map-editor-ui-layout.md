# Map Editor UI Layout — static shell

## Goal
Build the initial, non-interactive layout of the FF1 map editor screen from the Layout section of
`docs/Editor Spec.md`. Every region exists as its own scene with placeholder content, so later work
adds behavior into a settled structure.

## Scope
In:
- Top toolbar, left bar, right bar, center map canvas, status bar.
- Resizable sidebars (splitters) and resizable panels within each sidebar.
- Placeholder icons, a starter theme, and a static checkerboard canvas.

Out:
- Any behavior: tool switching, map loading, drawing, undo/redo, saving, settings.
- File menu bar (toolbar file buttons only).
- Treasure, NPC and encounter-domain inspectors (only Teleports in the right bar).
- Modals.

## Cleanup
- Delete `src/main.tscn`, `src/money_panel.gd`, `src/money_panel.gd.uid`, `src/money_panel.tscn`.
- `project.godot`: `run/main_scene` → `src/map_editor/map_editor.tscn`.

## Scene tree

```
src/map_editor/
  map_editor.tscn            Control (full rect), theme = map_editor_theme.tres
  map_editor.gd              sets window min size only
  map_editor_theme.tres
  sidebar_panel.tscn         base panel: PanelContainer > VBox > Title(Label) + Body(Control, expand)
  top_toolbar/
    top_toolbar.tscn
    tool_options_bar.tscn
  left_bar/
    left_bar.tscn
    map_picker.tscn
    palette_panel.tscn        inherits sidebar_panel.tscn
    tile_properties_panel.tscn inherits sidebar_panel.tscn
  right_bar/
    right_bar.tscn
    minimap_panel.tscn        inherits sidebar_panel.tscn
    teleports_panel.tscn      inherits sidebar_panel.tscn
    history_panel.tscn        inherits sidebar_panel.tscn
  map_canvas/
    map_canvas.tscn
  status_bar/
    status_bar.tscn
assets/icons/                 16px SVGs: new, open, save, undo, redo, select, pencil, line,
                              rectangle, ellipse, fill
assets/textures/checker.svg   tile-sized checker for the canvas placeholder
```

`map_editor.tscn` layout:

```
MapEditor (Control, full rect)
  VBox
    TopToolbar
    MainSplit (HSplitContainer, expand)
      LeftBar            min width 280
      CenterSplit (HSplitContainer, expand)
        MapCanvas        expand
        RightBar         min width 280
    StatusBar
```

If 4.7's `SplitContainer` supports more than two children, use one three-child `HSplitContainer`
instead of nesting.

### Top toolbar
An HBox in a PanelContainer, with groups separated by `VSeparator`:
- File: New, Open, Save
- History: Undo, Redo
- Tools: Select, Pencil, Line, Rectangle, Ellipse, Fill. These are toggle buttons in a shared
  `ButtonGroup` resource (declared in the tscn) with Pencil pressed by default.
- `ToolOptionsBar` (expand): an empty HBox that later holds each tool's options.

Every button has `icon` set from `assets/icons`, no text, and a `tooltip_text`.

### Left bar
A `VSplitContainer` stack:
1. MapPicker: an `OptionButton` with one item, "Overworld" (not inside a splitter pane, so it sits
   at the top with a fixed height)
2. PalettePanel ("Palette")
3. TilePropertiesPanel ("Tile Properties")

### Right bar
A `VSplitContainer` stack: MinimapPanel ("Minimap"), TeleportsPanel ("Teleports"),
HistoryPanel ("History").

### Map canvas
A `TextureRect` with `checker.svg`, `stretch_mode = tile` and `clip_contents`. No input handling.

### Status bar
An HBox in a PanelContainer, with labels left to right:
- `CursorLabel`: "X: —  Y: —"
- spacer (expand)
- `MapNameLabel`: "Overworld"
- `DirtyLabel`: "Saved"

## Window
- `display/window/size/viewport_width=1600`, `viewport_height=900`.
- `display/window/stretch/mode="disabled"`, so the UI keeps a fixed pixel scale and resizing the
  window gives more room instead of scaling.
- Minimum size 1280×720, set in `map_editor.gd` (`get_window().min_size`), because no project
  setting exists for it.

## Theme
`map_editor_theme.tres` starts from Godot's default look and sets only:
- `PanelContainer` stylebox with 6px content margins
- a `SidebarTitle` type variation on `Label` (bold or larger font) used by `sidebar_panel.tscn`

## Conventions
- Layout, theme overrides, ButtonGroup and all properties live in `.tscn`. The only script is
  `map_editor.gd`.
- Unique names (`%Name`) on nodes that later work will need: tool buttons, ToolOptionsBar, MapPicker,
  panel bodies, status labels.

## Verification
1. Rung 1: `godot --headless --path . --import`, then `--headless --quit-after 5` boot. Grep for
   `SCRIPT ERROR` / `ERROR`.
2. Rung 3: run the scene at 1600×900 and at 1280×720 and capture screenshots. Confirm that every
   region is visible, the splitters drag, icons render, and the canvas checker tiles.
3. Rung 4: the user signs off on the look.
