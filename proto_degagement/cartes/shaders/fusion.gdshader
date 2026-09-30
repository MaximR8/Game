// FEU — le métal du cadre en fusion : des veines incandescentes qui coulent vers
// le haut, et l'embrasement, une vague de chaleur qui remonte la carte.
// Posé SOUS le contenu de la carte : seule la bande du cadre le montre.
shader_type canvas_item;

uniform vec2 taille = vec2(486.0, 680.4);
uniform float rayon = 22.0;
uniform float echelle = 1.389;   // largeur / 350 : le motif est le même à toutes les tailles
uniform float vague = -1.0;      // 0..1 pendant l'embrasement, -1 sinon

float sd_rect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Un hachage sans sinus : stable en précision moyenne, sur tous les GPU mobiles.
float hache(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hache(i);
	float b = hache(i + vec2(1.0, 0.0));
	float c = hache(i + vec2(0.0, 1.0));
	float d = hache(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// chaleur -> couleur : métal noirci, braise, rouge, orange, jaune, blanc chaud
vec4 palette(float h) {
	vec4 a = vec4(0.102, 0.027, 0.012, 0.40);
	vec4 b = vec4(0.353, 0.071, 0.024, 0.55);
	vec4 c = vec4(0.784, 0.216, 0.047, 0.72);
	vec4 d = vec4(0.980, 0.471, 0.118, 0.90);
	vec4 e = vec4(1.000, 0.769, 0.353, 1.00);
	vec4 f = vec4(1.000, 0.965, 0.839, 1.00);
	if (h < 0.3) return mix(a, b, h / 0.3);
	if (h < 0.5) return mix(b, c, (h - 0.3) / 0.2);
	if (h < 0.68) return mix(c, d, (h - 0.5) / 0.18);
	if (h < 0.84) return mix(d, e, (h - 0.68) / 0.16);
	return mix(e, f, (h - 0.84) / 0.16);
}

void fragment() {
	vec2 p = UV * taille;
	float d = sd_rect(p - taille * 0.5, taille * 0.5, rayon);
	vec2 q = p / echelle;
	float t = TIME;
	// une veine = là où le bruit croise 0,5 : des lignes fines qui coulent vers le haut
	float n1 = bruit(vec2(q.x * 0.05, q.y * 0.035 + t * 0.6));
	float n2 = bruit(vec2(q.x * 0.12 + 17.3, q.y * 0.09 + t * 1.4));
	float v1 = max(0.0, 1.0 - abs(2.0 * n1 - 1.0) * 4.5);
	float v2 = max(0.0, 1.0 - abs(2.0 * n2 - 1.0) * 5.5);
	float h = 0.14 + 0.16 * bruit(vec2(q.x * 0.012 + 3.7, q.y * 0.012 + t * 0.25)) + v1 * v1 * 0.85 + v2 * v2 * 0.42;
	h *= 0.86 + 0.14 * sin(t * 2.1 + (q.x + q.y) * 0.015);
	if (vague >= 0.0) {
		float e = (p.y - taille.y * (1.15 - vague * 1.3)) / (taille.y * 0.1);
		h += exp(-e * e) * 0.5;
	}
	vec4 c = palette(clamp(h, 0.0, 1.0));
	c.a *= clamp(0.5 - d, 0.0, 1.0);
	COLOR = c;
}
