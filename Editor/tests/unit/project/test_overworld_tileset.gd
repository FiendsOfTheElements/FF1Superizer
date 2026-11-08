extends GutTest

const LAST_TILE := OverworldTileset.TILE_COUNT - 1
const LAST_CHR := OverworldTileset.CHR_COUNT - 1
const LAST_PIXEL := OverworldTileset.CHR_SIZE - 1


func test_chr_index_reads_planar_corner_tables() -> void:
	var tileset := OverworldTileset.new()
	tileset.tilemaps.resize(OverworldTileset.TILEMAP_BYTES)
	for corner: int in OverworldTileset.Corner.values():
		tileset.tilemaps[corner * OverworldTileset.TILE_COUNT + LAST_TILE] = corner + 1
	for corner: int in OverworldTileset.Corner.values():
		assert_eq(tileset.chr_index(LAST_TILE, corner), corner + 1)
		assert_eq(tileset.chr_index(0, corner), 0)


func test_chr_pixel_is_row_major() -> void:
	var tileset := OverworldTileset.new()
	tileset.chr.resize(OverworldTileset.CHR_DATA_BYTES)
	tileset.chr[LAST_CHR * OverworldTileset.CHR_BYTES + LAST_PIXEL * OverworldTileset.CHR_SIZE] = 1
	assert_eq(tileset.chr_pixel(LAST_CHR, 0, LAST_PIXEL), 1)
	assert_eq(tileset.chr_pixel(LAST_CHR, LAST_PIXEL, 0), 0)


func _blank_tileset(palette_size: int) -> OverworldTileset:
	var tileset := OverworldTileset.new()
	tileset.tilemaps.resize(OverworldTileset.TILEMAP_BYTES)
	tileset.chr.resize(OverworldTileset.CHR_DATA_BYTES)
	for i in palette_size:
		tileset.palette.append(Color8(i + 1, 2 * i + 1, 3 * i + 1))
	return tileset


func _assert_color(got: Color, expected: Color) -> void:
	assert_eq(got.to_rgba32(), expected.to_rgba32())


func test_atlas_origin() -> void:
	var size := OverworldTileset.TILE_SIZE
	var columns := OverworldTileset.ATLAS_COLUMNS
	assert_eq(OverworldTileset.atlas_origin(0), Vector2i.ZERO)
	assert_eq(OverworldTileset.atlas_origin(columns - 1), Vector2i((columns - 1) * size, 0))
	assert_eq(OverworldTileset.atlas_origin(columns), Vector2i(0, size))
	assert_eq(OverworldTileset.atlas_origin(LAST_TILE), OverworldTileset.ATLAS_SIZE - Vector2i.ONE * size)


func test_atlas_cell() -> void:
	var columns := OverworldTileset.ATLAS_COLUMNS
	assert_eq(OverworldTileset.atlas_cell(0), Vector2i.ZERO)
	assert_eq(OverworldTileset.atlas_cell(columns - 1), Vector2i(columns - 1, 0))
	assert_eq(OverworldTileset.atlas_cell(columns), Vector2i(0, 1))
	assert_eq(OverworldTileset.atlas_cell(LAST_TILE),
			Vector2i(columns - 1, OverworldTileset.ATLAS_ROWS - 1))
	for tile in OverworldTileset.TILE_COUNT:
		assert_eq(OverworldTileset.atlas_origin(tile),
				OverworldTileset.atlas_cell(tile) * OverworldTileset.TILE_SIZE)


func test_atlas_tile_at_inverts_atlas_origin() -> void:
	var far_corner := Vector2i.ONE * (OverworldTileset.TILE_SIZE - 1)
	for tile in OverworldTileset.TILE_COUNT:
		var origin := OverworldTileset.atlas_origin(tile)
		assert_eq(OverworldTileset.atlas_tile_at(origin), tile)
		assert_eq(OverworldTileset.atlas_tile_at(origin + far_corner), tile)


func test_atlas_tile_at_outside_is_none() -> void:
	assert_eq(OverworldTileset.atlas_tile_at(Vector2i(-1, 0)), -1)
	assert_eq(OverworldTileset.atlas_tile_at(Vector2i(0, -1)), -1)
	assert_eq(OverworldTileset.atlas_tile_at(Vector2i(OverworldTileset.ATLAS_SIZE.x, 0)), -1)
	assert_eq(OverworldTileset.atlas_tile_at(Vector2i(0, OverworldTileset.ATLAS_SIZE.y)), -1)


func test_atlas_has_atlas_size() -> void:
	assert_eq(_blank_tileset(1).build_atlas().get_size(), OverworldTileset.ATLAS_SIZE)


func test_atlas_places_each_corner() -> void:
	var corners := OverworldTileset.Corner.values()
	var tileset := _blank_tileset(corners.size() + 1)
	for corner: int in corners:
		var chr_id := corner + 1
		tileset.tilemaps[corner * OverworldTileset.TILE_COUNT + LAST_TILE] = chr_id
		tileset.chr[chr_id * OverworldTileset.CHR_BYTES] = corner + 1
	var atlas := tileset.build_atlas()
	for corner: int in corners:
		var pixel := OverworldTileset.atlas_origin(LAST_TILE) + OverworldTileset.corner_origin(corner)
		_assert_color(atlas.get_pixelv(pixel), tileset.palette[corner + 1])


func test_index_zero_is_opaque_palette_color() -> void:
	var tileset := _blank_tileset(1)
	_assert_color(tileset.build_atlas().get_pixel(0, 0), tileset.palette[0])


func test_index_past_palette_is_missing_color() -> void:
	var tileset := _blank_tileset(1)
	tileset.chr[0] = tileset.palette.size()
	_assert_color(tileset.build_atlas().get_pixel(0, 0), OverworldTileset.MISSING_COLOR)
