shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_factor : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base_col = texture(albedo_texture, UV) * albedo_tint;
	vec3 flashed_rgb = mix(base_col.rgb, flash_color.rgb, flash_factor);
	ALBEDO = flashed_rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	// 在受击高亮时激发强烈的自发光脉冲，提供极其清晰的打击反馈
	EMISSION = flash_color.rgb * (flash_factor * 2.5);
}
