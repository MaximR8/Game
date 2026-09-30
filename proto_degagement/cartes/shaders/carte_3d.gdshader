// LA CARTE EN 3D (27/09) : le recto et le verso, dessinés à plat dans deux SubViewports, posés
// sur un plan qui tourne (ry : autour de la verticale, rx : la bascule haut / bas), vu en
// perspective. Chaque pixel lance un rayon depuis l'œil, le croise avec le plan, et lit la face
// que le rayon touche. (carte_3d.gd)
shader_type canvas_item;

uniform sampler2D recto : filter_linear, repeat_disable;
uniform sampler2D verso : filter_linear, repeat_disable;
uniform vec2 zone = vec2(1200.0, 1600.0);   // la taille de ce dessin, en px
uniform vec2 plan = vec2(950.0, 1280.0);    // la taille d'une face (son SubViewport), en px
uniform float rx = 0.0;
uniform float ry = 0.0;
uniform float focale = 1800.0;              // l'œil, à cette distance du plan (en px)

void fragment() {
	vec2 p = (UV - 0.5) * zone;
	vec3 oeil = vec3(0.0, 0.0, -focale);
	vec3 dir = vec3(p, focale);
	float cy = cos(ry);
	float sy = sin(ry);
	float cx = cos(rx);
	float sx = sin(rx);
	// les axes de la carte, tournée : d'abord la bascule (autour de x), puis le tour (autour de y)
	vec3 ax = vec3(cy, 0.0, -sy);
	vec3 ay = vec3(sy * sx, cx, cy * sx);
	vec3 n = cross(ax, ay);
	float den = dot(dir, n);
	vec4 c = vec4(0.0);
	if (abs(den) > 1e-4) {
		vec3 impact = oeil + (-dot(oeil, n) / den) * dir;
		vec2 q = vec2(dot(impact, ax), dot(impact, ay)) / plan + 0.5;
		if (q.x >= 0.0 && q.x <= 1.0 && q.y >= 0.0 && q.y <= 1.0) {
			// le recto regarde l'œil quand le rayon arrive par son côté ; sinon on voit le
			// verso, retourné comme une vraie carte (sa gauche passe à droite)
			c = den > 0.0 ? texture(recto, q) : texture(verso, vec2(1.0 - q.x, q.y));
			// une carte de biais reçoit un peu moins de lumière
			float face = abs(den) / length(dir);
			c.rgb *= mix(0.78, 1.0, face);
		}
	}
	COLOR = c;
}
