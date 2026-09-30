class_name BarreNav
extends Control

# LA BARRE DU BAS (FEATURES ⑮, 26/09 — choisie par Maxim : « Médaillons », noms « Céleste »).
# Un rail gravé comme le bord d'un astrolabe porte cinq médaillons d'émail sertis d'or. L'onglet
# actif se soulève, passe au jade, s'allume d'une étoile nette et montre son nom dans un cartouche ;
# les autres restent muets. Les menus pas encore construits sont visibles mais SCELLÉS : éteints,
# un cadenas, et ils disent quand ils s'ouvriront (28/09 : le dernier, l'Astrolabe, s'est ouvert ; le
# mécanisme reste pour un sixième menu).
# 🔴 L'actif un peu plus petit que sur le premier canevas (54 au lieu de 62, ×3 ici) : Maxim, 26/09,
#    « peur que ça encombre trop l'écran sur les petits écrans ».

signal aller(id: String)
signal appui_long(id: String)

const ONGLETS := [
	{"id": "nebuleuse", "nom": "Nébuleuse", "ouvert": true},
	{"id": "astrolabe", "nom": "Astrolabe", "ouvert": true},    # les portails d'invocation (28/09, ⑩)
	{"id": "atlas", "nom": "Atlas", "ouvert": true},
	{"id": "voyage", "nom": "Voyage", "ouvert": true},
	{"id": "presages", "nom": "Présages", "ouvert": true},      # les défis du jour (28/09, ⑧)
]
const HAUT := 240.0
const MARGE := 36.0
const MED := 132.0
const MED_ACTIF := 162.0
const Y_MED := 78.0
const Y_MED_ACTIF := 0.0
const APPUI_LONG_S := 0.8

const SH_GRIS := "shader_type canvas_item;\nuniform float gris = 0.0;\nuniform float lum = 1.0;\nvoid fragment() {\n\tvec4 c = COLOR;\n\tfloat l = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(c.rgb, vec3(l), gris) * lum, c.a);\n}\n"

var actif := ""
var _tabs := {}
var _minuteur: Timer
var _appui_id := ""


func _ready() -> void:
	position = Vector2(0, 2400 - HAUT)
	size = Vector2(1080, HAUT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fond := TextureRect.new()
	fond.texture = Style.degrade(PackedColorArray([Color(0.059, 0.082, 0.075, 0.0), Color(0.059, 0.082, 0.075, 0.97),
		Color(0.027, 0.035, 0.031, 1.0)]), PackedFloat32Array([0.0, 0.14, 1.0]))
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.size = size
	fond.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fond)
	var rail := Control.new()
	rail.size = size
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.draw.connect(func():
		rail.draw_line(Vector2(0, 36), Vector2(1080, 36), Style.OR_FILET, 3.0)
		var x := 0.0
		while x < 1080.0:
			rail.draw_line(Vector2(x, 45), Vector2(x, 60), Color(0.81, 0.68, 0.43, 0.5), 2.0)
			x += 24.0)
	add_child(rail)
	var sh := Shader.new()
	sh.code = SH_GRIS
	var col := (1080.0 - 2.0 * MARGE) / ONGLETS.size()
	for i in ONGLETS.size():
		var o: Dictionary = ONGLETS[i]
		var id: String = o["id"]
		var cx := MARGE + (i + 0.5) * col
		var b := Button.new()
		b.flat = true
		b.position = Vector2(cx - col * 0.5, 0)
		b.size = Vector2(col, HAUT)
		for etat in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			b.add_theme_stylebox_override(etat, StyleBoxEmpty.new())
		add_child(b)
		var med := Control.new()
		med.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(med)
		var sombre := _image(med, "res://interface/medaillon-sombre.png")
		var jade := _image(med, "res://interface/medaillon-jade.png")
		jade.modulate.a = 0.0
		var emb := _image(med, "res://interface/nav-%s.png" % id)
		var mat := ShaderMaterial.new()
		mat.shader = sh
		emb.material = mat
		var etoile := Control.new()
		etoile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		etoile.size = Vector2(60, 60)
		etoile.draw.connect(func():
			var t := Effets.maintenant()
			Effets.dessiner_etoile(etoile, Vector2(30, 30), 24.0 * (0.92 + 0.1 * sin(t * 2.4)), etoile.modulate.a, 0.12 * sin(t * 1.3)))
		med.add_child(etoile)
		var lib := Label.new()
		lib.text = str(o["nom"]).to_upper()
		lib.add_theme_font_override("font", Style.police("etiquette", 4))
		lib.add_theme_font_size_override("font_size", 25)
		lib.add_theme_color_override("font_color", Style.OR_VIF)
		var sb := Style.boite(Color("#0b100e"), 15, Style.OR_FILET, 3)
		sb.content_margin_left = 21
		sb.content_margin_right = 21
		sb.content_margin_top = 7
		sb.content_margin_bottom = 5
		lib.add_theme_stylebox_override("normal", sb)
		lib.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lib)
		lib.size = lib.get_minimum_size()
		lib.position = Vector2((col - lib.size.x) * 0.5, HAUT - 15.0 - lib.size.y)
		lib.modulate.a = 0.0
		var cadenas: Control = null
		if not o.get("ouvert", false):
			cadenas = Control.new()
			cadenas.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cadenas.size = Vector2(33, 36)
			cadenas.draw.connect(func():
				var c := Color("#8f9994")
				cadenas.draw_rect(Rect2(3, 15, 27, 19), c, true)
				cadenas.draw_arc(Vector2(16.5, 15), 8.0, PI, TAU, 16, c, 4.0, true))
			b.add_child(cadenas)
		_tabs[id] = {"b": b, "med": med, "sombre": sombre, "jade": jade, "emb": emb, "mat": mat, "etoile": etoile,
			"lib": lib, "cadenas": cadenas, "cx": col * 0.5, "ouvert": o.get("ouvert", false), "scelle": o.get("scelle", "")}
		b.pressed.connect(_toucher.bind(id))
		b.button_down.connect(func():
			_appui_id = id
			_minuteur.start())
		b.button_up.connect(func(): _minuteur.stop())
		Style.jeu(b, med)
		_placer(id, false)
	_minuteur = Timer.new()
	_minuteur.one_shot = true
	_minuteur.wait_time = APPUI_LONG_S
	_minuteur.timeout.connect(func(): appui_long.emit(_appui_id))
	add_child(_minuteur)
	set_process(true)


func _image(parent: Control, chemin: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Style.texture(chemin)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _process(_d: float) -> void:
	# l'étoile de l'onglet actif scintille ; les points d'or battent
	if _tabs.has(actif):
		(_tabs[actif]["etoile"] as Control).queue_redraw()
	for id in _tabs:
		var t: Dictionary = _tabs[id]
		if t.has("point") and (t["point"] as Control).visible:
			(t["point"] as Control).queue_redraw()


func _toucher(id: String) -> void:
	var t: Dictionary = _tabs[id]
	if not bool(t["ouvert"]):
		Style.bulle(t["med"], str(t["scelle"]))
		Son.sonner("refus")
		return
	if id == actif:
		return
	Son.sonner("onglet")
	montrer(id)
	aller.emit(id)


# Le point d'un onglet : quelque chose l'attend (les Présages : un défi à recevoir). Il suit le médaillon.
func marquer(id: String, oui: bool) -> void:
	if not _tabs.has(id):
		return
	var t: Dictionary = _tabs[id]
	if not t.has("point"):
		var point := Control.new()
		point.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var med: Control = t["med"]
		# (29/09, « le point d'or manque un peu de visibilité ») : plus gros, cerclé de sombre, et un anneau net qui
		# s'élargit toutes les 1,5 s — pas de halo
		point.draw.connect(func():
			var dd: float = med.size.x
			point.size = med.size
			var c := Vector2(dd * 0.86, dd * 0.14)
			var k := fmod(Time.get_ticks_msec() / 1000.0, 1.5) / 1.5
			point.draw_arc(c, lerpf(dd * 0.14, dd * 0.34, sqrt(k)), 0.0, TAU, 40, Color(Style.OR_VIF, 0.9 * (1.0 - k)), 3.0, true)
			point.draw_circle(c, dd * 0.17, Color("#1a1208"))
			point.draw_circle(c, dd * 0.14, Style.OR_VIF)
			point.draw_circle(c + Vector2(-dd * 0.04, -dd * 0.04), dd * 0.035, Color(1, 1, 1, 0.85)))
		med.add_child(point)
		t["point"] = point
	var p: Control = t["point"]
	p.visible = oui
	p.queue_redraw()


# Là où est un onglet, à l'écran (l'accueil du premier pack le montre du doigt).
func rect_onglet(id: String) -> Rect2:
	return (_tabs[id]["b"] as Control).get_global_rect()


# L'onglet actif (sans rien émettre) : le médaillon se soulève, passe au jade, prend son étoile.
func montrer(id: String) -> void:
	var avant := actif
	actif = id
	for k in _tabs:
		if k == id or k == avant:
			_placer(k, avant != "")


func _placer(id: String, anime: bool) -> void:
	var t: Dictionary = _tabs[id]
	var est := id == actif
	var d := MED_ACTIF if est else MED
	var y := Y_MED_ACTIF if est else Y_MED
	var med: Control = t["med"]
	var cx: float = t["cx"]
	var cible_pos := Vector2(cx - d * 0.5, y)
	var e := 108.0 if est else 90.0
	var gris := 0.0 if est else (0.7 if bool(t["ouvert"]) else 1.0)
	var lum := 1.0 if est else (0.62 if bool(t["ouvert"]) else 0.32)
	var mat: ShaderMaterial = t["mat"]
	mat.set_shader_parameter("gris", gris)
	mat.set_shader_parameter("lum", lum)
	var poser := func(pos: Vector2, dd: float, ee: float):
		med.position = pos
		med.size = Vector2(dd, dd)
		med.pivot_offset = med.size * 0.5
		for n in [t["sombre"], t["jade"]]:
			(n as TextureRect).position = Vector2.ZERO
			(n as TextureRect).size = Vector2(dd, dd)
		var emb: TextureRect = t["emb"]
		emb.size = Vector2(ee, ee)
		emb.position = Vector2((dd - ee) * 0.5, (dd - ee) * 0.5)
		var et: Control = t["etoile"]
		et.position = Vector2(dd * 0.5 - 30.0, -34.0)
		var cad = t["cadenas"]
		if cad != null:
			(cad as Control).position = pos + Vector2(dd * 0.5 + 18.0, dd - 40.0)
	if not anime:
		poser.call(cible_pos, d, e)
		(t["jade"] as TextureRect).modulate.a = 1.0 if est else 0.0
		(t["etoile"] as Control).modulate.a = 1.0 if est else 0.0
		(t["lib"] as Label).modulate.a = 1.0 if est else 0.0
		return
	var de_pos := med.position
	var de_d := med.size.x
	var de_e := (t["emb"] as TextureRect).size.x
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(k: float): poser.call(de_pos.lerp(cible_pos, k), lerpf(de_d, d, k), lerpf(de_e, e, k)), 0.0, 1.0, 0.38) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(t["jade"], "modulate:a", 1.0 if est else 0.0, 0.25)
	tw.tween_property(t["etoile"], "modulate:a", 1.0 if est else 0.0, 0.25)
	tw.tween_property(t["lib"], "modulate:a", 1.0 if est else 0.0, 0.2)
