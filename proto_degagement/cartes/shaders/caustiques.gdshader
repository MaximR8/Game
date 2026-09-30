// EAU — les reflets des vagues sur l'illustration (caustiques calculées).
shader_type canvas_item;
render_mode blend_add;

uniform vec2 taille = vec2(420.0, 330.0);
uniform float rayon = 7.8;
uniform float force = 0.4;

void fragment() {
	float t = TIME * 0.5 + 23.0;
	vec2 p = UV * vec2(1.0, taille.y / taille.x) * 6.9115 - 250.0;
	vec2 i = p;
	float c = 1.0;
	float inten = 0.005;
	for (int n = 0; n < 4; n++) {
		float tt = t * (1.0 - (3.5 / float(n + 1)));
		i = p + vec2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
		c += 1.0 / length(vec2(p.x / (sin(i.x + tt) / inten), p.y / (cos(i.y + tt) / inten)));
	}
	c = 1.17 - pow(c / 4.0, 1.4);
	float v = clamp((pow(abs(c), 8.0) - 0.1) * 3.5, 0.0, 1.0);
	vec2 q = abs(UV * taille - taille * 0.5) - (taille * 0.5 - vec2(rayon));
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - rayon;
	COLOR = vec4(vec3(0.686, 0.941, 1.0), v * force * clamp(0.5 - d, 0.0, 1.0));
}
