// Animated nebula used by the Cosmic Void board and the Starfield environment.
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uColorA;
uniform vec4 uColorB;
uniform vec4 uColorC;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 5; i++) {
    v += amp * noise(p);
    p = p * 2.03 + vec2(1.7, 9.2);
    amp *= 0.5;
  }
  return v;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  vec2 p = uv * vec2(uSize.x / uSize.y, 1.0) * 2.6;
  float t = uTime * 0.04;
  vec2 q = vec2(fbm(p + vec2(0.0, t)), fbm(p + vec2(5.2, 1.3 - t)));
  float n = fbm(p + 2.0 * q + vec2(t * 1.7, t));
  vec3 col = mix(uColorA.rgb, uColorB.rgb, smoothstep(0.2, 0.8, n));
  col = mix(col, uColorC.rgb, smoothstep(0.55, 0.95, q.x * n * 1.6));
  // Stars.
  vec2 g = floor(frag / 3.0);
  float s = hash(g);
  float tw = 0.5 + 0.5 * sin(uTime * 2.0 + s * 40.0);
  col += vec3(step(0.9975, s) * tw);
  // Vignette.
  float v = smoothstep(1.2, 0.3, length(uv - 0.5) * 1.4);
  fragColor = vec4(col * v, 1.0);
}
