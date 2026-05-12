shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	// 採樣螢幕紋理 (CanvasGroup 透過 screen_texture 取得內容)
	vec4 tex = texture(screen_texture, SCREEN_UV);
	float alpha = tex.a;
	
	// Metaball 閾值處理
	alpha = smoothstep(threshold - softness, threshold + softness, alpha);
	
	// 光線要變成 1-alpha
	// 有光的地方 (alpha=1) 變成透明 (0)，沒光的地方 (alpha=0) 變成不透明 (1)
	// 沒有光線的地方就是黑的
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - alpha);
}
