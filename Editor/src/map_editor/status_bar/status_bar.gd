class_name StatusBar
extends PanelContainer

@onready var _project_label: Label = %ProjectLabel


func show_project(assets_dir: String) -> void:
	_project_label.text = assets_dir
