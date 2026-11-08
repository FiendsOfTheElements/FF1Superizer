class_name LeftBar
extends VBoxContainer

@onready var _palette_panel: PalettePanel = %PalettePanel


func show_atlas(atlas: Texture2D) -> void:
	_palette_panel.show_atlas(atlas)
