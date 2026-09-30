// L'illustration dans sa fenêtre : le recadrage (région de l'image), les
// filtres de la variante (sépia de l'or, clair-obscur de l'ombre), le holo
// du prismatique, et les coins arrondis.
shader_type canvas_item;

// La partie de l'image montrée : décalage et taille, en coordonnées 0..1.
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 taille = vec2(420.0, 363.0);
uniform float rayon = 7.8;

uniform float sepia = 0.0;
uniform float saturation = 1.0;
uniform float gris = 0.0;
uniform float luminosite = 1.0;
uniform float contraste = 1.0;
uniform float vignette = 0.0;

// Prismatique : une bande de spectre suit la lumière et s'allume sur ce qui
// est clair ; des paillettes changent de couleur. Dosé pour que le héros reste
// lisible (« trop coloré, on voit pas bien le personnage », 23/09).
uniform float holo = 0.0;
uniform vec2 lumiere = vec2(0.3, 0.28);
uniform float force = 0.55;
uniform sampler2D paillettes : filter_linear, repeat_enable;
uniform float paillettes_echelle = 3.2;

// Full art : un arc-en-ciel doux sur toute l'illustration, strié de fines raies,
// qui glisse avec la lumière (la maquette v2).
uniform float arc = 0.0;
uniform float pas_raies = 7.8;

vec3 arc_en_ciel(float t) {
	return clamp(abs(mod(t * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

vec3 esquive(vec3 base, vec3 s) {
	return min(base / max(vec3(1.0) - s, vec3(0.04)), vec3(1.0));
}

void fragment() {
	vec2 uv = region.xy + UV * region.zw;
	vec3 c = texture(TEXTURE, uv).rgb;

	if (sepia > 0.0) {
		vec3 s = vec3(dot(c, vec3(0.393, 0.769, 0.189)), dot(c, vec3(0.349, 0.686, 0.168)), dot(c, vec3(0.272, 0.534, 0.131)));
		c = mix(c, s, sepia);
	}
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(l), c, saturation);
	c = mix(c, vec3(dot(c, vec3(0.2126, 0.7152, 0.0722))), gris);
	c *= luminosite;
	c = (c - 0.5) * contraste + 0.5;
	if (vignette > 0.0) {
		vec2 q = (UV - vec2(0.5, 0.44)) * vec2(1.0, taille.y / taille.x);
		float v = smoothstep(0.2, 0.75, length(q));
		c = mix(c, vec3(0.03, 0.03, 0.035), vignette * v);
	}
	// l'ombre qui tombe au bas de la fenêtre
	c *= 1.0 - 0.32 * smoothstep(0.72, 1.0, UV.y);

	if (holo > 0.0) {
		vec2 axe = vec2(0.94, 0.34);
		float t = dot(UV, axe) * 2.2 + lumiere.x * 1.5 + lumiere.y;
		float bande = 1.0 - smoothstep(0.06, 0.2, abs(dot(UV - lumiere, axe)));
		vec3 s = arc_en_ciel(fract(t)) * (0.3 + force * 0.24);
		c = mix(c, esquive(c, s), holo * (0.12 + force * 0.5) * bande);
		float pl = texture(paillettes, UV * vec2(paillettes_echelle, paillettes_echelle * taille.y / taille.x)).r;
		c = mix(c, esquive(c, arc_en_ciel(fract(t + 0.5)) * pl), holo * (0.25 + force * 0.5));
	}

	if (arc > 0.0) {
		vec2 pa = UV * taille;
		vec2 axe = vec2(0.906, 0.423);
		float ta = dot(pa, axe) / (taille.x * 3.0) + lumiere.x * 0.5 + lumiere.y * 0.3;
		vec3 sa = arc_en_ciel(fract(ta)) * (0.45 + force * 0.25);
		float raie = step(0.75, fract(dot(pa, axe) / pas_raies)) * 0.08;
		c = mix(c, esquive(c, sa + vec3(raie)), arc * 0.22);
	}

	vec2 p = UV * taille;
	vec2 q2 = abs(p - taille * 0.5) - (taille * 0.5 - vec2(rayon));
	float d = length(max(q2, vec2(0.0))) + min(max(q2.x, q2.y), 0.0) - rayon;
	COLOR = vec4(clamp(c, 0.0, 1.0), clamp(0.5 - d, 0.0, 1.0));
}
