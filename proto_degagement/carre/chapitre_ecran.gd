class_name ChapitreEcran
extends Control

# ─────────────────────────────────────────────────────────────
# UNE TERRE DU VOYAGE (l'Aventure, étape 2 du Carré, 27/09) : ses 10 niveaux sont les étoiles
# d'une constellation (FEATURES ④ : « la carte des chapitres est le ciel du jeu »). Le 1ᵉʳ en bas,
# le boss en haut, la plus grande. Une étoile gagnée est d'or, avec ses ★ ; la prochaine bat
# (les anneaux de jade du guide) ; les autres attendent, éteintes. En bas, les 3 coffres : on
# y voit ce qu'ils donnent, et on les ouvre du doigt — le gain s'envole jusqu'au bandeau.
# ─────────────────────────────────────────────────────────────

signal choisir(n: int)
signal retour

const ZONE := Rect2(90, 590, 900, 950)
# Le tracé de la constellation (x, y dans la zone, de 0 à 1) : du niveau 1 (en bas) au boss (en haut).
const MODELE := [Vector2(0.08, 0.95), Vector2(0.36, 0.87), Vector2(0.68, 0.92), Vector2(0.92, 0.74), Vector2(0.64, 0.61),
	Vector2(0.30, 0.57), Vector2(0.07, 0.39), Vector2(0.34, 0.26), Vector2(0.68, 0.31), Vector2(0.50, 0.05)]
const JADE := Color("#7fd0b0")
const IMAGES_COFFRE := {10: "", 20: "etoile-invocation", 30: "pierre-lune"}

var terre := 1
var bandeau: Bandeau
var _points: Array = []
var _trace: Dessin
var _coffres: Array = []          # par seuil : {seuil, med, ico, lib}
var _t := 0.0


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func montrer(t: int) -> void:
	terre = t
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_coffres.clear()
	_construire()


func _premier() -> int:
	return (terre - 1) * Aventure.PAR_TERRE + 1


func _construire() -> void:
	var def: Dictionary = Aventure.TERRES[terre - 1]
	var b := Style.bouton(self, "‹  Le Voyage", Rect2(36, 250, 300, 84), false, 34)
	b.pressed.connect(func(): retour.emit())
	Style.libelle(self, str(def["nom"]), Rect2(0, 346, 1080, 104), "italique", 84, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	Style.libelle(self, "NIVEAUX %d À %d   ·   ★ %d / 30" % [_premier(), _premier() + 9, Aventure.etoiles_terre(terre)],
		Rect2(0, 450, 1080, 44), "etiquette", 27, Style.OR_VIF, HORIZONTAL_ALIGNMENT_CENTER, 5)
	Style.libelle(self, str(def["phrase"]), Rect2(80, 496, 920, 50), "italique", 33, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)

	# la constellation (miroir d'une terre à l'autre : elles ne se ressemblent pas toutes)
	_points.clear()
	for k in Aventure.PAR_TERRE:
		var m: Vector2 = MODELE[k]
		if terre % 2 == 0:
			m.x = 1.0 - m.x
		_points.append(ZONE.position + m * ZONE.size)
	_trace = Dessin.ajouter(self, Rect2(Vector2.ZERO, size), _dessiner)
	var prochain := Aventure.prochain()
	for k in Aventure.PAR_TERRE:
		var n := _premier() + k
		var boss := k == Aventure.PAR_TERRE - 1
		var p: Vector2 = _points[k]
		var ouvert := Aventure.niveau_ouvert(n)
		var coul := Style.IVOIRE if ouvert else Style.SOURD
		Style.libelle(self, str(n), Rect2(p.x - 70, p.y + (58 if boss else 38), 140, 44), "fort", 34 if boss else 30,
			Color(coul, 1.0 if ouvert else 0.55), HORIZONTAL_ALIGNMENT_CENTER)
		if boss:
			# « BOSS » seul : son nom est sur l'écran d'avant le combat (un nom long barrait la constellation)
			Style.libelle(self, "BOSS", Rect2(p.x - 100, p.y + 138, 200, 34), "etiquette", 23,
				Style.OR_VIF if ouvert else Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 5)
		var zone := Button.new()
		zone.flat = true
		zone.focus_mode = Control.FOCUS_NONE
		zone.position = p - Vector2(80, 80)
		zone.size = Vector2(160, 170)
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			zone.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		add_child(zone)
		zone.pressed.connect(func():
			if Aventure.niveau_ouvert(n):
				choisir.emit(n)
			else:
				Style.bulle(zone, "Gagne d'abord le niveau %d" % (n - 1)))
		if n == prochain and ouvert:
			Style.jeu(zone, zone)

	# les coffres
	Style.libelle(self, "LES COFFRES DE LA TERRE", Rect2(0, 1630, 1080, 40), "etiquette", 25, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 5)
	for i in Aventure.SEUILS_COFFRES.size():
		var s: int = Aventure.SEUILS_COFFRES[i]
		var cx := 270.0 + i * 270.0
		var med := Control.new()
		med.position = Vector2(cx - 90, 1690)
		med.size = Vector2(180, 180)
		med.pivot_offset = med.size * 0.5
		med.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(med)
		Style.icone(med, Style.texture("res://interface/medaillon-sombre.png"), Rect2(Vector2.ZERO, med.size))
		var g := Aventure.recompense_coffre(terre, s)
		var image := "pierre-%s" % g["pierre"] if s == 10 else str(IMAGES_COFFRE[s])
		var ico := Style.icone(med, Style.objet(image), Rect2(Vector2(38, 38), Vector2(104, 104)))
		if s == 30:
			Style.icone(med, Style.objet("etoile-invocation"), Rect2(Vector2(96, 96), Vector2(64, 64)))
		var lib := Style.libelle(self, "", Rect2(cx - 130, 1878, 260, 50), "fort", 34, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
		var zone := Button.new()
		zone.flat = true
		zone.focus_mode = Control.FOCUS_NONE
		zone.position = med.position
		zone.size = med.size + Vector2(0, 60)
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			zone.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		add_child(zone)
		Style.jeu(zone, med)
		var c := {"seuil": s, "med": med, "ico": ico, "lib": lib, "zone": zone}
		_coffres.append(c)
		zone.pressed.connect(_toucher_coffre.bind(c))
	_maj_coffres()


func _maj_coffres() -> void:
	var prets := Aventure.coffres_prets(terre)
	for c in _coffres:
		var s: int = c["seuil"]
		var med: Control = c["med"]
		var lib: Label = c["lib"]
		if Aventure.coffre_ouvert(terre, s):
			med.modulate = Color(1, 1, 1, 0.35)
			lib.text = "Ouvert"
			lib.add_theme_color_override("font_color", Style.SOURD)
		elif prets.has(s):
			med.modulate = Color.WHITE
			lib.text = "Ouvrir !"
			lib.add_theme_color_override("font_color", JADE)
		else:
			med.modulate = Color(1, 1, 1, 0.55)
			lib.text = "%d ★" % s
			lib.add_theme_color_override("font_color", Style.IVOIRE)


func _toucher_coffre(c: Dictionary) -> void:
	var s: int = c["seuil"]
	if not Aventure.coffres_prets(terre).has(s):
		if not Aventure.coffre_ouvert(terre, s):
			Style.bulle(c["med"], "Encore %d ★" % (s - Aventure.etoiles_terre(terre)))
		return
	var g := Aventure.recompense_coffre(terre, s)
	var med: Control = c["med"]
	var tw := med.create_tween()
	tw.tween_property(med, "scale", Vector2(1.25, 1.25), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(med, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Effets.pour(self).etincelles(med.get_global_rect(), 6, 26.0)
	Reglages.vibrer(25)
	Son.sonner("recevoir")
	Dessin.gains_en_vol(bandeau, g, med.get_global_rect().get_center(), func(): Aventure.ouvrir_coffre(terre, s))
	_maj_coffres()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	if _trace != null:
		_trace.queue_redraw()
	# un coffre prêt respire
	var prets := Aventure.coffres_prets(terre)
	for c in _coffres:
		if prets.has(c["seuil"]):
			var k := 1.0 + 0.05 * sin(_t * 5.0)
			(c["med"] as Control).scale = Vector2(k, k)


# Les traits de la constellation, puis ses étoiles.
func _dessiner(ci: CanvasItem) -> void:
	var prochain := Aventure.prochain()
	for k in range(1, _points.size()):
		var gagne := Aventure.gagne(_premier() + k - 1) and Aventure.gagne(_premier() + k)
		var vers := Aventure.gagne(_premier() + k - 1)
		var a: Vector2 = _points[k - 1]
		var b: Vector2 = _points[k]
		var c := Color(Style.IVOIRE, 0.75 if gagne else (0.4 if vers else 0.14))
		ci.draw_line(a, b, c, 3.0 if gagne else 2.0, true)
	for k in _points.size():
		var n := _premier() + k
		var p: Vector2 = _points[k]
		var boss := k == Aventure.PAR_TERRE - 1
		var r := 50.0 if boss else 34.0
		var m := Aventure.masque(n)
		if Aventure.gagne(n):
			Effets.dessiner_etoile(ci, p, r, 1.0, 0.0, Effets.OR_CLAIR)
			Dessin.trois_etoiles(ci, p + Vector2(0, (120 if boss else 98)), 10.0, m)
		elif Aventure.niveau_ouvert(n):
			if n == prochain:
				# la prochaine : elle bat, et les anneaux de jade du guide l'entourent
				for q in 2:
					var u := fposmod(_t / 1.3 + q * 0.5, 1.0)
					ci.draw_arc(p, r * 0.8 + u * 46.0, 0.0, TAU, 48, Color(JADE, (1.0 - u) * 0.8), 4.0 - u * 2.0, true)
			var s := 0.85 + 0.15 * sin(_t * 3.0)
			Effets.dessiner_etoile(ci, p, r * s, 1.0, 0.0, Style.IVOIRE)
			Dessin.trois_etoiles(ci, p + Vector2(0, (120 if boss else 98)), 10.0, m)
		else:
			Effets.dessiner_etoile(ci, p, r * 0.6, 0.35, 0.0, Dessin.GRIS)
