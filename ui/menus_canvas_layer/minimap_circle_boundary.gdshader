// res://ui/minimap_circle_border.gdshader
shader_type canvas_item;

// how big the circle is (0–0.5 = full rect, relative to shortest side)
uniform float radius : hint_range(0.0, 0.5, 0.01) = 0.48;

// width of the colored ring border
uniform float edge_thickness : hint_range(0.0, 0.1, 0.001) = 0.02;

// softness of anti-aliased edges
uniform float soften : hint_range(0.0, 0.05, 0.001) = 0.005;

// color of the border ring
uniform vec4 edge_color : source_color = vec4(0.10, 0.70, 1.00, 1.0);

// vignette strength inside circle (0 = off)
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.25;

// aspect ratio correction (rect_width / rect_height) — set via script
uniform float aspect : hint_range(0.1, 10.0, 0.01) = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // center UV and correct for aspect ratio
    vec2 p = UV - vec2(0.5);
    p.x *= aspect;

    float d = length(p); // distance from center
    float cut = radius;  // radius is already normalized
    float mask = 1.0 - smoothstep(cut, cut + soften, d);

    // ring between (cut - edge_thickness) and cut
    float r0 = cut - edge_thickness;
    float ring = smoothstep(r0 - soften, r0, d) - smoothstep(cut, cut + soften, d);

    // subtle vignette inside
    float vig = 1.0;
    if (vignette_strength > 0.0) {
        float inner = cut - edge_thickness - 0.02;
        float t = smoothstep(0.0, inner, d);
        vig = mix(1.0, 1.0 - vignette_strength, t);
    }

    vec4 base_col = tex * mask * vig;
    vec4 ring_col = edge_color * ring;

    COLOR = base_col + ring_col;
}