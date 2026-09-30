shader_type canvas_item;

// Une image posée à sa taille (TextureRect en STRETCH_SCALE, 1 pixel du jeu = 1 pixel de l'image) : ses coins
// s'arrondissent comme ceux des panneaux (Style.boite). Les bannières de l'Astrolabe (28/09).
// « voile_bas » assombrit doucement le bas : le texte qui s'y pose reste lisible.

uniform vec2 taille = vec2(1020.0, 1480.0);
uniform float rayon = 34.0;
uniform float voile_bas = 0.0;
uniform float voile_haut = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 p = UV * taille;
	vec2 q = abs(p - taille * 0.5) - (taille * 0.5 - vec2(rayon));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rayon;
	c.rgb *= 1.0 - voile_bas * smoothstep(0.5, 1.0, UV.y);
	c.rgb *= 1.0 - voile_haut * smoothstep(0.22, 0.0, UV.y);
	c.a *= clamp(0.5 - d, 0.0, 1.0);
	COLOR = c * COLOR;
}
