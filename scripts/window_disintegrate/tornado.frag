#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

// Qt default vertex shader expects qt_Matrix @0 and qt_Opacity @64.
// Same uniform layout as disintegrate.frag so the overlay can swap shaders.
// For tornado, blockSize carries window aspect (width/height).
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float blockSize;
    float intensity;
    float seed;
};

layout(binding = 1) uniform sampler2D source;

float hash11(float x) {
    return fract(sin(x * 127.1 + 311.7) * 43758.5453);
}

float sdRoundedBox(vec2 point, vec2 halfSize, float radius) {
    float r = min(radius, min(halfSize.x, halfSize.y));
    vec2 q = abs(point) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 uv = qt_TexCoord0;
    // progress=0 must match the capture exactly (no first-frame flash).
    float t = clamp(progress, 0.0, 1.0);

    float spinDir = hash11(seed + 0.37) > 0.5 ? 1.0 : -1.0;
    float spins = mix(3.0, 5.0, clamp(intensity - 0.5, 0.0, 1.5) / 1.5);

    float aspect = max(blockSize, 0.05);
    vec2 centered = uv - 0.5;
    // Aspect-correct radius so the spin wave is circular on screen.
    vec2 circP = vec2(centered.x * aspect, centered.y);
    float rMax = 0.5 * min(aspect, 1.0) * 1.41421356; // corner reach
    float rNorm = clamp(length(circP) / max(rMax, 1e-4), 0.0, 1.0);

    // Outside-in: spin wave starts at the rim and crawls toward the center.
    float rimDelay = 0.55;
    float join = clamp((t - (1.0 - rNorm) * rimDelay) / max(1e-3, 1.0 - rimDelay * 0.35), 0.0, 1.0);
    join = join * join * (3.0 - 2.0 * join);

    // Center join (rNorm=0): shrink of the plate only starts once the eye is spinning.
    float centerJoin = clamp((t - rimDelay) / max(1e-3, 1.0 - rimDelay), 0.0, 1.0);
    centerJoin = centerJoin * centerJoin * (3.0 - 2.0 * centerJoin);

    // Silhouette shrink waits for the center; per-pixel shrink follows local join.
    float scale = mix(1.0, 0.006, pow(centerJoin, 1.1));
    scale = max(scale, 0.001);
    // Still-static rings stay full size; spinning rings contract with the plate.
    float localScale = mix(1.0, scale, join);
    localScale = max(localScale, 0.001);

    // Outer leads: more turns at the rim, center catches up as join rises.
    float angle = join * spins * 6.28318530718 * spinDir;
    angle += join * intensity * 1.6 * rNorm * spinDir;

    vec2 dir = circP / max(length(circP), 1e-4);
    vec2 tang = vec2(-dir.y, dir.x) * spinDir;

    // Asymmetric tear follows the outer-first wave (only where join > 0).
    float side = centered.x * spinDir + centered.y * 0.35;
    float asym = mix(0.28, 1.0, smoothstep(-0.45, 0.55, side));
    float curl = join * intensity * 1.85 * asym * rNorm;
    centered += tang * curl * rNorm * rNorm * 1.2;
    centered *= 1.0 - curl * 0.38 * rNorm;

    float c = cos(angle);
    float s = sin(angle);
    vec2 rotated = vec2(
        centered.x * c + centered.y * s,
        -centered.x * s + centered.y * c
    );

    vec2 sampleUv = rotated / localScale + 0.5;

    if (sampleUv.x < 0.0 || sampleUv.x > 1.0 || sampleUv.y < 0.0 || sampleUv.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }

    sampleUv = clamp(sampleUv, vec2(0.001), vec2(0.999));
    vec4 color = texture(source, sampleUv);

    // Morph rect → circle during the spin-in; silhouette size follows centerJoin scale.
    vec2 shapeP = uv - 0.5;
    vec2 halfSize = vec2(0.5 * scale);
    float inscribedR = 0.5 * min(aspect, 1.0);
    float circleR = inscribedR * scale;
    vec2 circSpace = vec2(shapeP.x * aspect, shapeP.y);

    float cornerT = smoothstep(0.0, 0.42, t);
    float cornerR = cornerT * min(halfSize.x, halfSize.y);
    float roundedDist = sdRoundedBox(shapeP, halfSize, cornerR);

    float circleT = smoothstep(0.22, 0.72, t);
    float circDist = length(circSpace) - circleR;
    float shapeDist = mix(roundedDist, circDist, circleT);

    float soft = mix(0.003, 0.016, circleT) * max(scale, 0.08);
    float shapeMask = 1.0 - smoothstep(-soft, soft, shapeDist);

    float gulp = smoothstep(0.0, 0.035, scale);
    color *= shapeMask * gulp * qt_Opacity;
    fragColor = color;
}
