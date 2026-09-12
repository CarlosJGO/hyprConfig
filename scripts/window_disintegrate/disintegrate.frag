#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

// Qt default vertex shader expects qt_Matrix @0 and qt_Opacity @64.
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float blockSize;
    float intensity;
    float seed;
};

layout(binding = 1) uniform sampler2D source;

float hash21(vec2 point) {
    point = fract(point * vec2(123.34, 456.21));
    point += dot(point, point + 45.32);
    return fract(point.x * point.y);
}

vec2 hash22(vec2 point) {
    return vec2(hash21(point), hash21(point + vec2(27.1, 61.7)));
}

void main() {
    float cell = max(blockSize, 0.003);
    vec2 uv = qt_TexCoord0;

    // Irregular (voronoi) cells so shards are not a chessboard of squares.
    vec2 cellId = floor(uv / cell);
    vec2 cellFract = fract(uv / cell);
    float bestDist = 8.0;
    float secondDist = 8.0;
    vec2 bestId = cellId;
    for (int j = -1; j <= 1; ++j) {
        for (int i = -1; i <= 1; ++i) {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 site = hash22(cellId + neighbor + seed);
            vec2 delta = neighbor + site - cellFract;
            float dist = dot(delta, delta);
            if (dist < bestDist) {
                secondDist = bestDist;
                bestDist = dist;
                bestId = cellId + neighbor;
            } else if (dist < secondDist) {
                secondDist = dist;
            }
        }
    }

    float life = hash21(bestId + seed);
    float delay = life * 0.30;
    float t = clamp((progress - delay) / max(0.001, 1.0 - delay * 0.85), 0.0, 1.0);
    // Smooth ease — starts still (t=0 → no motion → no flash).
    t = t * t * (3.0 - 2.0 * t);

    vec2 rnd = hash22(bestId + seed + 3.0);
    vec2 dir = normalize(vec2(rnd.x * 2.0 - 1.0, mix(-0.05, 1.05, rnd.y)) + 1e-4);
    // Travel is 0 at t=0 (critical to avoid a first-frame jump / flash).
    float throwDist = intensity * 0.30 * (t * t);
    vec2 travel = dir * throwDist;

    // Soft organic rim instead of hard square clip.
    float edge = sqrt(max(secondDist, 0.0)) - sqrt(max(bestDist, 0.0));
    float crack = smoothstep(0.0, 0.045 + 0.04 * t, edge);

    // Sample original window content; move the shard by looking "back".
    vec2 sampleUv = uv - travel;
    sampleUv = clamp(sampleUv, vec2(0.001), vec2(0.999));
    vec4 color = texture(source, sampleUv);

    // Intact at start; shards peel off and fade. No flicker.
    float fade = 1.0 - smoothstep(0.35, 1.0, t);
    float visibility = mix(1.0, crack, clamp(t * 1.4, 0.0, 1.0));
    color *= visibility * fade * qt_Opacity;
    fragColor = color;
}
