shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

// UNE ÉTOILE NETTE (01/10, prototype « Base céleste ») : le cœur des sphères armillaires, l'éclat au centre
// de l'astrolabe. Toujours face à l'œil ; un cœur fin et une croix à quatre branches très fines — pas de
// halo (les goûts de Maxim : « des étoiles nettes qui scintillent »).

uniform vec3 couleur = vec3(1.0, 0.93, 0.74);
uniform float force = 1.0;

void vertex() {
	mat4 face = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	face = face * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * face;
}

void fragment() {
	vec2 d = (UV - 0.5) * 2.0;
	float r = length(d);
	float coeur = exp(-r * r / 0.004);
	float bras = exp(-abs(d.x) / 0.018) * exp(-abs(d.y) / 0.42) + exp(-abs(d.y) / 0.018) * exp(-abs(d.x) / 0.42);
	float diag = exp(-abs(d.x - d.y) / 0.015) * exp(-r / 0.16) + exp(-abs(d.x + d.y) / 0.015) * exp(-r / 0.16);
	float v = (coeur * 1.4 + 0.75 * bras + 0.35 * diag) * force;
	ALBEDO = couleur * clamp(v, 0.0, 1.6);
	// l'alpha suit l'étoile : autour, la vue reste transparente (le ciel du jeu se voit)
	ALPHA = clamp(v, 0.0, 1.0);
}
