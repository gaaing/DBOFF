shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D alpha_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_alpha_tex = false;
uniform vec2 uv_scale = vec2(1.0, -1.0);
uniform vec2 uv_offset = vec2(0.0, 1.0);

void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
	
	// 在左右接缝边缘 (u 接近 0 或 1) 进行双向平滑羽化融合，彻底消除天穹旋转时 360 度圆柱云层的垂直截断
	float u_fract = fract(uv.x);
	float seam_dist = min(u_fract, 1.0 - u_fract);
	vec4 col;
	if (seam_dist < 0.05) {
		float blend_w = smoothstep(0.0, 1.0, seam_dist / 0.05);
		vec2 wrap_uv = vec2(uv.x + (u_fract < 0.5 ? 1.0 : -1.0), uv.y);
		vec4 c1 = texture(albedo_tex, uv);
		vec4 c2 = texture(albedo_tex, wrap_uv);
		col = mix((c1 + c2) * 0.5, c1, blend_w);
	} else {
		col = texture(albedo_tex, uv);
	}

	float a = col.a;
	if (has_alpha_tex) {
		// 全景山体遮罩图 (如 sky00_a.png) 保存在单通道/红通道灰度中
		float mask = texture(alpha_tex, uv).r;
		// 消除天空基准残留灰度 (~0.08)，将山体边缘平滑裁剪，使上方天空完全透出渐变天穹底色
		a = smoothstep(0.20, 0.70, mask);
	}
	ALBEDO = col.rgb;
	ALPHA = a;
}
