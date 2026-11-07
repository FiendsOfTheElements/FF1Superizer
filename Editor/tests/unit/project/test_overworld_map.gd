extends GutTest

const LAST := OverworldMap.SIZE - 1

var errors: Array[String] = []


func before_each() -> void:
	errors = []


func _decode(rows: Array[PackedByteArray]) -> OverworldMap:
	return OverworldMap.decode(OverworldMapBuilder.encode(rows), errors)


func test_full_run_fills_row() -> void:
	var tile := OverworldMap.TILE_MASK - 1
	var map := _decode(OverworldMapBuilder.uniform(OverworldMapBuilder.full_row(tile)))
	assert_eq(errors, [] as Array[String])
	assert_eq(map.get_tile(0, 0), tile)
	assert_eq(map.get_tile(LAST, LAST), tile)


func test_highest_tile_decodes_as_single() -> void:
	var row := OverworldMapBuilder.row([OverworldMapBuilder.run(0, LAST),
			OverworldMapBuilder.single(OverworldMap.TILE_MASK)])
	var map := _decode(OverworldMapBuilder.uniform(row))
	assert_eq(errors, [] as Array[String])
	assert_eq(map.get_tile(LAST, 0), OverworldMap.TILE_MASK)


func test_singles_and_runs_mix() -> void:
	var row := OverworldMapBuilder.row([OverworldMapBuilder.single(1), OverworldMapBuilder.run(2, OverworldMap.SIZE - 2), OverworldMapBuilder.single(3)])
	var map := _decode(OverworldMapBuilder.uniform(row))
	assert_eq(errors, [] as Array[String])
	assert_eq(map.get_tile(0, 0), 1)
	assert_eq(map.get_tile(1, 0), 2)
	assert_eq(map.get_tile(LAST - 1, 0), 2)
	assert_eq(map.get_tile(LAST, 0), 3)


func test_rows_decode_from_their_own_offsets() -> void:
	var rows: Array[PackedByteArray] = []
	for y in OverworldMap.SIZE:
		rows.append(OverworldMapBuilder.full_row(y % OverworldMap.TILE_MASK))
	var map := _decode(rows)
	for y in OverworldMap.SIZE:
		assert_eq(map.get_tile(0, y), y % OverworldMap.TILE_MASK)


func test_trailing_bytes_are_ignored() -> void:
	var bytes := OverworldMapBuilder.encode(OverworldMapBuilder.uniform(OverworldMapBuilder.full_row(0)))
	bytes.append_array(PackedByteArray([OverworldMap.RUN_FLAG, OverworldMap.ROW_END]))
	assert_not_null(OverworldMap.decode(bytes, errors))
	assert_eq(errors, [] as Array[String])


func test_too_short_for_row_table() -> void:
	var bytes := PackedByteArray()
	bytes.resize(OverworldMap.ROW_TABLE_BYTES - 1)
	assert_null(OverworldMap.decode(bytes, errors))
	assert_eq(errors.size(), 1)


func test_offset_past_end_of_file() -> void:
	var bytes := OverworldMapBuilder.encode(OverworldMapBuilder.uniform(OverworldMapBuilder.full_row(0)))
	bytes.encode_u16(LAST * OverworldMap.ROW_POINTER_BYTES, bytes.size())
	assert_null(OverworldMap.decode(bytes, errors))
	assert_eq(errors.size(), 1)


func test_missing_terminator() -> void:
	var rows := OverworldMapBuilder.uniform(OverworldMapBuilder.full_row(0))
	rows[LAST] = OverworldMapBuilder.row([OverworldMapBuilder.run(0, OverworldMap.SIZE)], false)
	assert_null(_decode(rows))
	assert_eq(errors.size(), 1)


func test_run_missing_count() -> void:
	var rows := OverworldMapBuilder.uniform(OverworldMapBuilder.full_row(0))
	rows[LAST] = PackedByteArray([OverworldMap.RUN_FLAG])
	assert_null(_decode(rows))
	assert_eq(errors.size(), 1)


func test_short_row() -> void:
	var rows := OverworldMapBuilder.uniform(OverworldMapBuilder.full_row(0))
	rows[0] = OverworldMapBuilder.row([OverworldMapBuilder.run(0, OverworldMap.SIZE - 1)])
	assert_null(_decode(rows))
	assert_eq(errors.size(), 1)


func test_long_row() -> void:
	var rows := OverworldMapBuilder.uniform(OverworldMapBuilder.full_row(0))
	rows[0] = OverworldMapBuilder.row([OverworldMapBuilder.single(0), OverworldMapBuilder.run(0, OverworldMap.SIZE)])
	assert_null(_decode(rows))
	assert_eq(errors.size(), 1)


func test_every_bad_row_is_reported() -> void:
	var short_row := OverworldMapBuilder.row([OverworldMapBuilder.single(0)])
	assert_null(_decode(OverworldMapBuilder.uniform(short_row)))
	assert_eq(errors.size(), OverworldMap.SIZE)
