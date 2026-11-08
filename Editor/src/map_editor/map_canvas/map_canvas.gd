class_name MapCanvas
extends Control

signal cursor_moved(cell: Vector2i)

const NO_CELL := Vector2i(-1, -1)
const ZOOM_STEPS: Array[float] = [0.25, 0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0]
const DEFAULT_ZOOM := 1.0
const INITIAL_CENTER_CELL := Vector2i(0x99, 0xA5)
const ATLAS_SOURCE_ID := 0
const MAP_PIXELS := Vector2.ONE * OverworldMap.SIZE * OverworldTileset.TILE_SIZE

var _has_map := false
var _zoom_index := ZOOM_STEPS.find(DEFAULT_ZOOM)
var _center := Vector2.ZERO
var _panning := false
var _cursor_cell := NO_CELL

@onready var _map_view: Node2D = %MapView
@onready var _map_layer: TileMapLayer = %MapLayer


func show_map(map: OverworldMap, atlas: Texture2D) -> void:
	_map_layer.tile_set = _build_tile_set(atlas)
	_map_layer.clear()
	for y in OverworldMap.SIZE:
		for x in OverworldMap.SIZE:
			_map_layer.set_cell(Vector2i(x, y), ATLAS_SOURCE_ID,
					OverworldTileset.atlas_cell(map.get_tile(x, y)))
	_has_map = true
	_zoom_index = ZOOM_STEPS.find(DEFAULT_ZOOM)
	center_on_cell(INITIAL_CENTER_CELL)


func get_zoom() -> float:
	return ZOOM_STEPS[_zoom_index]


func map_point_at(local_pos: Vector2) -> Vector2:
	return _center + (local_pos - size / 2) / get_zoom()


func cell_at(local_pos: Vector2) -> Vector2i:
	if not _has_map:
		return NO_CELL
	var cell := Vector2i((map_point_at(local_pos) / OverworldTileset.TILE_SIZE).floor())
	if cell.x < 0 or cell.y < 0 or cell.x >= OverworldMap.SIZE or cell.y >= OverworldMap.SIZE:
		return NO_CELL
	return cell


func center_on_cell(cell: Vector2i) -> void:
	_center = (Vector2(cell) + Vector2.ONE * 0.5) * OverworldTileset.TILE_SIZE
	_clamp_and_apply()


func zoom_at(local_pos: Vector2, steps: int) -> void:
	var anchor := map_point_at(local_pos)
	_zoom_index = clampi(_zoom_index + steps, 0, ZOOM_STEPS.size() - 1)
	_center = anchor - (local_pos - size / 2) / get_zoom()
	_clamp_and_apply()


func pan_by(screen_delta: Vector2) -> void:
	_center -= screen_delta / get_zoom()
	_clamp_and_apply()


static func clamp_center(center: Vector2) -> Vector2:
	return center.clamp(Vector2.ZERO, MAP_PIXELS - Vector2.ONE)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if is_node_ready():
				_apply_view()
		NOTIFICATION_MOUSE_EXIT:
			_set_cursor_cell(NO_CELL)


func _gui_input(event: InputEvent) -> void:
	if not _has_map:
		return
	var button := event as InputEventMouseButton
	if button:
		_handle_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion:
		if _panning:
			pan_by(motion.relative)
		_set_cursor_cell(cell_at(motion.position))


func _handle_button(button: InputEventMouseButton) -> void:
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			if button.pressed:
				zoom_at(button.position, 1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else -1)
				_set_cursor_cell(cell_at(button.position))
		MOUSE_BUTTON_MIDDLE:
			_panning = button.pressed
		MOUSE_BUTTON_LEFT:
			_panning = button.pressed and Input.is_key_pressed(KEY_SPACE)
		_:
			return
	accept_event()


func _clamp_and_apply() -> void:
	_center = clamp_center(_center)
	_apply_view()


func _apply_view() -> void:
	var zoom := get_zoom()
	_map_view.scale = Vector2.ONE * zoom
	_map_view.position = (size / 2 - _center * zoom).round()


func _set_cursor_cell(cell: Vector2i) -> void:
	if cell != _cursor_cell:
		_cursor_cell = cell
		cursor_moved.emit(cell)


static func _build_tile_set(atlas: Texture2D) -> TileSet:
	var tile_size := Vector2i.ONE * OverworldTileset.TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = atlas
	source.texture_region_size = tile_size
	for tile in OverworldTileset.TILE_COUNT:
		source.create_tile(OverworldTileset.atlas_cell(tile))
	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size
	tile_set.add_source(source, ATLAS_SOURCE_ID)
	return tile_set
