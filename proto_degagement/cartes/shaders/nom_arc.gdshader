// Le nom du full art : un arc-en-ciel franc qui coule le long des lettres (27/09, Maxim :
// « le nom du héros doit bien être en couleur arc-en-ciel qui bouge »).
shader_type canvas_item;

uniform vec2 lumiere = vec2(0.3, 0.28);
// La largeur du nom, en px : l'arc-en-ciel fait un peu moins d'un tour sur le mot.
uniform float largeur = 300.0;

varying vec2 local;

vec3 arc_en_ciel(float t) {
	return clamp(abs(mod(t * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void vertex() {
	local = VERTEX;
}

void fragment() {
	// COLOR arrive déjà multiplié par le glyphe : on garde sa couverture, on change sa teinte.
	float t = (local.x + local.y * 0.35) / max(largeur, 1.0) * 0.8 - TIME * 0.3 + lumiere.x * 0.25;
	// un peu de blanc : lisible sur le verre sombre, sans perdre la couleur
	COLOR.rgb = mix(arc_en_ciel(fract(t)), vec3(1.0), 0.16);
}
