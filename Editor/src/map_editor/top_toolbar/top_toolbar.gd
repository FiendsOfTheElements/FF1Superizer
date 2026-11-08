extends PanelContainer

signal open_requested
signal view_mode_requested(mode: MapView.ViewMode)

@onready var _view_buttons: Array[Button] = [%NormalViewButton, %LandViewButton, %AirshipViewButton]


func show_view_mode(mode: MapView.ViewMode) -> void:
	for i in _view_buttons.size():
		_view_buttons[i].set_pressed_no_signal(i == mode)


func _on_open_button_pressed() -> void:
	open_requested.emit()


func _on_normal_view_pressed() -> void:
	view_mode_requested.emit(MapView.ViewMode.NORMAL)


func _on_land_view_pressed() -> void:
	view_mode_requested.emit(MapView.ViewMode.LAND)


func _on_airship_view_pressed() -> void:
	view_mode_requested.emit(MapView.ViewMode.AIRSHIP)
