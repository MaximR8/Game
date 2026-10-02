shader_type canvas_item;
render_mode blend_add;

// LE REFLET QUI GLISSE SUR L'OR (02/10, les décors peints) — Maxim : « des petites animations dessus, un peu comme les
// cartes » ; puis, sur le premier essai : « ça fait très pauvre, fait en CSS ». Donc plus de bande plate : la lumière ne
// court que sur les ARÊTES déjà claires de l'or (le masque de l'or × la clarté du décor), comme un vrai reflet qui suit le
// relief ; à la Supernova, l'emblème s'allume de sa propre lumière.

uniform sampler2D masque : filter_linear, repeat_disable;
uniform sampler2D decor : filter_linear, repeat_disable;
uniform float phase = -1.0;               // la position du reflet (de -0,6 à 1,8 : il traverse l'image)
uniform float force = 0.9;
uniform vec2 embleme = vec2(0.5, 0.25);   // le centre de l'emblème (UV)
uniform float r_embleme = 0.19;           // son rayon (en largeur d'image)
uniform float eclat_embleme = 0.0;        // la Supernova : l'emblème flambe

void fragment() {
	float m = texture(masque, UV).r;
	vec3 c = texture(decor, UV).rgb;
	float clair = smoothstep(0.55, 0.95, max(c.r, c.g));
	float d = UV.x * 0.78 + UV.y * 0.52 - phase;
	float bande = exp(-pow(d / 0.035, 2.0));
	vec2 q = (UV - embleme) * vec2(1.0, 1.5);
	float dans = smoothstep(r_embleme, r_embleme * 0.9, length(q));
	vec3 lumiere = c * m * (clair * bande * force + dans * eclat_embleme * (0.35 + 0.65 * clair));
	COLOR = vec4(lumiere, 1.0);
}
