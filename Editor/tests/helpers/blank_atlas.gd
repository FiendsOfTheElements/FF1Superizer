class_name BlankAtlas
extends RefCounted


static func texture() -> ImageTexture:
	var size := OverworldTileset.ATLAS_SIZE
	return ImageTexture.create_from_image(Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8))
