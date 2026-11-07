extends GutTest


func test_image_is_one_pixel_per_tile() -> void:
	var image := PlaceholderTerrain.generate()
	assert_eq(image.get_size(), Vector2i.ONE * OverworldMap.SIZE)


func test_generation_is_deterministic() -> void:
	assert_eq(PlaceholderTerrain.generate().get_data(), PlaceholderTerrain.generate().get_data())


func test_every_band_appears() -> void:
	var image := PlaceholderTerrain.generate()
	var seen := {}
	for y in OverworldMap.SIZE:
		for x in OverworldMap.SIZE:
			seen[image.get_pixel(x, y).to_html(false)] = true
	for color in PlaceholderTerrain.BAND_COLORS:
		var stored := Image.create_empty(1, 1, false, Image.FORMAT_RGB8)
		stored.set_pixel(0, 0, color)
		assert_true(seen.has(stored.get_pixel(0, 0).to_html(false)), "band %s missing" % color)


func test_band_for_splits_on_thresholds() -> void:
	assert_eq(PlaceholderTerrain.band_for(-1.0), 0)
	assert_eq(PlaceholderTerrain.band_for(1.0), PlaceholderTerrain.BAND_COLORS.size() - 1)
	assert_eq(PlaceholderTerrain.BAND_THRESHOLDS.size(), PlaceholderTerrain.BAND_COLORS.size() - 1)
