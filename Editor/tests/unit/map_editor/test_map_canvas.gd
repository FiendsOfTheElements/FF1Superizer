extends GutTest

const MapCanvasScene := preload("res://src/map_editor/map_canvas/map_canvas.tscn")
const TAKEOFF_SECONDS := MapView.TRANSITION_FRAMES / MapView.GAME_FPS

var canvas: MapCanvas


func before_each() -> void:
	canvas = MapCanvasScene.instantiate()
	add_child_autofree(canvas)


func test_airship_from_normal_animates_takeoff() -> void:
	canvas.set_view_mode(MapView.ViewMode.AIRSHIP)
	var airship := MapView.perspective_for(MapView.ViewMode.AIRSHIP)
	assert_lt(canvas._view.perspective, airship)
	await wait_seconds(TAKEOFF_SECONDS * 1.5)
	assert_eq(canvas._view.perspective, airship)


func test_normal_from_airship_snaps() -> void:
	canvas.set_view_mode(MapView.ViewMode.AIRSHIP)
	canvas.set_view_mode(MapView.ViewMode.NORMAL)
	assert_eq(canvas._view.perspective, MapView.perspective_for(MapView.ViewMode.NORMAL))
	assert_false(canvas._view.wrap)
