# Overworld Map Rendering

## Goal
After a project loads, the center canvas shows the decoded 256×256 overworld map, drawn from the
same tile atlas as the Palette panel. You can pan and zoom around it, and the status bar shows the
tile under the cursor.

## Scope
In:
- `TileMapLayer` rendering of the whole map from a `TileSet` built on the shared atlas texture.
- Pan: middle-drag, or Space + left-drag.
- Zoom: the wheel steps through `¼, ½, 1, 2, 3, 4, 6, 8×` around the cursor.
- Initial view: 1×, with tile `($99, $A5)` centered.
- Clamped view: the canvas center always stays over the map. The view does not wrap.
- Status bar cursor readout in hex.

Out:
- Drawing or editing tiles, selection, and tool behavior. Left-click without Space does nothing yet.
- A wrapped view, grid overlay, minimap, and teleport or object overlays.
- Remembering the view between sessions.
- Keyboard pan and zoom shortcuts.

## Shared atlas
- `map_editor.gd` builds `ImageTexture.create_from_image(tileset.build_atlas())` once per load and
  passes it to both the left bar and the canvas.
- `PaletteGrid.show_tileset(tileset)` becomes `show_atlas(atlas: Texture2D)`. The same rename
  applies to the forwarding methods on `PalettePanel` and `LeftBar`.

## Code

### `src/project/overworld_tileset.gd` (changes)
- `static func atlas_cell(tile: int) -> Vector2i` returns
  `Vector2i(tile % ATLAS_COLUMNS, tile / ATLAS_COLUMNS)`. This is the one place for the formula.
- `atlas_origin(tile)` becomes `atlas_cell(tile) * TILE_SIZE`.
- `atlas_tile_at` keeps its behavior.

### `src/map_editor/map_canvas/map_canvas.tscn`
```
MapCanvas (Control, clip_contents, focus_mode = click, script map_canvas.gd)
  Background (TextureRect, full rect, checker.svg, tile stretch, mouse_filter = ignore)
  MapView (Node2D, unique name)
    MapLayer (TileMapLayer, unique name, texture_filter = nearest)
```
The checker moves from the root onto `Background`.

### `src/map_editor/map_canvas/map_canvas.gd`: `class_name MapCanvas extends Control`
- `signal cursor_moved(cell: Vector2i)`, where `NO_CELL := Vector2i(-1, -1)` means off the map.
- `const ZOOM_STEPS := [0.25, 0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0]`, `const DEFAULT_ZOOM := 1.0`,
  `const INITIAL_CENTER_CELL := Vector2i(0x99, 0xA5)`, `const ATLAS_SOURCE_ID := 0`
- `const MAP_PIXELS := Vector2(OverworldMap.SIZE, OverworldMap.SIZE) * OverworldTileset.TILE_SIZE`
- `func show_map(map: OverworldMap, atlas: Texture2D) -> void`
  1. Build a `TileSet` with `tile_size = Vector2i.ONE * TILE_SIZE` and one `TileSetAtlasSource`
     (`texture = atlas`, `texture_region_size = Vector2i.ONE * TILE_SIZE`). Call `create_tile(atlas_cell(t))`
     for each of the `TILE_COUNT` tiles, then assign it to `MapLayer`.
  2. `MapLayer.clear()`, then call `set_cell(Vector2i(x, y), ATLAS_SOURCE_ID, atlas_cell(map.get_tile(x, y)))`
     for every cell.
  3. Reset the view to `DEFAULT_ZOOM` and center it on `INITIAL_CENTER_CELL`.
- View state is `_zoom_index` and `_center: Vector2`, the map-pixel point at the canvas center.
  One `_apply_view()` sets `MapView.scale = Vector2.ONE * zoom` and
  `MapView.position = size / 2 - _center * zoom`.
- `func map_point_at(local_pos: Vector2) -> Vector2` returns `_center + (local_pos - size / 2) / zoom`.
  This is the one screen→map formula, used by cursor, zoom and hit-testing.
- `func cell_at(local_pos: Vector2) -> Vector2i` returns the cell from `map_point_at`, or `NO_CELL`
  when it falls outside `[0, SIZE)` or no map is shown.
- `func center_on_cell(cell: Vector2i)` sets `_center = (Vector2(cell) + Vector2.ONE * 0.5) * TILE_SIZE`,
  then clamps and applies.
- `func zoom_at(local_pos: Vector2, steps: int)` keeps the map point under `local_pos` fixed while
  changing `_zoom_index` (clamped to `ZOOM_STEPS`). It then clamps and applies.
- `func pan_by(screen_delta: Vector2)` does `_center -= screen_delta / zoom`, then clamps and applies.
- `static func clamp_center(center: Vector2) -> Vector2` clamps to `[0, MAP_PIXELS]`. This is the rule
  that keeps the canvas center over the map.
- Input (`_gui_input`), all ignored until a map is shown:
  - Wheel up/down: `zoom_at(event.position, ±1)`.
  - Middle press, or left press while `Input.is_key_pressed(KEY_SPACE)`: start a pan. Motion while
    panning calls `pan_by(event.relative)`, and the release ends it.
  - Motion emits `cursor_moved(cell_at(event.position))` when the cell changes.
    `NOTIFICATION_MOUSE_EXIT` emits `NO_CELL`.
- `NOTIFICATION_RESIZED` calls `_apply_view()`. Because `_center` is stored in map space, the tile at
  the canvas center stays put.

### `src/map_editor/status_bar/status_bar.gd` (additions)
- `static func format_cursor(cell: Vector2i) -> String` returns `"X: $%02X  Y: $%02X"`, or
  `"X: —  Y: —"` for `MapCanvas.NO_CELL`.
- `func show_cursor(cell: Vector2i)` sets `%CursorLabel.text`.

### `src/map_editor/map_editor.gd` / `map_editor.tscn`
- `@onready var _map_canvas: MapCanvas = %MapCanvas`
- After a successful load, build the atlas texture once, then call `_left_bar.show_atlas(atlas)` and
  `_map_canvas.show_map(project.overworld_map, atlas)`.
- Add a `[connection signal="cursor_moved" from="VBox/MainSplit/MapCanvas" to="." method="_on_map_cursor_moved"]`.
  The handler calls `_status_bar.show_cursor(cell)`.

## Tests
`tests/unit/project/test_overworld_tileset.gd`:
- `atlas_cell` for the first tile, the last tile of row 0, the first tile of row 1 and the last tile.
  `atlas_origin == atlas_cell * TILE_SIZE` for every tile.

`tests/unit/map_editor/test_palette_grid.gd`:
- Update for `show_atlas`.

`tests/unit/map_editor/test_map_canvas.gd` (instances `map_canvas.tscn` with `add_child_autofree`
and a fixed size, then calls `show_map` with a synthetic map from `OverworldMapBuilder` whose rows
vary by `y`, plus a blank atlas `ImageTexture` of `ATLAS_SIZE`):
- Every cell's atlas coords equal `atlas_cell(map.get_tile(x, y))` (sampled at corners and center).
- After `show_map`, `cell_at(size / 2) == INITIAL_CENTER_CELL` and the zoom is `DEFAULT_ZOOM`.
- `zoom_at` keeps `cell_at(cursor)` the same across a zoom in and a zoom out, and clamps at both
  ends of `ZOOM_STEPS`.
- `pan_by` a huge delta in each direction keeps `cell_at(size / 2)` inside the map.
- `cell_at` returns `NO_CELL` off the map and before any map is shown.
- `cursor_moved` is emitted with the cell under a simulated motion event, and with `NO_CELL` on
  mouse exit (`watch_signals`).

`tests/unit/map_editor/test_status_bar.gd`:
- `format_cursor` for `NO_CELL`, `Vector2i.ZERO` and `Vector2i.ONE * (OverworldMap.SIZE - 1)`.

## Verification
1. Rung 1: `--import` for `MapCanvas`, then the headless boot check.
2. Rung 2: scoped GUT runs, then the full suite.
3. Rung 3: run the editor and open `ROMAssembly/assets`.
4. Rung 4: you confirm the map renders correctly around ($99, $A5), panning and zooming feel right,
   the edges clamp, and the status bar coordinates match the tile under the cursor.
