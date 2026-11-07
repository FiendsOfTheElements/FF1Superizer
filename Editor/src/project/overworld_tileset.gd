class_name OverworldTileset
extends RefCounted

enum Corner { UL, UR, LL, LR }

const TILE_COUNT := 128
const CORNER_COUNT := 4
const TILEMAP_BYTES := TILE_COUNT * CORNER_COUNT
const CHR_COUNT := 256
const CHR_SIZE := 8
const TILE_SIZE := CHR_SIZE * 2
const CHR_BYTES := CHR_SIZE * CHR_SIZE
const CHR_DATA_BYTES := CHR_COUNT * CHR_BYTES
const PROPERTIES_BYTES := TILE_COUNT * TileProperties.WORD_BYTES
const MAX_PALETTE_COLORS := 128

var tilemaps: PackedByteArray
var chr: PackedByteArray
var palette: PackedColorArray
var properties: PackedInt32Array


func chr_index(tile: int, corner: Corner) -> int:
	return tilemaps[corner * TILE_COUNT + tile]


func chr_pixel(chr_id: int, x: int, y: int) -> int:
	return chr[chr_id * CHR_BYTES + y * CHR_SIZE + x]
