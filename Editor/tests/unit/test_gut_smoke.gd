extends GutTest


func test_integers_are_equal() -> void:
	assert_eq(1 + 1, 2)


func test_strings_differ() -> void:
	assert_ne("pencil", "eraser")


func test_comparisons() -> void:
	assert_gt(10, 3)
	assert_lt(-1, 0)


func test_booleans() -> void:
	assert_true(Vector2i(256, 256) == Vector2i(256, 256))
	assert_false([].size() > 0)
