extends GutTest

const MapCanvasScene := preload("res://src/map_editor/map_canvas/map_canvas.tscn")
const CANVAS_SIZE := Vector2(800, 600)
const CURSOR := Vector2(100, 150)
const LAST := OverworldMap.SIZE - 1

var canvas: MapCanvas
var map: OverworldMap


func before_each() -> void:
	canvas = MapCanvasScene.instantiate()
	add_child_autofree(canvas)
	canvas.size = CANVAS_SIZE
	var rows: Array[PackedByteArray] = []
	for y in OverworldMap.SIZE:
		rows.append(OverworldMapBuilder.full_row(y % OverworldMap.TILE_MASK))
	var errors: Array[String] = []
	map = OverworldMap.decode(OverworldMapBuilder.encode(rows), errors)


func _show() -> void:
	canvas.show_map(map, BlankAtlas.texture())


func test_cells_use_map_tiles() -> void:
	_show()
	var layer: TileMapLayer = canvas._map_layer
	for cell in [Vector2i.ZERO, Vector2i(LAST, 0), Vector2i(0, LAST), Vector2i(LAST, LAST),
			MapCanvas.INITIAL_CENTER_CELL]:
		assert_eq(layer.get_cell_atlas_coords(cell),
				OverworldTileset.atlas_cell(map.get_tile(cell.x, cell.y)), str(cell))


func test_initial_view() -> void:
	_show()
	assert_eq(canvas.get_zoom(), MapCanvas.DEFAULT_ZOOM)
	assert_eq(canvas.cell_at(CANVAS_SIZE / 2), MapCanvas.INITIAL_CENTER_CELL)


func test_zoom_keeps_cell_under_cursor() -> void:
	_show()
	var cell := canvas.cell_at(CURSOR)
	canvas.zoom_at(CURSOR, 1)
	assert_gt(canvas.get_zoom(), MapCanvas.DEFAULT_ZOOM)
	assert_eq(canvas.cell_at(CURSOR), cell)
	canvas.zoom_at(CURSOR, -2)
	assert_lt(canvas.get_zoom(), MapCanvas.DEFAULT_ZOOM)
	assert_eq(canvas.cell_at(CURSOR), cell)


func test_zoom_clamps_to_steps() -> void:
	_show()
	canvas.zoom_at(CURSOR, MapCanvas.ZOOM_STEPS.size())
	assert_eq(canvas.get_zoom(), MapCanvas.ZOOM_STEPS.back())
	canvas.zoom_at(CURSOR, -MapCanvas.ZOOM_STEPS.size())
	assert_eq(canvas.get_zoom(), MapCanvas.ZOOM_STEPS.front())


func test_pan_keeps_center_over_map() -> void:
	_show()
	var far: Vector2 = MapCanvas.MAP_PIXELS * MapCanvas.ZOOM_STEPS.back()
	canvas.pan_by(far)
	assert_eq(canvas.cell_at(CANVAS_SIZE / 2), Vector2i.ZERO)
	canvas.pan_by(-far * 2)
	assert_eq(canvas.cell_at(CANVAS_SIZE / 2), Vector2i(LAST, LAST))


func test_cell_at_off_map_is_none() -> void:
	_show()
	canvas.pan_by(MapCanvas.MAP_PIXELS)
	assert_eq(canvas.cell_at(Vector2.ZERO), MapCanvas.NO_CELL)


func test_cell_at_before_map_is_none() -> void:
	assert_eq(canvas.cell_at(CANVAS_SIZE / 2), MapCanvas.NO_CELL)


func test_cursor_moved_signal() -> void:
	_show()
	watch_signals(canvas)
	var motion := InputEventMouseMotion.new()
	motion.position = CURSOR
	canvas._gui_input(motion)
	assert_signal_emitted_with_parameters(canvas, "cursor_moved", [canvas.cell_at(CURSOR)])
	canvas.notification(Control.NOTIFICATION_MOUSE_EXIT)
	assert_signal_emitted_with_parameters(canvas, "cursor_moved", [MapCanvas.NO_CELL])
