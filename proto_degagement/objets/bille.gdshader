shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back;

// LES BILLES DE VERRE (26/09 — Maxim : « l'XP comme l'étoile d'invocation, on dirait des boîtes à
// médicaments ; il faut en faire des sphères, transparentes, avec la poussière d'étoile dedans, et
// l'étoile d'invocation »). La poussière d'étoile et l'étoile d'invocation, dans la machine : une vraie
// sphère (un peu aplatie), éclairée en direct ; son intérieur — rendu d'avance, vu d'en haut, par
// design/objets/render_objets.py — se voit à travers le verre ; son bord laisse voir les pièces
// derrière. Même projection oblique que les pièces (corps.gdshader).
// 🔴 Revu le 26/09 (Maxim : « l'objet doit être plein centre ; je ne veux pas d'une bille blanche ; le
//    voile mauve avec les étoiles sur toute la surface ») : la bille est pleine (plus de bord clair) ;
//    son image est plaquée DANS L'AXE DE LA CAMÉRA (la vue est oblique : plaquée d'en haut, l'objet
//    remontait vers le haut de la bille) ; le reflet du ciel est teinté de mauve et discret.

// 🔴 Revu encore le 26/09 (Maxim : « ça fait une image ronde plutôt qu'une vraie bille en 3D » ; « la bille
//    de poussière, pas mauve, on va confondre ») : deux couches. Le VOILE (la nébuleuse ; bleu nuit pour
//    la poussière) est enroulé sur la sphère — lu par la normale, il se serre vers le bord — et tourne
//    lentement ; l'OBJET (l'étoile d'or, la poussière d'or) flotte au centre, grossi par le verre. Puis le
//    volume : l'ombre du côté opposé à la lumière, le bord plus sombre, la lumière qui ressort de l'autre
//    côté (teintée), un Fresnel teinté ; et le reflet de la fenêtre, un point vif et un arc le long du bord.
//    Le même modèle que l'icône (render_objets.py, bille_univers).
uniform sampler2D voile : filter_linear_mipmap, repeat_enable;
uniform sampler2D coeur : filter_linear_mipmap, repeat_disable;
uniform vec3 teinte = vec3(0.80, 0.70, 1.0);
uniform float taille_coeur = 0.62;
uniform float tourne = 0.025;       // la rotation du voile (tours de carte par seconde)
uniform float k_h = 0.9;
uniform float fondu_objet = 0.0;
uniform float rayon = 0.5;          // le rayon de la bille (unités)
uniform float aplati = 0.42;        // sa hauteur, en part de son diamètre
uniform float echelle = 0.9;        // le rayon de la bille dans l'image rendue

varying vec3 v_n;
varying vec3 v_loc;
varying vec3 v_rel;
varying vec3 v_ax;
varying vec3 v_ay;
varying vec3 v_az;

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

// l'or de l'étoile, au cœur (le modèle métal des pièces)
vec3 metal(vec3 n, vec3 alb, float ao) {
	vec3 R = 2.0 * n.z * n - VUE;
	float e = environnement(R);
	float diff = clamp(dot(n, L_CLE), 0.0, 1.0);
	float spec = pow(clamp(dot(n, normalize(L_CLE + VUE)), 0.0, 1.0), 80.0);
	return (alb * (0.08 + 0.30 * diff + 0.95 * e) + spec * 0.9 * vec3(1.0, 0.96, 0.84)) * ao;
}

float hachage(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_n = mat3(MODEL_MATRIX) * NORMAL;
	v_loc = VERTEX / rayon;
	v_rel = w - MODEL_MATRIX[3].xyz;
	v_ax = MODEL_MATRIX[0].xyz;
	v_ay = MODEL_MATRIX[1].xyz;
	v_az = MODEL_MATRIX[2].xyz;
	vec3 s = vec3(w.x, w.y + k_h * w.z, w.z - k_h * w.y);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(s, 1.0);
}

void fragment() {
	if (fondu_objet > 0.0 && hachage(FRAGCOORD.xy) < fondu_objet) {
		discard;
	}
	// 🔴 La sphère TELLE QU'ON LA VOIT (26/09 — Maxim : « ça fait encore un peu effet image plate ») :
	//    la vue est oblique, une vraie boule s'y affiche en œuf ; la bille est donc un ellipsoïde aplati
	//    dont le contour, à l'écran, est presque rond, et sa normale est calculée À L'ÉCRAN, comme celle
	//    d'une sphère parfaite : l'éclairage est celui d'une boule, quelle que soit la forme dessinée.
	float ry = rayon * aplati;
	float rs = sqrt(rayon * rayon + k_h * k_h * ry * ry);
	vec2 p = vec2(v_rel.x / rayon, (v_rel.z - k_h * v_rel.y) / rs);
	float r2 = dot(p, p);
	if (r2 > 1.0) {
		discard;
	}
	vec3 nv = vec3(p.x, p.y, sqrt(1.0 - r2));
	// 1. le voile, enroulé comme une planète (longitude, latitude), qui tourne lentement : il passe
	//    derrière le bord pendant que l'objet reste au centre — c'est ce qui fait la profondeur
	float lon = atan(nv.x, max(nv.z, 1e-4));
	float lat = asin(clamp(nv.y, -1.0, 1.0));
	vec3 c_voile = texture(voile, vec2(0.5 + lon / TAU + TIME * tourne, 0.5 + lat / PI)).rgb;
	// 2. le volume : le côté de la lumière, le côté de l'ombre, le bord plus sombre
	vec3 L = normalize(vec3(-0.45, -0.55, 0.70));
	float lum = 0.40 + 0.60 * clamp(dot(nv, L), 0.0, 1.0);
	float bord = 0.45 + 0.55 * pow(clamp(nv.z, 0.0, 1.0), 0.6);
	vec3 col = c_voile * lum * bord;
	vec2 dl = -normalize(L.xy);
	float rxy = length(nv.xy);
	float caust = lisse(0.35, 0.95, dot(nv.xy, dl)) * lisse(0.2, 0.7, rxy) * (1.0 - lisse(0.85, 1.0, rxy));
	col += teinte * caust * 0.35;
	// 3. l'objet au centre, dans le verre : il ne tourne pas
	vec4 c_coeur = texture(coeur, vec2(0.5) + 0.5 * p / taille_coeur);
	float a_c = c_coeur.a * 0.95 * (1.0 - step(taille_coeur, max(abs(p.x), abs(p.y))));
	col = mix(col, c_coeur.rgb * (0.85 + 0.15 * lum), a_c);
	// 4. le verre : un Fresnel teinté, le reflet de la fenêtre (un point vif, un arc le long du bord)
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
