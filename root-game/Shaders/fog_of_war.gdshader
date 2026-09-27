shader_type canvas_item;

uniform sampler2D mask_texture : hint_default_black, filter_linear, repeat_disable;
uniform vec4 mask_area;
uniform vec2 mask_texel_size;

uniform float blur_radius : hint_range(0.0, 32.0) = 3.0;
uniform float edge_min : hint_range(0.0, 1.0) = 0.05;
uniform float edge_max : hint_range(0.0, 1.0) = 0.6;

varying vec2 mask_uv;

const float WEIGHTS[5] = float[](1.0, 4.0, 6.0, 4.0, 1.0);


void vertex() {
	mask_uv = (VERTEX - mask_area.xy) / mask_area.zw;
}


void fragment() {
	vec2 step_uv = mask_texel_size * blur_radius * 0.5;
	float m = 0.0;
	for (int x = 0; x < 5; x++) {
		for (int y = 0; y < 5; y++) {
			vec2 offset = vec2(float(x - 2), float(y - 2)) * step_uv;
			m += texture(mask_texture, mask_uv + offset).r * WEIGHTS[x] * WEIGHTS[y];
		}
	}
	m /= 256.0;

	vec4 fog = texture(TEXTURE, UV) * COLOR;
	fog.a *= 1.0 - smoothstep(edge_min, edge_max, m);
	COLOR = fog;
}
