shader_type canvas_item;
render_mode blend_add;

// LE REFLET QUI GLISSE SUR L'OR (02/10, essai des décors peints) — Maxim : « des petites animations dessus, un peu comme
// les cartes ». Une bande de lumière nette, en biais, traverse l'or du décor (son masque : design/machines/<décor>-or.png) ;
// à la Supernova, l'emblème s'allume et les reflets se suivent. Pas de halo : la bande a des bords francs.

uniform sampler2D masque : filter_linear, repeat_disable;
uniform float phase = -1.0;               // la position de la bande (de -0,6 à 1,8 : elle traverse l'image)
uniform float force = 0.42;
uniform vec3 couleur = vec3(1.0, 0.93, 0.74);
uniform vec2 embleme = vec2(0.5, 0.25);   // le centre de l'emblème (UV)
uniform float r_embleme = 0.19;           // son rayon (en largeur d'image)
uniform float eclat_embleme = 0.0;        // la Supernova : l'emblème flambe

void fragment() {
	float m = texture(masque, UV).r;
	float d = UV.x * 0.78 + UV.y * 0.52 - phase;
	float bande = smoothstep(0.045, 0.012, abs(d)) * 0.85 + smoothstep(0.012, 0.0, abs(d - 0.06)) * 0.5;
	vec2 q = (UV - embleme) * vec2(1.0, 1.5);
	float dans = smoothstep(r_embleme, r_embleme * 0.92, length(q));
	vec3 c = couleur * m * (bande * force + dans * eclat_embleme);
	COLOR = vec4(c, 1.0);
}
