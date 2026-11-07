class_name OverworldMapBuilder
extends RefCounted


static func single(tile: int) -> PackedByteArray:
	return PackedByteArray([tile])


static func run(tile: int, count: int) -> PackedByteArray:
	return PackedByteArray([tile | OverworldMap.RUN_FLAG, count % OverworldMap.SIZE])


static func row(parts: Array[PackedByteArray], terminated := true) -> PackedByteArray:
	var bytes := PackedByteArray()
	for part in parts:
		bytes.append_array(part)
	if terminated:
		bytes.append(OverworldMap.ROW_END)
	return bytes


static func full_row(tile: int) -> PackedByteArray:
	return row([run(tile, OverworldMap.SIZE)])


static func uniform(row_bytes: PackedByteArray) -> Array[PackedByteArray]:
	var rows: Array[PackedByteArray] = []
	for y in OverworldMap.SIZE:
		rows.append(row_bytes)
	return rows


static func encode(rows: Array[PackedByteArray]) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(OverworldMap.ROW_TABLE_BYTES)
	for y in rows.size():
		bytes.encode_u16(y * OverworldMap.ROW_POINTER_BYTES, bytes.size())
		bytes.append_array(rows[y])
	return bytes
