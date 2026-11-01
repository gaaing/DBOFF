shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_always;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec2 uv_scale = vec2(1.0, -1.0);
uniform vec2 uv_offset = vec2(0.0, 1.0);
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float wind_speed = 1.6;
uniform float wind_strength = 0.12;
uniform float height_threshold = 3.0;

void vertex() {
	// 仅对超过高度阈值的树冠叶片产生柔和海风摆动，树干根部绝对刚性固定于地面
	if (VERTEX.y > height_threshold) {
		float h = clamp((VERTEX.y - height_threshold) * 0.10, 0.0, 1.5);
		float wave = sin(TIME * wind_speed + VERTEX.x * 0.35 + VERTEX.z * 0.35);
		VERTEX.x += wave * wind_strength * h;
		VERTEX.z += cos(TIME * (wind_speed * 0.85) + VERTEX.y * 0.20) * (wind_strength * 0.70) * h;
	}
}

void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
	vec4 col = texture(albedo_tex, uv);
	if (col.a < alpha_scissor_threshold) {
		discard;
	}
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
