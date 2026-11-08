class_name MapView
extends RefCounted

enum ViewMode { NORMAL, LAND, AIRSHIP }

const MIN_ZOOM := 1.0 / 16.0
const MAX_ZOOM := 4.0
const ZOOM_STEP := 1.25
const GLIDE_DURATION := 0.15
const GAME_SCREEN := Vector2(256, 224)
const MAX_PERSPECTIVE_SCALE := 8.0
const PERSPECTIVE_DIVISOR := 3.0
const TRANSITION_FRAMES := 64
const GAME_FPS := 60.0

var center := Vector2.ZERO
var zoom := 1.0
var view_size := Vector2.ZERO
var perspective := 0.0
var wrap := false


static func map_size() -> Vector2:
	return Vector2.ONE * OverworldMap.SIZE * OverworldTileset.TILE_SIZE


static func tile_rect_to_world(rect: Rect2i) -> Rect2:
	return Rect2(rect.position * OverworldTileset.TILE_SIZE, rect.size * OverworldTileset.TILE_SIZE)


static func world_to_tile(world: Vector2) -> Vector2i:
	return Vector2i((world / OverworldTileset.TILE_SIZE).floor())


static func stepped_zoom(from: float, steps: int) -> float:
	return clampf(from * pow(ZOOM_STEP, steps), MIN_ZOOM, MAX_ZOOM)


static func perspective_for(mode: ViewMode) -> float:
	return 1.0 if mode == ViewMode.AIRSHIP else 0.0


static func perspective_terms(f: float) -> Vector2:
	var t := 1.0 / (1.0 + f)
	return Vector2(t, (1.0 - t) / PERSPECTIVE_DIVISOR)


func row_denominator(game_y: float) -> float:
	var terms := perspective_terms(perspective)
	return terms.x + terms.y * game_y / (GAME_SCREEN.y / 2.0)


func row_scale(game_y: float) -> float:
	return 1.0 / maxf(row_denominator(game_y), 1.0 / MAX_PERSPECTIVE_SCALE)


func game_scale() -> float:
	return fit_zoom(Rect2(Vector2.ZERO, GAME_SCREEN))


func altitude() -> float:
	return game_scale() / zoom


func screen_to_game(screen: Vector2) -> Vector2:
	return (screen - view_size / 2.0) / game_scale()


func is_beyond_horizon(screen: Vector2) -> bool:
	return row_denominator(screen_to_game(screen).y) <= 1.0 / MAX_PERSPECTIVE_SCALE


func world_to_screen(world: Vector2) -> Vector2:
	var projected := (world - center) / altitude()
	var terms := perspective_terms(perspective)
	var game_y := projected.y * terms.x / (1.0 - projected.y * terms.y / (GAME_SCREEN.y / 2.0))
	var game := Vector2(projected.x * row_denominator(game_y), game_y)
	return game * game_scale() + view_size / 2.0


func screen_to_world(screen: Vector2) -> Vector2:
	var game := screen_to_game(screen)
	return center + game * row_scale(game.y) * altitude()


func visible_world_rect() -> Rect2:
	var world_size := view_size / zoom
	return Rect2(center - world_size / 2.0, world_size)


func footprint() -> PackedVector2Array:
	if not wrap:
		var rect := visible_world_rect()
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var half := GAME_SCREEN / 2.0
	var top := center + Vector2(half.x, -half.y) * row_scale(-half.y)
	var bottom := center + half * row_scale(half.y)
	return PackedVector2Array([
		Vector2(2.0 * center.x - top.x, top.y), top,
		bottom, Vector2(2.0 * center.x - bottom.x, bottom.y),
	])


func clamp_center() -> void:
	if wrap:
		center = Vector2(fposmod(center.x, map_size().x), fposmod(center.y, map_size().y))
	else:
		center = center.clamp(Vector2.ZERO, map_size())


func zoom_about(anchor_world: Vector2, new_zoom: float) -> void:
	var anchor_screen := world_to_screen(anchor_world)
	zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	center = anchor_world - (anchor_screen - view_size / 2.0) / zoom
	clamp_center()


func fit_zoom(world_rect: Rect2) -> float:
	var scale := view_size / world_rect.size
	return clampf(minf(scale.x, scale.y), MIN_ZOOM, MAX_ZOOM)
