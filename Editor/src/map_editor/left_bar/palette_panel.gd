class_name PalettePanel
extends PanelContainer

@onready var _palette_grid: PaletteGrid = %PaletteGrid


func show_atlas(atlas: Texture2D) -> void:
	_palette_grid.show_atlas(atlas)
