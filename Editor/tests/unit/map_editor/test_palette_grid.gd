extends GutTest

const ATLAS_WIDTH := OverworldTileset.ATLAS_SIZE.x


func test_zoom_for_width() -> void:
	assert_eq(PaletteGrid.zoom_for_width(ATLAS_WIDTH - 1), 1)
	assert_eq(PaletteGrid.zoom_for_width(ATLAS_WIDTH), 1)
	assert_eq(PaletteGrid.zoom_for_width(2 * ATLAS_WIDTH - 1), 1)
	assert_eq(PaletteGrid.zoom_for_width(2 * ATLAS_WIDTH), 2)


func _shown_grid(zoom: int) -> PaletteGrid:
	var grid := PaletteGrid.new()
	add_child_autofree(grid)
	grid.size = Vector2(zoom * ATLAS_WIDTH, 0)
	grid.show_atlas(BlankAtlas.texture())
	return grid


func test_tile_at_maps_zoomed_positions() -> void:
	var zoom := 2
	var grid := _shown_grid(zoom)
	var half_tile := Vector2.ONE * OverworldTileset.TILE_SIZE / 2.0
	for tile in [0, OverworldTileset.TILE_COUNT - 1]:
		var center := (Vector2(OverworldTileset.atlas_origin(tile)) + half_tile) * zoom
		assert_eq(grid.tile_at(center), tile)
	assert_eq(grid.tile_at(Vector2(OverworldTileset.ATLAS_SIZE * zoom)), -1)


func test_grid_height_follows_zoom() -> void:
	var zoom := 2
	var grid := _shown_grid(zoom)
	assert_eq(grid.custom_minimum_size.y, float(OverworldTileset.ATLAS_SIZE.y * zoom))


func test_tile_at_without_tileset_is_none() -> void:
	var grid := PaletteGrid.new()
	add_child_autofree(grid)
	assert_eq(grid.tile_at(Vector2.ZERO), -1)
