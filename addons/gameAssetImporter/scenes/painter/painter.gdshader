shader_type canvas_item;

uniform float border_thickness = 2.0;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 size = vec2(1.0 / SCREEN_PIXEL_SIZE); // Size in pixels
    vec2 pixel_pos = UV * size;

    bool is_border =
        pixel_pos.x < border_thickness ||
        pixel_pos.x > size.x - border_thickness ||
        pixel_pos.y < border_thickness ||
        pixel_pos.y > size.y - border_thickness;

    COLOR = is_border ? border_color : COLOR; // COLOR is modulate color for ColorRect
}
