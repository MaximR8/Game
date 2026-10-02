shader_type canvas_item;
render_mode blend_add;

// UNE FLAMME PEINTE QUI VIT (02/10, les décors peints) : la flamme du décor elle-même, relue avec une ondulation (l'air
// chaud qui monte) et un vacillement ; seuls ses pixels chauds et clairs s'ajoutent — pas de halo, pas de copie floue.

uniform sampler2D decor : filter_linear, repeat_disable;
uniform vec4 region = vec4(0.0, 0.0, 0.05, 0.05);   // x, y, largeur, hauteur de la flamme, en UV du décor
uniform float temps = 0.0;
uniform float force = 0.55;

void fragment() {
	float haut = 1.0 - UV.y;
	float onde = sin(UV.y * 17.0 - temps * 9.0) * 0.022 * haut + sin(UV.y * 29.0 - temps * 14.0) * 0.010 * haut;
	vec2 uv = region.xy + vec2(UV.x + onde, UV.y) * region.zw;
	vec4 c = texture(decor, uv);
	float chaud = smoothstep(0.10, 0.38, c.r - c.b) * smoothstep(0.50, 0.90, max(c.r, c.g));
	float vacille = 0.70 + 0.30 * sin(temps * 17.0 + region.x * 40.0) * sin(temps * 7.3);
	COLOR = vec4(c.rgb * chaud * force * vacille, 1.0);
}
