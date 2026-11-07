class_name SnesPalette
extends RefCounted

const COLOR_BYTES := 2
const CHANNEL_BITS := 5
const CHANNEL_MAX := (1 << CHANNEL_BITS) - 1


static func bgr555_to_color(word: int) -> Color:
	return Color(
		_channel(word, 0),
		_channel(word, CHANNEL_BITS),
		_channel(word, CHANNEL_BITS * 2))


static func decode(bytes: PackedByteArray) -> PackedColorArray:
	var colors := PackedColorArray()
	for offset in range(0, bytes.size() - 1, COLOR_BYTES):
		colors.append(bgr555_to_color(bytes.decode_u16(offset)))
	return colors


static func _channel(word: int, shift: int) -> float:
	return float((word >> shift) & CHANNEL_MAX) / CHANNEL_MAX
