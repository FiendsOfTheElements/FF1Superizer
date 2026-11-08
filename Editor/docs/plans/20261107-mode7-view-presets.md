# Mode 7 View Presets

## Goal
Preview the overworld the way the game projects it, from three toolbar presets on the far right:
**Normal** (the free editor view), **Land** (the game's walking/ship/canoe view) and **Airship**
(the game's perspective view). This lets map edits be checked in the projection players actually see.

## Scope
In:
- One canvas shader that renders all three views, including the 16-tile grid (projected in Airship).
- Toolbar preset toggles and F1/F2/F3 shortcuts.
- Animated Land↔Airship transitions, matching the game's takeoff and landing.
- A game-screen outline in Land/Airship. The minimap shows the game-screen
  footprint.
- Map wrap in Land/Airship, and a horizon cutoff with a backdrop in Airship.
- The cursor tile readout follows the projection.

Out:
- Editing through the projection (no tools exist yet; the readout is the only cursor behavior).
- Rotation (the game never rotates: `MAPANGLE` stays 0).
- Sprites, the player, vehicles.
- Any preset beyond the game's two projections.

## Game reference (`ROMAssembly/`)
- Screen 256×224, Mode 7 center = screen center (128,112) = player position. North-up, wraps
  (M7SEL repeat on).
- Walk/ship/canoe: flat 1× (no HDMA).
- Airship (`src/airship-m7-hdma.asm`, `SetupAirshipMode7HDMA` in `src/overworld.asm`): per
  scanline, M7A = M7D = scale, with
  - `t = 1 / (1 + f)`, `s = (1 - t) / 3`
  - `scale(line) = 1 / (t + s * (line - 112) / 112)`
  - Fully airborne, `f = 1`: 3.0× at line 0 (stored 768), ≈1.504× at line 223 (stored 385).
- Takeoff and landing step `f` across 64 tables, one per frame (`f = (k + 1) / 64`); no HDMA
  means `f = 0`.

## Projection model
One mapping covers all three views. For canvas pixel `p`:
- `game = (p - canvas_size / 2) / zoom`: game-pixel offset from the camera; native 1× when zoom = 1
- `denom = t + s * game.y / 112`
- if `denom <= 1 / MAX_PERSPECTIVE_SCALE`: backdrop (beyond the horizon)
- `world = center + game / denom`
- outside the map: backdrop when not wrapping, otherwise `fposmod`

| View | f | wrap | grid | labels | overlay |
|---|---|---|---|---|---|
| Normal | 0 | no (center clamped as today) | yes | yes | none |
| Land | 0 | yes | yes | no | game frame |
| Airship | 1 | yes | yes, projected | no | game frame |

`MAX_PERSPECTIVE_SCALE := 8.0`. The backdrop is the theme `Panel` background color.

The same formula lives in two places: in `MapView` (GDScript, for input, readout and footprint)
and in `map_canvas.gdshader` (pixels). That's unavoidable, since shaders can't call GDScript.
GUT tests cover the GDScript copy, and the visual check covers the shader.

## Files

```
src/map_editor/map_canvas/
  map_view.gd           + ViewMode enum, perspective, wrap, projection math, footprint
  map_canvas.gdshader   new: projection + grid + backdrop
  map_canvas.gd         draws one full-rect quad through the shader; overlay draw; view modes
  map_canvas.tscn       ShaderMaterial; Overlay child (full rect, mouse ignore)
src/map_editor/right_bar/
  minimap.gd            footprint polygon, wrapped copies
  minimap_panel.tscn    Body clip_contents
  right_bar.gd          show_view signature
src/map_editor/top_toolbar/
  top_toolbar.gd/.tscn  view preset toggles in their own ButtonGroup, after ToolOptionsBar
src/map_editor/map_editor.gd/.tscn  wiring
assets/icons/view_normal.svg, view_land.svg, view_airship.svg
project.godot           map_view_normal/land/airship = F1/F2/F3
tests/unit/map_editor/test_map_view.gd  + projection tests
```

## MapView additions
- `enum ViewMode { NORMAL, LAND, AIRSHIP }`
- `const GAME_SCREEN := Vector2(256, 224)`, `MAX_PERSPECTIVE_SCALE := 8.0`,
  `PERSPECTIVE_DIVISOR := 3.0`, `TRANSITION_FRAMES := 64`, `GAME_FPS := 60.0`
- `var perspective := 0.0` (f), `var wrap := false`
- `static func perspective_terms(f) -> Vector2`: (t, s)
- `func row_denominator(game_y) -> float`; `row_scale(game_y) -> float`
- `func screen_to_world(screen) -> Vector2`: the projection above (flat when f = 0)
- `func is_beyond_horizon(screen) -> bool`
- `world_to_screen` stays flat. Only Normal uses it (labels, zoom anchor).
- `clamp_center()`: `fposmod` into the map when wrapping, otherwise the clamp from today
- `func footprint() -> PackedVector2Array`: Normal → the visible rect's corners. Land/Airship → the
  game frame's corners: rows ±112, columns ±128, each × `row_scale`.
- `static func perspective_for(mode) -> float`: AIRSHIP → 1, otherwise 0

## MapCanvas
- `_draw`: one `draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)`. The shader computes
  `world` from `UV * canvas_size`. The old CPU grid code goes away.
- Shader uniforms are pushed in `_view_moved()` (only on change). Names are `StringName` consts.
- `%Overlay` `draw` → `_on_overlay_draw`:
  - Normal: the labels from today
  - Land/Airship: a screen-space game frame of `GAME_SCREEN * zoom` around the canvas center, with
    a 1 px white outline and a 1 px dark shadow (no dimming)
- `set_view_mode(mode)`:
  - Normal ↔ projected: snaps `perspective` and `wrap`, re-clamps the center
  - Land ↔ Airship: a linear tween of `perspective` over
    `abs(Δf) * TRANSITION_FRAMES / GAME_FPS` s
  - Emits `view_mode_changed(mode)`
- F1/F2/F3 (`map_view_*` actions, canvas focus) call `set_view_mode`.
- In Land/Airship:
  - Zoom anchors on `center`.
  - Home frames `GAME_SCREEN` with `fit_zoom`.
  - Middle-drag moves by `relative / zoom * row_scale(cursor game row)`.
  - Key pan multiplies by `row_scale(0)`.
- Cursor readout: `screen_to_world` → `fposmod` when wrapping; `on_map` is false beyond the horizon
  or off the map in Normal.
- `view_changed(footprint: PackedVector2Array, wraps: bool, zoom: float)` replaces the Rect2
  signature.

## Minimap
`show_view(footprint, wraps)`:
- Not wrapping: points clamp into the body inset by 1 px, as today.
- Wrapping: the polygon is drawn at the 9 offsets `{-1, 0, 1}² × map_size` with `%Body`
  `clip_contents`.
- Outline: a 3 px dark polyline under a 1 px white closed polyline.

## Toolbar
- `ViewSeparator` + `NormalViewButton`, `LandViewButton`, `AirshipViewButton` after
  `ToolOptionsBar`, which already expands, so they sit far right.
- `ButtonGroup_views`; Normal pressed.
- `signal view_mode_requested(mode)`; `show_view_mode(mode)` uses `set_pressed_no_signal`.
- Wiring in `map_editor.tscn`:
  - TopToolbar `view_mode_requested` → MapCanvas `set_view_mode`
  - MapCanvas `view_mode_changed` → TopToolbar `show_view_mode`

## Tests
- `perspective_terms(0)` is (1, 0); `row_scale` is 1 everywhere at f = 0.
- At f = 1, `row_scale` matches the airship table: line 0 → 768/256, line 223 → 385/256 (±1/256).
- `screen_to_world` at f = 0 equals the flat inverse of `world_to_screen`.
- `is_beyond_horizon` is true just above the cap row and false at the game frame top.
- The Land footprint is `GAME_SCREEN` centered on the camera; the Airship top edge is wider than
  the bottom.
- `clamp_center` wraps with `wrap` and clamps without it.

## Verification
1. Import, then a headless boot.
2. The full GUT suite.
3. Movie-maker captures: Normal, Land and Airship, the latter showing the outline, the
   horizon and the minimap trapezoid.
4. The user checks the feel: the takeoff animation, panning in Airship, F1–F3.

## TODO
- The preview sizing may be wrong: the game-screen outline, the Airship scale and the minimap
  footprint are all measured against the placeholder map. Re-check and redo them against the
  game once real tiles render.
