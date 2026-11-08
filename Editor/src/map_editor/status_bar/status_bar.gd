class_name StatusBar
extends PanelContainer

const NO_CURSOR_TEXT := "X: —  Y: —"

@onready var _cursor_label: Label = %CursorLabel
@onready var _zoom_label: Label = %ZoomLabel
@onready var _project_label: Label = %ProjectLabel


static func format_cursor(tile: Vector2i, on_map: bool) -> String:
	return "X: $%02X  Y: $%02X" % [tile.x, tile.y] if on_map else NO_CURSOR_TEXT


func show_project(assets_dir: String) -> void:
	_project_label.text = assets_dir


func show_cursor_tile(tile: Vector2i, on_map: bool) -> void:
	_cursor_label.text = format_cursor(tile, on_map)


func show_zoom(zoom: float) -> void:
	_zoom_label.text = "%d%%" % roundi(zoom * 100.0)
