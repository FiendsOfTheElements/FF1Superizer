class_name MapView
extends RefCounted

const MIN_ZOOM := 1.0 / 16.0
const MAX_ZOOM := 16.0
const ZOOM_STEP := 1.25
const GLIDE_DURATION := 0.15

var center := Vector2.ZERO
var zoom := 1.0
var view_size := Vector2.ZERO


static func map_size() -> Vector2:
	return Vector2.ONE * OverworldMap.SIZE * OverworldTileset.TILE_SIZE


static func tile_rect_to_world(rect: Rect2i) -> Rect2:
	return Rect2(rect.position * OverworldTileset.TILE_SIZE, rect.size * OverworldTileset.TILE_SIZE)


static func world_to_tile(world: Vector2) -> Vector2i:
	return Vector2i((world / OverworldTileset.TILE_SIZE).floor())


static func stepped_zoom(from: float, steps: int) -> float:
	return clampf(from * pow(ZOOM_STEP, steps), MIN_ZOOM, MAX_ZOOM)


func world_to_screen(world: Vector2) -> Vector2:
	return (world - center) * zoom + view_size / 2.0


func screen_to_world(screen: Vector2) -> Vector2:
	return (screen - view_size / 2.0) / zoom + center


func visible_world_rect() -> Rect2:
	var world_size := view_size / zoom
	return Rect2(center - world_size / 2.0, world_size)


func clamp_center() -> void:
	center = center.clamp(Vector2.ZERO, map_size())


func zoom_about(anchor_world: Vector2, new_zoom: float) -> void:
	var anchor_screen := world_to_screen(anchor_world)
	zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	center = anchor_world - (anchor_screen - view_size / 2.0) / zoom
	clamp_center()


func fit_zoom(world_rect: Rect2) -> float:
	var scale := view_size / world_rect.size
	return clampf(minf(scale.x, scale.y), MIN_ZOOM, MAX_ZOOM)
