class_name Evolution
extends Control

# L'ÉVOLUTION, EN PLEIN ÉCRAN (FEATURES ⑮, 26/09 — le canevas v3, validé par Maxim : « juste
# génial »). La pierre, EN 3D (le même volume que dans la machine, Volumes), arrive en tournant
# et se pose sur la carte ; elle y reste deux secondes et vibre de plus en plus fort ; elle éclate
# en poussière qui tourbillonne et entre dans la carte ; la carte devient blanche, des étoiles
# filantes et des constellations d'or passent ; puis le blanc s'évapore en poussière d'or et
# dévoile le nouveau stade. Toucher l'écran passe tout ; une fois fini, toucher ferme.
# ⛔ Pas d'étoile au dévoilement (Maxim, 26/09 : « enlève l'étoile qui apparaît »), ni halo, ni fissure.

signal fini

const LARGEUR := 720.0
const CENTRE := Vector2(540, 1180)
const SW := 64
const SHH := 90
const BANDE := 0.03

var h: Dictionary
var stade_neuf := 2
var variante := "base"
var pierre := "lune"

var boite: Control
var carte: CarteView
var blanc: ColorRect
var mat_blanc: ShaderMaterial
var vue: SubViewport
var gemme: MeshInstance3D
var ecran_pierre: TextureRect
var fx: Effets
var titre: Label
var nom: Label
var legende: Label

var _passe := false
var _fini := false
var _tweens: Array = []
var _tourne := 1.0
var _tremble := 0.0
var _angle := 0.0
var _vibre := false
var _vibre_t0 := 0.0
var _evap := false
var _evap_t0 := 0.0
var _seuils := PackedFloat32Array()
var _pierre_pos := Vector2.ZERO
var _boite_pos := Vector2.ZERO


func lancer(p_h: Dictionary, ancien_stade: int, p_stade_neuf: int, p_variante: String, p_pierre: String) -> void:
	h = p_h
	stade_neuf = p_stade_neuf
	variante = p_variante
	pierre = p_pierre
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.03, 0.028, 0.95)
	voile.size = size
	voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(voile)
	var haut := CENTRE.y - LARGEUR * 0.7
	titre = Style.libelle(self, "ÉVOLUTION", Rect2(0, haut - 214, 1080, 44), "etiquette", 39, Style.OR_FILET, HORIZONTAL_ALIGNMENT_CENTER, 8)
	nom = Style.libelle(self, str(h["nom"]), Rect2(0, haut - 164, 1080, 100), "normal", 90, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	nom.pivot_offset = Vector2(540, 50)
	boite = Control.new()
	boite.size = Vector2(LARGEUR, LARGEUR * 1.4)
	boite.position = CENTRE - boite.size * 0.5
	boite.pivot_offset = boite.size * 0.5
	boite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boite_pos = boite.position
	add_child(boite)
	carte = CarteView.new()
	boite.add_child(carte)
	carte.configurer(h, ancien_stade, variante, LARGEUR, true)
	blanc = ColorRect.new()
	blanc.size = boite.size
	blanc.color = Color.WHITE
	blanc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat_blanc = ShaderMaterial.new()
	mat_blanc.shader = preload("res://interface/evaporation.gdshader")
	mat_blanc.set_shader_parameter("taille", boite.size)
	mat_blanc.set_shader_parameter("t", -1.0)
	mat_blanc.set_shader_parameter("seuils", _faire_seuils())
	blanc.material = mat_blanc
	blanc.modulate.a = 0.0
	boite.add_child(blanc)
	_pierre_3d()
	fx = Effets.new()
	fx.size = size
	add_child(fx)
	legende = Style.libelle(self, "Touche l'écran pour passer", Rect2(0, 2250, 1080, 60), "italique", 42, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	gui_input.connect(_toucher)
	_derouler()


# La pierre en 3D : son volume et sa matière, dans une petite vue à part (une caméra au-dessus).
func _pierre_3d() -> void:
	vue = SubViewport.new()
	vue.size = Vector2i(512, 512)
	vue.transparent_bg = true
	vue.own_world_3d = true
	vue.msaa_3d = Viewport.MSAA_4X
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vue)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0, 4.6, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	vue.add_child(cam)
	var nom_image := "pierre-" + pierre
	var d := Volumes.objet(nom_image)
	gemme = MeshInstance3D.new()
	if not d.is_empty():
		gemme.mesh = Volumes.volume(d["contour"], d["disque"], 1.0, 0.3)
	gemme.material_override = Volumes.matiere(nom_image, 0.0)
	vue.add_child(gemme)
	ecran_pierre = TextureRect.new()
	ecran_pierre.texture = vue.get_texture()
	ecran_pierre.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ecran_pierre.stretch_mode = TextureRect.STRETCH_SCALE
	ecran_pierre.size = Vector2(470, 470)
	ecran_pierre.pivot_offset = ecran_pierre.size * 0.5
	ecran_pierre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ecran_pierre.visible = false
	add_child(ecran_pierre)
	_pierre_pos = CENTRE - ecran_pierre.size * 0.5


# Où le blanc part en premier : un bruit doux à deux octaves, le centre d'abord.
func _faire_seuils() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var grilles := []
	for n in [6, 17]:
		var g := PackedFloat32Array()
		for i in (n + 2) * (n + 2):
			g.append(rng.randf())
		grilles.append([n, g])
	_seuils.resize(SW * SHH)
	var mn := 9.0
	var mx := -9.0
	for y in SHH:
		for x in SW:
			var u := (x + 0.5) / SW
			var v := (y + 0.5) / SHH
			var s := 0.55 * _doux(grilles[0], u, v) + 0.2 * _doux(grilles[1], u, v)
			s += 0.4 * Vector2(u - 0.5, (v - 0.5) * 1.4).length() / 0.86
			_seuils[y * SW + x] = s
			mn = minf(mn, s)
			mx = maxf(mx, s)
	# 🔴 8 bits, pas de flottants : WebGL ne lisse pas une texture en flottants 32 bits (elle se lit à 0)
	var img := Image.create(SW, SHH, false, Image.FORMAT_L8)
	for y in SHH:
		for x in SW:
			var s := (_seuils[y * SW + x] - mn) / (mx - mn)
			_seuils[y * SW + x] = s
			img.set_pixel(x, y, Color(s, s, s))
	return ImageTexture.create_from_image(img)


static func _doux(gr: Array, u: float, v: float) -> float:
	var n: int = gr[0]
	var g: PackedFloat32Array = gr[1]
	var w := n + 2
	var fx_ := u * n
	var fy := v * n
	var ix := int(floor(fx_))
	var iy := int(floor(fy))
	var tx := fx_ - ix
	var ty := fy - iy
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var a := g[iy * w + ix]
	var b := g[iy * w + ix + 1]
	var c := g[(iy + 1) * w + ix]
	var d := g[(iy + 1) * w + ix + 1]
	return a + (b - a) * tx + (c - a) * ty + (a - b - c + d) * tx * ty


func _seuil(u: float, v: float) -> float:
	var x := clampi(int(u * SW), 0, SW - 1)
	var y := clampi(int(v * SHH), 0, SHH - 1)
	return _seuils[y * SW + x]


func _tw() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


func _attendre(s: float) -> bool:
	if _passe:
		return true
	await get_tree().create_timer(s).timeout
	return _passe


func _couleurs_pierre() -> Array:
	if pierre == "lune":
		return [Color("#b8ccff"), Color("#e8f0ff"), Style.OR_VIF, Color.WHITE]
	var ty: Dictionary = GS.TYPES.get(pierre, GS.TYPES["aucun"])
	return [ty["elt"], ty["clair"], Style.OR_VIF, ty["clair"]]


func _derouler() -> void:
	modulate.a = 0.0
	_tw().tween_property(self, "modulate:a", 1.0, 0.26)
	boite.scale = Vector2(0.9, 0.9)
	_tw().tween_property(boite, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if await _attendre(0.5):
		return
	# 1. la pierre arrive en tournant et se pose au centre de la carte
	ecran_pierre.visible = true
	ecran_pierre.position = Vector2(_pierre_pos.x, 2500)
	ecran_pierre.scale = Vector2(0.55, 0.55)
	var tw := _tw().set_parallel(true)
	tw.tween_property(ecran_pierre, "position", _pierre_pos, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ecran_pierre, "scale", Vector2.ONE, 0.82).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if await _attendre(0.6):
		return
	# l'élan retombe : la pierre finit face à nous
	var de := _angle
	var vers := roundf(_angle / TAU) * TAU + TAU
	_tourne = 0.0
	_tw().tween_method(func(k: float): _angle = lerpf(de, vers, k), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if await _attendre(0.22):
		return
	var tb := _tw()
	tb.tween_property(boite, "scale", Vector2(0.975, 0.975), 0.1)
	tb.tween_property(boite, "scale", Vector2.ONE, 0.12)
	for i in 5:
		fx.etoile(CENTRE + Vector2(randf_range(-220, 220), randf_range(-220, 220)), randf_range(21, 36), 0.48, i * 0.05)
	# 2. elle reste deux secondes et vibre de plus en plus fort
	_vibre = true
	_vibre_t0 = Effets.maintenant()
	if await _attendre(2.0):
		return
	_vibre = false
	_tremble = 0.0
	boite.position = _boite_pos
	# 3. elle éclate en poussière, qui tourbillonne et entre dans la carte
	ecran_pierre.visible = false
	Son.sonner("choc", 2.0, -5.0)            # (29/09) la pierre éclate
	var couls := _couleurs_pierre()
	for g in 170:
		var an := randf() * TAU
		var d2 := LARGEUR * randf_range(0.35, 0.9)
		var tour := an + 1.6
		fx.grain(CENTRE + Vector2(randf_range(-24, 24), randf_range(-24, 24)), CENTRE + Vector2.from_angle(an) * d2 * 1.5,
			CENTRE + Vector2.from_angle(tour) * LARGEUR * 0.1, randf_range(0.8, 1.25), randf() * 0.12, couls[g % 4],
			randf_range(0.8, 1.6), Callable(), true, true)
	for j in 8:
		fx.etoile(CENTRE + Vector2(randf_range(-180, 180), randf_range(-180, 180)), randf_range(30, 54), 0.52, j * 0.03)
	if await _attendre(0.42):
		return
	# 4. la carte devient blanche ; des étoiles filantes et des constellations d'or passent
	Son.sonner("portail")
	_tw().tween_property(blanc, "modulate:a", 1.0, 0.65)
	_tw().tween_property(boite, "scale", Vector2(1.04, 1.04), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var ch := LARGEUR * 1.4
	for f in 9:
		var y1 := CENTRE.y - ch * 0.7 + randf() * ch * 1.1
		fx.filante(Vector2(-120 + randf() * 180, y1), Vector2(1200, y1 + randf_range(270, 630)), randf_range(330, 510), randf_range(0.9, 1.3), 0.25 + f * 0.19)
	var bords := [Vector2(-0.78, -0.42), Vector2(0.8, -0.3), Vector2(-0.82, 0.3), Vector2(0.78, 0.42), Vector2(0, -0.66), Vector2(-0.1, 0.68)]
	for i in bords.size():
		var b: Vector2 = bords[i]
		var o := CENTRE + Vector2(b.x * (LARGEUR * 0.5 + 60.0), b.y * ch)
		var pts: Array = []
		for q in 4 + (i % 2):
			pts.append(o + Vector2(randf_range(-135, 135), randf_range(-120, 120)))
		pts.sort_custom(func(p1: Vector2, p2: Vector2): return p1.x < p2.x)
		fx.constellation(PackedVector2Array(pts), 2.1, 0.2 + i * 0.15, Color("#e8c877"), 3.0, Style.OR_VIF)
	if await _attendre(0.7):
		return
	# sous le blanc, la carte a déjà changé de stade
	carte.configurer(h, stade_neuf, variante, LARGEUR, true)
	if await _attendre(1.2):
		return
	# 5. le blanc s'évapore en poussière d'or et dévoile la carte
	Son.sonner("evolution")
	_evap = true
	_evap_t0 = Effets.maintenant()
	if await _attendre(1.8):
		return
	_evap = false
	blanc.visible = false
	_tw().tween_property(boite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_nom_final()
	if await _attendre(0.6):
		return
	legende.text = "Touche l'écran pour fermer"
	_fini = true


func _nom_final() -> void:
	var formes: Array = h["formes"]
	nom.text = "%s · %s" % [h["nom"], formes[clampi(stade_neuf - 1, 0, formes.size() - 1)]]
	# un nom long rétrécit pour tenir dans l'écran
	var large := Style.police("normal").get_string_size(nom.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 90).x
	nom.add_theme_font_size_override("font_size", mini(90, int(90.0 * 960.0 / maxf(large, 1.0))))
	var tn := _tw()
	tn.tween_property(nom, "scale", Vector2(1.12, 1.12), 0.12)
	tn.tween_property(nom, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if gemme != null and ecran_pierre.visible:
		_angle += delta * 6.5 * _tourne
		var tilt := 0.25 + 0.35 * _tourne + randf_range(-0.08, 0.08) * _tremble
		gemme.basis = Basis(Vector3.RIGHT, tilt) * Basis(Vector3.UP, _angle) * Basis(Vector3.FORWARD, randf_range(-0.08, 0.08) * _tremble)
	if _vibre:
		var t := clampf((Effets.maintenant() - _vibre_t0) / 2.0, 0.0, 1.0)
		var a := (0.4 + 7.0 * t * t) * 3.0
		_tremble = t * t
		ecran_pierre.position = _pierre_pos + Vector2(randf_range(-a, a), randf_range(-a, a))
		ecran_pierre.scale = Vector2.ONE * (1.0 + 0.08 * t)
		var lum := 1.0 + 0.8 * t
		ecran_pierre.modulate = Color(lum, lum, lum)
		boite.position = _boite_pos + Vector2(randf_range(-a, a) * 0.3, 0)
		if randf() < 0.08 + 0.35 * t:
			fx.etoile(CENTRE + Vector2.from_angle(randf() * TAU) * LARGEUR * randf_range(0.32, 0.52), randf_range(9, 21), 0.36)
	if _evap:
		var k := clampf((Effets.maintenant() - _evap_t0) / 1.8, 0.0, 1.0)
		var T := -0.04 + 1.1 * Effets.lisse(k)
		mat_blanc.set_shader_parameter("t", T)
		var ech := boite.scale.x
		var pris := 0
		for essai in 260:
			if pris >= 16:
				break
			var u := randf()
			var v := randf()
			var s := _seuil(u, v)
			if s >= T and s < T + BANDE:
				pris += 1
				var p := CENTRE + Vector2((u - 0.5) * LARGEUR, (v - 0.5) * LARGEUR * 1.4) * ech
				var dx := randf_range(-0.5, 0.5)
				fx.grain(p, p + Vector2(dx * 120, -72 - randf() * 90), p + Vector2(dx * 270, -180 - randf() * 210), randf_range(0.7, 1.2), 0.0,
					Style.OR_VIF if randf() < 0.7 else Color("#fff3cf"), randf_range(0.6, 1.3), Callable(), true, true)


func _toucher(ev: InputEvent) -> void:
	var b := ev as InputEventMouseButton
	if b == null or not b.pressed or b.button_index != MOUSE_BUTTON_LEFT:
		return
	if _fini:
		_fini = false
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.22)
		tw.tween_callback(func():
			fini.emit()
			queue_free())
		return
	# passer tout : l'état final, tout de suite
	_passe = true
	for tw in _tweens:
		if (tw as Tween).is_valid():
			(tw as Tween).kill()
	_vibre = false
	_evap = false
	fx.vider()
	modulate.a = 1.0
	ecran_pierre.visible = false
	blanc.visible = false
	boite.scale = Vector2.ONE
	boite.position = _boite_pos
	carte.configurer(h, stade_neuf, variante, LARGEUR, true)
	_nom_final()
	legende.text = "Touche l'écran pour fermer"
	_fini = true
