class_name PlaceholderTerrain
extends RefCounted

const SEED := 1987
const FREQUENCY := 0.012
const BAND_COLORS: Array[Color] = [
	Color(0.07, 0.16, 0.42),
	Color(0.18, 0.38, 0.72),
	Color(0.86, 0.79, 0.52),
	Color(0.36, 0.66, 0.27),
	Color(0.14, 0.4, 0.17),
	Color(0.48, 0.42, 0.38),
]
const BAND_THRESHOLDS: Array[float] = [-0.15, 0.0, 0.06, 0.25, 0.45]


static func generate() -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = SEED
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = FREQUENCY
	var image := Image.create_empty(OverworldMap.SIZE, OverworldMap.SIZE, false, Image.FORMAT_RGB8)
	for y in OverworldMap.SIZE:
		for x in OverworldMap.SIZE:
			image.set_pixel(x, y, BAND_COLORS[band_for(noise.get_noise_2d(x, y))])
	return image


static func band_for(value: float) -> int:
	return BAND_THRESHOLDS.bsearch(value)
