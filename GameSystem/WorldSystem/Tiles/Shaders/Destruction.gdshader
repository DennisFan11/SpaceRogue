shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale = 4.0;
uniform vec4 crack_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 hit_center = vec2(0.5, 0.5);

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

void fragment() {
    // 如果進度為0，不繪製任何內容
    if (progress <= 0.0) {
        discard;
    }

    vec2 p = UV * scale;
    vec2 n = floor(p);
    vec2 f = fract(p);

    vec2 mg, mr;
    float md = 8.0;
    
    // 第一步：尋找最近的點
    for (int j=-1; j<=1; j++) {
        for (int i=-1; i<=1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = hash(n + g);
            vec2 r = g + o - f;
            float d = dot(r, r);

            if (d < md) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }

    // 第二步：尋找與邊緣的距離
    md = 8.0;
    for (int j=-2; j<=2; j++) {
        for (int i=-2; i<=2; i++) {
            vec2 g = mg + vec2(float(i), float(j));
            vec2 o = hash(n + g);
            vec2 r = g + o - f;

            if (dot(mr-r, mr-r) > 0.00001) {
                float d = dot(0.5*(mr+r), normalize(r-mr));
                md = min(md, d);
            }
        }
    }

    // md 是到邊緣的距離（在邊緣時為0，內部為正值）
    
    // 中心權重
    float dist_to_center = length(UV - hit_center);
    float center_weight = 1.0 - smoothstep(0.0, 0.5, dist_to_center); // 中心為1，邊緣為0
    
    // 裂紋強度
    // md 越小越接近邊緣，我們希望邊緣處強度高
    float edge_intensity = 1.0 - smoothstep(0.0, 0.1, md); // 邊緣處為1，內部為0
    
    // 結合中心權重
    // 讓中心的裂紋更強烈 (增加權重倍數為 5.0)
    float intensity = edge_intensity * (1.0 + center_weight * 5.0);
    
    // 使用進度來控制閾值
    // intensity 最大約為 6.0 (edge_intensity=1 * (1 + center_weight=1 * 5))
    // 我們讓進度控制需要的強度閾值，使裂紋從受傷點向外擴展
    float threshold = 6.0 * (1.0 - progress);
    float is_crack = step(threshold, intensity);
    
    COLOR = vec4(crack_color.rgb, is_crack * crack_color.a);
}
