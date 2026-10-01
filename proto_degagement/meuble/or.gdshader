shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// LE MEUBLE DE LA MACHINE, « BASE CÉLESTE » (01/10, prototype) : l'or et l'émail bleu nuit.
// Le modèle métal des pièces (objets/corps.gdshader : un ciel reflété, une fenêtre de lumière nette, la
// même tonalité), mais vu EN PERSPECTIVE : la normale et le reflet sont pris dans la vue (y vers le haut
// de l'écran, z vers l'œil). Sans lumière du moteur : le même éclairage que les pièces, partout.
// Pas de halo flou (les goûts de Maxim) : ce qui s'allume s'allume dans sa forme, net.

uniform vec3 teinte = vec3(1.0, 0.74, 0.30);       // l'or des pièces
uniform float email = 0.0;                          // 1 : un émail laqué, pas du métal
uniform vec3 couleur_email = vec3(0.035, 0.075, 0.20);
uniform float cannelures = 0.0;                     // > 0 : des cannelures le long de U (leur nombre)
uniform float allume = 0.0;                         // 0 à 1 : la pièce s'allume (le cœur des sphères, l'étoile)
uniform vec3 couleur_allume = vec3(1.0, 0.92, 0.68);
uniform float eclat = 0.9;
uniform float chenillard = 0.0;                     // > 0 : les perles s'allument en file (la Supernova)
uniform float n_perles = 60.0;
uniform float vitesse_chenillard = 14.0;

varying float v_rang;

const vec3 L_CLE = vec3(-0.4545, 0.6126, 0.6324);
const vec3 L_CONTRE = vec3(0.6353, -0.4303, 0.6763);

float lisse(float e0, float e1, float x) {
	float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}

// le ciel reflété (celui des pièces) : clair vers le haut de l'écran, une fenêtre en haut à gauche
float environnement(vec3 R) {
	float haut = R.y;
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

// les extrêmes resserrés autour d'un or moyen (comme les pièces : « ni très claires ni très sombres »)
vec3 adoucir(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float cible = mix(0.50, l, 0.85);
	vec3 c2 = c * (cible / max(l, 0.03));
	c2 = mix(vec3(cible), c2, 1.12);
	return clamp(c2, vec3(0.0), vec3(1.0));
}

void vertex() {
	// le rang d'une perle dans sa file (MultiMesh, donnée de l'instance) ; 0 ailleurs
	v_rang = INSTANCE_CUSTOM.r;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	if (cannelures > 0.0) {
		// des cannelures : la normale ondule le long de U (le fût des colonnes, les joncs)
		float o = sin(UV.x * cannelures * 6.2832);
		n = normalize(n + normalize(TANGENT) * o * 0.35);
	}
	vec3 V = normalize(VIEW);
	vec3 R = reflect(-V, n);
	float diff = clamp(dot(n, L_CLE), 0.0, 1.0);
	float spec = pow(clamp(dot(n, normalize(L_CLE + V)), 0.0, 1.0), 80.0);
	float spec2 = pow(clamp(dot(n, normalize(L_CONTRE + V)), 0.0, 1.0), 60.0) * 0.35;
	vec3 col;
	if (email > 0.5) {
		// l'émail : un bleu profond, un reflet net et étroit, le ciel sur les bords qui fuient
		float fres = 0.04 + 0.96 * pow(1.0 - clamp(dot(n, V), 0.0, 1.0), 5.0);
		float e = environnement(R);
		float sp = pow(clamp(dot(n, normalize(L_CLE + V)), 0.0, 1.0), 120.0) * 0.55;
		col = couleur_email * (0.55 + 0.45 * diff) + vec3(0.55, 0.62, 0.85) * e * fres * 0.35 + sp * vec3(0.9, 0.93, 1.0);
		ALBEDO = tonalite(col);
	} else {
		float e = mix(0.40, environnement(R), 0.55);
		col = teinte * (0.10 + 0.30 * diff + 0.95 * e) + (spec * eclat + spec2 * 0.7) * vec3(1.0, 0.96, 0.84);
		ALBEDO = adoucir(tonalite(col));
	}
	float a_tot = allume;
	if (chenillard > 0.0) {
		// une perle sur trois allumée, la file avance
		float onde = step(0.62, fract(v_rang * n_perles / 3.0 - TIME * vitesse_chenillard / 3.0));
		a_tot = max(a_tot, chenillard * onde);
	}
	if (a_tot > 0.0) {
		// allumé : la couleur de la lumière, pleine, le relief gardé dans un léger modelé
		vec3 vif = couleur_allume * (0.86 + 0.14 * diff) + vec3(spec * 0.3);
		ALBEDO = mix(ALBEDO, clamp(vif, vec3(0.0), vec3(1.0)), clamp(a_tot, 0.0, 1.0));
	}
}
