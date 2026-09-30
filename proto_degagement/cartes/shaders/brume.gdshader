// OMBRE — une brume couleur fumée qui dérive tout autour du cadre, par volutes
// pâles et sombres mêlées, et qui déborde un peu de la carte. Par-dessus tout.
// Allégée le 23/09 (« l'effet de l'ombre est trop fort ») : moins de volutes,
// moins opaques, et elle mord moins sur la carte.
shader_type canvas_item;

uniform vec2 taille = vec2(486.0, 680.4);
uniform float marge = 38.9;
uniform float rayon = 22.0;
uniform float bande = 18.5;
uniform float houle = 0.0;       // 0..1 : la brume s'épaissit par vagues

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

float fbm3(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * bruit(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v / 0.875;
}

void fragment() {
	vec2 p = UV * (taille + 2.0 * marge) - marge;
	vec2 c = taille * 0.5;
	float d = sd_rect(p - c, c, rayon);
	float w = taille.x;
	// l'anneau : plein sur la bande, qui s'efface vers le centre et vers l'extérieur
	float masque = d < 0.0 ? smoothstep(-(bande + 0.06 * w), -bande + 0.01 * w, d) : 1.0 - smoothstep(0.0, marge, d);
	if (masque <= 0.001) {
		discard;
	}
	vec2 q = p / (w * 0.16);
	float t = TIME;
	vec2 derive = vec2(t * 0.05, -t * 0.035);
	vec2 tord = vec2(bruit(q * 0.8 + derive), bruit(q * 0.8 - derive + 5.2));
	float n = fbm3(q + tord * 1.4 + derive);
	float pale = smoothstep(0.5, 0.84, n) * (0.75 + 0.35 * houle);
	float sombre = smoothstep(0.66, 0.92, 1.0 - n) * 0.4;
	float total = clamp(pale + sombre, 0.0, 1.0);
	vec3 col = mix(vec3(0.05, 0.05, 0.06), vec3(0.8, 0.82, 0.86), pale / max(pale + sombre, 0.001));
	COLOR = vec4(col, total * masque * 0.6);
}
