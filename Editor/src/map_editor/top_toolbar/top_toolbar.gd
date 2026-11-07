extends PanelContainer

signal open_requested


func _on_open_button_pressed() -> void:
	open_requested.emit()
