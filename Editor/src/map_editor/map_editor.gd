extends Panel

const MIN_WINDOW_SIZE := Vector2i(1280, 720)

var project: Project

@onready var _open_project_dialog: FileDialog = %OpenProjectDialog
@onready var _load_error_dialog: AcceptDialog = %LoadErrorDialog
@onready var _status_bar: StatusBar = %StatusBar
@onready var _map_canvas: MapCanvas = %MapCanvas
@onready var _right_bar: RightBar = %RightBar


func _ready() -> void:
	get_window().min_size = MIN_WINDOW_SIZE
	var placeholder := PlaceholderTerrain.generate()
	_map_canvas.set_map_image(placeholder)
	_right_bar.set_map_image(placeholder)


func _on_open_requested() -> void:
	_open_project_dialog.popup_centered()


func _on_project_dir_selected(assets_dir: String) -> void:
	var errors: Array[String] = []
	var loaded := ProjectLoader.load_project(assets_dir, errors)
	if loaded == null:
		_load_error_dialog.dialog_text = "\n".join(errors)
		_load_error_dialog.popup_centered()
		return
	project = loaded
	_status_bar.show_project(assets_dir)
	_map_canvas.fit_map(0.0)


func _on_view_changed(_footprint: PackedVector2Array, _wraps: bool, zoom: float) -> void:
	_status_bar.show_zoom(zoom)
