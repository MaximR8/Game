shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// LE PLATEAU, MIROIR DU CIEL (01/10, prototype « Base céleste ») : le bleu nuit du meuble, la poussière
// d'étoiles du jeu, plus profond vers l'avant, assombri le long des parois (comme le dessin d'avant).

uniform sampler2D etoiles : filter_linear_mipmap, repeat_enable;
uniform vec2 x_bords = vec2(0.46, 10.34);
uniform vec3 clair = vec3(0.030, 0.058, 0.140);
uniform vec3 profond = vec3(0.012, 0.024, 0.066);
uniform float sombre = 0.0;          // 1 : le fond d'une fente

varying vec3 v_monde;

void vertex() {
	v_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_monde.xz;
	vec3 col = mix(clair, profond, smoothstep(6.0, 14.0, p.y));
	vec4 te = texture(etoiles, p * 0.17);
	col += te.rgb * te.a * 0.7;
	float bords = min(p.x - x_bords.x, x_bords.y - p.x);
	col *= 0.55 + 0.45 * smoothstep(0.0, 1.3, bords);
	ALBEDO = mix(col, vec3(0.0), sombre);
}
