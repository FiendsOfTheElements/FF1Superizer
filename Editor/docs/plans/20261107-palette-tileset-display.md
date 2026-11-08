# Palette Tileset Display

## Goal
Once a project loads, the Palette panel shows the 128 overworld tiles as a 16×8 grid. Clicking a
tile selects it, and the hovered tile is outlined. Later work uses the selection for drawing tools
and the Tile Properties panel.

## Scope
In:
- Composing the 128 16×16 tiles (tilemaps + chr + palette) into one atlas `Image`.
- A palette grid control in the Palette panel: 16 columns, integer zoom fit to width, vertical
  scroll.
- Click to select, with selected and hover outlines and a `tile_selected(tile)` signal.

Out:
- Any consumer of the selection: drawing tools, Tile Properties panel, status bar.
- Map canvas rendering. It will reuse the atlas later.
- Tooltips, gridlines and empty-state text. The panel is blank until a project loads.
- Keyboard navigation of the grid.
- Rebuilding the atlas after edits. There is no editing yet.

## Rendering rules
- A tile is 2×2 chr: corner `Corner.UL/UR/LL/LR` sits at
  `(corner % 2, corner / 2) * CHR_SIZE` inside the tile.
- A pixel's color is `palette[chr_pixel(...)]`. Index 0 is drawn as an opaque `palette[0]`, because
  that is what the SNES shows: a transparent Mode 7 pixel reveals the backdrop, which is CGRAM color 0.
- A pixel index at or past `palette.size()` is drawn in `OverworldTileset.MISSING_COLOR`
  (`Color.CYAN`, #00FFFF), so broken data stands out. The palette can be shorter than 128 colors,
  and the atlas must not crash on such data.
- Atlas layout: tile `t` sits at column `t % ATLAS_COLUMNS`, row `t / ATLAS_COLUMNS`.

## Code

### `src/project/overworld_tileset.gd` (additions)
- `const TILE_SIZE := CHR_SIZE * 2`
- `const ATLAS_COLUMNS := 16`, `const ATLAS_ROWS := TILE_COUNT / ATLAS_COLUMNS`
- `const ATLAS_SIZE := Vector2i(ATLAS_COLUMNS, ATLAS_ROWS) * TILE_SIZE`
- `const MISSING_COLOR := Color.CYAN`
- `static func atlas_origin(tile: int) -> Vector2i`. This is the one place the tile→atlas formula
  lives, used by the atlas build and by the grid's hit-testing and outlines.
- `func build_atlas() -> Image` returns `Image.FORMAT_RGBA8` at `ATLAS_SIZE`, filled per the rules above.

### `src/map_editor/left_bar/palette_grid.gd`: `class_name PaletteGrid extends Control`
- `signal tile_selected(tile: int)`
- `var _texture: ImageTexture`, `var _zoom := 1`, `var _selected := 0`, `var _hovered := -1`
- `func show_tileset(tileset: OverworldTileset)` builds the atlas texture, resets `_selected` to 0,
  updates the layout and redraws. It does not emit, because a selection only comes from a click.
- `static func zoom_for_width(width: float) -> int` returns `maxi(1, floori(width / ATLAS_SIZE.x))`.
- `func tile_at(local_pos: Vector2) -> int` returns -1 outside the drawn atlas.
- Layout: on `NOTIFICATION_RESIZED` and in `show_tileset`, set `_zoom` from `size.x` and set
  `custom_minimum_size.y = ATLAS_SIZE.y * _zoom`. With no texture the minimum height is 0.
  The ScrollContainer sets the width, and the minimum height drives vertical scrolling.
- `_gui_input`: mouse motion updates `_hovered`, and a left-button press sets `_selected` and emits
  `tile_selected`. `NOTIFICATION_MOUSE_EXIT` clears `_hovered`. Each change calls `queue_redraw()`
  only when the value changed.
- `_draw`: draws the texture at `(0, 0)`, sized `ATLAS_SIZE * _zoom`. It then draws the hover
  outline (1px, white at 50% alpha) and the selected outline (1px white, plus a 1px dark inner
  rectangle). One `_tile_rect(tile) -> Rect2` helper serves both outlines.
- `texture_filter = TEXTURE_FILTER_NEAREST` is set in the scene.

### `src/map_editor/left_bar/palette_panel.tscn` / `palette_panel.gd`
- Under the inherited `%Body`: `ScrollContainer` (full rect, `horizontal_scroll_mode = DISABLED`)
  › `PaletteGrid` (unique name, `size_flags_horizontal = EXPAND_FILL`, `mouse_filter = STOP`).
- `palette_panel.gd`: `func show_tileset(tileset)` forwards to `%PaletteGrid`.

### `src/map_editor/left_bar/left_bar.gd` (new, on `left_bar.tscn`)
- `func show_tileset(tileset)` forwards to `%PalettePanel`.

### `src/map_editor/map_editor.gd`
- `@onready var _left_bar: LeftBar = %LeftBar`
- After a successful load, call `_left_bar.show_tileset(project.overworld_tileset)`.

`tile_selected` stays on `PaletteGrid` for now. It gets forwarded up through `PalettePanel` and
`LeftBar` once something consumes it.

## Tests
`tests/unit/project/test_overworld_tileset.gd` (additions), using a synthetic tileset built from
the class constants:
- `atlas_origin` for tile 0, the last tile of row 0, the first tile of row 1 and the last tile.
- `build_atlas` returns an image of `ATLAS_SIZE`.
- Corner placement: give each corner of the last tile a distinct chr whose pixel (0,0) has a
  distinct palette index, then check the four atlas pixels at `atlas_origin + corner offset`.
- Index 0 renders `palette[0]` opaque.
- An index at or past `palette.size()` renders `MISSING_COLOR`.

`tests/unit/map_editor/test_palette_grid.gd`:
- `zoom_for_width` gives 1 below `2 * ATLAS_SIZE.x`, 2 at exactly `2 * ATLAS_SIZE.x`, and 1 (never 0)
  for widths under `ATLAS_SIZE.x`.
- `tile_at`: with a grid instance sized for zoom 2 and a texture shown, the centers of the first and
  last tiles map back to their indices, and a point past the atlas gives -1.

`tests/integration/project/test_real_assets.gd` (addition):
- Building the atlas from the real tileset gives `ATLAS_SIZE`, and no chr pixel indexes past the
  palette, so no `MISSING_COLOR` comes from bad indices. A pixel comparison isn't used, because a
  real palette color could legitimately be cyan.

## Verification
1. Rung 1: `--import` (for `PaletteGrid` and `LeftBar`), then the headless boot check.
2. Rung 2: scoped GUT runs, then the full suite.
3. Rung 3: run the editor, open `ROMAssembly/assets`, and capture the left bar at the default width
   and with it widened past 2×.
4. Rung 4: you confirm the tiles look right and that clicking and hovering behave as expected.
