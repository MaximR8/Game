class_name Bandeau
extends Control

# LE BANDEAU DU HAUT (FEATURES ⑮, 26/09 — choisi par Maxim : « Constellations »).
# Trois compteurs à même le ciel — les étoiles d'invocation, la poussière d'étoile, les pierres —
# reliés par un trait de constellation. Des chiffres d'or cerclés de sombre, qui défilent quand
# ils changent. Les pierres sont comptées ensemble ; la case montre la dernière gagnée, et la
# toucher ouvre la bourse (le compte de chacune).
#
# 🔴 Un objet gagné sur le plateau s'envole jusqu'ici (plus de fenêtre « Gagné ») : la poussette
#    RETIENT le gain le temps du vol (retenir), puis le compteur le reçoit (recevoir) et défile.

const CLES := ["etoiles", "poussiere", "pierres"]
const IMAGES := {"etoiles": "etoile-invocation", "poussiere": "poussiere-etoile", "pierres": "pierre-lune"}
const LIBELLES := {"etoiles": "ÉTOILES", "poussiere": "POUSSIÈRE", "pierres": "PIERRES"}
const X0 := 36.0
const COL := 336.0
const HAUT := 36.0

var _icone := {}
var _chiffre := {}
var _affiche := {}
var _retenu := {"etoiles": 0, "poussiere": 0, "pierres": 0}
var _roule := {}
var bourse: Control
var _bourse_grille: GridContainer
var _minuteur_bourse: SceneTreeTimer


func _ready() -> void:
	size = Vector2(1080, 222)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fond := TextureRect.new()
	fond.texture = Style.degrade(PackedColorArray([Color(0.035, 0.047, 0.043, 0.97), Color(0.035, 0.047, 0.043, 0.97),
		Color(0.035, 0.047, 0.043, 0.0)]), PackedFloat32Array([0.0, 0.72, 1.0]))
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.size = size
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	var liens := Control.new()
	liens.size = size
	liens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	liens.draw.connect(_dessiner_liens.bind(liens))
	add_child(liens)
	for i in CLES.size():
		var cle: String = CLES[i]
		var x := X0 + COL * i
		var ico := Style.icone(self, Style.objet(IMAGES[cle]), Rect2(x, HAUT, 90, 90))
		ico.pivot_offset = Vector2(45, 45)
		_icone[cle] = ico
		var ch := Style.libelle(self, "", Rect2(x + 111, HAUT - 4, 220, 66), "normal", 57, Style.OR_VIF)
		ch.add_theme_color_override("font_outline_color", Color("#1a1208"))
		ch.add_theme_constant_override("outline_size", 10)
		ch.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		ch.add_theme_constant_override("shadow_offset_y", 4)
		ch.pivot_offset = Vector2(0, 33)
		_chiffre[cle] = ch
		Style.libelle(self, LIBELLES[cle], Rect2(x + 113, HAUT + 60, 220, 30), "etiquette", 21, Style.OR_FILET,
			HORIZONTAL_ALIGNMENT_LEFT, 5)
	# la case des pierres s'ouvre sur la bourse
	var touche := Button.new()
	touche.flat = true
	touche.position = Vector2(X0 + COL * 2 - 12, HAUT - 12)
	touche.size = Vector2(COL, 114)
	for etat in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		touche.add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	touche.pressed.connect(basculer_bourse)
	add_child(touche)
	Style.jeu(touche, _icone["pierres"])
	_construire_bourse()
	GS.changed.connect(_maj)
	for cle in CLES:
		_affiche[cle] = _valeur(cle)
		(_chiffre[cle] as Label).text = Style.nombre(_affiche[cle])
	_icone_pierres()


func _valeur(cle: String) -> int:
	match cle:
		"etoiles":
			return GS.etoiles
		"poussiere":
			return GS.poussiere
	return GS.total_pierres()


# Le trait de constellation, fin, sous les trois compteurs (entre eux, il touchait les chiffres).
func _dessiner_liens(c: Control) -> void:
	var col := Color(0.81, 0.68, 0.43, 0.38)
	var pts := PackedVector2Array([Vector2(40, 152), Vector2(300, 170), Vector2(560, 150), Vector2(818, 172), Vector2(1040, 154)])
	c.draw_polyline(pts, col, 2.0, true)
	for k in [1, 3]:
		Effets.dessiner_etoile(c, pts[k], 12.0, 0.85)


# Un changement qui ne vient pas d'un vol (une invocation dépense des étoiles, une carte monte) :
# le compteur défile tout de suite.
func _maj() -> void:
	for cle in CLES:
		var cible := _valeur(cle) - int(_retenu[cle])
		if cible != int(_affiche[cle]):
			_rouler(cle, cible)
	if bourse.visible:
		_remplir_bourse()


func _rouler(cle: String, cible: int) -> void:
	var de := int(_affiche[cle])
	_affiche[cle] = cible
	var lbl: Label = _chiffre[cle]
	if _roule.has(cle) and (_roule[cle] as Tween).is_valid():
		(_roule[cle] as Tween).kill()
	var tw := create_tween()
	tw.tween_method(func(v: float): lbl.text = Style.nombre(int(round(v))), float(de), float(cible), 0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_roule[cle] = tw


# Le gain d'un objet en vol : le compteur l'attend (il ne bouge pas encore).
func retenir(cle: String, n: int) -> void:
	_retenu[cle] = int(_retenu[cle]) + n


# L'objet est arrivé : le compteur le reçoit, défile, l'icône bondit, « +n » monte, des étincelles.
func recevoir(cle: String, n: int, image := "") -> void:
	_retenu[cle] = maxi(0, int(_retenu[cle]) - n)
	if cle == "pierres" and image != "":
		(_icone["pierres"] as TextureRect).texture = Style.objet(image)
	_rouler(cle, _valeur(cle) - int(_retenu[cle]))
	var ico: TextureRect = _icone[cle]
	var tw := ico.create_tween()
	tw.tween_property(ico, "scale", Vector2(1.32, 1.32), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ico, "scale", Vector2(0.94, 0.94), 0.12)
	tw.tween_property(ico, "scale", Vector2.ONE, 0.16)
	Effets.global.etincelles(ico.get_global_rect().grow(-10), 3, 16.0)
	var lbl: Label = _chiffre[cle]
	var plus := Style.libelle(self, "+%s" % Style.nombre(n), Rect2(lbl.position.x + lbl.get_minimum_size().x + 14, lbl.position.y + 6, 200, 50),
		"normal", 40, Style.OR_VIF)
	plus.add_theme_color_override("font_outline_color", Color("#1a1208"))
	plus.add_theme_constant_override("outline_size", 8)
	plus.modulate.a = 0.0
	var tp := plus.create_tween().set_parallel(true)
	tp.tween_property(plus, "modulate:a", 1.0, 0.2)
	tp.tween_property(plus, "position:y", plus.position.y - 36.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tp.chain().tween_property(plus, "modulate:a", 0.0, 0.3)
	tp.chain().tween_callback(plus.queue_free)


# Le centre de l'icône d'un compteur, là où atterrit ce qui s'envole (coordonnées du jeu).
func centre_icone(cle: String) -> Vector2:
	return (_icone[cle] as TextureRect).get_global_rect().get_center()


# L'icône des pierres : la pierre qu'on a le plus, sinon la lune (puis la dernière gagnée).
func _icone_pierres() -> void:
	var meilleure := "lune"
	var n := 0
	for t in GS.pierres:
		if int(GS.pierres[t]) > n:
			n = int(GS.pierres[t])
			meilleure = str(t)
	(_icone["pierres"] as TextureRect).texture = Style.objet("pierre-" + meilleure)


# ─────────────────────────────────────────────────────────────
# La bourse de pierres
# ─────────────────────────────────────────────────────────────

func _construire_bourse() -> void:
	bourse = Style.panneau(self, Rect2(1080 - 27 - 696, 214, 696, 360), Color(0.05, 0.07, 0.06, 0.98), 36)
	bourse.visible = false
	bourse.mouse_filter = Control.MOUSE_FILTER_STOP
	Style.libelle(bourse, "LA BOURSE DE PIERRES", Rect2(0, 26, 696, 34), "etiquette", 22, Style.OR_FILET,
		HORIZONTAL_ALIGNMENT_CENTER, 5)
	_bourse_grille = GridContainer.new()
	_bourse_grille.columns = 4
	_bourse_grille.position = Vector2(30, 76)
	_bourse_grille.size = Vector2(636, 260)
	_bourse_grille.add_theme_constant_override("h_separation", 12)
	_bourse_grille.add_theme_constant_override("v_separation", 12)
	_bourse_grille.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bourse.add_child(_bourse_grille)
	var toucher := Button.new()
	toucher.flat = true
	toucher.size = bourse.size
	for etat in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		toucher.add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	toucher.pressed.connect(func(): bourse.visible = false)
	bourse.add_child(toucher)


func _remplir_bourse() -> void:
	for c in _bourse_grille.get_children():
		c.queue_free()
	for t in GS.PIERRES:
		var n := GS.nb_pierres(t)
		var case := VBoxContainer.new()
		case.custom_minimum_size = Vector2(150, 124)
		case.alignment = BoxContainer.ALIGNMENT_CENTER
		case.add_theme_constant_override("separation", 0)
		case.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bourse_grille.add_child(case)
		var ico := Style.icone(case, Style.objet("pierre-" + t), Rect2(0, 0, 150, 84))
		ico.modulate.a = 1.0 if n > 0 else 0.35
		Style.libelle(case, str(n), Rect2(0, 0, 150, 40), "normal", 36, Style.IVOIRE if n > 0 else Style.SOURD,
			HORIZONTAL_ALIGNMENT_CENTER)


func basculer_bourse() -> void:
	bourse.visible = not bourse.visible
	if not bourse.visible:
		return
	_remplir_bourse()
	bourse.pivot_offset = Vector2(bourse.size.x * 0.8, 0)
	bourse.scale = Vector2(0.97, 0.97)
	bourse.modulate.a = 0.0
	var tw := bourse.create_tween().set_parallel(true)
	tw.tween_property(bourse, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(bourse, "modulate:a", 1.0, 0.15)
	_minuteur_bourse = get_tree().create_timer(5.0)
	var m := _minuteur_bourse
	m.timeout.connect(func():
		if m == _minuteur_bourse:
			bourse.visible = false)
