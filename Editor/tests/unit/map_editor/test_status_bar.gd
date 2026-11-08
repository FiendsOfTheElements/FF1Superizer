extends GutTest


func test_no_cell() -> void:
	assert_eq(StatusBar.format_cursor(MapCanvas.NO_CELL), StatusBar.NO_CURSOR_TEXT)


func test_cells_format_as_hex() -> void:
	var last := OverworldMap.SIZE - 1
	assert_eq(StatusBar.format_cursor(Vector2i.ZERO), "X: $00  Y: $00")
	assert_eq(StatusBar.format_cursor(Vector2i(last, last)), "X: $%X  Y: $%X" % [last, last])