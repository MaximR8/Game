// Le bord du full art : un arc-en-ciel qui tourne tout autour de la carte,
// dans une bande fine, par-dessus l'illustration (la maquette v2).
shader_type canvas_item;
render_mode blend_add;

uniform vec2 taille = vec2(486.0, 680.4);
uniform float rayon = 22.0;
uniform float largeur = 11.7;
uniform float force = 0.5;

vec3 arc_en_ciel(float t) {
	return clamp(abs(mod(t * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

float sd_rect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * taille;
	vec2 c = taille * 0.5;
	float d = sd_rect(p - c, c, rayon);
	// dans la bande : du bord jusqu'à « largeur » vers l'intérieur, adoucie
	float bande = (1.0 - smoothstep(-1.0, 0.5, d)) * smoothstep(-largeur - 2.0, -largeur, d);
	float ang = atan(p.y - c.y, p.x - c.x) / 6.2831853 + TIME * 0.2;
	COLOR = vec4(arc_en_ciel(fract(ang)), bande * force);
}
