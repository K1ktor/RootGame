shader_type canvas_item;

uniform sampler2D mask_texture : hint_default_black, filter_linear, repeat_disable;
uniform vec4 mask_area;
uniform vec2 mask_texel_size;

uniform float blur_radius : hint_range(0.0, 32.0) = 3.0;
uniform float edge_min : hint_range(0.0, 1.0) = 0.05;
uniform float edge_max : hint_range(0.0, 1.0) = 0.6;

// Znikanie mgły po ukończeniu levela: 0 = cała mgła, 1 = brak mgły.
// Piksel znika, gdy próg dissolve przekroczy wartość szumu Perlina w tym miejscu.
uniform sampler2D dissolve_noise : hint_default_white, filter_linear, repeat_enable;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve_softness : hint_range(0.001, 0.5) = 0.08;
uniform float noise_world_size = 512.0;   // ile pikseli świata zajmuje jeden kafel szumu

varying vec2 mask_uv;
varying vec2 noise_uv;

const float WEIGHTS[5] = float[](1.0, 4.0, 6.0, 4.0, 1.0);


void vertex() {
	mask_uv = (VERTEX - mask_area.xy) / mask_area.zw;
	noise_uv = VERTEX / noise_world_size;
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

	// Próg przesuwa się od -softness do 1, żeby przy 0 i 1 nie zostawały pojedyncze plamy
	float n = texture(dissolve_noise, noise_uv).r;
	float threshold = mix(-dissolve_softness, 1.0, dissolve);
	fog.a *= smoothstep(threshold, threshold + dissolve_softness, n);
	COLOR = fog;
}
