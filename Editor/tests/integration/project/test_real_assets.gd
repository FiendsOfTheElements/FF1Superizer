extends GutTest

const REAL_ASSETS_RELATIVE := "../ROMAssembly/assets"


func test_real_assets_load() -> void:
	var assets_dir := ProjectSettings.globalize_path("res://").path_join(REAL_ASSETS_RELATIVE).simplify_path()
	if not DirAccess.dir_exists_absolute(assets_dir):
		pending("No real assets at %s" % assets_dir)
		return
	var errors: Array[String] = []
	var project := ProjectLoader.load_project(assets_dir, errors)
	assert_eq(errors, [] as Array[String])
	assert_not_null(project)
	if project == null:
		return
	var tileset := project.overworld_tileset
	var max_pixel := 0
	for pixel in tileset.chr:
		max_pixel = maxi(max_pixel, pixel)
	assert_lt(max_pixel, tileset.palette.size(), "every chr pixel indexes a palette color")
