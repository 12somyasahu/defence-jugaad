shader_type canvas_item;

// base_ground_tile_01.png has a baked 2px border (dark line + highlight) and its interior
// is not seamless, so plain repeating drew a visible grid. Skip the border and mirror
// alternate tiles so neighbouring edges always match. Presentation only.
uniform float inset_px = 2.0;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 inset = vec2(inset_px) / size;
	vec2 mirrored = vec2(1.0) - abs(vec2(1.0) - mod(UV, vec2(2.0)));
	vec2 uv = inset + mirrored * (vec2(1.0) - 2.0 * inset);
	COLOR = texture(TEXTURE, uv) * vertex_color;
}
