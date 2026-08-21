shader_type canvas_item;

uniform float intensidad : hint_range(0.5, 4.0) = 1.0;

void fragment() {
	vec2  uv   = UV - vec2(0.5);
	float d    = length(uv);
	float t    = TIME * 2.5 * intensidad;

	float r1   = sin(d * 25.0 - t * 2.0)        * 0.5 + 0.5;
	float r2   = sin(d * 18.0 - t * 1.6 + 1.2)  * 0.5 + 0.5;
	float n    = sin(uv.x * 14.0 + t * 1.1) * cos(uv.y * 11.0 - t * 0.9) * 0.4 + 0.6;

	float fade = smoothstep(0.5, 0.08, d);
	float val  = (r1 * 0.45 + r2 * 0.35 + n * 0.2) * fade;

	vec3 col   = mix(vec3(0.3, 0.7, 1.0), vec3(1.0, 1.0, 1.0), val * 0.6);
	COLOR      = vec4(col, val * 0.88);
}
