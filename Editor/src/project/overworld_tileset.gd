class_name OverworldTileset
extends RefCounted

enum Corner { UL, UR, LL, LR }

const TILE_COUNT := 128
const CORNER_COUNT := 4
const TILEMAP_BYTES := TILE_COUNT * CORNER_COUNT
const CHR_COUNT := 256
const CHR_SIZE := 8
const CHR_BYTES := CHR_SIZE * CHR_SIZE
const CHR_DATA_BYTES := CHR_COUNT * CHR_BYTES
const PROPERTIES_BYTES := TILE_COUNT * TileProperties.WORD_BYTES
const MAX_PALETTE_COLORS := 128
const TILE_SIZE := CHR_SIZE * 2
const ATLAS_COLUMNS := 16
const ATLAS_ROWS := TILE_COUNT / ATLAS_COLUMNS
const ATLAS_SIZE := Vector2i(ATLAS_COLUMNS, ATLAS_ROWS) * TILE_SIZE
const MISSING_COLOR := Color.CYAN

var tilemaps: PackedByteArray
var chr: PackedByteArray
var palette: PackedColorArray
var properties: PackedInt32Array


func chr_index(tile: int, corner: Corner) -> int:
	return tilemaps[corner * TILE_COUNT + tile]


func chr_pixel(chr_id: int, x: int, y: int) -> int:
	return chr[chr_id * CHR_BYTES + y * CHR_SIZE + x]


static func atlas_cell(tile: int) -> Vector2i:
	return Vector2i(tile % ATLAS_COLUMNS, tile / ATLAS_COLUMNS)


static func atlas_origin(tile: int) -> Vector2i:
	return atlas_cell(tile) * TILE_SIZE


static func atlas_tile_at(pixel: Vector2i) -> int:
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= ATLAS_SIZE.x or pixel.y >= ATLAS_SIZE.y:
		return -1
	var cell := pixel / TILE_SIZE
	return cell.y * ATLAS_COLUMNS + cell.x


static func corner_origin(corner: Corner) -> Vector2i:
	return Vector2i(corner % 2, corner / 2) * CHR_SIZE


func build_atlas() -> Image:
	var image := Image.create_empty(ATLAS_SIZE.x, ATLAS_SIZE.y, false, Image.FORMAT_RGBA8)
	for tile in TILE_COUNT:
		for corner: Corner in Corner.values():
			var origin := atlas_origin(tile) + corner_origin(corner)
			var chr_id := chr_index(tile, corner)
			for y in CHR_SIZE:
				for x in CHR_SIZE:
					image.set_pixel(origin.x + x, origin.y + y, _color(chr_pixel(chr_id, x, y)))
	return image


func _color(index: int) -> Color:
	return palette[index] if index < palette.size() else MISSING_COLOR
