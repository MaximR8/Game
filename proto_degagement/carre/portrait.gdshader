shader_type canvas_item;

// Le portrait rond de l'adversaire (le Carré, 27/09) : l'illustration recadrée sur la tête
// (« region » : x, y, largeur, hauteur dans l'image), découpée en disque au bord net.
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	vec2 uv = region.xy + UV * region.zw;
	vec4 c = texture(TEXTURE, uv);
	float d = length(UV - vec2(0.5)) * 2.0;
	float aa = fwidth(d);
	c.a *= 1.0 - smoothstep(1.0 - aa, 1.0, d);
	COLOR = c * COLOR;
}
