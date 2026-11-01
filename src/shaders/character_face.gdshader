shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_skin_tex : source_color, filter_linear_mipmap;
uniform sampler2D face_feature_tex : source_color, filter_linear_mipmap;
uniform vec4 skin_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 skin_col = texture(base_skin_tex, UV) * skin_tint;
	vec4 face_col = texture(face_feature_tex, UV);
	ALBEDO = mix(skin_col.rgb, face_col.rgb, face_col.a);
	ROUGHNESS = 0.65;
	METALLIC = 0.0;
}
