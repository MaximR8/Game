// LES PIÈCES ET LES OBJETS, VUS DANS UN DÉCOR PEINT (02/10, essai) : une copie de objets/corps.gdshader avec la profondeur étirée à l'image.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// LA MATIÈRE DES PIÈCES ET DES OBJETS DE LA POUSSETTE (FEATURES ⑦, 25/09).
// Le modèle métal des rendus en relief (design/objets/render_objets.py), calculé en
// temps réel : le relief et les reflets suivent la pièce quand elle penche ou roule.
// La projection est celle du dessin 2D — perspective oblique : écran = (x, z − k_h·h) —
// et la profondeur h + k_h·z fait passer devant ce qui est devant.

uniform sampler2D relief : filter_linear_mipmap, repeat_disable;       // étoile | lune : normale (RG), occlusion (B), motif (A)
uniform sampler2D cuit : filter_linear_mipmap, repeat_disable;  // un objet : le dessus, déjà rendu
uniform float mode_cuit = 0.0;
// Les objets de l'univers (FEATURES ⑭, 26/09) : éclairés en direct, comme les pièces (objets/volumes.gd).
// relief_objet : normale (RG), occlusion (B), matière (A : or · argent · pierre ou verre · roche) ;
// corps_objet : la couleur du corps, et ce que l'objet couvre (A).
uniform sampler2D relief_objet : filter_linear_mipmap, repeat_disable;
uniform sampler2D corps_objet : filter_linear_mipmap, repeat_disable;
uniform float mode_objet = 0.0;
uniform float resserre = 0.3;          // 1 : le reflet du ciel entier ; moins : resserré autour du gris moyen
uniform float relief_vif = 1.1;        // la part du relief dans le reflet (le « HD » d'une pièce)
uniform float eclat = 0.9;             // les reflets nets de la lumière
uniform float garde_contraste = 0.85;  // la part du contraste gardée par adoucir (26/09 : 0,55 rendait les pièces ternes)
uniform vec3 metal_face = vec3(1.0, 0.74, 0.30);
uniform vec3 metal_tranche = vec3(0.86, 0.60, 0.25);
uniform float k_h = 0.9;
uniform float fondu_objet = 0.0;      // un objet (hors MultiMesh) qui tombe s'efface

varying vec3 v_n;
varying vec3 v_t;
varying vec3 v_b;
varying vec3 v_nf;
varying float v_partie;
varying float v_face;
varying float v_fondu;

const vec3 L_CLE = vec3(-0.4545, -0.6126, 0.6324);
const vec3 L_CONTRE = vec3(0.6353, 0.4303, 0.6763);
const vec3 VUE = vec3(0.0, 0.0, 1.0);
const vec3 ARGENT = vec3(0.86, 0.885, 0.93);

float lisse(float e0, float e1, float x) {
	float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}

float environnement(vec3 R) {
	float haut = -R.y;
	float base = 0.05 + 0.80 * lisse(-0.25, 0.95, haut);
	// l'horizon sombre, adouci (0,28 → 0,12) : une pièce à plat le reflète en entier et tirait sur l'olive
	float horizon = 0.12 * exp(-pow((haut - 0.08) / 0.16, 2.0));
	// 🔴 la « boîte à lumière » reflétée : 2,1 → 1,3 (Maxim, 25/09 : « trop de reflet clair »)
	float boite = pow(clamp(dot(R, L_CLE), 0.0, 1.0), 14.0) * 1.3;
	float contre = pow(clamp(dot(R, L_CONTRE), 0.0, 1.0), 7.0) * 0.55;
	float sol = 0.06 * lisse(0.1, -0.9, haut);
	return max(base - horizon + boite + contre - sol, 0.0);
}

// 🔴 Le ciel reflété, en deux parts (Maxim, 26/09 : « certaines pièces très claires, d'autres très
//    sombres ; garder le jeu de lumière, mais certaines c'est trop ») :
//    · ce que donne la PENTE de la pièce (sa normale d'ensemble, nm) fait les extrêmes d'une pièce
//      à l'autre — penchée vers le haut, elle reflétait le clair (0,85) ; vers le bas, le sombre
//      (0,05) : on le resserre autour d'un gris moyen ;
//    · ce que donne son RELIEF (la normale fine, n) fait l'éclat dans la pièce : on le garde entier.
vec3 metal2(vec3 n, vec3 nm, vec3 alb, float ao, float mat) {
	vec3 R = 2.0 * n.z * n - VUE;
	vec3 Rm = 2.0 * nm.z * nm - VUE;
	float em = environnement(Rm);
	// (le relief borné : sur une pièce très penchée, il reflétait le sol et dessinait des cernes noirs)
	float e = mix(0.40, em, resserre) + clamp(environnement(R) - em, -0.22, 0.45) * relief_vif;
	float diff = clamp(dot(n, L_CLE), 0.0, 1.0);
	float spec = pow(clamp(dot(n, normalize(L_CLE + VUE)), 0.0, 1.0), 80.0);
	float spec2 = pow(clamp(dot(n, normalize(L_CONTRE + VUE)), 0.0, 1.0), 60.0) * 0.35;
	vec3 col = alb * (0.08 + 0.30 * diff + (0.95 * mat + 0.25 * (1.0 - mat)) * e)
		+ (spec * eclat + spec2 * 0.7) * vec3(1.0, 0.96, 0.84);
	return col * ao;
}


vec3 metal(vec3 n, vec3 alb, float ao, float mat) {
	return metal2(n, n, alb, ao, mat);
}

// la tonalité douce des rendus : pas de blanc cramé
// ⛔ Pas de conversion vers le linéaire : le rendu « Compatibility » écrit ces valeurs telles quelles
//    (vu le 25/09 : avec pow(2,2), les pièces sortaient presque noires).
vec3 tonalite(vec3 c) {
	c = max(c, vec3(0.0));
	c = (1.0 - exp(-c * 1.55)) / (1.0 - exp(-1.55));
	return pow(clamp(c, 0.0, 1.0), vec3(1.0 / 1.08));
}

// 🔴 Les deux extrêmes resserrés (Maxim, 25/09 : « certaines pièces sont très sombres, d'autres
//    très claires ») : la luminosité est ramenée vers celle d'un or moyen, la teinte gardée.
// 26/09 : un or un peu plus profond (0,54 → 0,48) et plus saturé (×1,12) — resserrées, les pièces pâlissaient.
vec3 adoucir(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float cible = mix(0.48, l, garde_contraste);
	vec3 c2 = c * (cible / max(l, 0.03));
	c2 = mix(vec3(cible), c2, 1.12);
	return clamp(c2, vec3(0.0), vec3(1.0));
}

// Une pierre ou un verre : la couleur du corps (rendue d'avance), le reflet du ciel sur les bords
// qui fuient (Fresnel), et deux reflets nets qui glissent de facette en facette quand l'objet penche.
vec3 gemme(vec3 n, vec3 corps, float ao) {
	vec3 R = 2.0 * n.z * n - VUE;
	float nz = clamp(n.z, 0.0, 1.0);
	float fres = 0.05 + 0.95 * pow(1.0 - nz, 3.0);
	float e = environnement(R);
	float mx = max(max(corps.r, corps.g), max(corps.b, 0.02));
	vec3 teinte = 0.75 + 0.25 * corps / mx;
	float spec = pow(clamp(dot(n, normalize(vec3(-0.45, -0.57, 0.69) + VUE)), 0.0, 1.0), 260.0) * 2.0
		+ pow(clamp(dot(n, normalize(L_CONTRE + VUE)), 0.0, 1.0), 200.0) * 0.7;
	return (corps * (1.0 - fres) + e * fres * 0.8 * teinte + spec * vec3(0.97, 1.0, 0.98)) * ao;
}

// Une roche (les astéroïdes de l'étoile) : sombre, un reflet net sur ses arêtes.
vec3 roche(vec3 n, vec3 corps, float ao) {
	float diff = clamp(dot(n, L_CLE), 0.0, 1.0);
	float spec = lisse(0.975, 0.992, dot(n, normalize(L_CLE + VUE))) * 0.55;
	return (corps * (0.3 + 1.3 * diff) + spec * vec3(0.92, 0.9, 1.0)) * ao;
}

float hachage(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// (02/10, essai des décors peints) la profondeur du plateau étirée À L'IMAGE autour du bord (la physique ne change pas) :
// le creux peint est plus profond que notre plateau ; etirement = 1 : rien ne change.
uniform float etirement = 1.0;
uniform float bord_plateau = 14.0;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// seul le CENTRE suit l'étirement : la pièce garde sa forme (étirée, elle se déformait — Maxim, 02/10)
	vec3 c_obj = MODEL_MATRIX[3].xyz;
	w = w - c_obj + vec3(c_obj.x, c_obj.y, bord_plateau - etirement * (bord_plateau - c_obj.z));
	vec3 ax = MODEL_MATRIX[0].xyz;
	vec3 ay = MODEL_MATRIX[1].xyz;
	vec3 az = MODEL_MATRIX[2].xyz;
	v_partie = COLOR.r;
	// dessus (1) : la normale du disque est +Y local ; dessous (0) : −Y ; tranche (0,5) : radiale
	v_nf = v_partie > 0.25 ? ay : -ay;
	v_t = ax;
	v_b = v_partie > 0.75 ? az : -az;
	v_n = mat3(MODEL_MATRIX) * NORMAL;
	v_face = INSTANCE_CUSTOM.r;
	v_fondu = max(INSTANCE_CUSTOM.g, fondu_objet);
	vec3 s = vec3(w.x, w.y + k_h * w.z, w.z - k_h * w.y);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(s, 1.0);
}

void fragment() {
	if (v_fondu > 0.0 && hachage(FRAGCOORD.xy) < v_fondu) {
		discard;
	}
	// les textures sont lues hors des branches : les dérivées (mipmaps) y restent justes
	float dessus = step(0.75, v_partie);
	float f = mix(1.0 - v_face, v_face, dessus);
	vec4 r = texture(relief, vec2((clamp(UV.x, 0.0, 1.0) + f) * 0.5, UV.y));
	vec3 c_cuit = texture(cuit, UV).rgb;
	vec4 ro = texture(relief_objet, UV);
	vec4 co = texture(corps_objet, UV);
	vec3 nf = normalize(v_nf);
	vec3 col;
	if (v_partie > 0.75 || v_partie < 0.25) {
		if (mode_objet > 0.5) {
			if (v_partie > 0.75) {
				// le dessus : seulement ce que l'image couvre
				if (co.a < 0.5) {
					discard;
				}
				vec2 nxy = ro.rg * 2.0 - 1.0;
				vec3 nm = vec3(nxy, sqrt(max(0.0, 1.0 - dot(nxy, nxy))));
				vec3 n = normalize(nm.x * normalize(v_t) + nm.y * normalize(v_b) + nm.z * nf);
				vec3 nv = vec3(n.x, n.z, n.y);
				vec3 nfv = vec3(nf.x, nf.z, nf.y);
				if (ro.a < 0.17) {
					ALBEDO = adoucir(tonalite(metal2(nv, nfv, metal_face, ro.b, 1.0)));
				} else if (ro.a < 0.5) {
					ALBEDO = adoucir(tonalite(metal2(nv, nfv, ARGENT, ro.b, 1.0)));
				} else if (ro.a < 0.83) {
					ALBEDO = tonalite(gemme(nv, co.rgb, ro.b));
				} else {
					ALBEDO = tonalite(roche(nv, co.rgb, ro.b));
				}
			} else {
				// le dessous : le métal de la tranche, rarement vu
				ALBEDO = adoucir(tonalite(metal(vec3(nf.x, nf.z, nf.y), metal_tranche, 0.7, 1.0)));
			}
		} else if (mode_cuit > 0.5) {
			// un objet : son dessus rendu, un peu plus sombre quand il penche loin de la lumière
			float penche = clamp(0.75 + 0.25 * nf.y, 0.0, 1.0);
			ALBEDO = c_cuit * penche;
		} else {
			vec2 nxy = r.rg * 2.0 - 1.0;
			vec3 nm = vec3(nxy, sqrt(max(0.0, 1.0 - dot(nxy, nxy))));
			vec3 n = normalize(nm.x * normalize(v_t) + nm.y * normalize(v_b) + nm.z * nf);
			col = metal2(vec3(n.x, n.z, n.y), vec3(nf.x, nf.z, nf.y), metal_face, r.b, 1.0 - 0.3 * r.a);
			ALBEDO = adoucir(tonalite(col));
		}
	} else {
		// la tranche, moletée
		vec3 n = normalize(v_n);
		vec3 autour = normalize(cross(nf, n) + vec3(1e-5));
		// les objets ont un serti lisse ; les pièces, une tranche moletée
		n = normalize(n + autour * (mode_objet > 0.5 ? 0.0 : 0.35) * sin(UV.x * 6.2832 * 90.0));
		col = metal(vec3(n.x, n.z, n.y), metal_tranche, (mode_cuit > 0.5 || mode_objet > 0.5) ? 1.0 : 0.8, 1.0);
		ALBEDO = adoucir(tonalite(col));
	}
}
