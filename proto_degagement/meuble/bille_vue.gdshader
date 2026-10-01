shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back;

// LES BILLES, VUES EN PERSPECTIVE (01/10, prototype « Base céleste ») : le modèle d'objets/bille.gdshader
// (le voile qui tourne comme une planète, l'objet qui flotte au centre, le verre), mais sur une vraie
// sphère vue par une caméra : la normale de la vue donne directement le point de la boule qu'on regarde.

uniform sampler2D voile : filter_linear_mipmap, repeat_enable;
uniform sampler2D coeur : filter_linear_mipmap, repeat_disable;
uniform vec3 teinte = vec3(0.80, 0.70, 1.0);
uniform float taille_coeur = 0.62;
uniform float tourne = 0.025;
uniform float k_h = 0.0;
uniform float fondu_objet = 0.0;
uniform float rayon = 0.5;
uniform float aplati = 1.0;
uniform float echelle = 0.9;

const vec3 L_CLE = vec3(-0.4545, -0.6126, 0.6324);
const vec3 L_CONTRE = vec3(0.6353, 0.4303, 0.6763);
const vec3 VUE = vec3(0.0, 0.0, 1.0);

float lisse(float e0, float e1, float x) {
	float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}

float environnement(vec3 R) {
	float haut = -R.y;
	float base = 0.05 + 0.80 * lisse(-0.25, 0.95, haut);
	float horizon = 0.12 * exp(-pow((haut - 0.08) / 0.16, 2.0));
	float boite = pow(clamp(dot(R, L_CLE), 0.0, 1.0), 14.0) * 1.3;
	float contre = pow(clamp(dot(R, L_CONTRE), 0.0, 1.0), 7.0) * 0.55;
	float sol = 0.06 * lisse(0.1, -0.9, haut);
	return max(base - horizon + boite + contre - sol, 0.0);
}

vec3 tonalite(vec3 c) {
	c = max(c, vec3(0.0));
	c = (1.0 - exp(-c * 1.55)) / (1.0 - exp(-1.55));
	return pow(clamp(c, 0.0, 1.0), vec3(1.0 / 1.08));
}

float hachage(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	if (fondu_objet > 0.0 && hachage(FRAGCOORD.xy) < fondu_objet) {
		discard;
	}
	vec3 nvue = normalize(NORMAL);
	// l'écran vers le bas, comme le dessin d'avant (l'image du cœur est rendue ainsi)
	vec2 p = vec2(nvue.x, -nvue.y);
	float r2 = min(dot(p, p), 0.999);
	vec3 nv = vec3(p.x, p.y, sqrt(1.0 - r2));
	float lon = atan(nv.x, max(nv.z, 1e-4));
	float lat = asin(clamp(nv.y, -1.0, 1.0));
	vec3 c_voile = texture(voile, vec2(0.5 + lon / TAU + TIME * tourne, 0.5 + lat / PI)).rgb;
	vec3 L = normalize(vec3(-0.45, -0.55, 0.70));
	float lum = 0.40 + 0.60 * clamp(dot(nv, L), 0.0, 1.0);
	float bord = 0.45 + 0.55 * pow(clamp(nv.z, 0.0, 1.0), 0.6);
	vec3 col = c_voile * lum * bord;
	vec2 dl = -normalize(L.xy);
	float rxy = length(nv.xy);
	float caust = lisse(0.35, 0.95, dot(nv.xy, dl)) * lisse(0.2, 0.7, rxy) * (1.0 - lisse(0.85, 1.0, rxy));
	col += teinte * caust * 0.35;
	vec4 c_coeur = texture(coeur, vec2(0.5) + 0.5 * p / taille_coeur);
	float a_c = c_coeur.a * 0.95 * (1.0 - step(taille_coeur, max(abs(p.x), abs(p.y))));
	col = mix(col, c_coeur.rgb * (0.85 + 0.15 * lum), a_c);
	float fres = 0.04 + 0.96 * pow(1.0 - clamp(nv.z, 0.0, 1.0), 4.0);
	vec3 R = 2.0 * nv.z * nv - VUE;
	float e = environnement(R);
	col = col * (1.0 - 0.5 * fres) + teinte * e * fres * 0.6;
	float point = lisse(0.9960, 0.9985, dot(nv, normalize(L_CLE + VUE))) * 1.2;
	vec2 vers = vec2(-0.63, -0.77);
	float cos_tl = dot(nv.xy, vers) / max(rxy, 1e-4);
	float arc = lisse(0.62, 0.70, rxy) * (1.0 - lisse(0.82, 0.88, rxy)) * lisse(0.55, 0.85, cos_tl) * 0.6;
	float contre = lisse(0.9975, 0.999, dot(nv, normalize(L_CONTRE + VUE))) * 0.3;
	col += vec3(point + arc + contre);
	ALBEDO = tonalite(col);
}
