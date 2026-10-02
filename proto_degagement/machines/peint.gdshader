shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// UN CACHE PEINT (02/10, essai des décors peints) : un volume invisible à l'œil, qui montre exactement le décor derrière
// lui (lu à sa place sur l'écran : la vue 3D couvre le décor au pixel près) — mais qui cache ce qui passe derrière. La
// lèvre d'or de l'avant : les pièces qui tombent du bord disparaissent derrière elle, comme dans une vraie machine.

uniform sampler2D decor : filter_linear, repeat_disable;

void fragment() {
	ALBEDO = texture(decor, SCREEN_UV).rgb;
}
