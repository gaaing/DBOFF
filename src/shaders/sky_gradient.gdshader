shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 top_color : source_color = vec4(0.302, 0.055, 0.584, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.0, 0.635, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

varying float v_height;

void vertex() {
	v_height = VERTEX.y;
}

void fragment() {
	float y = v_height;
	vec3 col;
	// 严格对标 OpenDBO-Core: NtlPLSky.cpp: SetColorOfDiffuseSkyAtomic
	// dNTL_PL_DIFFUSE_SKY_RGB_HEIGHT0(300), HEIGHT1(280), HEIGHT2(210), HEIGHT3(140), HEIGHT4(40), HEIGHT5(0), HEIGHT6(-180)
	if (y >= 280.0) {
		col = top_color.rgb;
	} else if (y >= 210.0) {
		float t = (y - 210.0) / 70.0;
		col = mix(mix(top_color.rgb, horizon_color.rgb, 0.5), top_color.rgb, t);
	} else if (y >= 140.0) {
		float t = (y - 140.0) / 70.0;
		col = mix(horizon_color.rgb, mix(top_color.rgb, horizon_color.rgb, 0.5), t);
	} else if (y >= 40.0) {
		float t = (y - 40.0) / 100.0;
		col = mix(mix(horizon_color.rgb, bottom_color.rgb, 0.5), horizon_color.rgb, t);
	} else if (y >= 0.0) {
		float t = y / 40.0;
		col = mix(bottom_color.rgb, mix(horizon_color.rgb, bottom_color.rgb, 0.5), t);
	} else {
		col = bottom_color.rgb;
	}
	ALBEDO = col;
}
