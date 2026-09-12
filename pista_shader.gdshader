shader_type spatial;

render_mode blend_mix;

varying float track_x;

void vertex() {
    track_x = VERTEX.x;
}

void fragment() {
    ALBEDO = vec3(0.1, 0.1, 0.1);

    float alpha = 1.0 - smoothstep(1, 0.3, track_x);

    ALPHA = alpha;
}