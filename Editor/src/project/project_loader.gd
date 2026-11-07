class_name ProjectLoader
extends RefCounted

const MAP_PATH := "data/overworld-map.bin"
const TILEMAPS_PATH := "data/overworld-tilemaps.bin"
const PROPERTIES_PATH := "data/overworld-tileproperties.bin"
const CHR_PATH := "graphics/overworld-chr.m7"
const PALETTE_PATH := "graphics/overworld-map-palette.pal"


static func load_project(assets_dir: String, errors: Array[String]) -> Project:
	var error_count := errors.size()
	var tileset := OverworldTileset.new()
	tileset.tilemaps = _read_exact(assets_dir, TILEMAPS_PATH, OverworldTileset.TILEMAP_BYTES, errors)
	var property_bytes := _read_exact(
			assets_dir, PROPERTIES_PATH, OverworldTileset.PROPERTIES_BYTES, errors)
	tileset.chr = _read_exact(assets_dir, CHR_PATH, OverworldTileset.CHR_DATA_BYTES, errors)
	var palette_bytes := _read_sized(assets_dir, PALETTE_PATH, SnesPalette.COLOR_BYTES,
			OverworldTileset.MAX_PALETTE_COLORS * SnesPalette.COLOR_BYTES, SnesPalette.COLOR_BYTES,
			errors)
	var map: OverworldMap = null
	var map_error_count := errors.size()
	var map_bytes := _read(assets_dir, MAP_PATH, errors)
	if errors.size() == map_error_count:
		map = OverworldMap.decode(map_bytes, errors)
	if errors.size() != error_count:
		return null

	tileset.properties = TileProperties.decode(property_bytes)
	tileset.palette = SnesPalette.decode(palette_bytes)
	var project := Project.new()
	project.assets_dir = assets_dir
	project.overworld_map = map
	project.overworld_tileset = tileset
	return project


static func _read(assets_dir: String, relative_path: String, errors: Array[String]) -> PackedByteArray:
	var bytes := FileAccess.get_file_as_bytes(assets_dir.path_join(relative_path))
	var open_error := FileAccess.get_open_error()
	if open_error != OK:
		errors.append("%s: couldn't read (%s)." % [relative_path, error_string(open_error)])
	return bytes


static func _read_exact(assets_dir: String, relative_path: String, size: int,
		errors: Array[String]) -> PackedByteArray:
	return _read_sized(assets_dir, relative_path, size, size, 1, errors)


static func _read_sized(assets_dir: String, relative_path: String, min_size: int, max_size: int,
		step: int, errors: Array[String]) -> PackedByteArray:
	var error_count := errors.size()
	var bytes := _read(assets_dir, relative_path, errors)
	if errors.size() != error_count:
		return bytes
	var size := bytes.size()
	if size < min_size or size > max_size or size % step != 0:
		var expected := ("%d bytes" % min_size) if min_size == max_size \
				else ("%d to %d bytes in steps of %d" % [min_size, max_size, step])
		errors.append("%s is %d bytes, expected %s." % [relative_path, size, expected])
	return bytes
