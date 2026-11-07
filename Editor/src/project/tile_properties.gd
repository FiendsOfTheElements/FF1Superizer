class_name TileProperties
extends RefCounted

enum Flag {
	NO_WALK = 0x0001,
	NO_CANOE = 0x0002,
	NO_SHIP = 0x0004,
	NO_AIRSHIP = 0x0008,
	FOREST = 0x0010,
	DOCK = 0x0020,
}

enum Event { NONE = 0x00, CHIME = 0x40, CARAVAN = 0x80, AIRSHIP = 0xC0 }

enum Fight { LAND = 0x4000, RIVER = 0x4100, OCEAN = 0x4200 }

const WORD_BYTES := 2
const EVENT_MASK := 0xC0
const FIGHT_BIT := 0x4000
const FIGHT_MASK := 0xFF00
const TELEPORT_BIT := 0x8000
const TELEPORT_INDEX_SHIFT := 8
const TELEPORT_INDEX_MASK := 0x7F


static func has_flag(word: int, flag: Flag) -> bool:
	return (word & flag) != 0


static func event(word: int) -> Event:
	return (word & EVENT_MASK) as Event


static func is_teleport(word: int) -> bool:
	return (word & TELEPORT_BIT) != 0


# The teleport index shares the high byte with the fight bit, so a teleport is never a fight.
static func is_fight(word: int) -> bool:
	return not is_teleport(word) and (word & FIGHT_BIT) != 0


static func fight(word: int) -> Fight:
	return (word & FIGHT_MASK) as Fight


static func teleport_index(word: int) -> int:
	return (word >> TELEPORT_INDEX_SHIFT) & TELEPORT_INDEX_MASK


static func decode(bytes: PackedByteArray) -> PackedInt32Array:
	var words := PackedInt32Array()
	for offset in range(0, bytes.size() - 1, WORD_BYTES):
		words.append(bytes.decode_u16(offset))
	return words
