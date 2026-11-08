class_name MapCanvas
extends Control

signal view_changed(footprint: PackedVector2Array, wraps: bool, zoom: float)
signal cursor_tile_changed(tile: Vector2i, on_map: bool)
signal view_mode_changed(mode: MapView.ViewMode)

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
const FRAME_COLOR := Color.WHITE
const FRAME_SHADOW_COLOR := Color(0, 0, 0, 0.75)
const PAN_ACTIONS: Array[StringName] = [&"map_pan_left", &"map_pan_right", &"map_pan_up", &"map_pan_down"]
const VIEW_ACTIONS: Array[StringName] = [&"map_view_normal", &"map_view_land", &"map_view_airship"]

const P_CANVAS_SIZE := &"canvas_size"
const P_CENTER := &"center"
const P_ZOOM := &"zoom"
const P_PERSPECTIVE_TERMS := &"perspective_terms"
const P_GAME_HALF_HEIGHT := &"game_half_height"
const P_MAX_SCALE := &"max_scale"
const P_WRAP_MAP := &"wrap_map"
const P_MAP_SIZE := &"map_size"
const P_BACKDROP := &"backdrop"
const P_GRID_WORLD := &"grid_world"
const P_GRID_COLOR := &"grid_color"
const P_GRID_MIN_SPACING := &"grid_min_spacing"

var _view := MapView.new()
var _mode := MapView.ViewMode.NORMAL
var _texture: ImageTexture
var _tween: Tween
var _mode_tween: Tween
var _zoom_target := 1.0
var _fitted := false
var _dragging := false
var _mouse_inside := false

@onready var _overlay: Control = %Overlay
@onready var _shader: ShaderMaterial = material


func _ready() -> void:
	_shader.set_shader_parameter(P_GAME_HALF_HEIGHT, MapView.GAME_SCREEN.y / 2.0)
	_shader.set_shader_parameter(P_MAX_SCALE, MapView.MAX_PERSPECTIVE_SCALE)
	_shader.set_shader_parameter(P_MAP_SIZE, MapView.map_size())
	_shader.set_shader_parameter(P_BACKDROP, (get_theme_stylebox(&"panel", &"Panel") as StyleBoxFlat).bg_color)
	_shader.set_shader_parameter(P_GRID_WORLD, float(GRID_TILES * OverworldTileset.TILE_SIZE))
	_shader.set_shader_parameter(P_GRID_COLOR, GRID_COLOR)
	_shader.set_shader_parameter(P_GRID_MIN_SPACING, GRID_MIN_SPACING)
	_on_resized.call_deferred()


func set_map_image(image: Image) -> void:
	_texture = ImageTexture.create_from_image(image)
	queue_redraw()


func set_view_mode(mode: MapView.ViewMode) -> void:
	if mode == _mode:
		return
	var projected_switch := _mode != MapView.ViewMode.NORMAL and mode != MapView.ViewMode.NORMAL
	_mode = mode
	if _mode_tween:
		_mode_tween.kill()
	_view.wrap = mode != MapView.ViewMode.NORMAL
	var target := MapView.perspective_for(mode)
	if projected_switch:
		var duration := absf(target - _view.perspective) * MapView.TRANSITION_FRAMES / MapView.GAME_FPS
		_mode_tween = create_tween()
		_mode_tween.tween_method(_set_perspective, _view.perspective, target, duration)
	else:
		_view.perspective = target
		_view_moved()
	view_mode_changed.emit(mode)


func fit_map(duration: float) -> void:
	if _view.wrap:
		_glide(_view.center, _view.fit_zoom(Rect2(Vector2.ZERO, MapView.GAME_SCREEN)), duration)
		return
	fit_tile_rect(Rect2i(Vector2i.ZERO, Vector2i.ONE * OverworldMap.SIZE), duration)


func fit_tile_rect(rect: Rect2i, duration: float) -> void:
	var world_rect := MapView.tile_rect_to_world(rect)
	_glide(world_rect.get_center(), _view.fit_zoom(world_rect), duration)


func pan_to(world: Vector2, duration: float) -> void:
	_glide(world, _view.zoom, duration)


func zoom_step_at(steps: int, anchor_world: Vector2) -> void:
	var target := MapView.stepped_zoom(_zoom_target, steps)
	var anchor := _view.center if _view.wrap else anchor_world
	_kill_tween()
	_zoom_target = target
	_tween = create_tween()
	_tween.tween_method(_zoom_about.bind(anchor), _view.zoom, _zoom_target, ZOOM_DURATION)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED when is_node_ready():
			_on_resized()
		NOTIFICATION_MOUSE_ENTER:
			_mouse_inside = true
		NOTIFICATION_MOUSE_EXIT:
			_mouse_inside = false
			cursor_tile_changed.emit(Vector2i.ZERO, false)


func _on_resized() -> void:
	_view.view_size = size
	if not _fitted and size.x > 0 and size.y > 0:
		_fitted = true
		fit_map(0.0)
	else:
		_view_moved()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button:
		_on_mouse_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion:
		if _dragging:
			_kill_tween()
			_view.center -= motion.relative / _view.zoom * _view.row_scale(_view.screen_to_game(motion.position).y)
			_view_moved()
		_emit_cursor_tile()
		return
	if event.is_action_pressed(&"map_zoom_in", true):
		zoom_step_at(1, _view.center)
	elif event.is_action_pressed(&"map_zoom_out", true):
		zoom_step_at(-1, _view.center)
	elif event.is_action_pressed(&"map_fit"):
		fit_map(MapView.GLIDE_DURATION)
	elif VIEW_ACTIONS.any(event.is_action_pressed):
		set_view_mode(VIEW_ACTIONS.find_custom(event.is_action_pressed) as MapView.ViewMode)
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
	_view.center += direction * speed * delta / _view.zoom * _view.row_scale(0.0)
	_view_moved()


func _draw() -> void:
	if _texture:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)


func _on_overlay_draw() -> void:
	if _view.wrap:
		_draw_game_frame()
	else:
		_draw_labels()


func _draw_game_frame() -> void:
	var frame_size := MapView.GAME_SCREEN * _view.zoom
	var frame := Rect2((size - frame_size) / 2.0, frame_size)
	_overlay.draw_rect(frame.grow(1.0), FRAME_SHADOW_COLOR, false, 1.0)
	_overlay.draw_rect(frame, FRAME_COLOR, false, 1.0)


func _draw_labels() -> void:
	var spacing := GRID_TILES * OverworldTileset.TILE_SIZE * _view.zoom
	if spacing < LABEL_MIN_SPACING:
		return
	var lines := OverworldMap.SIZE / GRID_TILES
	var origin := _view.world_to_screen(Vector2.ZERO)
	var first := Vector2i((-origin / spacing).floor()).clamp(Vector2i.ZERO, Vector2i.ONE * (lines - 1))
	var last := Vector2i(((size - origin) / spacing).ceil()).clamp(Vector2i.ZERO, Vector2i.ONE * (lines - 1))
	var font := get_theme_default_font()
	var baseline := Vector2(0, font.get_ascent(LABEL_FONT_SIZE))
	for j in range(first.y, last.y + 1):
		for i in range(first.x, last.x + 1):
			var pos := origin + Vector2(i, j) * spacing + LABEL_OFFSET + baseline
			var text := "%d,%d" % [i * GRID_TILES, j * GRID_TILES]
			_overlay.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, LABEL_OUTLINE, LABEL_OUTLINE_COLOR)
			_overlay.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)


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


func _set_perspective(f: float) -> void:
	_view.perspective = f
	_view_moved()


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_zoom_target = _view.zoom


func _view_moved() -> void:
	_view.clamp_center()
	_shader.set_shader_parameter(P_CANVAS_SIZE, size)
	_shader.set_shader_parameter(P_CENTER, _view.center)
	_shader.set_shader_parameter(P_ZOOM, _view.zoom)
	_shader.set_shader_parameter(P_PERSPECTIVE_TERMS, MapView.perspective_terms(_view.perspective))
	_shader.set_shader_parameter(P_WRAP_MAP, _view.wrap)
	_overlay.queue_redraw()
	view_changed.emit(_view.footprint(), _view.wrap, _view.zoom)
	if _mouse_inside:
		_emit_cursor_tile()


func _emit_cursor_tile() -> void:
	var screen := get_local_mouse_position()
	var world := _view.screen_to_world(screen)
	if _view.wrap:
		world = world.posmod(MapView.map_size().x)
	var tile := MapView.world_to_tile(world)
	var on_map := not _view.is_beyond_horizon(screen) and Rect2i(Vector2i.ZERO, Vector2i.ONE * OverworldMap.SIZE).has_point(tile)
	cursor_tile_changed.emit(tile, on_map)
