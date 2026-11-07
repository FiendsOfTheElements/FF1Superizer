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
