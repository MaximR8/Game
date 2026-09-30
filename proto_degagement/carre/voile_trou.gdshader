shader_type canvas_item;

// Le voile du guide (le Carré, 27/09) : tout l'écran s'assombrit, sauf un rectangle aux coins
// arrondis — ce qu'il faut toucher — cerné d'un filet d'or net.
uniform vec2 taille = vec2(1080.0, 2400.0);
uniform vec4 trou = vec4(0.0, 0.0, 0.0, 0.0);   // x, y, largeur, hauteur (px) ; largeur 0 : pas de trou
uniform float rayon = 26.0;
uniform float noir = 0.62;

void fragment() {
	vec2 p = UV * taille;
	float d = 1e4;
	if (trou.z > 0.0) {
		vec2 c = trou.xy + trou.zw * 0.5;
		vec2 q = abs(p - c) - (trou.zw * 0.5 - vec2(rayon));
		d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rayon;
	}
	float voile = noir * smoothstep(-1.0, 1.0, d);
	float filet = (1.0 - smoothstep(1.5, 3.0, abs(d - 4.0))) * step(-1.0, d) * (trou.z > 0.0 ? 1.0 : 0.0);
	vec3 or_vif = vec3(0.945, 0.824, 0.541);
	COLOR = vec4(mix(vec3(0.0), or_vif, filet), max(voile, filet * 0.95));
}
