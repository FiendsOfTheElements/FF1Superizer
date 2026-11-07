extends GutTest

const EPSILON := 0.001
const DEFAULT_BODY := Vector2.ONE * OverworldMap.SIZE


func test_thumb_rect_is_centered_square_that_fits() -> void:
	var body := Vector2(300, 200)
	var thumb := Minimap.thumb_rect(body)
	assert_eq(thumb.size.x, thumb.size.y)
	assert_eq(thumb.size.y, body.y)
	assert_almost_eq(thumb.get_center(), body / 2.0, Vector2.ONE * EPSILON)


func test_default_body_maps_one_pixel_per_tile() -> void:
	var tile_world := Vector2.ONE * OverworldTileset.TILE_SIZE
	var a := Minimap.world_to_minimap(Vector2.ZERO, DEFAULT_BODY)
	var b := Minimap.world_to_minimap(tile_world, DEFAULT_BODY)
	assert_almost_eq(b - a, Vector2.ONE, Vector2.ONE * EPSILON)


func test_minimap_world_round_trip() -> void:
	var body := Vector2(400, 300)
	var world := MapView.map_size() * Vector2(0.3, 0.8)
	var point := Minimap.world_to_minimap(world, body)
	assert_almost_eq(Minimap.minimap_to_world(point, body), world, Vector2.ONE * EPSILON)


func test_letterbox_points_clamp_into_map() -> void:
	var body := Vector2(400, 300)
	assert_eq(Minimap.minimap_to_world(Vector2.ZERO, body), Vector2.ZERO)
	assert_eq(Minimap.minimap_to_world(body, body), MapView.map_size())
