// La lumière qui passe sur la carte, par-dessus tout : un éclat doux sous la
// lumière, et pour l'or un reflet qui balaie la carte en boucle.
shader_type canvas_item;
render_mode blend_add;

uniform vec2 taille = vec2(486.0, 680.4);
uniform float rayon = 22.0;
uniform vec2 lumiere = vec2(0.3, 0.28);
uniform float eclat = 0.06;
uniform vec4 balayage : source_color = vec4(1.0, 0.95, 0.8, 0.0);
uniform float periode = 4.4;

float sd_rect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * taille;
	float dedans = clamp(0.5 - sd_rect(p - taille * 0.5, taille * 0.5, rayon), 0.0, 1.0);
	vec2 q = (UV - lumiere) * vec2(1.0, taille.y / taille.x);
	float a = eclat * (1.0 - smoothstep(0.0, 0.55, length(q)));
	vec3 rgb = vec3(1.0) * a;
	if (balayage.a > 0.0) {
		float ph = fract(TIME / periode);
		ph = ph * ph * (3.0 - 2.0 * ph);
		// la bande avance le long de 105°, d'un bord à l'autre
		vec2 dir = vec2(0.966, 0.259);
		float s = dot(p, dir) / (taille.x * dir.x + taille.y * dir.y);
		float centre = mix(-0.35, 1.35, ph);
		float b = max(0.0, 1.0 - abs(s - centre) / 0.12);
		rgb += balayage.rgb * balayage.a * b * b;
	}
	COLOR = vec4(rgb, dedans);
}
