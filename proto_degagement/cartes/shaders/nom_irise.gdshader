// Une feuille irisée, qui glisse avec la lumière : le nom du prismatique, les bannières des très rares.
shader_type canvas_item;

uniform vec2 lumiere = vec2(0.3, 0.28);
// La part de couleur dans le blanc : 0,28 pour les bannières, plus pour le nom du prismatique.
uniform float teinte = 0.28;

vec3 arc_en_ciel(float t) {
	return clamp(abs(mod(t * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void fragment() {
	// COLOR arrive déjà multiplié par le glyphe : on garde sa couverture, on change sa teinte.
	float t = SCREEN_UV.x * 3.0 + lumiere.x * 1.2;
	vec3 pastel = mix(vec3(1.0), arc_en_ciel(fract(t)), teinte);
	COLOR.rgb = pastel;
}
