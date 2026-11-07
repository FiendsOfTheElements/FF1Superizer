class_name StatusBar
extends PanelContainer

@onready var _cursor_label: Label = %CursorLabel
@onready var _zoom_label: Label = %ZoomLabel
@onready var _project_label: Label = %ProjectLabel


func show_project(assets_dir: String) -> void:
	_project_label.text = assets_dir


func show_cursor_tile(tile: Vector2i, on_map: bool) -> void:
	_cursor_label.text = "X: %d  Y: %d" % [tile.x, tile.y] if on_map else "X: —  Y: —"


func show_zoom(zoom: float) -> void:
	_zoom_label.text = "%d%%" % roundi(zoom * 100.0)
