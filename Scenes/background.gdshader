shader_type canvas_item;

void fragment() {
	vec2 uv = UV;

	uv.y += fract(TIME * -0.05);

	COLOR = texture(TEXTURE, uv);
}
