# Project Asset Loader

## Goal
The toolbar **Open** button asks for an assets directory and loads the overworld assets from it into
typed, in-memory data. That data is what the map canvas, palette panel and tile-properties panel
will render and edit later.

## Scope
In:
- Toolbar Open button → native folder picker → load.
- Decode into typed data:
  - `data/overworld-map.bin` (RLE → 256×256 tile indices)
  - `data/overworld-tilemaps.bin` (128 tiles × 4 chr indices)
  - `data/overworld-tileproperties.bin` (128 × 16-bit words, with named flags)
  - `graphics/overworld-chr.m7` (256 chr × 8×8 indexed pixels)
  - `graphics/overworld-map-palette.pal` (up to 128 BGR555 colors → `Color`)
- An error dialog when a load fails. On success, the status bar shows the project.

Out:
- Menu bar. Opening uses only the toolbar button.
- Any rendering: textures, tile atlas, canvas drawing, palette panel contents.
- Saving, backups, settings, remembering or auto-reopening the last project.
- ROM import and first-run asset generation.
- Every other asset file (sprites, font, title screen, battle).

## Directory picked
The user picks the **assets folder itself**, the one that holds `data/` and `graphics/` (for example
`ROMAssembly/assets`).

## File formats (verified against `ROMAssembly/assets`)

| File | Size | Layout |
|---|---|---|
| `overworld-map.bin` | any | 256 × u16 LE row offsets from file start (row 0 at `0x200`), then RLE rows. Trailing bytes after the last row are ignored. The file is valid exactly when it decompresses to 256×256 tiles. |
| `overworld-tilemaps.bin` | 512 | Four planar tables of 128 chr indices each, in order UL, UR, LL, LR. Tile *t*'s corner *c* is at `c*128 + t`. |
| `overworld-tileproperties.bin` | 256 | 128 × u16 LE words. |
| `overworld-chr.m7` | 16384 | 256 chr × 64 bytes, one byte per pixel (palette index), row-major. |
| `overworld-map-palette.pal` | 2–256 (128 today) | 1 to 128 × u16 LE SNES BGR555 (`0bbbbbgggggrrrrr`). |

**RLE row** (from the FF1 overworld format):
- byte `0xFF` ends the row
- byte `< 0x80`: one tile with that index
- byte `>= 0x80`: tile `b & 0x7F`, then a count byte; a count of `0` means 256

A valid row decodes to exactly 256 tiles before its `0xFF`.

**Tile property word** (from `ROMAssembly/includes/defines.inc`, `OWTP_*`):

| Bits | Meaning |
|---|---|
| `0x0001` | no walk |
| `0x0002` | no canoe |
| `0x0004` | no ship |
| `0x0008` | no airship landing |
| `0x0010` | forest |
| `0x0020` | dock |
| `0x00C0` | event: `0x00` none, `0x40` chime, `0x80` caravan, `0xC0` airship (floater) |
| `0x4000` | fight; the low bits of the high byte select the domain: `0x4000` land, `0x4100` river, `0x4200` ocean |
| `0x8000` | teleport; `(word >> 8) & 0x7F` is the teleport index |

The word is stored as-is, so bits we don't model survive a future save unchanged.

## Code layout

```
src/project/
  project.gd                 class_name Project (RefCounted)
  project_loader.gd          class_name ProjectLoader (RefCounted, static funcs only)
  overworld_map.gd           class_name OverworldMap (RefCounted)
  overworld_tileset.gd       class_name OverworldTileset (RefCounted)
  tile_properties.gd         class_name TileProperties (RefCounted)
  snes_palette.gd            class_name SnesPalette (RefCounted)
src/map_editor/
  top_toolbar/top_toolbar.gd       new: signal open_requested
  status_bar/status_bar.gd         new: show_project(dir)
  map_editor.gd                    owns `project: Project`, the dialogs, and the load flow
```

### `OverworldMap`
- `const SIZE := 256`, `const ROW_TABLE_BYTES := SIZE * 2`, `const RUN_FLAG := 0x80`,
  `const ROW_END := 0xFF`
- `var tiles: PackedByteArray` holds `SIZE * SIZE` bytes, row-major
- `func get_tile(x: int, y: int) -> int`
- `static func decode(bytes: PackedByteArray, errors: PackedStringArray) -> OverworldMap`. It
  validates that every row's offset can be read and points inside the file, every row ends in
  `ROW_END` within the file, and every row decodes to exactly `SIZE` tiles. Each failure appends a message
  that names the row, and the function returns `null` if any errors occurred.

### `OverworldTileset`
- `const TILE_COUNT := 128`, `enum Corner { UL, UR, LL, LR }`, `const CHR_COUNT := 256`,
  `const CHR_SIZE := 8`, `const CHR_BYTES := CHR_SIZE * CHR_SIZE`
- `const TILEMAP_BYTES := TILE_COUNT * Corner.size()`, `const CHR_DATA_BYTES := CHR_COUNT * CHR_BYTES`,
  `const MAX_PALETTE_COLORS := 128`
- `var tilemaps: PackedByteArray` (raw planar), `var chr: PackedByteArray`,
  `var palette: PackedColorArray`, `var properties: PackedInt32Array` (`TILE_COUNT` words)
- `func chr_index(tile: int, corner: Corner) -> int`
- `func chr_pixel(chr_id: int, x: int, y: int) -> int`

### `TileProperties`
Pure static helpers over a property word. Nothing is held.
- `enum Flag { NO_WALK = 0x0001, NO_CANOE = 0x0002, NO_SHIP = 0x0004, NO_AIRSHIP = 0x0008,
  FOREST = 0x0010, DOCK = 0x0020 }`
- `enum Event { NONE = 0x00, CHIME = 0x40, CARAVAN = 0x80, AIRSHIP = 0xC0 }`, `const EVENT_MASK := 0xC0`
- `enum Fight { LAND = 0x4000, RIVER = 0x4100, OCEAN = 0x4200 }`, `const FIGHT_BIT := 0x4000`,
  `const TELEPORT_BIT := 0x8000`, `const TELEPORT_INDEX_MASK := 0x7F`
- `static func has_flag(word, flag) -> bool`, `event(word) -> Event`, `is_fight(word) -> bool`,
  `fight(word) -> Fight`, `is_teleport(word) -> bool`, `teleport_index(word) -> int`
- `const WORD_BYTES := 2` and `static func decode(bytes) -> PackedInt32Array` (u16 LE)

### `SnesPalette`
- `const COLOR_BYTES := 2`
- `static func bgr555_to_color(word: int) -> Color`. This is the one place the BGR555 formula lives,
  and later `.pal` work reuses it.
- `static func decode(bytes: PackedByteArray) -> PackedColorArray`

### `Project`
- `var assets_dir: String`, `var overworld_map: OverworldMap`, `var overworld_tileset: OverworldTileset`

### `ProjectLoader`
- Relative path constants for the five files. Tilemaps, tile properties and chr are each paired with
  an exact size taken from the constants above.
- The palette size must be a nonzero multiple of `COLOR_BYTES` and at most
  `OverworldTileset.MAX_PALETTE_COLORS * COLOR_BYTES`.
- `overworld-map.bin` has no size check. `OverworldMap.decode` alone decides whether it is valid.
- `static func load_project(assets_dir: String, errors: PackedStringArray) -> Project`
  1. Read every file with `FileAccess.get_file_as_bytes`. A file that is missing or unreadable
     (`FileAccess.get_open_error()`) appends an error. A size mismatch appends an error that gives
     the expected and actual sizes.
  2. Check **every** file before returning, so the dialog lists all problems at once.
  3. If anything failed, return `null`. Otherwise decode and build the `Project`; decode errors
     also return `null`.

## UI wiring

**`top_toolbar.tscn` / `top_toolbar.gd`**
- Attach the script: `signal open_requested`, `func _on_open_button_pressed() -> void: open_requested.emit()`.
- Add `[connection signal="pressed" from="HBox/OpenButton" to="." method="_on_open_button_pressed"]`.

**`map_editor.tscn`**
- Add a `FileDialog` named `OpenProjectDialog` (unique name) with `file_mode = FILE_MODE_OPEN_DIR`,
  `access = ACCESS_FILESYSTEM`, `use_native_dialog = true`, and `title = "Open Project"`.
- Add an `AcceptDialog` named `LoadErrorDialog` (unique name) with `title = "Couldn't Open Project"`.
- Connections: `TopToolbar.open_requested → MapEditor._on_open_requested`,
  `OpenProjectDialog.dir_selected → MapEditor._on_project_dir_selected`.

**`map_editor.gd`**
- `var project: Project`
- `_on_open_requested()` calls `%OpenProjectDialog.popup_centered()`
- `_on_project_dir_selected(dir)`
  1. Call `ProjectLoader.load_project(dir, errors)`.
  2. On failure, set `LoadErrorDialog.dialog_text` to the errors joined by newlines and pop it up.
     `project` is left unchanged.
  3. On success, assign `project` and call `%StatusBar.show_project(dir)`.

**`status_bar.tscn` / `status_bar.gd`**
- Add a `ProjectLabel` (unique name) to the left of the spacer, after `CursorLabel`, with the text
  "No project".
- `show_project(dir: String)` sets `ProjectLabel.text = dir`.

## Tests

All literals come from the classes' own constants. Fixtures are built in code, not checked in.

`tests/unit/project/`
- `test_overworld_map.gd`: builds RLE rows with `RUN_FLAG`/`ROW_END`/`SIZE`. Covers single tiles,
  runs, count 0 meaning `SIZE`, a mix of both, a missing terminator, a row that is too short or too
  long, an offset outside the file, a file too short to hold the row table, and a valid map with
  trailing bytes.
- `test_tile_properties.gd`: every `Flag`, every `Event`, every `Fight`, and teleport with its index,
  all built from the enums. `decode` reads u16 LE.
- `test_snes_palette.gd`: the channel extremes for each of R, G and B, plus black and white.
- `test_overworld_tileset.gd`: `chr_index` across all four corners, and `chr_pixel` addressing.

`tests/integration/project/`
- `test_project_loader.gd`: writes a synthetic assets dir under `user://` with correctly sized files
  and checks that the load succeeds. It then covers each missing file, each wrong size (including
  a palette that is empty, has an odd byte count, or exceeds `MAX_PALETTE_COLORS`), a palette of
  exactly `MAX_PALETTE_COLORS`, and several
  bad files at once (all of them must be reported together).
- `test_real_assets.gd`: loads `<res://>/../ROMAssembly/assets` (resolved through
  `ProjectSettings.globalize_path`). It passes with no errors and checks that all rows decode. It
  is marked pending when the folder isn't there.

## Verification
1. Rung 1: `godot --headless --path . --import` for the new `class_name`s, then
   `--headless --quit-after 5`, and grep for `SCRIPT ERROR`.
2. Rung 2: run scoped GUT runs with `-gconfig=.gutconfig.json -gselect=<script>` while iterating,
   and the full suite at the end.
3. Rung 3: run the editor and confirm that the toolbar Open button opens the native folder picker.
4. Rung 4: the user opens `ROMAssembly/assets` and confirms that the status bar shows the path and
   that a broken folder (for example one with a file renamed) lists the problems.
