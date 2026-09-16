#version 320 es
precision highp float;

// @settle 0.6

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;
uniform float time;
uniform vec2 surface_size;
uniform vec2 velocity;
uniform vec2 size_velocity;
uniform vec2 peak_velocity;
uniform vec2 peak_size_velocity;
uniform float is_moving;
uniform float is_resizing;
uniform float is_dragging;
uniform float settle;

const float TAU = 6.28318530718;
const float MOVE_GAIN = 0.0000012;
const float RESIZE_GAIN = 0.000018;
const float MAX_AMPLITUDE = 0.1;

void main() {
    vec2 safe_size = max(surface_size, vec2(1.0));
    vec2 live_motion = velocity * is_moving + size_velocity * is_resizing;
    vec2 peak_motion = peak_velocity * is_moving + peak_size_velocity * is_resizing;
    vec2 motion = live_motion;

    if (length(motion) < 0.001) {
        motion = peak_motion;
    }

    float move_amount = length(velocity) * MOVE_GAIN;
    float resize_amount = length(size_velocity) * RESIZE_GAIN;
    float peak_amount = length(peak_motion) * MOVE_GAIN * 0.35;
    float amplitude = clamp(max(move_amount, resize_amount) + peak_amount, 0.0, MAX_AMPLITUDE);
    amplitude *= 1.0 - clamp(settle, 0.0, 1.0);

    vec2 direction = normalize(motion + vec2(0.00001));
    vec2 perpendicular = vec2(-direction.y, direction.x);
    vec2 centered = v_texcoord - 0.5;
    float wave = sin(dot(centered, perpendicular) * TAU);
    vec2 displacement = direction * wave * amplitude;

    vec2 uv = clamp(v_texcoord + displacement / safe_size, 0.001, 0.999);
    fragColor = texture(tex, uv);
}
