extends GutTest


func test_off_map() -> void:
	assert_eq(StatusBar.format_cursor(Vector2i.ZERO, false), StatusBar.NO_CURSOR_TEXT)


func test_cells_format_as_hex() -> void:
	var last := OverworldMap.SIZE - 1
	assert_eq(StatusBar.format_cursor(Vector2i.ZERO, true), "X: $00  Y: $00")
	assert_eq(StatusBar.format_cursor(Vector2i(last, last), true), "X: $%X  Y: $%X" % [last, last])
