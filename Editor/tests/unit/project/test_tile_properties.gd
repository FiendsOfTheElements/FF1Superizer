extends GutTest


func test_each_flag_is_independent() -> void:
	for flag: int in TileProperties.Flag.values():
		for other: int in TileProperties.Flag.values():
			assert_eq(TileProperties.has_flag(flag, other), flag == other)


func test_events() -> void:
	for event: int in TileProperties.Event.values():
		assert_eq(TileProperties.event(event | TileProperties.Flag.NO_WALK), event)


func test_fights() -> void:
	for fight: int in TileProperties.Fight.values():
		var word := fight | TileProperties.Flag.FOREST
		assert_true(TileProperties.is_fight(word))
		assert_false(TileProperties.is_teleport(word))
		assert_eq(TileProperties.fight(word), fight)


func test_teleports_are_never_fights() -> void:
	for index in [0, TileProperties.TELEPORT_INDEX_MASK]:
		var word: int = TileProperties.TELEPORT_BIT | (index << TileProperties.TELEPORT_INDEX_SHIFT)
		assert_true(TileProperties.is_teleport(word))
		assert_false(TileProperties.is_fight(word))
		assert_eq(TileProperties.teleport_index(word), index)


func test_plain_tile_has_nothing() -> void:
	assert_false(TileProperties.is_fight(0))
	assert_false(TileProperties.is_teleport(0))
	assert_eq(TileProperties.event(0), TileProperties.Event.NONE)


func test_decode_reads_little_endian_words() -> void:
	var words := PackedInt32Array([TileProperties.Fight.OCEAN | TileProperties.Flag.DOCK, TileProperties.TELEPORT_BIT | TileProperties.Event.AIRSHIP])
	var bytes := PackedByteArray()
	bytes.resize(words.size() * TileProperties.WORD_BYTES)
	for i in words.size():
		bytes.encode_u16(i * TileProperties.WORD_BYTES, words[i])
	assert_eq(TileProperties.decode(bytes), words)
