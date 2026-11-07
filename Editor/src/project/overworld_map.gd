class_name OverworldMap
extends RefCounted

const SIZE := 256
const ROW_POINTER_BYTES := 2
const ROW_TABLE_BYTES := SIZE * ROW_POINTER_BYTES
const RUN_FLAG := 0x80
const TILE_MASK := 0x7F
const ROW_END := 0xFF

var tiles := PackedByteArray()


func get_tile(x: int, y: int) -> int:
	return tiles[y * SIZE + x]


static func decode(bytes: PackedByteArray, errors: Array[String]) -> OverworldMap:
	if bytes.size() < ROW_TABLE_BYTES:
		errors.append("Overworld map is %d bytes, too short for its %d-byte row table."
				% [bytes.size(), ROW_TABLE_BYTES])
		return null
	var map := OverworldMap.new()
	map.tiles.resize(SIZE * SIZE)
	var error_count := errors.size()
	for y in SIZE:
		var row_error := map._decode_row(bytes, y)
		if not row_error.is_empty():
			errors.append("Overworld map row %d: %s" % [y, row_error])
	return map if errors.size() == error_count else null


func _decode_row(bytes: PackedByteArray, y: int) -> String:
	var pos := bytes.decode_u16(y * ROW_POINTER_BYTES)
	if pos >= bytes.size():
		return "offset 0x%X is past the end of the file." % pos
	var x := 0
	while true:
		if pos >= bytes.size():
			return "data runs past the end of the file."
		var value := bytes[pos]
		pos += 1
		if value == ROW_END:
			break
		var count := 1
		if value & RUN_FLAG:
			if pos >= bytes.size():
				return "run is missing its count."
			count = bytes[pos]
			pos += 1
			if count == 0:
				count = SIZE
		if x + count > SIZE:
			return "decodes to more than %d tiles." % SIZE
		for i in count:
			tiles[y * SIZE + x + i] = value & TILE_MASK
		x += count
	if x != SIZE:
		return "decodes to %d tiles, expected %d." % [x, SIZE]
	return ""
