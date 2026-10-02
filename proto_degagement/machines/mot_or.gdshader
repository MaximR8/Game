shader_type canvas_item;

// LE MOT SUPERNOVA (02/10) : l'inscription d'or rendue par design/machines/supernova.py ; un reflet la traverse — il ne
// s'allume que sur l'or déjà clair (pas sur l'émail ni l'ombre), comme le reflet du décor (reflet_or).

uniform float balai = -1.0;      // la position du reflet (de -0,3 à 1,3 : il traverse le mot)
uniform float eclat = 0.0;       // tout le mot s'illumine (son apparition)

varying vec4 teinte;             // la couleur du nœud (son modulate : le fondu)

void vertex() {
	teinte = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float clair = smoothstep(0.45, 0.85, max(c.r, c.g)) * step(0.1, c.r - c.b);
	float d = UV.x + (UV.y - 0.5) * 0.35 - balai;
	float bande = exp(-pow(d / 0.045, 2.0));
	c.rgb += c.rgb * clair * (bande * 1.1 + eclat * 0.8);
	COLOR = c * teinte;
}
