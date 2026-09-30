class_name CarteFx
extends Node2D

# ─────────────────────────────────────────────────────────────
# LES EFFETS D'UNE CARTE — portés de la maquette (fx_moteur.js).
#
# Des shaders pour ce qui couvre une surface (métal en fusion, brume,
# caustiques, rais de soleil, brume fantôme) ; des particules du
# moteur pour ce qui monte droit (braises, spores) ; du dessin à la
# main pour ce qui ondule ou arrive par événement (neige et rafales,
# feuilles qui tournoient, bulles qui éclatent, éclairs, feux follets,
# éclats de lumière).
# 🔴 Jamais un motif répété à vitesse constante (verdict du 22/09).
# 🔴 Un effet naît de la carte, jamais du vide autour (22/09).
# ─────────────────────────────────────────────────────────────

const SH_FUSION := preload("res://cartes/shaders/fusion.gdshader")
const SH_BRUME := preload("res://cartes/shaders/brume.gdshader")
const SH_CAUSTIQUES := preload("res://cartes/shaders/caustiques.gdshader")
const SH_RAYONS := preload("res://cartes/shaders/rayons.gdshader")
const SH_BRUME_ART := preload("res://cartes/shaders/brume_art.gdshader")
const TEX_FEUILLE := preload("res://cartes/svg/feuille.svg")
const TEX_BULLE := preload("res://cartes/svg/bulle.svg")
const TEX_FLOCON := preload("res://cartes/svg/flocon.svg")
const TEX_ETOILE := preload("res://cartes/svg/etoile.svg")
const TEINTES_FEUILLES := [Color("#b2dc84"), Color("#dce382"), Color("#e6ad62")]
const ARC := [Color(1.0, 0.47, 0.55), Color(1.0, 0.78, 0.47), Color(0.92, 1.0, 0.55),
	Color(0.51, 1.0, 0.67), Color(0.47, 0.92, 1.0), Color(0.55, 0.63, 1.0), Color(0.84, 0.55, 1.0)]
const ELEMENTS := ["feu", "foudre", "eau", "glace", "nature", "esprit"]

var kind := ""
var recto := true
var W := 486.0
var H := 680.4
var u := 4.86
var s := 1.389   # largeur / 350 : les réglages de la maquette valent pour une carte de 350 px
var k := 1.0     # moins de particules dans les petites cartes
var b := 18.5    # la bande du cadre
var o := 38.9    # la marge autour de la carte, où les effets peuvent déborder
var art := Rect2()
var t := 0.0

var _rng := RandomNumberGenerator.new()
var _sous: Node2D
var _normal: Node2D           # ce qui se peint en mélange normal (neige, bulles, feuilles)
var _recto_seul: Array = []   # ce qui disparaît quand la carte est de dos
var _dessine := false         # l'effet se redessine à chaque image (sinon : shaders et particules seuls)

# feu
var _pro := 0.0
var _vague := -1.0
var _mat_fusion: ShaderMaterial
var _chaleur: TextureRect
var _gerbe: CPUParticles2D
# foudre
var _eclairs: Array = []
var _arcs: Array = []
var _electrons: Array = []
var _flash := 0.0
var _rappel := 0.0
var _parc := 0.0
var _boite_flash := StyleBoxFlat.new()
# eau
var _bulles: Array = []
var _pops: Array = []
var _gouttes: Array = []
# glace
var _flocons: Array = []
var _rafale := 0.0
var _givre: Node2D
var _givre_traits: Array = []   # un lot de traits par profondeur : [points, couleurs, épaisseur]
# nature
var _feuilles: Array = []
var _pousses: Array = []
# esprit
var _feux: Array = []
# ombre
var _mat_brume: ShaderMaterial
var _houle := 0.0
# prismatique
var _eclats: Array = []

static var _tex_point: Texture2D


static func tex_point() -> Texture2D:
	if _tex_point == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0)])
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		_tex_point = gt
	return _tex_point


# ─────────────────────────────────────────────────────────────
# Mise en place
# ─────────────────────────────────────────────────────────────

func configurer(p_kind: String, taille: Vector2, rect_art: Rect2, bande: float, sous: Node2D) -> void:
	kind = p_kind
	W = taille.x
	H = taille.y
	u = W / 100.0
	s = W / 350.0
	k = clampf(s, 0.4, 1.0)
	b = bande
	o = 8.0 * u
	art = rect_art
	_sous = sous
	_rng.randomize()
	# chaque carte a son propre temps : les cartes ne battent pas à l'unisson
	t = _rng.randf_range(0.0, 20.0)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add
	_normal = Node2D.new()
	_normal.draw.connect(_dessiner_normal)
	add_child(_normal)
	_recto_seul.append(_normal)
	_boite_flash.set_corner_radius_all(int(round(4.6 * u)))
	match kind:
		"feu":
			_init_feu()
		"foudre":
			_init_foudre()
		"eau":
			_init_eau()
		"glace":
			_init_glace()
		"nature":
			_init_nature()
		"esprit":
			_init_esprit()
		"ombre":
			_init_ombre()
		"prisme", "full":
			_init_prisme()
	set_process(kind != "")


func set_face(v: bool) -> void:
	recto = v
	for n in _recto_seul:
		(n as CanvasItem).visible = v
	queue_redraw()


func _element() -> bool:
	return kind in ELEMENTS


func _process(delta: float) -> void:
	# De dos, l'élémentaire se tait ; la brume de l'ombre et les éclats du prismatique restent.
	if not recto and _element():
		return
	var dt := minf(delta, 0.05)
	t += dt
	match kind:
		"feu":
			_pas_feu(dt)
		"foudre":
			_pas_foudre(dt)
		"eau":
			_pas_eau(dt)
		"glace":
			_pas_glace(dt)
		"nature":
			_pas_nature(dt)
		"esprit":
			_pas_esprit(dt)
		"ombre":
			_pas_ombre(dt)
		"prisme", "full":
			_pas_prisme(dt)
	if _dessine:
		queue_redraw()
		_normal.queue_redraw()


func _draw() -> void:
	if not recto and _element():
		return
	match kind:
		"foudre":
			_dessiner_foudre()
		"eau":
			_dessiner_gouttes()
		"esprit":
			_dessiner_esprit()
		"prisme", "full":
			_dessiner_prisme()


func _dessiner_normal() -> void:
	if not recto and _element():
		return
	match kind:
		"eau":
			_dessiner_bulles()
		"glace":
			_dessiner_neige()
		"nature":
			_dessiner_feuilles()


# ─────────────────────────────────────────────────────────────
# Outils
# ─────────────────────────────────────────────────────────────

func _signe() -> float:
	return -1.0 if _rng.randf() < 0.5 else 1.0


# Un point sur le milieu de la bande du cadre : [position, normale vers l'extérieur,
# tangente]. tt parcourt tout le tour, de 0 à 1.
func _bord(tt: float) -> Array:
	var m := b * 0.5
	var w := W - b
	var h := H - b
	var d := fposmod(tt, 1.0) * 2.0 * (w + h)
	if d < w:
		return [Vector2(m + d, m), Vector2(0, -1), Vector2(1, 0)]
	d -= w
	if d < h:
		return [Vector2(m + w, m + d), Vector2(1, 0), Vector2(0, 1)]
	d -= h
	if d < w:
		return [Vector2(m + w - d, m + h), Vector2(0, 1), Vector2(-1, 0)]
	d -= w
	return [Vector2(m, m + h - d), Vector2(-1, 0), Vector2(0, -1)]


func _coins_t() -> Array:
	var w := W - b
	var h := H - b
	var L := 2.0 * (w + h)
	return [0.0, w / L, (w + h) / L, (2.0 * w + h) / L]


func _materiau_add() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _rampe(arrets: Array) -> Gradient:
	var g := Gradient.new()
	var off := PackedFloat32Array()
	var col := PackedColorArray()
	for a in arrets:
		off.append(float(a[0]))
		col.append(a[1])
	g.offsets = off
	g.colors = col
	return g


func _particules(n: int, additif: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = maxi(1, int(round(n * k)))
	p.texture = tex_point()
	p.local_coords = true
	if additif:
		p.material = _materiau_add()
	return p


func _rect(pos: Vector2, taille: Vector2, sh: Shader) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = pos
	cr.size = taille
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = sh
	cr.material = m
	return cr


# ─────────────────────────────────────────────────────────────
# FEU — le métal du cadre en fusion, des braises qui s'en échappent,
# et l'embrasement : une vague de chaleur qui remonte, avec une gerbe.
# ─────────────────────────────────────────────────────────────

func _init_feu() -> void:
	var cr := _rect(Vector2.ZERO, Vector2(W, H), SH_FUSION)
	_mat_fusion = cr.material as ShaderMaterial
	_mat_fusion.set_shader_parameter("taille", Vector2(W, H))
	_mat_fusion.set_shader_parameter("rayon", 4.6 * u)
	_mat_fusion.set_shader_parameter("echelle", s)
	_sous.add_child(cr)
	_recto_seul.append(cr)

	# la chaleur au pied de l'illustration, qui monte avec la vague
	var clip := Control.new()
	clip.position = art.position
	clip.size = art.size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	_recto_seul.append(clip)
	var gt := GradientTexture2D.new()
	gt.gradient = _rampe([[0.0, Color(1.0, 0.47, 0.16, 1.0)], [1.0, Color(1.0, 0.47, 0.16, 0.0)]])
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	_chaleur = TextureRect.new()
	_chaleur.texture = gt
	_chaleur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chaleur.size = Vector2(art.size.x * 1.6, art.size.x * 1.6)
	_chaleur.position = Vector2(art.size.x * 0.5, art.size.y) - _chaleur.size * 0.5
	_chaleur.material = _materiau_add()
	_chaleur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_chaleur)

	# les braises : du cadre (plus d'une sur deux) et du pied de l'illustration
	var pts := PackedVector2Array()
	for i in 120:
		var P := _bord(_rng.randf())
		pts.append((P[0] as Vector2) + (P[1] as Vector2) * _rng.randf_range(-0.4, 0.4) * b)
	for i in 100:
		pts.append(Vector2(_rng.randf_range(art.position.x + art.size.x * 0.08, art.end.x - art.size.x * 0.08),
			art.end.y - _rng.randf_range(0.0, art.size.y * 0.25)))
	var rampe := _rampe([[0.0, Color(1, 0.96, 0.82, 0)], [0.08, Color(1, 0.95, 0.8, 1)], [0.3, Color(1, 0.63, 0.24, 1)],
		[0.6, Color(1, 0.36, 0.12, 0.8)], [1.0, Color(0.8, 0.15, 0.05, 0)]])
	var br := _particules(46, true)
	br.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	br.emission_points = pts
	br.direction = Vector2(0, -1)
	br.spread = 16.0
	br.initial_velocity_min = 24.0 * s
	br.initial_velocity_max = 76.0 * s
	br.gravity = Vector2(0, -12.0 * s)
	br.lifetime = 2.6
	br.lifetime_randomness = 0.5
	br.scale_amount_min = 0.18 * s
	br.scale_amount_max = 0.42 * s
	br.color_ramp = rampe
	br.preprocess = 3.0
	add_child(br)
	_recto_seul.append(br)

	_gerbe = _particules(18, true)
	_gerbe.one_shot = true
	_gerbe.explosiveness = 0.85
	_gerbe.emitting = false
	_gerbe.position = Vector2(W * 0.5, H - b * 0.5)
	_gerbe.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_gerbe.emission_rect_extents = Vector2(W * 0.45, b * 0.4)
	_gerbe.direction = Vector2(0, -1)
	_gerbe.spread = 22.0
	_gerbe.initial_velocity_min = 40.0 * s
	_gerbe.initial_velocity_max = 105.0 * s
	_gerbe.gravity = Vector2(0, -12.0 * s)
	_gerbe.lifetime = 2.2
	_gerbe.lifetime_randomness = 0.4
	_gerbe.scale_amount_min = 0.2 * s
	_gerbe.scale_amount_max = 0.45 * s
	_gerbe.color_ramp = rampe
	add_child(_gerbe)
	_recto_seul.append(_gerbe)
	_pro = _rng.randf_range(2.5, 5.0)


func _pas_feu(dt: float) -> void:
	_pro -= dt
	if _pro <= 0.0:
		_pro = _rng.randf_range(5.0, 8.0)
		_vague = 0.0
		_gerbe.restart()
		_gerbe.emitting = true
	if _vague >= 0.0:
		_vague += dt / 1.1
		if _vague > 1.0:
			_vague = -1.0
	_mat_fusion.set_shader_parameter("vague", _vague)
	var chal := 0.16 + 0.05 * sin(t * 3.1) + 0.04 * sin(t * 7.7)
	if _vague >= 0.0:
		chal += 0.18 * sin(PI * _vague)
	_chaleur.modulate = Color(1, 1, 1, clampf(chal, 0.0, 1.0))


# ─────────────────────────────────────────────────────────────
# FOUDRE — l'éclair frappe (parfois deux fois) et illumine la carte ;
# un courant file le long du cadre et y fait claquer des arcs.
# ─────────────────────────────────────────────────────────────

func _init_foudre() -> void:
	_dessine = true
	for i in maxi(1, int(round(9 * k))):
		_electrons.append({"t": _rng.randf(), "v": _rng.randf_range(0.05, 0.13) * _signe(),
			"off": _rng.randf_range(-0.3, 0.3), "z": _rng.randf()})
	_pro = _rng.randf_range(0.5, 1.4)


func _foudroie(a: Vector2, z: Vector2, rugo: float, prof: int) -> PackedVector2Array:
	var pts := PackedVector2Array([a, z])
	for n in prof:
		var np := PackedVector2Array([pts[0]])
		for i in pts.size() - 1:
			var A := pts[i]
			var B := pts[i + 1]
			var d := B - A
			var L := maxf(d.length(), 0.001)
			np.append((A + B) * 0.5 + Vector2(-d.y, d.x) / L * _rng.randf_range(-rugo, rugo))
			np.append(B)
		pts = np
		rugo *= 0.52
	return pts


func _frapper(rappel: bool) -> void:
	var x0 := _rng.randf_range(W * 0.18, W * 0.82)
	var y0 := -_rng.randf_range(0.3, 0.9) * o
	var x1 := clampf(x0 + _rng.randf_range(-0.35, 0.35) * W, W * 0.08, W * 0.92)
	var y1 := _rng.randf_range(0.5, 1.02) * H
	var L := Vector2(x1 - x0, y1 - y0).length()
	var corps := _foudroie(Vector2(x0, y0), Vector2(x1, y1), L * 0.2, 6)
	var branches: Array = []
	for n in (2 if _rng.randf() < 0.5 else 1):
		var P := corps[int(_rng.randf_range(0.25, 0.65) * corps.size())]
		var ang := atan2(y1 - y0, x1 - x0) + _signe() * _rng.randf_range(0.45, 0.9)
		var l := L * _rng.randf_range(0.18, 0.36)
		branches.append(_foudroie(P, P + Vector2(cos(ang), sin(ang)) * l, l * 0.22, 5))
	_eclairs.append({"corps": corps, "branches": branches, "age": 0.0, "vie": 0.34})
	_flash = 1.0
	# une fois sur trois, l'orage frappe deux fois de suite
	if not rappel and _rng.randf() < 0.3:
		_rappel = _rng.randf_range(0.1, 0.18)


func _pas_foudre(dt: float) -> void:
	_pro -= dt
	if _pro <= 0.0:
		_pro = _rng.randf_range(2.2, 4.8)
		_frapper(false)
	if _rappel > 0.0:
		_rappel -= dt
		if _rappel <= 0.0:
			_frapper(true)
	_flash *= exp(-dt * 7.5)
	for i in range(_eclairs.size() - 1, -1, -1):
		_eclairs[i]["age"] += dt
		if _eclairs[i]["age"] > _eclairs[i]["vie"]:
			_eclairs.remove_at(i)
	_parc -= dt
	if _parc <= 0.0:
		_parc = _rng.randf_range(0.05, 0.16)
		var P := _bord(_rng.randf())
		var l := _rng.randf_range(0.06, 0.16) * W
		var pts := PackedVector2Array()
		for j in 8:
			var f := j / 7.0 - 0.5
			var jit := 0.0 if (j == 0 or j == 7) else _rng.randf_range(-1.0, 1.0) * b
			pts.append((P[0] as Vector2) + (P[2] as Vector2) * f * l + (P[1] as Vector2) * jit)
		_arcs.append({"pts": pts, "age": 0.0, "vie": _rng.randf_range(0.08, 0.2)})
	for i in range(_arcs.size() - 1, -1, -1):
		_arcs[i]["age"] += dt
		if _arcs[i]["age"] > _arcs[i]["vie"]:
			_arcs.remove_at(i)
	for p in _electrons:
		p["t"] += p["v"] * dt


func _dessiner_foudre() -> void:
	if _flash > 0.01:
		_boite_flash.bg_color = Color(0.725, 0.804, 1.0, _flash * 0.22)
		draw_style_box(_boite_flash, Rect2(0, 0, W, H))
	var passes := [[7.5, Color(0.431, 0.549, 1.0), 0.2], [3.4, Color(0.667, 0.765, 1.0), 0.5], [1.4, Color(1, 1, 1), 0.95]]
	for e in _eclairs:
		var a: float = e["age"]
		var v := 1.0
		if a < 0.04:
			v = 1.0
		elif a < 0.07:
			v = 0.08
		elif a < 0.14:
			v = 0.95
		else:
			v = maxf(0.0, 1.0 - (a - 0.14) / (float(e["vie"]) - 0.14))
		for pz in passes:
			var col: Color = pz[1]
			col.a = float(pz[2]) * v
			draw_polyline(e["corps"], col, float(pz[0]) * s, true)
			for br in e["branches"]:
				draw_polyline(br, col, float(pz[0]) * s * 0.55, true)
	for a in _arcs:
		var v := 1.0 - float(a["age"]) / float(a["vie"])
		draw_polyline(a["pts"], Color(0.549, 0.667, 1.0, 0.4 * v), 4.5 * s, true)
		draw_polyline(a["pts"], Color(0.941, 0.961, 1.0, 0.95 * v), 1.3 * s, true)
	var tex := tex_point()
	for p in _electrons:
		for kk in range(5, -1, -1):
			var B := _bord(float(p["t"]) - float(p["v"]) * kk * 0.014)
			var pos: Vector2 = (B[0] as Vector2) + (B[1] as Vector2) * float(p["off"]) * b
			var sz := (2.6 - kk * 0.32) * s * 2.2 * (0.7 + float(p["z"]) * 0.6)
			var col := Color(1, 1, 1, 0.8) if kk == 0 else Color(0.75, 0.82, 1.0, (1.0 - kk / 6.0) * 0.8)
			draw_texture_rect(tex, Rect2(pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, col)


# ─────────────────────────────────────────────────────────────
# EAU — les reflets des vagues (caustiques), des bulles qui montent et
# éclatent, des gouttes qui glissent le long du cadre.
# ─────────────────────────────────────────────────────────────

func _init_eau() -> void:
	_dessine = true
	# les caustiques, sur l'illustration — sans le ruban qui la chevauche
	var cr := _rect(art.position, Vector2(art.size.x, art.size.y - 2.8 * u), SH_CAUSTIQUES)
	(cr.material as ShaderMaterial).set_shader_parameter("taille", cr.size)
	(cr.material as ShaderMaterial).set_shader_parameter("rayon", 1.6 * u)
	add_child(cr)
	_recto_seul.append(cr)
	for i in maxi(1, int(round(28 * k))):
		_bulles.append(_naitre_bulle({}, true))
	for i in 3:
		_gouttes.append({"cote": i % 2, "y": _rng.randf_range(0.0, H), "v": 0.0, "attente": _rng.randf_range(0.0, 2.0)})


func _naitre_bulle(p: Dictionary, partout: bool) -> Dictionary:
	var z := _rng.randf()
	p["z"] = z
	p["r"] = (1.8 + z * z * 6.0) * s
	p["x0"] = _rng.randf_range(art.position.x + art.size.x * 0.05, art.end.x - art.size.x * 0.05)
	if partout:
		p["y"] = _rng.randf_range(art.position.y + art.size.y * 0.3, art.end.y)
	else:
		p["y"] = art.end.y + _rng.randf_range(0.0, 6.0 * s)
	p["vy"] = -(10.0 + float(p["r"]) / s * 5.0) * s
	p["ph"] = _rng.randf_range(0.0, TAU)
	p["f"] = _rng.randf_range(1.8, 3.4)
	p["fin"] = art.position.y + _rng.randf_range(0.0, art.size.y * 0.35)
	return p


func _pas_eau(dt: float) -> void:
	for p in _bulles:
		p["y"] += p["vy"] * dt
		if p["y"] < p["fin"]:
			_pops.append({"x": float(p["x0"]) + sin(t * float(p["f"]) + float(p["ph"])) * (1.5 + float(p["r"]) * 0.6),
				"y": p["y"], "r": p["r"], "age": 0.0})
			_naitre_bulle(p, false)
	for i in range(_pops.size() - 1, -1, -1):
		_pops[i]["age"] += dt
		if _pops[i]["age"] > 0.16:
			_pops.remove_at(i)
	for d in _gouttes:
		if d["attente"] > 0.0:
			d["attente"] -= dt
			continue
		d["v"] = minf(float(d["v"]) + 60.0 * s * dt, 90.0 * s)
		d["y"] += d["v"] * dt
		if d["y"] > H:
			d["y"] = _rng.randf_range(0.0, H * 0.5)
			d["v"] = 0.0
			d["attente"] = _rng.randf_range(0.6, 2.5)


func _dessiner_bulles() -> void:
	for p in _bulles:
		var r: float = p["r"]
		var x := float(p["x0"]) + sin(t * float(p["f"]) + float(p["ph"])) * (1.5 + r * 0.6)
		var y: float = p["y"]
		_normal.draw_texture_rect(TEX_BULLE, Rect2(x - r, y - r, 2.0 * r, 2.0 * r), false, Color(1, 1, 1, 0.45 + float(p["z"]) * 0.45))
	for q in _pops:
		var a := float(q["age"]) / 0.16
		_normal.draw_arc(Vector2(q["x"], q["y"]), float(q["r"]) * (1.0 + a * 1.4), 0.0, TAU, 20,
			Color(0.88, 0.98, 1.0, 0.6 * (1.0 - a)), 0.9 * s, true)


func _dessiner_gouttes() -> void:
	var tex := tex_point()
	for d in _gouttes:
		if d["attente"] > 0.0:
			continue
		var x := W - b * 0.5 if int(d["cote"]) == 1 else b * 0.5
		var y: float = d["y"]
		var tr := minf(30.0 * s, float(d["v"]) * 0.2)
		if tr > 0.5:
			draw_line(Vector2(x, y - tr), Vector2(x, y - tr * 0.5), Color(0.82, 0.96, 1.0, 0.18), 1.4 * s, true)
			draw_line(Vector2(x, y - tr * 0.5), Vector2(x, y), Color(0.82, 0.96, 1.0, 0.5), 1.4 * s, true)
		var sz := 6.0 * s
		draw_texture_rect(tex, Rect2(x - sz * 0.5, y - sz * 0.5, sz, sz), false, Color(0.82, 0.96, 1.0, 0.9))


# ─────────────────────────────────────────────────────────────
# GLACE — de la neige sur trois profondeurs, des rafales, du givre qui
# pousse depuis le cadre et scintille.
# ─────────────────────────────────────────────────────────────

func _init_glace() -> void:
	_dessine = true
	_givre = Node2D.new()
	_givre.draw.connect(_dessiner_givre)
	add_child(_givre)
	_recto_seul.append(_givre)
	_construire_givre()
	for i in maxi(1, int(round(84 * k))):
		_flocons.append(_naitre_flocon({}, true))
	_pro = _rng.randf_range(5.0, 8.0)


func _naitre_flocon(p: Dictionary, partout: bool) -> Dictionary:
	var r := _rng.randf()
	var z := _rng.randf_range(0.08, 0.35) if r < 0.55 else (_rng.randf_range(0.35, 0.7) if r < 0.88 else _rng.randf_range(0.72, 1.0))
	p["z"] = z
	p["x"] = _rng.randf_range(-o, W + o)
	p["y"] = _rng.randf_range(-o, H + o) if partout else -o * _rng.randf_range(0.6, 1.4)
	p["vy"] = (9.0 + z * 50.0) * s
	p["ph"] = _rng.randf_range(0.0, TAU)
	p["f"] = _rng.randf_range(0.6, 1.4)
	p["rot"] = _rng.randf_range(0.0, TAU)
	p["vr"] = _rng.randf_range(-1.0, 1.0)
	p["cristal"] = z > 0.35 and z < 0.72 and _rng.randf() < 0.45
	return p


func _pas_glace(dt: float) -> void:
	_pro -= dt
	if _pro <= 0.0:
		_pro = _rng.randf_range(6.0, 9.0)
		_rafale = 1.0
	_rafale = maxf(0.0, _rafale - dt * 0.7)
	var vent := (7.0 * sin(t * 0.21) + 38.0 * _rafale * _rafale) * s
	for p in _flocons:
		var z: float = p["z"]
		p["x"] += (vent * (0.35 + z) + cos(t * float(p["f"]) + float(p["ph"])) * (5.0 + z * 13.0) * s) * dt
		p["y"] += p["vy"] * dt
		p["rot"] += p["vr"] * dt
		if p["y"] > H + o * 0.6 or p["x"] > W + o * 1.2:
			_naitre_flocon(p, false)
	# le givre respire
	_givre.modulate = Color(1, 1, 1, 0.75 + 0.12 * sin(t * 0.7))


func _dessiner_neige() -> void:
	var doux := tex_point()
	for p in _flocons:
		var z: float = p["z"]
		var pos := Vector2(p["x"], p["y"])
		if z > 0.72:
			# les plus proches sont gros et flous : c'est la profondeur
			var sz := (6.0 + (z - 0.72) * 14.0) * s * 2.2
			_normal.draw_texture_rect(doux, Rect2(pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, Color(0.88, 0.93, 1.0, 0.42))
		elif p["cristal"]:
			var sc := (3.5 + z * 5.0) * s * 2.6
			_normal.draw_set_transform(pos, float(p["rot"]), Vector2.ONE)
			_normal.draw_texture_rect(TEX_FLOCON, Rect2(-sc * 0.5, -sc * 0.5, sc, sc), false, Color(1, 1, 1, 0.95))
			_normal.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var sd := (1.4 + z * 2.6) * s * 2.0
			_normal.draw_texture_rect(doux, Rect2(pos - Vector2(sd, sd) * 0.5, Vector2(sd, sd)), false, Color(1, 1, 1, 0.55 + z * 0.45))


# Le givre : des cristaux qui poussent depuis la bande du cadre vers l'intérieur,
# et s'effacent en avançant. Calculé une fois, dessiné une fois.
func _construire_givre() -> void:
	# Des tableaux ordinaires pendant la pousse (des références sûres), convertis
	# une seule fois à la fin : un trait par couple de points, une couleur par trait.
	var points := [[], [], [], []]
	var couleurs := [[], [], [], []]
	var dedans := b + W * 0.05
	var flou := W * 0.09
	var coins := _coins_t()
	for i in maxi(1, int(round(70 * k))):
		var tt := (float(coins[_rng.randi_range(0, 3)]) + _rng.randf_range(-0.035, 0.035)) if _rng.randf() < 0.4 else _rng.randf()
		var P := _bord(tt)
		var n: Vector2 = P[1]
		var depart: Vector2 = (P[0] as Vector2) + n * _rng.randf_range(-b * 0.4, b * 0.5)
		var pile := [[depart, atan2(-n.y, -n.x) + _rng.randf_range(-0.85, 0.85), _rng.randf_range(0.045, 0.1) * W, 3]]
		while pile.size() > 0:
			var br: Array = pile.pop_back()
			var x: Vector2 = br[0]
			var a: float = br[1]
			var l: float = br[2]
			var prof: int = br[3]
			if prof < 0 or l < 1.2:
				continue
			var x2 := x + Vector2(cos(a), sin(a)) * l
			var milieu := (x + x2) * 0.5
			var bord_proche := minf(minf(milieu.x, W - milieu.x), minf(milieu.y, H - milieu.y))
			var fondu := 1.0 - smoothstep(dedans - flou * 0.6, dedans + flou * 0.6, bord_proche)
			(points[prof] as Array).append(x)
			(points[prof] as Array).append(x2)
			(couleurs[prof] as Array).append(Color(0.894, 0.957, 1.0, (0.14 + prof * 0.09) * fondu))
			for j in range(1, 3):
				var f := j / 3.0
				pile.append([x + (x2 - x) * f, a + (1.0 if j % 2 == 1 else -1.0) * _rng.randf_range(0.55, 1.05), l * _rng.randf_range(0.32, 0.5), prof - 1])
			pile.append([x2, a + _rng.randf_range(-0.3, 0.3), l * _rng.randf_range(0.55, 0.72), prof - 1])
	_givre_traits = []
	for p in 4:
		_givre_traits.append([PackedVector2Array(points[p]), PackedColorArray(couleurs[p]), (0.45 + p * 0.32) * s])


func _dessiner_givre() -> void:
	for lot in _givre_traits:
		var pts: PackedVector2Array = lot[0]
		if pts.size() >= 2:
			_givre.draw_multiline_colors(pts, lot[1], float(lot[2]), true)


# ─────────────────────────────────────────────────────────────
# NATURE — des feuilles qui tournoient en tombant, des spores, des rais
# de soleil, des pousses aux quatre coins.
# ─────────────────────────────────────────────────────────────

func _init_nature() -> void:
	_dessine = true
	var ray := _rect(Vector2.ZERO, Vector2(W, H), SH_RAYONS)
	(ray.material as ShaderMaterial).set_shader_parameter("taille", Vector2(W, H))
	(ray.material as ShaderMaterial).set_shader_parameter("rayon", 4.6 * u)
	add_child(ray)
	_recto_seul.append(ray)
	var sp := _particules(26, true)
	sp.position = Vector2(W * 0.5, H * 0.5)
	sp.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sp.emission_rect_extents = Vector2(W * 0.5, H * 0.5)
	sp.direction = Vector2(0, -1)
	sp.spread = 25.0
	sp.gravity = Vector2.ZERO
	sp.initial_velocity_min = 4.0 * s
	sp.initial_velocity_max = 11.0 * s
	sp.lifetime = 12.0
	sp.lifetime_randomness = 0.5
	sp.scale_amount_min = 0.07 * s
	sp.scale_amount_max = 0.16 * s
	sp.color_ramp = _rampe([[0.0, Color(0.91, 0.965, 0.745, 0)], [0.15, Color(0.91, 0.965, 0.745, 0.75)],
		[0.85, Color(0.91, 0.965, 0.745, 0.6)], [1.0, Color(0.91, 0.965, 0.745, 0)]])
	sp.preprocess = 12.0
	add_child(sp)
	_recto_seul.append(sp)
	for i in maxi(1, int(round(18 * k))):
		_feuilles.append(_naitre_feuille({}, true))
	for c in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var base := atan2(-1.0 if c.y > 0.5 else 1.0, -1.0 if c.x > 0.5 else 1.0)
		for j in 4:
			_pousses.append({"c": c, "a": base + (j - 1.5) * 0.45 + _rng.randf_range(-0.12, 0.12),
				"l": _rng.randf_range(22.0, 34.0), "ph": _rng.randf_range(0.0, TAU), "teinte": j % 2})


func _naitre_feuille(p: Dictionary, partout: bool) -> Dictionary:
	var z := _rng.randf_range(0.8, 1.0) if _rng.randf() < 0.18 else _rng.randf_range(0.15, 0.7)
	p["z"] = z
	if partout:
		p["x"] = _rng.randf_range(-o, W)
		p["y"] = _rng.randf_range(-o, H)
	elif _rng.randf() < 0.6:
		p["x"] = _rng.randf_range(-o, W * 0.75)
		p["y"] = -o * _rng.randf_range(0.5, 1.0)
	else:
		p["x"] = -o * _rng.randf_range(0.5, 1.0)
		p["y"] = _rng.randf_range(-o, H * 0.55)
	p["vx"] = (8.0 + z * 22.0) * s
	p["vy"] = (11.0 + z * 26.0) * s
	p["rot"] = _rng.randf_range(0.0, TAU)
	p["vr"] = _rng.randf_range(-1.4, 1.4)
	p["fl"] = _rng.randf_range(1.5, 3.2)
	p["ph"] = _rng.randf_range(0.0, TAU)
	p["teinte"] = _rng.randi_range(0, 2)
	return p


func _pas_nature(dt: float) -> void:
	for p in _feuilles:
		p["x"] += (float(p["vx"]) + sin(t * 1.1 + float(p["ph"])) * 14.0 * s) * dt
		p["y"] += p["vy"] * dt
		p["rot"] += p["vr"] * dt
		if p["x"] > W + o or p["y"] > H + o:
			_naitre_feuille(p, false)


func _dessiner_feuilles() -> void:
	for p in _pousses:
		var c: Vector2 = p["c"]
		var pos := Vector2(W - b * 0.9 if c.x > 0.5 else b * 0.9, H - b * 0.9 if c.y > 0.5 else b * 0.9)
		var L := float(p["l"]) * s
		_normal.draw_set_transform(pos, float(p["a"]) + sin(t * 1.3 + float(p["ph"])) * 0.12, Vector2.ONE)
		_normal.draw_texture_rect(TEX_FEUILLE, Rect2(0.0, -L * 0.25, L, L * 0.5), false, TEINTES_FEUILLES[int(p["teinte"])])
	for p in _feuilles:
		var z: float = p["z"]
		var L := (10.0 + z * 20.0) * s
		# la feuille se retourne en tombant : on écrase sa hauteur au rythme de sa rotation
		var ecrase := maxf(0.16, absf(cos(t * float(p["fl"]) + float(p["ph"]))))
		_normal.draw_set_transform(Vector2(p["x"], p["y"]), float(p["rot"]), Vector2(1.0, ecrase))
		var col: Color = TEINTES_FEUILLES[int(p["teinte"])]
		col.a = 0.8 if z > 0.8 else 0.97
		_normal.draw_texture_rect(TEX_FEUILLE, Rect2(-L * 0.5, -L * 0.25, L, L * 0.5), false, col)
	_normal.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ─────────────────────────────────────────────────────────────
# ESPRIT — des feux follets en comètes, une brume fantôme dans l'image.
# ─────────────────────────────────────────────────────────────

func _init_esprit() -> void:
	_dessine = true
	var cr := _rect(art.position, art.size, SH_BRUME_ART)
	(cr.material as ShaderMaterial).set_shader_parameter("taille", art.size)
	(cr.material as ShaderMaterial).set_shader_parameter("rayon", 1.6 * u)
	add_child(cr)
	_recto_seul.append(cr)
	var teintes := [Color(0.843, 0.765, 1.0), Color(0.725, 0.922, 1.0), Color(0.902, 0.804, 1.0), Color(0.686, 0.882, 0.98)]
	for i in 4:
		_feux.append({"ax": _rng.randf_range(0.36, 0.56), "ay": _rng.randf_range(0.34, 0.52),
			"fx": _rng.randf_range(0.35, 0.6), "fy": _rng.randf_range(0.42, 0.7),
			"p1": _rng.randf_range(0.0, TAU), "p2": _rng.randf_range(0.0, TAU), "col": teintes[i], "trace": PackedVector2Array()})


func _pas_esprit(_dt: float) -> void:
	for f in _feux:
		var pos := Vector2(W * 0.5 + float(f["ax"]) * W * cos(t * float(f["fx"]) + float(f["p1"])),
			H * 0.5 + float(f["ay"]) * H * sin(t * float(f["fy"]) + float(f["p2"])))
		var tr: PackedVector2Array = f["trace"]
		tr.append(pos)
		if tr.size() > 48:
			tr.remove_at(0)
		f["trace"] = tr


func _dessiner_esprit() -> void:
	var tex := tex_point()
	var i := 0
	for f in _feux:
		var tr: PackedVector2Array = f["trace"]
		var n := tr.size()
		var col: Color = f["col"]
		for j in n:
			var q := (j + 1.0) / n
			var sz := (3.0 + q * 11.0) * s
			draw_texture_rect(tex, Rect2(tr[j] - Vector2(sz, sz), Vector2(sz, sz) * 2.0), false, Color(col, pow(q, 1.4) * 0.6))
		if n >= 2:
			var P := tr[n - 1]
			var ang := (P - tr[n - 2]).angle()
			var r := 18.0 * s * (0.8 + 0.2 * sin(t * 3.0 + i))
			# la flamme s'étire dans le sens de sa course : une comète, pas un point
			draw_set_transform(P, ang, Vector2(1.9, 1.0))
			draw_texture_rect(tex, Rect2(-r, -r, 2.0 * r, 2.0 * r), false, Color(col, 0.7))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var r2 := 3.6 * s
			draw_texture_rect(tex, Rect2(P - Vector2(r2, r2), Vector2(r2, r2) * 2.0), false, Color(1, 1, 1, 0.95))
		i += 1


# ─────────────────────────────────────────────────────────────
# OMBRE — une brume qui dérive tout autour du cadre, et s'épaissit par
# vagues. Elle reste de dos : c'est aussi ce qui trahit une ombre.
# ─────────────────────────────────────────────────────────────

func _init_ombre() -> void:
	var cr := _rect(Vector2(-o, -o), Vector2(W + 2.0 * o, H + 2.0 * o), SH_BRUME)
	_mat_brume = cr.material as ShaderMaterial
	_mat_brume.set_shader_parameter("taille", Vector2(W, H))
	_mat_brume.set_shader_parameter("marge", o)
	_mat_brume.set_shader_parameter("rayon", 4.6 * u)
	_mat_brume.set_shader_parameter("bande", b)
	add_child(cr)
	_pro = _rng.randf_range(4.0, 7.0)


func _pas_ombre(dt: float) -> void:
	_pro -= dt
	if _pro <= 0.0:
		_pro = _rng.randf_range(6.0, 9.0)
		_houle = 1.0
	_houle = maxf(0.0, _houle - dt * 0.5)
	_mat_brume.set_shader_parameter("houle", _houle)


# ─────────────────────────────────────────────────────────────
# PRISMATIQUE — des éclats de lumière s'allument sur le cadre (même de
# dos) et sur l'illustration.
# ─────────────────────────────────────────────────────────────

func _init_prisme() -> void:
	_dessine = true
	_pro = 0.2


func _pas_prisme(dt: float) -> void:
	_pro -= dt
	if _pro <= 0.0:
		_pro = _rng.randf_range(0.12, 0.42)
		var pos: Vector2
		if not recto or _rng.randf() < 0.5:
			var P := _bord(_rng.randf())
			pos = (P[0] as Vector2) + (P[1] as Vector2) * _rng.randf_range(-0.5, 0.5) * b
		else:
			pos = Vector2(_rng.randf_range(art.position.x, art.end.x), _rng.randf_range(art.position.y, art.end.y))
		_eclats.append({"pos": pos, "age": 0.0, "vie": _rng.randf_range(0.45, 0.9), "taille": _rng.randf_range(0.6, 1.3),
			"rot": PI / 4.0 if _rng.randf() < 0.3 else 0.0,
			# le full art scintille en blanc, partout sur la carte (son « art » est la carte entière)
			"col": Color.WHITE if kind == "full" else ARC[_rng.randi_range(0, ARC.size() - 1)]})
	for i in range(_eclats.size() - 1, -1, -1):
		_eclats[i]["age"] += dt
		if _eclats[i]["age"] > _eclats[i]["vie"]:
			_eclats.remove_at(i)


func _dessiner_prisme() -> void:
	var halo := tex_point()
	for e in _eclats:
		var a := float(e["age"]) / float(e["vie"])
		var v := sin(a * PI)
		var sz := (12.0 + 18.0 * float(e["taille"])) * s * (0.5 + 0.5 * v)
		var r := sz * 0.45
		var pos: Vector2 = e["pos"]
		draw_texture_rect(halo, Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(e["col"], v * 0.55))
		draw_set_transform(pos, float(e["rot"]) + a * 0.6, Vector2.ONE)
		draw_texture_rect(TEX_ETOILE, Rect2(-sz * 0.5, -sz * 0.5, sz, sz), false, Color(1, 1, 1, v))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
