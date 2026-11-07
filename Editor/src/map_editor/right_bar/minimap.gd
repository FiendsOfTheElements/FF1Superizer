class_name Minimap
extends PanelContainer

signal pan_requested(world: Vector2, duration: float)
signal zoom_requested(steps: int, anchor_world: Vector2)
signal focus_canvas_requested

const THUMB_TILE_PX := 4
const DRAG_THRESHOLD := 4.0
const BOX_COLOR := Color.WHITE
const BOX_SHADOW_COLOR := Color(0, 0, 0, 0.75)

var _texture: ImageTexture
var _view_rect := Rect2()
var _press_position := Vector2.ZERO
var _pressed := false
var _dragging := false

@onready var _body: Control = %Body


static func thumb_rect(body_size: Vector2) -> Rect2:
	var side := minf(body_size.x, body_size.y)
	return Rect2((body_size - Vector2.ONE * side) / 2.0, Vector2.ONE * side)


static func minimap_to_world(point: Vector2, body_size: Vector2) -> Vector2:
	var thumb := thumb_rect(body_size)
	var t := ((point - thumb.position) / thumb.size).clamp(Vector2.ZERO, Vector2.ONE)
	return t * MapView.map_size()


static func world_to_minimap(world: Vector2, body_size: Vector2) -> Vector2:
	var thumb := thumb_rect(body_size)
	return thumb.position + world / MapView.map_size() * thumb.size


func set_map_image(image: Image) -> void:
	var thumb := image.duplicate() as Image
	thumb.resize(OverworldMap.SIZE * THUMB_TILE_PX, OverworldMap.SIZE * THUMB_TILE_PX, Image.INTERPOLATE_NEAREST)
	_texture = ImageTexture.create_from_image(thumb)
	_body.queue_redraw()


func show_view(visible_world_rect: Rect2) -> void:
	_view_rect = visible_world_rect
	_body.queue_redraw()


func _on_body_gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button:
		_on_mouse_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion and _pressed:
		if not _dragging and motion.position.distance_to(_press_position) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			pan_requested.emit(minimap_to_world(motion.position, _body.size), 0.0)
		_body.accept_event()


func _on_mouse_button(button: InputEventMouseButton) -> void:
	match button.button_index:
		MOUSE_BUTTON_LEFT:
			if button.pressed:
				_pressed = true
				_dragging = false
				_press_position = button.position
				focus_canvas_requested.emit()
			elif _pressed:
				_pressed = false
				if not _dragging:
					pan_requested.emit(minimap_to_world(button.position, _body.size), MapView.GLIDE_DURATION)
		MOUSE_BUTTON_WHEEL_UP when button.pressed:
			zoom_requested.emit(1, minimap_to_world(button.position, _body.size))
		MOUSE_BUTTON_WHEEL_DOWN when button.pressed:
			zoom_requested.emit(-1, minimap_to_world(button.position, _body.size))
		_:
			return
	_body.accept_event()


func _on_body_draw() -> void:
	if _texture == null:
		return
	var thumb := thumb_rect(_body.size)
	_body.draw_texture_rect(_texture, thumb, false)
	var top_left := world_to_minimap(_view_rect.position, _body.size)
	var box := Rect2(top_left, world_to_minimap(_view_rect.end, _body.size) - top_left).intersection(Rect2(Vector2.ZERO, _body.size).grow(-1.0))
	_body.draw_rect(box.grow(1.0), BOX_SHADOW_COLOR, false, 1.0)
	_body.draw_rect(box, BOX_COLOR, false, 1.0)
