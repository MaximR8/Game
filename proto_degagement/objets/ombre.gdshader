shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

// L'ombre d'une pièce ou d'un objet de la poussette : un disque doux posé juste sous
// lui, décalé vers la droite et le bas. Il assombrit ce qui est dessous (les pièces du
// dessous, le plateau), jamais ce qui est au-dessus. Même projection que corps.gdshader.

uniform float k_h = 0.9;
uniform float force_objet = -1.0;     // un objet (hors MultiMesh) : sa force d'ombre
varying float v_force;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_force = force_objet >= 0.0 ? force_objet : INSTANCE_CUSTOM.b;
	vec3 s = vec3(w.x, w.y + k_h * w.z, w.z - k_h * w.y);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(s, 1.0);
}

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	ALBEDO = vec3(0.0);
	ALPHA = (1.0 - smoothstep(0.3, 1.0, d)) * v_force;
}
