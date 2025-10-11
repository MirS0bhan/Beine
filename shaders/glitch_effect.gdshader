shader_type canvas_item;

// Pixelation effect parameters
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.0;
uniform float pixelation_amount : hint_range(1.0, 200.0) = 96.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    if (glitch_strength > 0.0) {
        // Calculate pixel size based on glitch strength
        float pixel_size = floor(mix(1.0, pixelation_amount, glitch_strength));
        
        // Get screen resolution
        vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
        
        // Create clean pixel blocks by snapping UVs to grid
        vec2 block_count = resolution / pixel_size;
        vec2 pixelated_uv = floor(uv * block_count) / block_count;
        
        // Sample the texture at the center of each pixel block for cleaner result
        vec2 offset = (0.5 / block_count);
        vec3 color = texture(screen_texture, pixelated_uv + offset).rgb;
        
        COLOR = vec4(color, 1.0);
    } else {
        COLOR = texture(screen_texture, uv);
    }
}

