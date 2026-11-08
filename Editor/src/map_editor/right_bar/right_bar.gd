class_name RightBar
extends VSplitContainer

signal pan_requested(world: Vector2, duration: float)
signal zoom_requested(steps: int, anchor_world: Vector2)
signal focus_canvas_requested

@onready var _minimap: Minimap = %MinimapPanel


func set_map_image(image: Image) -> void:
	_minimap.set_map_image(image)


func show_view(footprint: PackedVector2Array, wraps: bool, _zoom: float) -> void:
	_minimap.show_view(footprint, wraps)


func _on_minimap_pan_requested(world: Vector2, duration: float) -> void:
	pan_requested.emit(world, duration)


func _on_minimap_zoom_requested(steps: int, anchor_world: Vector2) -> void:
	zoom_requested.emit(steps, anchor_world)


func _on_minimap_focus_canvas_requested() -> void:
	focus_canvas_requested.emit()
