shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_tex : source_color, filter_linear_mipmap;
uniform vec4 skin_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int race_mode = 0; // 0: Human, 1: Namek, 2: Majin

void fragment() {
	vec4 tex = texture(base_tex, UV);
	vec3 base_rgb = tex.rgb;
	if (race_mode == 1) {
		// 那美克星人：保护红色/粉色肌肉条纹与触角基底不被肤色染绿，其余部分应用肤色变换
		float red_diff = base_rgb.r - base_rgb.g;
		if (red_diff > 0.12) {
			ALBEDO = base_rgb;
		} else {
			ALBEDO = base_rgb * skin_tint.rgb;
		}
	} else {
		ALBEDO = base_rgb * skin_tint.rgb;
	}
	ROUGHNESS = 0.70;
	METALLIC = 0.0;
}
