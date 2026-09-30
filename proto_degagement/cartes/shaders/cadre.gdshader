// Le cadre d'une carte : la matière de la variante (un dégradé), la gravure
// croisée qui attrape la lumière, l'ombre portée et la lueur autour.
// Le nœud déborde de la carte de « marge » de chaque côté : c'est là que
// l'ombre et la lueur se dessinent.
shader_type canvas_item;

uniform vec2 taille = vec2(486.0, 680.4);
uniform float marge = 40.0;
uniform float rayon = 22.0;

// La matière : un dégradé le long d'un angle (0° = vers le haut, comme en CSS),
// ou un dégradé radial depuis le haut (ombre).
uniform sampler2D degrade : source_color, filter_linear, repeat_disable;
uniform float angle_deg = 160.0;
uniform bool radial = false;
uniform float echelle = 1.0;
uniform vec2 centre_degrade = vec2(243.0, 340.2);

uniform vec4 gravure_col : source_color = vec4(0.77, 0.63, 0.38, 0.10);
uniform float gravure_pas = 5.35;
uniform float gravure_trait = 1.36;

uniform vec4 lueur_col : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float lueur_taille = 24.0;
uniform float ombre_alpha = 0.55;
uniform float ombre_dy = 14.6;
uniform float ombre_flou = 34.0;

// Prismatique : le spectre teinte le chrome, et glisse avec la lumière.
uniform float spectre = 0.0;
uniform vec2 lumiere = vec2(0.3, 0.28);
// Ombre : une brume immobile aux coins, couleur fumée.
uniform float brume = 0.0;
uniform vec3 brume_col : source_color = vec3(0.72, 0.74, 0.78);

float sd_rect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

vec3 arc_en_ciel(float t) {
	return clamp(abs(mod(t * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

float lum(vec3 c) {
	return dot(c, vec3(0.3, 0.59, 0.11));
}

// Le mode « color » : garde la lumière l, prend la teinte et la saturation de c.
vec3 teinte_sur(vec3 c, float l) {
	c += l - lum(c);
	float L = lum(c);
	float n = min(min(c.r, c.g), c.b);
	float x = max(max(c.r, c.g), c.b);
	if (n < 0.0) c = L + (c - L) * L / max(L - n, 1e-4);
	if (x > 1.0) c = L + (c - L) * (1.0 - L) / max(x - L, 1e-4);
	return c;
}

float tache(vec2 uv, vec2 c, vec2 r) {
	return 1.0 - smoothstep(0.0, 0.7, length((uv - c) / r));
}

void fragment() {
	vec2 p = UV * (taille + 2.0 * marge) - marge;
	vec2 c = taille * 0.5;
	float d = sd_rect(p - c, c, rayon);

	// Dehors : l'ombre portée, puis la lueur par-dessus.
	float ds = sd_rect(p - c - vec2(0.0, ombre_dy), c, rayon);
	float a_ombre = ombre_alpha * (1.0 - smoothstep(-ombre_flou * 0.25, ombre_flou, ds));
	float a_lueur = lueur_col.a * (1.0 - smoothstep(0.0, lueur_taille, max(d, 0.0)));
	float a_dehors = a_lueur + a_ombre * (1.0 - a_lueur);
	vec3 rgb_dehors = lueur_col.rgb * a_lueur / max(a_dehors, 1e-4);

	// Dedans : la matière.
	float t;
	if (radial) {
		t = length((p - vec2(c.x, 0.0)) / (taille * vec2(1.2, 0.9)));
	} else {
		float a = radians(angle_deg);
		vec2 dir = vec2(sin(a), -cos(a));
		float L = abs(taille.x * sin(a)) + abs(taille.y * cos(a));
		t = dot(p - centre_degrade, dir) / (L * echelle) + 0.5;
	}
	vec3 col = texture(degrade, vec2(clamp(t, 0.0, 1.0), 0.5)).rgb;

	// La gravure : deux trames à 45°, qui se croisent.
	float s1 = fract(dot(p, vec2(0.7071, -0.7071)) / gravure_pas);
	float s2 = fract(dot(p, vec2(-0.7071, -0.7071)) / gravure_pas);
	float k = gravure_trait / gravure_pas;
	float g = max(step(s1, k), step(s2, k));
	col = mix(col, gravure_col.rgb, gravure_col.a * g);

	if (spectre > 0.0) {
		float ts = dot(p / taille, vec2(0.57, 0.82)) * 2.6 + lumiere.x * 1.4 + lumiere.y * 0.9;
		col = mix(col, teinte_sur(arc_en_ciel(fract(ts)), lum(col)), spectre);
	}
	if (brume > 0.0) {
		vec2 uv = p / taille;
		float h = 0.38 * tache(uv, vec2(0.0, 0.0), vec2(0.42, 0.30))
			+ 0.32 * tache(uv, vec2(1.0, 1.0), vec2(0.42, 0.30))
			+ 0.22 * tache(uv, vec2(1.0, 0.22), vec2(0.36, 0.24))
			+ 0.26 * tache(uv, vec2(0.0, 0.76), vec2(0.36, 0.24));
		col = 1.0 - (1.0 - col) * (1.0 - brume * h * brume_col);
	}

	float couvre = clamp(0.5 - d, 0.0, 1.0);
	COLOR = mix(vec4(rgb_dehors, a_dehors), vec4(col, 1.0), couvre);
}
