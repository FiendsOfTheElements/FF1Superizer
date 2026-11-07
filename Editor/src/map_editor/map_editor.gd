extends Panel

const MIN_WINDOW_SIZE := Vector2i(1280, 720)


func _ready() -> void:
	get_window().min_size = MIN_WINDOW_SIZE
