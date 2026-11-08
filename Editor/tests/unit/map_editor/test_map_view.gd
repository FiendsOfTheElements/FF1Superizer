extends GutTest

const VIEW_SIZE := Vector2(1000, 600)
const EPSILON := 0.001
const ASM_SCALE_UNIT := 256.0
const ASM_AIRSHIP_TOP := 768.0
const ASM_AIRSHIP_BOTTOM := 385.0
const GAME_HALF := MapView.GAME_SCREEN / 2.0


func _make_view() -> MapView:
	var view := MapView.new()
	view.view_size = VIEW_SIZE
	view.center = MapView.map_size() / 2.0
	view.zoom = 2.0
	return view


func test_world_screen_round_trip() -> void:
	var view := _make_view()
	var world := Vector2(123.5, 987.25)
	assert_almost_eq(view.screen_to_world(view.world_to_screen(world)), world, Vector2.ONE * EPSILON)
	assert_almost_eq(view.world_to_screen(view.center), VIEW_SIZE / 2.0, Vector2.ONE * EPSILON)


func test_zoom_about_keeps_anchor_on_screen() -> void:
	var view := _make_view()
	var visible := view.visible_world_rect()
	for anchor: Vector2 in [visible.position + visible.size * 0.25, visible.end + visible.size]:
		view = _make_view()
		var before := view.world_to_screen(anchor)
		view.zoom_about(anchor, view.zoom * MapView.ZOOM_STEP)
		assert_almost_eq(view.world_to_screen(anchor), before, Vector2.ONE * EPSILON)


func test_zoom_clamps_to_range() -> void:
	var view := _make_view()
	view.zoom_about(view.center, MapView.MAX_ZOOM * 2.0)
	assert_eq(view.zoom, MapView.MAX_ZOOM)
	view.zoom_about(view.center, MapView.MIN_ZOOM / 2.0)
	assert_eq(view.zoom, MapView.MIN_ZOOM)


func test_stepped_zoom_stacks_and_clamps() -> void:
	assert_almost_eq(MapView.stepped_zoom(1.0, 2), MapView.ZOOM_STEP * MapView.ZOOM_STEP, EPSILON)
	assert_almost_eq(MapView.stepped_zoom(MapView.stepped_zoom(1.0, 1), -1), 1.0, EPSILON)
	assert_eq(MapView.stepped_zoom(MapView.MAX_ZOOM, 1), MapView.MAX_ZOOM)
	assert_eq(MapView.stepped_zoom(MapView.MIN_ZOOM, -1), MapView.MIN_ZOOM)


func test_clamp_center_bounds_to_map() -> void:
	var view := _make_view()
	view.center = -Vector2.ONE * 100.0
	view.clamp_center()
	assert_eq(view.center, Vector2.ZERO)
	view.center = MapView.map_size() * 2.0
	view.clamp_center()
	assert_eq(view.center, MapView.map_size())


func test_fit_zoom_contains_rect_and_touches_one_axis() -> void:
	var view := _make_view()
	var whole := Rect2(Vector2.ZERO, MapView.map_size())
	var sub := MapView.tile_rect_to_world(Rect2i(10, 20, 30, 8))
	for rect: Rect2 in [whole, sub]:
		var zoom := view.fit_zoom(rect)
		var on_screen := rect.size * zoom
		assert_true(on_screen.x <= VIEW_SIZE.x + EPSILON and on_screen.y <= VIEW_SIZE.y + EPSILON)
		assert_true(is_equal_approx(on_screen.x, VIEW_SIZE.x) or is_equal_approx(on_screen.y, VIEW_SIZE.y))


func test_visible_world_rect_matches_view_over_zoom() -> void:
	var view := _make_view()
	var rect := view.visible_world_rect()
	assert_almost_eq(rect.size, VIEW_SIZE / view.zoom, Vector2.ONE * EPSILON)
	assert_almost_eq(rect.get_center(), view.center, Vector2.ONE * EPSILON)


func test_tile_conversions_use_tile_size() -> void:
	var tile := Vector2i(7, 9)
	var world := MapView.tile_rect_to_world(Rect2i(tile, Vector2i.ONE))
	assert_eq(world.size, Vector2.ONE * OverworldTileset.TILE_SIZE)
	assert_eq(MapView.world_to_tile(world.get_center()), tile)


func _make_projected(mode: MapView.ViewMode) -> MapView:
	var view := _make_view()
	view.wrap = true
	view.perspective = MapView.perspective_for(mode)
	return view


func test_land_projection_is_flat() -> void:
	assert_eq(MapView.perspective_terms(0.0), Vector2(1.0, 0.0))
	var view := _make_projected(MapView.ViewMode.LAND)
	for game_y: float in [-GAME_HALF.y, 0.0, GAME_HALF.y]:
		assert_eq(view.row_scale(game_y), 1.0)


func test_airship_scale_matches_rom_table() -> void:
	var view := _make_projected(MapView.ViewMode.AIRSHIP)
	var tolerance := 1.0 / ASM_SCALE_UNIT
	assert_almost_eq(view.row_scale(-GAME_HALF.y), ASM_AIRSHIP_TOP / ASM_SCALE_UNIT, tolerance)
	assert_almost_eq(view.row_scale(GAME_HALF.y - 1.0), ASM_AIRSHIP_BOTTOM / ASM_SCALE_UNIT, tolerance)


func test_flat_screen_to_world_inverts_world_to_screen() -> void:
	var view := _make_projected(MapView.ViewMode.LAND)
	var world := view.center + Vector2(37.0, -81.5)
	assert_almost_eq(view.screen_to_world(view.world_to_screen(world)), world, Vector2.ONE * EPSILON)


func test_horizon_lies_above_game_frame() -> void:
	var view := _make_projected(MapView.ViewMode.AIRSHIP)
	var frame_top := VIEW_SIZE / 2.0 - Vector2(0.0, GAME_HALF.y * view.game_scale())
	assert_false(view.is_beyond_horizon(frame_top))
	view.view_size = Vector2(VIEW_SIZE.x, 4000.0)
	assert_true(view.is_beyond_horizon(Vector2(VIEW_SIZE.x / 2.0, 0.0)))
	assert_eq(view.row_scale(-GAME_HALF.y * 10.0), MapView.MAX_PERSPECTIVE_SCALE)


func test_land_footprint_is_game_screen() -> void:
	var view := _make_projected(MapView.ViewMode.LAND)
	var footprint := view.footprint()
	assert_almost_eq(footprint[0], view.center - GAME_HALF, Vector2.ONE * EPSILON)
	assert_almost_eq(footprint[2], view.center + GAME_HALF, Vector2.ONE * EPSILON)


func test_airship_footprint_is_wider_at_top() -> void:
	var footprint := _make_projected(MapView.ViewMode.AIRSHIP).footprint()
	var top_width := footprint[1].x - footprint[0].x
	var bottom_width := footprint[2].x - footprint[3].x
	assert_gt(top_width, bottom_width)
	assert_gt(bottom_width, MapView.GAME_SCREEN.x)


func test_airship_screen_to_world_inverts_world_to_screen() -> void:
	var view := _make_projected(MapView.ViewMode.AIRSHIP)
	for zoom: float in [MapView.MIN_ZOOM, view.game_scale(), MapView.MAX_ZOOM]:
		view.zoom = zoom
		for corner in view.footprint():
			assert_almost_eq(view.screen_to_world(view.world_to_screen(corner)), corner, Vector2.ONE * EPSILON)


func test_airship_game_zoom_frames_game_screen() -> void:
	var view := _make_projected(MapView.ViewMode.AIRSHIP)
	view.zoom = view.game_scale()
	var footprint := view.footprint()
	var half_frame := GAME_HALF * view.game_scale()
	assert_almost_eq(view.world_to_screen(footprint[0]), VIEW_SIZE / 2.0 - half_frame, Vector2.ONE * EPSILON)
	assert_almost_eq(view.world_to_screen(footprint[2]), VIEW_SIZE / 2.0 + half_frame, Vector2.ONE * EPSILON)


func test_airship_zoom_keeps_horizon_and_changes_altitude() -> void:
	var view := _make_projected(MapView.ViewMode.AIRSHIP)
	var screen := VIEW_SIZE / 2.0 - Vector2(0.0, GAME_HALF.y * view.game_scale())
	view.zoom = view.game_scale()
	var game := view.screen_to_game(screen)
	var near := view.screen_to_world(screen) - view.center
	view.zoom /= MapView.ZOOM_STEP
	assert_eq(view.screen_to_game(screen), game)
	assert_almost_eq(view.screen_to_world(screen) - view.center, near * MapView.ZOOM_STEP, Vector2.ONE * EPSILON)


func test_clamp_center_wraps_when_projected() -> void:
	var view := _make_projected(MapView.ViewMode.LAND)
	view.center = MapView.map_size() + Vector2(10.0, 20.0)
	view.clamp_center()
	assert_almost_eq(view.center, Vector2(10.0, 20.0), Vector2.ONE * EPSILON)
