shader_type canvas_item;

// LE BLANC QUI S'ÉVAPORE EN POUSSIÈRE D'OR (FEATURES ⑮, 26/09 — Maxim : « le blanc qui cache,
// ça serait bien de le faire disparaître comme s'il s'évaporait en poussière d'or, et la carte se
// dévoile comme ça »). Le blanc couvre la carte ; ce qui est sous le front « t » est parti ; un
// liseré d'or marque le front. Les seuils (seuils) sont calculés par evolution.gd — qui sait donc
// où le front passe, et y fait naître la poussière d'or.

uniform sampler2D seuils : filter_linear, repeat_disable;
uniform float t = -1.0;
uniform vec2 taille = vec2(720.0, 1008.0);
uniform float rayon = 32.0;
uniform float filet = 9.0;

const vec3 BLANC = vec3(1.0, 0.992, 0.965);
const vec3 OR_VIF = vec3(0.945, 0.824, 0.541);
const vec3 FILET = vec3(0.89, 0.769, 0.494);
const float BANDE = 0.03;

void fragment() {
	vec2 p = UV * taille;
	vec2 q = abs(p - taille * 0.5) - (taille * 0.5 - vec2(rayon));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rayon;
	if (d > 0.0) {
		discard;
	}
	float s = texture(seuils, UV).r;
	if (s < t) {
		discard;
	}
	vec3 c = s < t + BANDE ? OR_VIF : (d > -filet ? FILET : BLANC);
	COLOR = vec4(c, COLOR.a);
}
