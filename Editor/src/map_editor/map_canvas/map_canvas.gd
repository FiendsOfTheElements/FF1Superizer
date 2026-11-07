class_name MapCanvas
extends Control

signal view_changed(visible_world_rect: Rect2, zoom: float)
signal cursor_tile_changed(tile: Vector2i, on_map: bool)

const PAN_SPEED_SCREEN := 1000.0
const PAN_BOOST := 3.0
const ZOOM_DURATION := 0.08
const GRID_TILES := 16
const GRID_COLOR := Color(1, 1, 1, 0.15)
const GRID_MIN_SPACING := 8.0
const LABEL_MIN_SPACING := 48.0
const LABEL_FONT_SIZE := 12
const LABEL_OUTLINE := 2
const LABEL_OFFSET := Vector2(3, 3)
const LABEL_OUTLINE_COLOR := Color.BLACK
const PAN_ACTIONS: Array[StringName] = [&"map_pan_left", &"map_pan_right", &"map_pan_up", &"map_pan_down"]

var _view := MapView.new()
var _texture: ImageTexture
var _tween: Tween
var _zoom_target := 1.0
var _fitted := false
var _dragging := false
var _mouse_inside := false


func set_map_image(image: Image) -> void:
	_texture = ImageTexture.create_from_image(image)
	queue_redraw()


func fit_map(duration: float) -> void:
	fit_tile_rect(Rect2i(Vector2i.ZERO, Vector2i.ONE * OverworldMap.SIZE), duration)


func fit_tile_rect(rect: Rect2i, duration: float) -> void:
	var world_rect := MapView.tile_rect_to_world(rect)
	_glide(world_rect.get_center(), _view.fit_zoom(world_rect), duration)


func pan_to(world: Vector2, duration: float) -> void:
	_glide(world, _view.zoom, duration)


func zoom_step_at(steps: int, anchor_world: Vector2) -> void:
	var target := MapView.stepped_zoom(_zoom_target, steps)
	_kill_tween()
	_zoom_target = target
	_tween = create_tween()
	_tween.tween_method(_zoom_about.bind(anchor_world), _view.zoom, _zoom_target, ZOOM_DURATION)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_view.view_size = size
			if not _fitted and size.x > 0 and size.y > 0:
				_fitted = true
				fit_map(0.0)
			else:
				_view_moved()
		NOTIFICATION_MOUSE_ENTER:
			_mouse_inside = true
		NOTIFICATION_MOUSE_EXIT:
			_mouse_inside = false
			cursor_tile_changed.emit(Vector2i.ZERO, false)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button:
		_on_mouse_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion:
		if _dragging:
			_kill_tween()
			_view.center -= motion.relative / _view.zoom
			_view_moved()
		_emit_cursor_tile()
		return
	if event.is_action_pressed(&"map_zoom_in", true):
		zoom_step_at(1, _view.center)
	elif event.is_action_pressed(&"map_zoom_out", true):
		zoom_step_at(-1, _view.center)
	elif event.is_action_pressed(&"map_fit"):
		fit_map(MapView.GLIDE_DURATION)
	elif not PAN_ACTIONS.any(event.is_action):
		return
	accept_event()


func _on_mouse_button(button: InputEventMouseButton) -> void:
	match button.button_index:
		MOUSE_BUTTON_MIDDLE:
			_dragging = button.pressed
			if button.pressed:
				grab_focus()
		MOUSE_BUTTON_WHEEL_UP when button.pressed:
			zoom_step_at(1, _view.screen_to_world(button.position))
		MOUSE_BUTTON_WHEEL_DOWN when button.pressed:
			zoom_step_at(-1, _view.screen_to_world(button.position))
		_:
			return
	accept_event()


func _process(delta: float) -> void:
	if not has_focus():
		return
	var direction := Input.get_vector(PAN_ACTIONS[0], PAN_ACTIONS[1], PAN_ACTIONS[2], PAN_ACTIONS[3])
	if direction == Vector2.ZERO:
		return
	_kill_tween()
	var speed := PAN_SPEED_SCREEN * (PAN_BOOST if Input.is_action_pressed(&"map_pan_boost") else 1.0)
	_view.center += direction * speed * delta / _view.zoom
	_view_moved()


func _draw() -> void:
	draw_style_box(get_theme_stylebox(&"panel", &"Panel"), Rect2(Vector2.ZERO, size))
	if _texture == null:
		return
	var origin := _view.world_to_screen(Vector2.ZERO)
	draw_texture_rect(_texture, Rect2(origin, MapView.map_size() * _view.zoom), false)
	var spacing := GRID_TILES * OverworldTileset.TILE_SIZE * _view.zoom
	if spacing < GRID_MIN_SPACING:
		return
	var lines := OverworldMap.SIZE / GRID_TILES
	var first := Vector2i((-origin / spacing).floor()).clamp(Vector2i.ZERO, Vector2i.ONE * lines)
	var last := Vector2i(((size - origin) / spacing).ceil()).clamp(Vector2i.ZERO, Vector2i.ONE * lines)
	var map_end := origin + MapView.map_size() * _view.zoom
	for i in range(first.x, last.x + 1):
		var x := origin.x + i * spacing
		draw_line(Vector2(x, origin.y), Vector2(x, map_end.y), GRID_COLOR)
	for j in range(first.y, last.y + 1):
		var y := origin.y + j * spacing
		draw_line(Vector2(origin.x, y), Vector2(map_end.x, y), GRID_COLOR)
	if spacing < LABEL_MIN_SPACING:
		return
	var font := get_theme_default_font()
	var baseline := Vector2(0, font.get_ascent(LABEL_FONT_SIZE))
	for j in range(first.y, mini(last.y, lines - 1) + 1):
		for i in range(first.x, mini(last.x, lines - 1) + 1):
			var pos := origin + Vector2(i, j) * spacing + LABEL_OFFSET + baseline
			var text := "%d,%d" % [i * GRID_TILES, j * GRID_TILES]
			draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, LABEL_OUTLINE, LABEL_OUTLINE_COLOR)
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)


func _glide(target_center: Vector2, target_zoom: float, duration: float) -> void:
	_kill_tween()
	_zoom_target = target_zoom
	if duration <= 0.0:
		_view.center = target_center
		_view.zoom = target_zoom
		_view_moved()
		return
	_tween = create_tween()
	_tween.tween_method(_glide_step.bind(_view.center, _view.zoom, target_center, target_zoom), 0.0, 1.0, duration)


func _glide_step(t: float, from_center: Vector2, from_zoom: float, to_center: Vector2, to_zoom: float) -> void:
	_view.center = from_center.lerp(to_center, t)
	_view.zoom = lerpf(from_zoom, to_zoom, t)
	_view_moved()


func _zoom_about(zoom: float, anchor_world: Vector2) -> void:
	_view.zoom_about(anchor_world, zoom)
	_view_moved()


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_zoom_target = _view.zoom


func _view_moved() -> void:
	_view.clamp_center()
	queue_redraw()
	view_changed.emit(_view.visible_world_rect(), _view.zoom)
	if _mouse_inside:
		_emit_cursor_tile()


func _emit_cursor_tile() -> void:
	var tile := MapView.world_to_tile(_view.screen_to_world(get_local_mouse_position()))
	var on_map := Rect2i(Vector2i.ZERO, Vector2i.ONE * OverworldMap.SIZE).has_point(tile)
	cursor_tile_changed.emit(tile, on_map)
