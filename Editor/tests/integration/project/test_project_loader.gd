extends GutTest

const ASSETS_DIR := "user://test_project_loader"
const ALL_PATHS: Array[String] = [ProjectLoader.MAP_PATH, ProjectLoader.TILEMAPS_PATH, ProjectLoader.PROPERTIES_PATH, ProjectLoader.CHR_PATH, ProjectLoader.PALETTE_PATH]
const FIXED_SIZES := {
	ProjectLoader.TILEMAPS_PATH: OverworldTileset.TILEMAP_BYTES,
	ProjectLoader.PROPERTIES_PATH: OverworldTileset.PROPERTIES_BYTES,
	ProjectLoader.CHR_PATH: OverworldTileset.CHR_DATA_BYTES,
}

var errors: Array[String] = []


func before_each() -> void:
	errors = []
	_write(ProjectLoader.MAP_PATH, OverworldMapBuilder.encode(OverworldMapBuilder.uniform(OverworldMapBuilder.full_row(0))))
	for path: String in FIXED_SIZES:
		_write_zeros(path, FIXED_SIZES[path])
	_write_zeros(ProjectLoader.PALETTE_PATH, SnesPalette.COLOR_BYTES)


func after_each() -> void:
	for path in ALL_PATHS:
		DirAccess.remove_absolute(ASSETS_DIR.path_join(path))
	for path in ALL_PATHS:
		DirAccess.remove_absolute(ASSETS_DIR.path_join(path).get_base_dir())
	DirAccess.remove_absolute(ASSETS_DIR)


func _write(path: String, bytes: PackedByteArray) -> void:
	var full_path := ASSETS_DIR.path_join(path)
	DirAccess.make_dir_recursive_absolute(full_path.get_base_dir())
	var file := FileAccess.open(full_path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func _write_zeros(path: String, size: int) -> void:
	var bytes := PackedByteArray()
	bytes.resize(size)
	_write(path, bytes)


func _load() -> Project:
	return ProjectLoader.load_project(ASSETS_DIR, errors)


func test_valid_project_loads() -> void:
	var project := _load()
	assert_eq(errors, [] as Array[String])
	assert_eq(project.assets_dir, ASSETS_DIR)
	assert_eq(project.overworld_map.tiles.size(), OverworldMap.SIZE * OverworldMap.SIZE)
	assert_eq(project.overworld_tileset.properties.size(), OverworldTileset.TILE_COUNT)
	assert_eq(project.overworld_tileset.palette.size(), 1)


func test_each_missing_file_is_reported() -> void:
	for path in ALL_PATHS:
		before_each()
		DirAccess.remove_absolute(ASSETS_DIR.path_join(path))
		assert_null(_load(), path)
		assert_eq(errors.size(), 1, path)
		assert_string_contains(errors[0], path)


func test_each_wrong_fixed_size_is_reported() -> void:
	for path: String in FIXED_SIZES:
		before_each()
		_write_zeros(path, FIXED_SIZES[path] + 1)
		assert_null(_load(), path)
		assert_eq(errors.size(), 1, path)
		assert_string_contains(errors[0], path)


func test_bad_palette_sizes_are_reported() -> void:
	var max_bytes := OverworldTileset.MAX_PALETTE_COLORS * SnesPalette.COLOR_BYTES
	for size in [0, SnesPalette.COLOR_BYTES + 1, max_bytes + SnesPalette.COLOR_BYTES]:
		before_each()
		_write_zeros(ProjectLoader.PALETTE_PATH, size)
		assert_null(_load(), str(size))
		assert_eq(errors.size(), 1, str(size))


func test_max_palette_loads() -> void:
	_write_zeros(ProjectLoader.PALETTE_PATH, OverworldTileset.MAX_PALETTE_COLORS * SnesPalette.COLOR_BYTES)
	var project := _load()
	assert_eq(errors, [] as Array[String])
	assert_eq(project.overworld_tileset.palette.size(), OverworldTileset.MAX_PALETTE_COLORS)


func test_bad_map_is_reported() -> void:
	_write_zeros(ProjectLoader.MAP_PATH, OverworldMap.ROW_TABLE_BYTES - 1)
	assert_null(_load())
	assert_eq(errors.size(), 1)


func test_all_problems_are_reported_together() -> void:
	DirAccess.remove_absolute(ASSETS_DIR.path_join(ProjectLoader.MAP_PATH))
	_write_zeros(ProjectLoader.CHR_PATH, OverworldTileset.CHR_DATA_BYTES - 1)
	_write_zeros(ProjectLoader.PALETTE_PATH, 0)
	assert_null(_load())
	assert_eq(errors.size(), 3)
