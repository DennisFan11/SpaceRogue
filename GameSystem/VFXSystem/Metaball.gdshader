shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	// 採樣螢幕紋理 (依據用戶要求，CanvasGroup 透過 screen_texture 取得內容)
	vec4 tex = texture(screen_texture, SCREEN_UV);
	float alpha = tex.a;
	
	// Metaball 閾值處理
	alpha = smoothstep(threshold - softness, threshold + softness, alpha);
	
	COLOR = vec4(tex.rgb, alpha);
}
