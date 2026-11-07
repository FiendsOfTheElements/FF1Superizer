extends GutTest

const RED := SnesPalette.CHANNEL_MAX
const GREEN := SnesPalette.CHANNEL_MAX << SnesPalette.CHANNEL_BITS
const BLUE := SnesPalette.CHANNEL_MAX << (SnesPalette.CHANNEL_BITS * 2)


func test_black() -> void:
	assert_eq(SnesPalette.bgr555_to_color(0), Color.BLACK)


func test_white() -> void:
	assert_eq(SnesPalette.bgr555_to_color(RED | GREEN | BLUE), Color.WHITE)


func test_channels() -> void:
	assert_eq(SnesPalette.bgr555_to_color(RED), Color.RED)
	assert_eq(SnesPalette.bgr555_to_color(GREEN), Color(0, 1, 0))
	assert_eq(SnesPalette.bgr555_to_color(BLUE), Color.BLUE)


func test_decode_reads_little_endian_colors() -> void:
	var words := [RED, GREEN, BLUE]
	var bytes := PackedByteArray()
	bytes.resize(words.size() * SnesPalette.COLOR_BYTES)
	for i in words.size():
		bytes.encode_u16(i * SnesPalette.COLOR_BYTES, words[i])
	assert_eq(SnesPalette.decode(bytes), PackedColorArray([Color.RED, Color(0, 1, 0), Color.BLUE]))
