//shader_type canvas_item;
//
//uniform vec2 scroll_direction = vec2(1.0, 0); // horizontal by default
//uniform float scroll_speed = 0.001; // slower scroll
//uniform float blur_strength = 1.0; // increase for more blur
//uniform float uv_scale = 10.0; // Smaller = bigger tiles, Larger = smaller tiles
//
//
//void vertex() {
	//// Called for every vertex the material is visible on.
//}
//
//void fragment() {
	//// Called for every pixel the material is visible on.
	//vec2 scaled_uv = UV / uv_scale;
	//vec2 uv_offset = scaled_uv + scroll_direction * TIME * scroll_speed;
//
//
    //// --- Simple multi-sample blur ---
    //vec4 col = vec4(0.0);
    //float total = 0.0;
//
    //for (int x = -2; x <= 2; x++) {
        //for (int y = -2; y <= 2; y++) {
            //float weight = 1.0 - (abs(float(x)) + abs(float(y))) * 0.25;
            //vec2 offset = vec2(float(x), float(y)) * (blur_strength / 1000.0);
            //col += texture(TEXTURE, uv_offset + offset) * weight;
            //total += weight;
        //}
    //}
//
    //COLOR = col / total;
//}
//
////void light() {
////	// Called for every pixel for every light affecting the CanvasItem.
////	// Uncomment to replace the default light processing function with this one.
////}

shader_type canvas_item;

uniform vec2 scroll_direction = vec2(1.0, 0.0); // direction of movement
uniform float scroll_speed = 0.06;             // movement speed
uniform float blur_strength = 3.0;

// Ping-pong function (Godot stdlib has this in 4.x)
float pingpong(float value, float length) {
    float mod_val = mod(value, length * 2.0);
    return length - abs(mod_val - length);
}

void fragment() {
    // limit scroll to the UV space (0→1)
    float offset_amount = pingpong(TIME * scroll_speed, 1.0);

    vec2 offset_uv = UV + scroll_direction * (offset_amount - 0.5);

    // clamp so we never sample outside the texture
    offset_uv = clamp(offset_uv, vec2(0.0), vec2(1.0));

    // --- Blur sampling ---
    vec4 col = vec4(0.0);
    float weight_sum = 0.0;

    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            float w = 1.0 - (abs(float(x)) + abs(float(y))) * 0.25;
            vec2 off = vec2(float(x), float(y)) * (blur_strength / 1000.0);
            col += texture(TEXTURE, offset_uv + off) * w;
            weight_sum += w;
        }
    }

    COLOR = col / weight_sum;
}
