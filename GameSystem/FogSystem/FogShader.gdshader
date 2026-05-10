shader_type canvas_item;
render_mode unshaded;

uniform float visible_range = 300.0; // 可視距離維持 uniform

// 數量和過渡寬度寫成 const
const float GRADIENT_WIDTH = 100.0;
const float STAGES = 5.0; // 分 5 階段

void fragment() {
    // 獲取 SDF 距離
    float sdf_dist = texture_sdf(screen_uv_to_sdf(SCREEN_UV));
    
    // 減去可視距離
    float d = sdf_dist - visible_range;
    
    // 線性過渡因子 (0.0 到 1.0)
    float factor = clamp(d / GRADIENT_WIDTH, 0.0, 1.0);
    
    // 量化為 5 個階段
    factor = floor(factor * (STAGES - 1.0) + 0.5) / (STAGES - 1.0);
    
    // alpha = 0.0 代表可見 (透明)
    // alpha = 1.0 代表迷霧 (全黑)
    float alpha = factor;
    
    // 直接輸出帶透明度的黑色
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
