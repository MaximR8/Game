class_name DecksEcran
extends Control

# ─────────────────────────────────────────────────────────────
# MES DECKS — l'écran (27/09, sorti de l'étape 3). Deux vues :
#   · la liste : tes decks (6 au plus), leurs 5 cartes, leur poids ; on touche un deck pour le
#     choisir (c'est lui qui combat), « Modifier » ouvre l'éditeur ;
#   · l'éditeur : les 5 places et la jauge du poids en haut, ta collection en dessous (elle
#     défile au doigt). Toucher une carte de la collection la met dans le deck, au stade le plus
#     haut qui tient dans le poids ; toucher une carte du deck montre ses réglages juste en
#     dessous (son stade, sa variante, « Retirer ») — pas de fenêtre qui s'ouvre.
# Tout au toucher, aucun nom à taper (le clavier du téléphone, dans un jeu web, est pénible).
# La logique vit dans decks.gd.
# ─────────────────────────────────────────────────────────────

signal retour

const JADE := Color("#7fd0b0")
const CARMIN := Color("#ec8f9a")
const L_PLACE := 170.0
const L_COLL := 180.0
const COLONNES := 5
const PAS_COLL := Vector2(196, 300)
const NOMS_STADES := ["I", "II", "III"]

var _k := 0                        # le deck qu'on modifie
var _cartes: Array = []            # ses cartes (chaque changement s'écrit aussitôt)
var _choisie := -1                 # la place dont on règle la carte
var _vue: Control
var _reglages: Control
var _places: Control
var _jauge: Dessin
var _poids_lbl: Label
var _defil: ScrollContainer
var _grille: Control
var _cases: Dictionary = {}        # id → {cellule, carte}
var _construction := 0             # pour abandonner une construction en cours (on a changé de vue)
var retour_texte := "‹  Avant le combat"   # le Voyage ; l'Atlas l'ouvre aussi (28/09) : « ‹  L'Atlas »


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _vider() -> void:
	_construction += 1
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_cases.clear()
	_vue = Control.new()
	_vue.size = size
	_vue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vue)


# ─────────────────────────────────────────────────────────────
# La liste
# ─────────────────────────────────────────────────────────────

func montrer_liste() -> void:
	_vider()
	var b := Style.bouton(_vue, retour_texte, Rect2(36, 250, 440, 84), false, 32)
	b.pressed.connect(func(): retour.emit())
	Style.libelle(_vue, "Mes decks", Rect2(0, 346, 1080, 104), "italique", 84, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	Style.libelle(_vue, "5 CARTES  ·  POIDS 14 AU PLUS", Rect2(0, 450, 1080, 40), "etiquette", 23,
		Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 4)
	var l := Decks.liste()
	for k in l.size():
		_ligne_deck(k, l[k], 516.0 + k * 238.0)
	if l.size() < Decks.MAX_DECKS:
		var nv := Style.bouton(_vue, "Nouveau deck", Rect2(290, 516.0 + l.size() * 238.0 + 8.0, 500, 100), true, 42)
		nv.pressed.connect(func():
			var k := Decks.nouveau()
			if k >= 0:
				montrer_editeur(k))


func _ligne_deck(k: int, cartes: Array, y: float) -> void:
	var choisi := k == Decks.actif()
	var ligne := Control.new()
	ligne.position = Vector2(40, y)
	ligne.size = Vector2(1000, 224)
	ligne.pivot_offset = ligne.size * 0.5
	ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vue.add_child(ligne)
	var fond := Panel.new()
	fond.size = ligne.size
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond.add_theme_stylebox_override("panel", Style.boite(Color(0.035, 0.05, 0.047, 0.92), 30,
		JADE if choisi else Style.OR_FILET, 4 if choisi else 2))
	ligne.add_child(fond)
	# le toucher qui choisit : sous le reste (« Modifier » garde le sien)
	var zone := Button.new()
	zone.flat = true
	zone.focus_mode = Control.FOCUS_NONE
	zone.size = ligne.size
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		zone.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	ligne.add_child(zone)
	Style.jeu(zone, ligne)
	zone.pressed.connect(func():
		Decks.choisir(k)
		montrer_liste())
	Style.libelle(ligne, Decks.nom(k), Rect2(30, 20, 280, 62), "italique", 48, Style.IVOIRE)
	var raison := Decks.pourquoi(cartes)
	Style.libelle(ligne, "POIDS %d / %d" % [MoteurCarre.poids_deck(cartes), MoteurCarre.POIDS_MAX], Rect2(32, 84, 280, 34), "etiquette", 22,
		Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var etat := "CHOISI" if choisi else ""
	if raison != "":
		etat = "INCOMPLET"
	Style.libelle(ligne, etat, Rect2(32, 118, 280, 34), "etiquette", 22, JADE if raison == "" else CARMIN, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var mod := Style.bouton(ligne, "Modifier", Rect2(26, 150, 250, 62), false, 30)
	mod.pressed.connect(func(): montrer_editeur(k))
	var ech := 110.0 / CarteCarre.LARGEUR
	for i in MoteurCarre.TAILLE_DECK:
		var centre := Vector2(348.0 + i * 126.0 + 55.0, 112.0)
		if i < cartes.size():
			var cc := CarteCarre.new()
			ligne.add_child(cc)
			cc.configurer(cartes[i], "j")
			cc.scale = Vector2(ech, ech)
			cc.position = centre - CarteCarre.TAILLE * 0.5
		else:
			Dessin.ajouter(ligne, Rect2(centre - Vector2(55, 77), Vector2(110, 154)), func(ci: CanvasItem):
				ci.draw_rect(Rect2(Vector2(2, 2), Vector2(106, 150)), Color(Style.IVOIRE, 0.18), false, 2.0, true))


# ─────────────────────────────────────────────────────────────
# L'éditeur
# ─────────────────────────────────────────────────────────────

func montrer_editeur(k: int) -> void:
	_vider()
	_k = k
	_cartes = (Decks.liste()[k] as Array).duplicate(true)
	_choisie = -1
	var b := Style.bouton(_vue, "‹  Mes decks", Rect2(36, 250, 330, 84), false, 32)
	b.pressed.connect(montrer_liste)
	var auto := Style.bouton(_vue, "Composer tout seul", Rect2(596, 250, 448, 84), false, 32)
	auto.pressed.connect(func():
		_cartes = Decks.nettoyer(VoyageEcran.deck_auto())
		_choisie = -1
		_enregistrer())
	if Decks.liste().size() > 1:
		var sup := Style.bouton(_vue, "Supprimer", Rect2(780, 2044, 264, 80), false, 30)
		sup.pressed.connect(func():
			Decks.supprimer(_k)
			montrer_liste())
	Style.libelle(_vue, Decks.nom(k), Rect2(52, 350, 500, 80), "italique", 66, Style.IVOIRE)
	_poids_lbl = Style.libelle(_vue, "", Rect2(560, 356, 470, 70), "fort", 46, Style.OR_VIF, HORIZONTAL_ALIGNMENT_RIGHT)
	_jauge = Dessin.ajouter(_vue, Rect2(52, 436, 976, 18), _dessiner_jauge)
	_places = Control.new()
	_places.size = size
	_places.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vue.add_child(_places)
	_reglages = Control.new()
	_reglages.position = Vector2(0, 742)
	_reglages.size = Vector2(1080, 210)
	_reglages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vue.add_child(_reglages)
	Style.libelle(_vue, "TA COLLECTION  ·  %d CARTES" % GS.cartes.size(), Rect2(52, 962, 700, 40), "etiquette", 24, Style.SOURD,
		HORIZONTAL_ALIGNMENT_LEFT, 5)
	_defil = ScrollContainer.new()
	_defil.position = Vector2(40, 1010)
	_defil.size = Vector2(1000, 1020 if Decks.liste().size() > 1 else 1140)
	_defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_defil.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER      # on défile au doigt (Maxim, 23/09)
	_vue.add_child(_defil)
	_grille = Control.new()
	_grille.mouse_filter = Control.MOUSE_FILTER_PASS
	_defil.add_child(_grille)
	_maj_deck()
	_construire_collection()


# Ta collection, de la plus forte à la plus faible (à son stade le plus haut) ; construite quelques
# cartes par image, pour ne pas geler à l'ouverture.
func _construire_collection() -> void:
	var ids := GS.cartes.keys()
	ids = MoteurCarre.trier(ids, func(a, b): return float(MoteurCarre.force(_carte_max(str(b))) - MoteurCarre.force(_carte_max(str(a)))))
	var rangees := ceili(float(ids.size()) / COLONNES)
	_grille.custom_minimum_size = Vector2(1000, rangees * PAS_COLL.y + 20.0)
	var jeton := _construction
	for i in ids.size():
		if i > 0 and i % 4 == 0:
			await get_tree().process_frame
			if jeton != _construction:
				return
		_case_collection(str(ids[i]), Vector2((i % COLONNES) * PAS_COLL.x + 8.0, (i / COLONNES) * PAS_COLL.y + 8.0))
	_maj_collection()


func _carte_max(id: String) -> Dictionary:
	return {"id": id, "s": Decks.stade_max(id), "v": str(GS.cartes[id]["variante"])}


func _case_collection(id: String, pos: Vector2) -> void:
	var cellule := Control.new()
	cellule.position = pos
	cellule.size = Vector2(L_COLL, L_COLL * 1.4 + 40.0)
	cellule.pivot_offset = Vector2(L_COLL * 0.5, L_COLL * 0.7)
	cellule.mouse_filter = Control.MOUSE_FILTER_PASS
	_grille.add_child(cellule)
	var cc := CarteCarre.new()
	cellule.add_child(cc)
	var c := _carte_max(id)
	cc.configurer(c, "j")
	var ech := L_COLL / CarteCarre.LARGEUR
	cc.scale = Vector2(ech, ech)
	cc.position = Vector2(L_COLL, L_COLL * 1.4) * 0.5 - CarteCarre.TAILLE * 0.5
	Style.libelle(cellule, "POIDS %d" % MoteurCarre.poids(id, int(c["s"])), Rect2(0, L_COLL * 1.4 + 4.0, L_COLL, 34), "etiquette", 21,
		Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 3)
	_cases[id] = {"cellule": cellule, "carte": cc}
	# un toucher (le doigt n'a presque pas bougé) : sinon, c'est qu'on fait défiler
	var appui := [Vector2.ZERO, false]
	cellule.gui_input.connect(func(ev: InputEvent):
		var b := ev as InputEventMouseButton
		if b != null and b.button_index == MOUSE_BUTTON_LEFT:
			if b.pressed:
				appui[0] = b.global_position
				appui[1] = true
			elif appui[1]:
				appui[1] = false
				if b.global_position.distance_to(appui[0]) < 24.0:
					_toucher_collection(id)
		var mv := ev as InputEventMouseMotion
		if mv != null and appui[1] and mv.global_position.distance_to(appui[0]) >= 24.0:
			appui[1] = false)


func _toucher_collection(id: String) -> void:
	for i in _cartes.size():
		if _cartes[i]["id"] == id:
			_choisie = i          # déjà dans le deck : on la règle
			_maj_deck()
			return
	var r := Decks.ajouter_carte(_cartes, id)
	var cellule: Control = _cases[id]["cellule"]
	if not r["ok"]:
		Style.trembler(cellule)
		Style.bulle(cellule, str(r["raison"]))
		return
	Reglages.vibrer(15)
	Effets.pour(self).etincelles(cellule.get_global_rect(), 3, 18.0)
	_choisie = -1
	_enregistrer()


func _enregistrer() -> void:
	Decks.remplacer(_k, _cartes)
	_cartes = (Decks.liste()[_k] as Array).duplicate(true)
	_maj_deck()


# Les 5 places, la jauge, les réglages de la carte touchée, et la collection (ce qui est pris s'efface).
func _maj_deck() -> void:
	for c in _places.get_children():
		_places.remove_child(c)
		c.queue_free()
	var x0 := 540.0 - (MoteurCarre.TAILLE_DECK * L_PLACE + (MoteurCarre.TAILLE_DECK - 1) * 22.0) * 0.5
	var ech := L_PLACE / CarteCarre.LARGEUR
	for i in MoteurCarre.TAILLE_DECK:
		var centre := Vector2(x0 + i * (L_PLACE + 22.0) + L_PLACE * 0.5, 478.0 + L_PLACE * 0.7)
		var zone := Button.new()
		zone.flat = true
		zone.focus_mode = Control.FOCUS_NONE
		zone.position = centre - Vector2(L_PLACE, L_PLACE * 1.4) * 0.5
		zone.size = Vector2(L_PLACE, L_PLACE * 1.4)
		zone.pivot_offset = zone.size * 0.5
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			zone.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		if i < _cartes.size():
			var cc := CarteCarre.new()
			_places.add_child(cc)
			cc.configurer(_cartes[i], "j")
			cc.scale = Vector2(ech, ech)
			cc.position = centre - CarteCarre.TAILLE * 0.5
			if i == _choisie:
				Dessin.ajouter(_places, Rect2(zone.position - Vector2(8, 8), zone.size + Vector2(16, 16)),
					func(ci: CanvasItem): ci.draw_rect(Rect2(Vector2(2.5, 2.5), zone.size + Vector2(11, 11)), JADE, false, 5.0, true))
			zone.pressed.connect(func():
				_choisie = -1 if _choisie == i else i
				_maj_deck())
			Style.jeu(zone)        # (pas sur la carte : son rebond la remettrait à sa taille réelle)
		else:
			Dessin.ajouter(_places, Rect2(zone.position, zone.size), func(ci: CanvasItem):
				ci.draw_rect(Rect2(Vector2(3, 3), zone.size - Vector2(6, 6)), Color(Style.IVOIRE, 0.22), false, 3.0, true)
				var m := zone.size * 0.5
				ci.draw_line(m - Vector2(22, 0), m + Vector2(22, 0), Color(Style.IVOIRE, 0.35), 4.0, true)
				ci.draw_line(m - Vector2(0, 22), m + Vector2(0, 22), Color(Style.IVOIRE, 0.35), 4.0, true))
			zone.pressed.connect(func(): Style.bulle(zone, "Touche une carte de ta collection"))
		_places.add_child(zone)
	var p := MoteurCarre.poids_deck(_cartes)
	_poids_lbl.text = "POIDS %d / %d" % [p, MoteurCarre.POIDS_MAX]
	_poids_lbl.add_theme_color_override("font_color", CARMIN if p > MoteurCarre.POIDS_MAX else Style.OR_VIF)
	_jauge.queue_redraw()
	_maj_reglages()
	_maj_collection()


func _dessiner_jauge(ci: CanvasItem) -> void:
	var p := MoteurCarre.poids_deck(_cartes)
	var l := 976.0
	ci.draw_rect(Rect2(0, 0, l, 18), Color(0.02, 0.03, 0.03, 0.9), true)
	var k := minf(1.0, float(p) / MoteurCarre.POIDS_MAX)
	ci.draw_rect(Rect2(0, 0, l * k, 18), CARMIN if p > MoteurCarre.POIDS_MAX else (JADE if _cartes.size() == MoteurCarre.TAILLE_DECK else Style.OR), true)
	for g in range(1, MoteurCarre.POIDS_MAX):
		var x := l * g / MoteurCarre.POIDS_MAX
		ci.draw_line(Vector2(x, 0), Vector2(x, 18), Color(0, 0, 0, 0.55), 2.0)
	ci.draw_rect(Rect2(0, 0, l, 18), Style.OR_FILET, false, 2.0)


# Les réglages de la carte touchée, juste sous le deck : son stade, sa variante, « Retirer ».
func _maj_reglages() -> void:
	for c in _reglages.get_children():
		_reglages.remove_child(c)
		c.queue_free()
	if _choisie < 0 or _choisie >= _cartes.size():
		var aide := "Touche une carte de ta collection pour l'ajouter." if _cartes.size() < MoteurCarre.TAILLE_DECK \
			else "Touche une carte de ton deck pour la régler."
		Style.libelle(_reglages, aide, Rect2(0, 60, 1080, 60), "italique", 36, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var c: Dictionary = _cartes[_choisie]
	var id := str(c["id"])
	Style.libelle(_reglages, "STADE", Rect2(52, 18, 200, 70), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var smax := Decks.stade_max(id)
	var stades := int(MoteurCarre.fiche(id)["stades"]) if not MoteurCarre.un_seul(id) else 1
	for s in range(1, stades + 1):
		var b := Style.bouton(_reglages, NOMS_STADES[s - 1], Rect2(262 + (s - 1) * 132, 14, 118, 78), s == int(c["s"]), 34)
		b.disabled = s > smax
		b.set_meta("pourquoi", "Fais-la évoluer d'abord")
		b.pressed.connect(func():
			_cartes[_choisie]["s"] = s
			_enregistrer())
	var ret := Style.bouton(_reglages, "Retirer", Rect2(780, 14, 250, 78), false, 32)
	ret.pressed.connect(func():
		_cartes.remove_at(_choisie)
		_choisie = -1
		_enregistrer())
	var vs: Array = GS.cartes[id]["variantes"] if GS.cartes.has(id) else ["base"]
	Style.libelle(_reglages, "VARIANTE", Rect2(52, 112, 200, 70), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var x := 262.0
	for v in GS.VARIANTES:
		if not vs.has(v["id"]):
			continue
		var nomv := str(v["nom"])
		var l := maxf(118.0, 26.0 + nomv.length() * 17.0)
		if x + l > 1040.0:
			break
		var b := Style.bouton(_reglages, nomv, Rect2(x, 108, l, 78), str(c["v"]) == str(v["id"]), 28)
		b.pressed.connect(func():
			_cartes[_choisie]["v"] = str(v["id"])
			_enregistrer())
		x += l + 12.0


func _maj_collection() -> void:
	var pris := {}
	for c in _cartes:
		pris[c["id"]] = true
	for id in _cases:
		(_cases[id]["cellule"] as Control).modulate = Color(1, 1, 1, 0.32 if pris.has(id) else 1.0)
