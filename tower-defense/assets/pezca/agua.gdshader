shader_type canvas_item;

uniform vec4 color_fondo : source_color = vec4(0.08, 0.18, 0.50, 1.0);
uniform vec4 color_ola   : source_color = vec4(0.22, 0.52, 0.88, 1.0);
uniform float velocidad  : hint_range(0.1, 5.0) = 1.2;
uniform float escala     : hint_range(1.0, 20.0) = 6.0;

void fragment() {
	vec2 uv = UV * escala;
	float t  = TIME * velocidad;
	float w1 = sin(uv.x * 1.8 + t)        * sin(uv.y * 1.2 + t * 0.6) * 0.5 + 0.5;
	float w2 = sin(uv.x * 2.7 - t * 0.8 + 2.1) * sin(uv.y * 2.1 + t * 0.5) * 0.5 + 0.5;
	float w3 = sin((uv.x + uv.y) * 1.6 + t * 1.1) * 0.5 + 0.5;
	float mezcla = w1 * 0.4 + w2 * 0.4 + w3 * 0.2;
	COLOR = mix(color_fondo, color_ola, mezcla);
}
