shader_type canvas_item;

uniform vec4 color_bright : source_color = vec4(0.6, 0.4, 0.2, 1.0);
uniform vec4 color_dark : source_color = vec4(0.3, 0.2, 0.1, 1.0);
uniform float scale = 0.05; // 世界座標下的縮放需要調小 (例如 0.05 代表每 20 像素一個單元)
uniform float jitter : hint_range(0.0, 1.0) = 0.9;
uniform float seed = 12.345;

varying vec2 world_pos;

void vertex() {
    // 獲取頂點在世界空間中的座標
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

vec2 random(vec2 uv) {
    return fract(sin(vec2(dot(uv + seed, vec2(127.1, 311.7)), dot(uv + seed, vec2(269.5, 183.3)))) * 43758.5453);
}

float random_float(vec2 uv) {
    return fract(sin(dot(uv + seed, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // 使用世界座標進行採樣
    vec2 uv = world_pos * scale;
    vec2 id = floor(uv);
    vec2 gv = fract(uv);
    
    float min_dist = 10.0;
    vec2 closest_id = vec2(0.0);
    
    for (float y = -1.0; y <= 1.0; y++) {
        for (float x = -1.0; x <= 1.0; x++) {
            vec2 offs = vec2(x, y);
            vec2 p = random(id + offs);
            vec2 r = offs + p * jitter - gv;
            float d = dot(r, r);
            
            if (d < min_dist) {
                min_dist = d;
                closest_id = id + offs;
            }
        }
    }
    
    float r = random_float(closest_id);
    vec4 final_color = mix(color_bright, color_dark, r);
    
    COLOR = final_color;
}
