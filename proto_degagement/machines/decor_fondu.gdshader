shader_type canvas_item;

// LE DÉCOR PEINT, FONDU EN HAUT ET EN BAS (02/10, essai) : ses bords se perdent dans le ciel du jeu (pas de couture).
// (02/10, la Supernova) l'aspiration : la salle s'assombrit, sauf l'astrolabe qui se charge — l'explosion n'en est que plus
// vive (on assombrit le décor, on n'ajoute aucun halo).

uniform float fondu_haut = 0.03;
uniform float fondu_bas = 0.04;
uniform float lumiere = 1.0;              // 1 : le décor tel quel
uniform vec2 embleme = vec2(0.5, 0.25);   // le centre de l'emblème (UV)
uniform float r_embleme = 0.19;           // son rayon (en largeur d'image)

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float a = smoothstep(0.0, fondu_haut, UV.y) * smoothstep(1.0, 1.0 - fondu_bas, UV.y);
	float garde = smoothstep(r_embleme * 1.25, r_embleme * 0.85, length((UV - embleme) * vec2(1.0, 1.5)));
	COLOR = vec4(c.rgb * mix(lumiere, 1.0, garde), c.a * a);
}
