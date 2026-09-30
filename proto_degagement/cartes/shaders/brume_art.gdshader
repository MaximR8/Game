// ESPRIT — une brume fantôme qui dérive dans le bas de l'illustration.
shader_type canvas_item;
render_mode blend_add;

uniform vec2 taille = vec2(420.0, 330.0);
uniform float rayon = 7.8;

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

void fragment() {
	vec2 p = UV * taille;
	float t = TIME;
	vec2 q = p / (taille.x * 0.22) + vec2(t * 0.06, 0.0);
	float n = 0.55 * bruit(q) + 0.3 * bruit(q * 2.1 + vec2(-t * 0.05, 3.1)) + 0.15 * bruit(q * 4.3);
	float a = smoothstep(0.45, 0.85, n) * smoothstep(0.35, 1.0, UV.y) * 0.32;
	vec2 r = abs(p - taille * 0.5) - (taille * 0.5 - vec2(rayon));
	float d = length(max(r, vec2(0.0))) + min(max(r.x, r.y), 0.0) - rayon;
	COLOR = vec4(vec3(0.745, 0.675, 0.933), a * clamp(0.5 - d, 0.0, 1.0));
}
