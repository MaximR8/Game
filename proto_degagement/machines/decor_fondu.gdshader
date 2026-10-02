shader_type canvas_item;

// LE DÉCOR PEINT, FONDU EN HAUT ET EN BAS (02/10, essai) : ses bords se perdent dans le ciel du jeu (pas de couture).

uniform float fondu_haut = 0.03;
uniform float fondu_bas = 0.04;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float a = smoothstep(0.0, fondu_haut, UV.y) * smoothstep(1.0, 1.0 - fondu_bas, UV.y);
	COLOR = vec4(c.rgb, c.a * a);
}
