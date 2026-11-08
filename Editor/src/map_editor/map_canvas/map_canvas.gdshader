shader_type canvas_item;

uniform vec2 canvas_size = vec2(1.0);
uniform vec2 center;
uniform float game_scale = 1.0;
uniform float altitude = 1.0;
uniform vec2 perspective_terms = vec2(1.0, 0.0);
uniform float game_half_height = 112.0;
uniform float max_scale = 8.0;
uniform bool wrap_map = false;
uniform vec2 map_size = vec2(1.0);
uniform vec4 backdrop : source_color;
uniform float grid_world = 256.0;
uniform vec4 grid_color : source_color;
uniform float grid_min_spacing = 8.0;

void fragment() {
	vec2 game = (UV * canvas_size - canvas_size * 0.5) / game_scale;
	float denom = perspective_terms.x + perspective_terms.y * game.y / game_half_height;
	vec2 world = center + game / max(denom, 1e-4) * altitude;
	vec2 pixel_world = fwidth(world);
	bvec2 grid_crossed = notEqual(floor((world - pixel_world * 0.5) / grid_world), floor((world + pixel_world * 0.5) / grid_world));
	bool grid_visible = grid_world / max(pixel_world.x, pixel_world.y) >= grid_min_spacing;
	vec2 uv = world / map_size;
	bool off_map = any(lessThan(uv, vec2(0.0))) || any(greaterThanEqual(uv, vec2(1.0)));
	if (denom <= 1.0 / max_scale || (!wrap_map && off_map)) {
		COLOR = backdrop;
	} else {
		COLOR = texture(TEXTURE, fract(uv));
		if (grid_visible && any(grid_crossed)) {
			COLOR.rgb = mix(COLOR.rgb, grid_color.rgb, grid_color.a);
		}
	}
}
