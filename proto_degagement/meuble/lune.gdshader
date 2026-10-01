shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// UNE LUNE DE LA JAUGE (01/10, prototype « Base céleste ») : incrustée dans l'arche. Éteinte, sa phase
// (de la nouvelle à la nouvelle) se lit en or sur un émail bleu nuit ; allumée, elle devient pleine,
// vive, cerclée net (la jauge d'avant, sur la frise : pusher_screen._dessiner_jauge). Le disque :
// UV = la face (0,5 ; 0,5 au centre).

uniform float phase = 0.5;      // de 0 (nouvelle) à 1 (pleine) ; négatif : elle décroît
uniform float allume = 0.0;
uniform float pulse = 1.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	vec3 or_ = vec3(0.92, 0.70, 0.33);
	vec3 email = vec3(0.025, 0.05, 0.14);
	// la bague d'or
	float bague = smoothstep(0.80, 0.84, r);
	// la phase : la part éclairée, du côté droit quand elle croît
	float k = abs(phase);
	float cote = phase >= 0.0 ? 1.0 : -1.0;
	float x = p.x * cote;
	float rx = (1.0 - 2.0 * k) * sqrt(max(0.0, 0.64 - p.y * p.y));
	float eclaire = step(r, 0.80) * step(rx, x);
	if (k > 0.999) {
		eclaire = step(r, 0.80);
	}
	vec3 col = mix(email, or_ * 0.85, eclaire);
	col = mix(col, or_, bague);
	if (allume > 0.0) {
		// allumée : pleine, ivoire doré, un cercle net autour
		vec3 vive = vec3(1.0, 0.93, 0.66) * (0.9 + 0.1 * (1.0 - r));
		vec3 c2 = mix(vive, vec3(1.0, 0.97, 0.85), bague);
		col = mix(col, c2 * pulse + col * (1.0 - pulse) * 0.3, allume);
	}
	ALBEDO = col;
}
