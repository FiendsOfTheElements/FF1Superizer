# Map Canvas Navigation & Minimap

## Goal
Make the center map canvas navigable (pan, zoom, fit-to-region) and make the Minimap panel a live
thumbnail of the map with a view box you can click, drag and wheel. A generated placeholder map
replaces the checkerboard so motion and position are readable. Real tile rendering comes later and
slots into the same canvas.

## Scope
In:
- Placeholder terrain map (generated, fixed seed) with a 16-tile coordinate grid and labels.
- Canvas: middle-drag pan, WASD/arrow pan, wheel and `-`/`=` zoom, fit-to-tile-rect API, Home to
  fit the whole map, fit on startup and on project load, edge clamping.
- Minimap: 4×4-px-per-tile thumbnail scaled to fit its panel, view box overlay, click-to-glide,
  drag-to-pan, wheel zoom.
- Status bar: cursor tile and zoom percent.

Out:
- Rendering real tiles from `Project` (the placeholder stays even after a project loads).
- Wrap-around panning.
- Selection, drawing tools, any trigger of fit-to-rect other than Home and load.
- Minimap box-drag to fit a region.

## Files

```
src/project/overworld_tileset.gd         + const TILE_SIZE := CHR_SIZE * 2
src/map_editor/map_canvas/
  map_view.gd                            class_name MapView (RefCounted): pure view math
  placeholder_terrain.gd                 class_name PlaceholderTerrain: generates the placeholder Image
  map_canvas.gd                          class_name MapCanvas (Control): input, drawing, animation
  map_canvas.tscn                        TextureRect → Control with map_canvas.gd
src/map_editor/right_bar/
  minimap.gd                             class_name Minimap (PanelContainer) on the MinimapPanel root;
                                         draws on and reads input from %Body via [connection]s
  minimap_panel.tscn                     script on root; Body min size 256×256
  right_bar.gd                           relays Minimap signals up, view updates down
  right_bar.tscn                         script; custom_minimum_size.x 280 → 268
src/map_editor/status_bar/
  status_bar.gd / .tscn                  show_cursor_tile(), show_zoom(); new ZoomLabel
src/map_editor/map_editor.gd / .tscn     builds the placeholder, hands it down, [connection]s
project.godot                            input actions
assets/textures/checker.svg (+ .import)  delete
tests/unit/map_editor/
  test_map_view.gd
  test_placeholder_terrain.gd
  test_minimap_layout.gd
```

## Units
- **World px**: map pixels at 1× zoom. The map is `OverworldMap.SIZE * OverworldTileset.TILE_SIZE`
  = 4096 world px square.
- **Zoom**: screen px per world px, range `1/16` to `16`, any value in between.
- **View**: `center` (world px, `Vector2`) + `zoom` + canvas `size`. Only the canvas's own rect
  counts toward the visible area, never the sidebars, toolbar or status bar.

## MapView (pure math, fully unit-tested)
`RefCounted` holding `center: Vector2`, `zoom: float`, `view_size: Vector2`. Every formula lives
here once; the canvas and minimap both go through it.

- `const MIN_ZOOM := 1.0 / 16.0`, `MAX_ZOOM := 16.0`, `ZOOM_STEP := 1.25`, `GLIDE_DURATION := 0.15`
- `map_size() -> Vector2` from `OverworldMap.SIZE * OverworldTileset.TILE_SIZE`
- `world_to_screen(p)`, `screen_to_world(p)`
- `visible_world_rect() -> Rect2`
- `clamp_center()`: center ∈ `[0, map_size]` on each axis. This lets the view go half a canvas past
  any edge (a corner can sit mid-screen).
- `zoom_about(anchor_world: Vector2, new_zoom: float)`: clamps zoom, keeps `anchor_world` at the
  same screen position, then clamps the center
- `stepped_zoom(from: float, steps: int) -> float`: `from * ZOOM_STEP ** steps`, clamped
- `fit_zoom(world_rect: Rect2) -> float`: the largest zoom that fits the rect in the view, clamped
- `world_to_tile(world: Vector2) -> Vector2i`
- `tile_rect_to_world(rect: Rect2i) -> Rect2`

## Placeholder terrain
`PlaceholderTerrain.generate() -> Image`: `OverworldMap.SIZE`² image, one pixel per tile,
`FORMAT_RGB8`.
- `FastNoiseLite` with a const seed and fractal (fbm) simplex noise, sampled per tile.
- Six bands by threshold, as a const `Array[Color]` and thresholds: deep ocean, shallow water, sand,
  grass, forest, mountain. The output is identical on every run.

## MapCanvas
`Control`, `clip_contents`, `focus_mode = FOCUS_CLICK`, `texture_filter = NEAREST`.

Public API:
- `set_map_image(image: Image)`: builds an `ImageTexture` and redraws
- `fit_tile_rect(rect: Rect2i, duration: float)`
- `fit_map(duration: float)`: `fit_tile_rect` over the whole map
- `pan_to(world: Vector2, duration: float)`: used by the minimap
- `zoom_step_at(steps: int, anchor_world: Vector2)`: used by wheel, keys and the minimap

Signals:
- `view_changed(visible_world_rect: Rect2, zoom: float)`: emitted after any view change or resize
- `cursor_tile_changed(tile: Vector2i, on_map: bool)`

Behavior:
- **Middle-drag**: on press, `grab_focus()` and kill any running glide. While moving,
  `center -= relative / zoom` 1:1, then clamp. No smoothing.
- **Keyboard pan** (only while `has_focus()`): in `_process`, take the direction from the
  `map_pan_*` actions, normalized. Speed is `PAN_SPEED_SCREEN := 1000.0` screen px/s divided by
  zoom, times `PAN_BOOST := 3.0` while `map_pan_boost` (Shift) is held. Linear, with an instant stop.
- **Zoom**: the wheel (anchor = world point under the cursor) and `map_zoom_in`/`map_zoom_out`
  (anchor = view center, echo allowed) call `zoom_step_at`. It retargets from the current *target*
  zoom so fast wheeling stacks. The animation is a linear `create_tween()` on the canvas over
  `ZOOM_DURATION := 0.08` s, driving zoom and applying `MapView.zoom_about` with the fixed anchor
  each frame. A new step kills and replaces the tween. Nothing awaits the tween.
- **Glide** (`pan_to` / `fit_*` with duration > 0): a linear tween of center (and zoom for fit).
  Middle-drag, keyboard pan and a minimap drag kill it.
- **Fit**: `map_fit` (Home) calls `fit_map(MapView.GLIDE_DURATION)`.
  Startup and project load call `fit_map(0.0)`. The startup fit waits for the canvas's first
  non-zero size (`resized`).
- **Resize**: keep center and zoom, re-clamp, emit `view_changed`.
- **Draw**:
  1. Fill the area outside the map with the theme panel color.
  2. Draw the map texture scaled to `map_size() * zoom` at `world_to_screen(Vector2.ZERO)`.
  3. Grid every 16 tiles in screen space, 1 px, `Color(1, 1, 1, 0.15)`, skipped when the spacing is
     under 8 screen px.
  4. Labels `"x,y"` (tile coords) at each crossing, offset 3 px, theme default font at 12 px, white
     with a 2 px black outline (`draw_string_outline` then `draw_string`). Skipped when the spacing
     is under 48 screen px. Only crossings inside the visible rect are drawn.

## Minimap
Script on the `MinimapPanel` root (`texture_filter = NEAREST`). `%Body`'s `draw` and `gui_input`
signals connect to it in `minimap_panel.tscn`, so `RightBar` reaches it as `%MinimapPanel`.

- `set_map_image(image: Image)`: copies the image and resizes it ×4 with `INTERPOLATE_NEAREST` to a
  1024² thumbnail (`THUMB_TILE_PX := 4`), then builds an `ImageTexture`.
- `show_view(visible_world_rect: Rect2)`: stores the rect and redraws.
- Layout: `static func thumb_rect(body_size: Vector2) -> Rect2` returns the largest centered square.
  This is the one mapping function, with `minimap_to_world()` / `world_to_minimap()` built on it.
- Default size: RightBar min width 268 minus the 2 × 6 px panel margins leaves a 256 px body, so the
  thumbnail draws at exactly ¼ scale (1 px per tile). Body `custom_minimum_size = (256, 256)` keeps
  it there unless the user drags a splitter. Larger panels scale it up freely.
- **View box**: the visible world rect mapped into the thumbnail, clipped to the control. 1 px white
  outline, with a 1 px dark (`Color(0, 0, 0, 0.75)`) outline just outside it.
- **Left press**: record the position and emit `focus_canvas_requested`.
  - Move past `DRAG_THRESHOLD := 4.0` px → dragging: emit `pan_requested(world, 0.0)` on each motion
    (box center tracks the cursor).
  - Release without dragging → `pan_requested(world, GLIDE_DURATION)`. The glide starts on mouse-up
    only.
  - Positions in the letterbox clamp to the thumbnail.
- **Wheel**: `zoom_requested(steps, world_under_cursor)`.

Signals: `pan_requested(world: Vector2, duration: float)`,
`zoom_requested(steps: int, anchor_world: Vector2)`, `focus_canvas_requested`.

## Wiring
Components never reference each other. `%Name` is scene-local, so:
- `right_bar.gd` re-declares the three minimap signals, re-emits them (connected in
  `right_bar.tscn`), and exposes `show_view()` / `set_map_image()`, which forward to `%MinimapPanel`.
- MapCanvas accepts pan-key events in `_gui_input`, so the arrow keys don't trigger `ui_*` focus
  navigation.
- `map_editor.tscn` `[connection]`s:
  - RightBar `pan_requested` → MapCanvas `pan_to`
  - RightBar `zoom_requested` → MapCanvas `zoom_step_at`
  - RightBar `focus_canvas_requested` → MapCanvas `grab_focus`
  - MapCanvas `view_changed` → RightBar `show_view` (a minimap overlay update, so the zoom arg is
    unbound in the connection)
  - MapCanvas `view_changed` → MapEditor `_on_view_changed` → `StatusBar.show_zoom`
  - MapCanvas `cursor_tile_changed` → StatusBar `show_cursor_tile`
- `map_editor.gd` `_ready`: `PlaceholderTerrain.generate()` → `%MapCanvas.set_map_image()` and
  `%RightBar.set_map_image()`. On a successful project load: `%MapCanvas.fit_map(0.0)`.

## Status bar
- `show_cursor_tile(tile, on_map)`: `"X: %d  Y: %d"`, or `"X: —  Y: —"` when off the map or
  the cursor leaves the canvas.
- `show_zoom(zoom)`: a new `ZoomLabel` after CursorLabel, `"%d%%" % roundi(zoom * 100)`.

## Input actions (`project.godot`)
| Action | Keys |
|---|---|
| `map_pan_left` | A, Left |
| `map_pan_right` | D, Right |
| `map_pan_up` | W, Up |
| `map_pan_down` | S, Down |
| `map_pan_boost` | Shift |
| `map_zoom_in` | `=`, Keypad + |
| `map_zoom_out` | `-`, Keypad − |
| `map_fit` | Home |

The canvas reads these only while it has focus, so typing in other panels never pans.

## Tests (GUT, data-driven from the classes' own constants)
- `test_map_view.gd`:
  - world↔screen round-trip
  - `zoom_about` keeps the anchor's screen position, at an anchor inside and one outside the view
  - zoom clamps at `MIN_ZOOM` / `MAX_ZOOM`
  - `stepped_zoom` stacks
  - `clamp_center` bounds equal `[0, map_size()]`
  - `fit` of the whole map and of a sub-rect contains the rect and touches the view on one axis
  - `visible_world_rect` matches `view_size / zoom`
- `test_placeholder_terrain.gd`:
  - the size is `OverworldMap.SIZE`²
  - two calls produce identical bytes
  - every band color appears
- `test_minimap_layout.gd`:
  - `thumb_rect` is square, centered and fits
  - a 256 body maps 1 px per tile
  - `minimap_to_world` ∘ `world_to_minimap` round-trip
  - letterbox points clamp into the map

## Verification
1. Rung 1: `--headless --path . --import` (new `class_name`s), then a `--quit-after 5` boot, grep
   `SCRIPT ERROR`.
2. Rung 2: the full GUT suite.
3. Rung 3: run `map_editor.tscn` at 1600×900 and capture:
   - the startup fit
   - the minimap at exactly 256 px with the box around the whole view
   - zoomed in on a corner, with the box in the corner and labels readable
4. Rung 4: the user checks the feel (drag 1:1, key speed and boost, wheel stacking, minimap
   click-glide versus drag, Home).
