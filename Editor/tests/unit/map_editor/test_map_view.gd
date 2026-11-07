extends GutTest

const VIEW_SIZE := Vector2(1000, 600)
const EPSILON := 0.001


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
