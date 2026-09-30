// NATURE — deux rais de soleil qui tombent en biais et oscillent doucement.
// Ils restent dans la carte : un faisceau qui en sort fait tache (22/09).
shader_type canvas_item;
render_mode blend_add;

uniform vec2 taille = vec2(486.0, 680.4);
uniform float rayon = 22.0;

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

float rai(vec2 p, float x0, float largeur, float a) {
	// un rai part du haut en x0 et descend vers la droite
	vec2 dir = normalize(vec2(0.42, 1.0));
	vec2 nrm = vec2(dir.y, -dir.x);
	float ecart = dot(p - vec2(x0, 0.0), nrm);
	float bord = 1.0 - smoothstep(largeur * 0.3, largeur, abs(ecart));
	return a * bord * (1.0 - clamp(p.y / taille.y, 0.0, 1.0));
}

void fragment() {
	vec2 p = UV * taille;
	float d = sd_rect(p - taille * 0.5, taille * 0.5, rayon);
	float t = TIME;
	float a = rai(p, taille.x * (0.18 + sin(t * 0.25) * 0.03), taille.x * 0.10, 0.13)
		+ rai(p, taille.x * (0.46 + sin(t * 0.25 + 2.0) * 0.03), taille.x * 0.08, 0.09);
	COLOR = vec4(vec3(0.882, 0.961, 0.745), a * clamp(0.5 - d, 0.0, 1.0));
}
