class_name PaletteGrid
extends Control

signal tile_selected(tile: int)

const HOVER_COLOR := Color(1, 1, 1, 0.5)
const SELECTED_COLOR := Color.WHITE
const SELECTED_INNER_COLOR := Color(0, 0, 0, 0.75)

var _texture: Texture2D
var _zoom := 1
var _selected := 0
var _hovered := -1


func show_atlas(atlas: Texture2D) -> void:
	_texture = atlas
	_selected = 0
	_hovered = -1
	_update_layout()
	queue_redraw()


static func zoom_for_width(width: float) -> int:
	return maxi(1, floori(width / OverworldTileset.ATLAS_SIZE.x))


func tile_at(local_pos: Vector2) -> int:
	if _texture == null:
		return -1
	return OverworldTileset.atlas_tile_at(Vector2i((local_pos / _zoom).floor()))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_update_layout()
		NOTIFICATION_MOUSE_EXIT:
			_set_hovered(-1)


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion:
		_set_hovered(tile_at(motion.position))
		return
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		var tile := tile_at(button.position)
		if tile < 0:
			return
		if tile != _selected:
			_selected = tile
			queue_redraw()
		tile_selected.emit(tile)
		accept_event()


func _draw() -> void:
	if _texture == null:
		return
	draw_texture_rect(_texture, Rect2(Vector2.ZERO, OverworldTileset.ATLAS_SIZE * _zoom), false)
	if _hovered >= 0 and _hovered != _selected:
		draw_rect(_tile_rect(_hovered).grow(-0.5), HOVER_COLOR, false, 1.0)
	var selected_rect := _tile_rect(_selected)
	draw_rect(selected_rect.grow(-0.5), SELECTED_COLOR, false, 1.0)
	draw_rect(selected_rect.grow(-1.5), SELECTED_INNER_COLOR, false, 1.0)


func _update_layout() -> void:
	_zoom = zoom_for_width(size.x)
	custom_minimum_size.y = OverworldTileset.ATLAS_SIZE.y * _zoom if _texture else 0
	queue_redraw()


func _set_hovered(tile: int) -> void:
	if tile != _hovered:
		_hovered = tile
		queue_redraw()


func _tile_rect(tile: int) -> Rect2:
	return Rect2(OverworldTileset.atlas_origin(tile) * _zoom,
			Vector2.ONE * OverworldTileset.TILE_SIZE * _zoom)
