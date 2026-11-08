class_name StatusBar
extends PanelContainer

const NO_CURSOR_TEXT := "X: —  Y: —"

@onready var _cursor_label: Label = %CursorLabel
@onready var _project_label: Label = %ProjectLabel


static func format_cursor(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0:
		return NO_CURSOR_TEXT
	return "X: $%02X  Y: $%02X" % [cell.x, cell.y]


func show_cursor(cell: Vector2i) -> void:
	_cursor_label.text = format_cursor(cell)


func show_project(assets_dir: String) -> void:
	_project_label.text = assets_dir
