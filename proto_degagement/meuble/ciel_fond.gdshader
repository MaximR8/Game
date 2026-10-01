shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// LE CIEL SOUS L'ARCHE (01/10, prototype « Base céleste ») : un bleu nuit profond, une nébuleuse
// discrète, des étoiles NETTES qui scintillent (une croix fine et un cœur, pas de halo), deux
// constellations tracées d'un trait d'or fin (une seule teinte), une étoile filante de temps en temps.
// Le fond est découpé à la forme de l'arche (centre, rayon) : au-dessus de la naissance de l'arche,
// seulement ce qui est dans le cercle. Pendant la Supernova, le ciel se dore.

uniform vec2 centre_arche = vec2(5.4, 2.2);
uniform float rayon_arche = 5.1;
uniform vec2 coin_bas_gauche = vec2(0.0, 0.5);    // le rectangle couvert (x, y monde)
uniform vec2 coin_haut_droit = vec2(10.8, 7.4);
uniform sampler2D etoiles : filter_linear_mipmap, repeat_enable;
uniform float supernova = 0.0;
uniform float t_supernova = 0.0;

varying vec3 v_monde;

void vertex() {
	v_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(17.3, 51.9)));
}

float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		s += a * bruit(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

// une étoile nette : un cœur fin et une croix à quatre branches très fines
float etoile_nette(vec2 d, float taille) {
	float r = length(d);
	float coeur = exp(-r * r / (taille * taille * 0.10));
	float bras = exp(-abs(d.x) / (taille * 0.035)) * exp(-abs(d.y) / (taille * 0.55))
		+ exp(-abs(d.y) / (taille * 0.035)) * exp(-abs(d.x) / (taille * 0.55));
	return coeur + 0.55 * bras;
}

float segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 p = v_monde.xy;
	// la forme de l'arche
	if (p.y > centre_arche.y && distance(p, centre_arche) > rayon_arche) {
		discard;
	}
	vec2 uv = (p - coin_bas_gauche) / (coin_haut_droit - coin_bas_gauche);
	// le bleu nuit : plus profond en haut, un peu plus clair derrière l'astrolabe
	vec3 col = mix(vec3(0.020, 0.040, 0.115), vec3(0.012, 0.022, 0.070), uv.y);
	float centre = exp(-pow(distance(p, vec2(centre_arche.x, centre_arche.y + 2.2)) / 3.2, 2.0));
	col += vec3(0.030, 0.060, 0.150) * centre;
	// la nébuleuse, discrète : un voile bleu, un peu de violet, un fil turquoise
	float n1 = fbm(p * 0.42 + vec2(TIME * 0.006, 0.0));
	float n2 = fbm(p * 0.75 + vec2(3.1, -TIME * 0.004));
	col += vec3(0.05, 0.08, 0.22) * smoothstep(0.42, 0.85, n1) * 0.9;
	col += vec3(0.10, 0.05, 0.18) * smoothstep(0.55, 0.92, n2) * 0.6;
	col += vec3(0.02, 0.10, 0.12) * smoothstep(0.62, 0.95, fbm(p * 1.1 + 7.7)) * 0.5;
	// la poussière d'étoiles (l'image du jeu), fine
	vec4 te = texture(etoiles, p * 0.16);
	col += te.rgb * te.a * 0.9;
	// les étoiles nettes, qui scintillent
	vec2 g = p * 1.25;
	vec2 cel = floor(g);
	for (int dx = -1; dx <= 1; dx++) {
		for (int dy = -1; dy <= 1; dy++) {
			vec2 c = cel + vec2(float(dx), float(dy));
			vec2 h = hash2(c);
			if (h.x > 0.62) {
				vec2 pos = c + 0.15 + 0.7 * hash2(c + 3.3);
				float taille = 0.10 + 0.22 * pow(hash(c + 9.1), 3.0);
				float sc = 0.55 + 0.45 * sin(TIME * (1.2 + 2.5 * h.y) + h.x * 40.0);
				float v = etoile_nette((g - pos) / 1.25, taille) * sc;
				col += vec3(0.85, 0.90, 1.0) * v * 0.85;
			}
		}
	}
	// deux constellations, d'un trait d'or fin (une seule teinte, peu de traits)
	vec2 cst[5] = vec2[5](vec2(1.6, 5.6), vec2(2.5, 6.3), vec2(3.4, 6.05), vec2(3.0, 5.1), vec2(1.9, 4.6));
	vec2 cst2[4] = vec2[4](vec2(7.6, 6.2), vec2(8.6, 5.7), vec2(9.2, 4.8), vec2(8.3, 4.2));
	float d_trait = 99.0;
	for (int i = 0; i < 4; i++) {
		d_trait = min(d_trait, segment(p, cst[i], cst[i + 1]));
	}
	for (int i = 0; i < 3; i++) {
		d_trait = min(d_trait, segment(p, cst2[i], cst2[i + 1]));
	}
	float trait = 1.0 - smoothstep(0.008, 0.022, d_trait);
	col = mix(col, vec3(0.86, 0.70, 0.40), trait * 0.55);
	for (int i = 0; i < 5; i++) {
		col += vec3(1.0, 0.92, 0.72) * etoile_nette(p - cst[i], 0.16) * 0.9;
	}
	for (int i = 0; i < 4; i++) {
		col += vec3(1.0, 0.92, 0.72) * etoile_nette(p - cst2[i], 0.16) * 0.9;
	}
	// une étoile filante, toutes les 9 secondes
	float cycle = mod(TIME, 9.0);
	if (cycle < 0.9) {
		float k = cycle / 0.9;
		vec2 a = vec2(8.8, 7.0) + vec2(-4.2, -1.6) * k;
		vec2 dir = normalize(vec2(-4.2, -1.6));
		vec2 q = p - a;
		float le_long = dot(q, -dir);
		float travers = abs(dot(q, vec2(-dir.y, dir.x)));
		float queue = step(0.0, le_long) * exp(-le_long / 0.9) * exp(-travers / 0.012);
		col += vec3(1.0, 0.95, 0.85) * queue * sin(k * 3.1416) * 1.2;
	}
	// la Supernova : le ciel se dore, puis revient
	if (supernova > 0.0) {
		float onde = exp(-pow((distance(p, vec2(centre_arche.x, centre_arche.y + 2.2)) - t_supernova * 6.0) / 0.5, 2.0));
		col = mix(col, col * vec3(1.6, 1.25, 0.7) + vec3(0.10, 0.06, 0.0), supernova * 0.6);
		col += vec3(1.0, 0.85, 0.5) * onde * supernova * 0.6;
		// des rayons d'or NETS (pas de halo) : seize faisceaux fins qui tournent, d'autres en sens contraire
		vec2 d = p - vec2(centre_arche.x, centre_arche.y + 2.35);
		float ang = atan(d.y, d.x);
		float rr = length(d);
		float ray = pow(abs(cos(ang * 8.0 + t_supernova * 0.7)), 70.0)
			+ 0.6 * pow(abs(cos(ang * 8.0 + 0.196 - t_supernova * 0.45)), 110.0);
		float masque = smoothstep(2.5, 2.9, rr) * exp(-(rr - 2.7) / 3.5);
		col += vec3(1.0, 0.84, 0.50) * ray * masque * supernova * 0.75;
	}
	ALBEDO = clamp(col, vec3(0.0), vec3(1.0));
}
