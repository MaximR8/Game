class_name CollectionScreen
extends Control

# LA COLLECTION — regarder ses cartes, choisir la variante qu'on affiche, monter de niveau,
# faire évoluer ; en haut, le deck qui combat et « Mes decks » (Maxim, 27/09 : « le bouton n'est
# pas forcément bien visible pour changer de deck »). Depuis le 28/09, on invoque dans l'Astrolabe
# (astrolabe_ecran.gd, les portails) : il lance, mais le rituel et les révélations vivent ici.
# Look « Conte mystique » : les cartes posées sur le ciel commun, l'interface
# en Style (panneaux à double filet d'or, boutons ivoire).
#
# 🔴 Les grands moments — révélations, carte en grand, probabilités — vivent
#    dans une COUCHE au-dessus de tout : ils couvrent aussi le bandeau et la
#    navigation de main. L'invocation ×10 prend tout l'écran.

signal multi_ferme      # l'invocation ×10 refermée (l'accueil du premier pack attend ce moment)
signal revelation_fermee    # l'invocation simple refermée (l'Astrolabe relit ses ciels)

const GRILLE_VSEP := 40
const LARGEUR_MINI := 486.0     # la grille : deux colonnes
const LARGEUR_GRANDE := 820.0   # une carte en grand, et la révélation simple
const LARGEUR_MULTI := 320.0    # l'invocation ×10 : 3-2-3-2, sur tout l'écran
const LARGEUR_PLEIN := 1040.0   # la carte seule, en plein écran
const LARGEUR_VEDETTE := 760.0  # un full art tiré dans un ×10 : il vient au centre, en grand
const DUREE_PORTAIL := 1.7
const SH_IRISE := preload("res://cartes/shaders/nom_irise.gdshader")
const CENTRE_ECRAN := Vector2(540, 1200)
const CENTRE_MULTI := Vector2(540, 1162)
const LEGENDE_H := 64.0
const VOILE := Color(0.016, 0.024, 0.022, 0.97)

var grille: Control              # le contenu de la grille recyclée (sa hauteur fait défiler)
var portail := "grand"           # le ciel où l'on invoque (Portails) : l'Astrolabe le choisit, « Encore » y reste
var _page: Control               # tout l'Atlas ; caché quand « Mes decks » est ouvert par-dessus
var _decks: DecksEcran
var _deck_panneau: Panel         # en haut : le deck qui combat, et « Mes decks »
var _deck_contenu: Control
var btn_decks: Button
var lbl_collection: Label
var _sale := true
# 🔴 La grille est GARDÉE (25/09) : 31 emplacements, une carte n'est construite que quand
#    elle approche de l'écran, et refaite seulement si elle a changé. Avant, chaque
#    ouverture reconstruisait les 31 cartes (2,5 s la première fois sur le PC, des à-coups
#    de 150 à 300 ms ensuite).
var defil: ScrollContainer
var vignettes: Vignettes         # les cartes de la grille, en images (vignettes.gd)

# Au-dessus de tout, même du bandeau et de la navigation de main.
var couche: CanvasLayer

# La carte en grand
var detail: Control
var detail_carte: Carte3D     # la carte en grand : elle se tourne au doigt, son dos dit sa légende
var detail_nom: Label
var detail_info: Label
var detail_variantes: HBoxContainer
var btn_niveau: Button
var lvl_badge: PanelContainer       # « LVL 8 » en or, au-dessus de la carte en grand
var lvl_nombre: Label
var _lvl_anime := false
var btn_evo: Button
var btn_obtenir: Button          # une carte qu'on n'a pas : « Obtenir · N éclats » (28/09, ⑧ lot B)
var lbl_eclats: Label            # les éclats, au-dessus de la grille (c'est ici qu'on les dépense)
var selection := ""

# La carte seule, en plein écran
var plein: Control
var plein_carte: CarteView

# La révélation d'une invocation simple
var rev: Control
var rev_lueur: TextureRect
var rev_carte: CarteView
var rev_titre: Label
var rev_sous: Label
var btn_encore: Button
var btn_rev_fermer: Button
var rev_rituel_fond: Rituel     # derrière la carte : le portail, les rayons
var rev_rituel: Rituel          # devant : l'éclat, les étincelles, l'éclair
var _rev_pos := Vector2.ZERO
var _rev_tween: Tween
var _rev_r: Dictionary = {}
var _rev_fini := true
var rev_banniere: Label
var multi_banniere: Label
var _secousse_tween: Tween
var _banniere_tween: Tween

# L'invocation ×10
var multi: Control
var multi_cartes: Array = []
var multi_lueurs: Array = []
var multi_bilan: Label
var multi_aide: Label
var multi_voir: Label
var btn_multi_encore: Button
var btn_multi_fermer: Button
var multi_rituel_fond: Rituel
var multi_rituel: Rituel
var multi_vedette: CarteView
var _ombre_tween: Tween
var _multi_lot: Array = []
var _multi_tween: Tween
var _multi_fini := true
var _multi_fin_ms := 0

# Les probabilités
var probas: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construire()
	GS.changed.connect(_rafraichir)
	_rafraichir()


# ─────────────────────────────────────────────────────────────
# Petits outils
# ─────────────────────────────────────────────────────────────

func _plein_ecran() -> Control:
	var c := Control.new()
	c.size = Vector2(1080, 2400)
	c.visible = false
	couche.add_child(c)
	return c


func _voile(parent: Node) -> ColorRect:
	var v := ColorRect.new()
	v.color = VOILE
	v.size = Vector2(1080, 2400)
	v.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(v)
	return v


func _lueur(parent: Node) -> TextureRect:
	var l := Style.icone(parent, Style.texture("res://ciel/lueur.png"), Rect2(0, 0, 10, 10), Color(1, 1, 1, 0))
	l.stretch_mode = TextureRect.STRETCH_SCALE
	return l


# Un lien : du texte d'or, sans cadre.
func _lien(parent: Node, texte: String, rect: Rect2) -> Button:
	var b := Button.new()
	b.text = texte
	b.position = rect.position
	b.size = rect.size
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_theme_font_override("font", Style.police("italique"))
	b.add_theme_font_size_override("font_size", 34)
	for etat in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Style.OR)
	b.add_theme_color_override("font_pressed_color", Style.IVOIRE)
	parent.add_child(b)
	return b


# La couleur de la lueur d'une carte révélée : rien pour la base, de plus en plus fort ensuite.
static func _couleur_lueur(v: String, type_id: String) -> Color:
	match v:
		"or":
			return Color(1.0, 0.82, 0.42, 0.75)
		"ombre":
			return Color(0.8, 0.82, 0.88, 0.6)
		"elem":
			return Color(GS.TYPES[type_id]["elt"], 0.9)
		"prisme":
			return Color(0.82, 0.9, 1.0, 1.0)
		"full":
			return Color(1, 1, 1, 1)
	return Color(0, 0, 0, 0)


# La couleur du nom d'une variante, dans les légendes et sur ses pastilles.
static func _couleur_variante(v: String, type_id: String) -> Color:
	match v:
		"or":
			return Color("#e8c877")
		"ombre":
			return Color("#b9bec8")
		"elem":
			return GS.TYPES[type_id]["clair"]
		"prisme":
			return Color("#cfe0ff")
		"full":
			return Color.WHITE
	return Style.SOURD


static func _pct(p: float) -> String:
	return String.num(p, 1).replace(".", ",") + " %"


static func _etoiles(n: int) -> String:
	return "%d étoile%s" % [n, "s" if n > 1 else ""]


# ─────────────────────────────────────────────────────────────
# Construction
# ─────────────────────────────────────────────────────────────

func _construire() -> void:
	# Pas de fond : le ciel commun (Ciel, dans main) se voit derrière la grille.
	_page = Control.new()
	_page.size = Vector2(1080, 2400)
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_page)
	# en haut, à la place de l'invocation (partie dans l'Astrolabe) : le deck qui combat, et « Mes decks »
	_deck_panneau = Style.panneau(_page, Rect2(30, 214, 1020, 300), Color(0.035, 0.05, 0.045, 0.66), 34)
	Style.libelle(_deck_panneau, "TON DECK POUR COMBATTRE", Rect2(48, 28, 600, 40), "etiquette", 23, Style.OR_FILET,
		HORIZONTAL_ALIGNMENT_LEFT, 5)
	_deck_contenu = Control.new()
	_deck_contenu.size = _deck_panneau.size
	_deck_contenu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_panneau.add_child(_deck_contenu)
	btn_decks = Style.bouton(_deck_panneau, "Mes decks", Rect2(690, 174, 290, 96), true, 42)
	btn_decks.pressed.connect(_ouvrir_decks)
	_decks = DecksEcran.new()
	_decks.retour_texte = "‹  L'Atlas"
	_decks.visible = false
	add_child(_decks)
	_decks.retour.connect(_fermer_decks)

	lbl_collection = Style.libelle(_page, "", Rect2(48, 540, 984, 40), "etiquette", 23, Style.OR_FILET,
		HORIZONTAL_ALIGNMENT_LEFT, 5)
	# les éclats (28/09, ⑧ lot B) : chaque carte invoquée en donne ; ils achètent une carte, ici
	var ligne_ec := HBoxContainer.new()
	ligne_ec.position = Vector2(640, 524)
	ligne_ec.size = Vector2(392, 70)
	ligne_ec.alignment = BoxContainer.ALIGNMENT_END
	ligne_ec.add_theme_constant_override("separation", 10)
	ligne_ec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.add_child(ligne_ec)
	var ico_ec := Style.icone(ligne_ec, Style.objet("eclat"), Rect2(0, 0, 56, 56))
	ico_ec.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_eclats = _chiffre_or(ligne_ec, 44)
	var mot := Style.libelle(ligne_ec, "éclats", Rect2(0, 0, 10, 70), "italique", 32, Style.SOURD)
	mot.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	defil = ScrollContainer.new()
	defil.position = Vector2(40, 596)
	defil.size = Vector2(1000, 1604)
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# On défile au doigt : pas de barre (demande de Maxim, 23/09).
	defil.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_page.add_child(defil)

	grille = Control.new()
	grille.mouse_filter = Control.MOUSE_FILTER_PASS
	defil.add_child(grille)
	# les sbires (27/09) : leur rangée, sous les héros, sous ce titre
	for rg in ORDRE_RANGS:
		titres_rangs[rg] = Style.libelle(grille, "", Rect2(8, 0, 984, TITRE_SBIRES_H - 30.0), "etiquette", 23,
			Style.couleur_rang(rg), HORIZONTAL_ALIGNMENT_LEFT, 5)
	defil.get_v_scroll_bar().value_changed.connect(func(_v: float): _placer_cases())
	vignettes = Vignettes.new()
	vignettes.largeur = LARGEUR_MINI
	add_child(vignettes)
	vignettes.prete.connect(_vignette_prete)
	_construire_preparation()

	couche = CanvasLayer.new()
	couche.layer = 10
	add_child(couche)
	_construire_revelation()
	_construire_multi()
	_construire_detail()
	_construire_plein()
	probas = _plein_ecran()


func _construire_detail() -> void:
	detail = _plein_ecran()
	_voile(detail)
	Style.libelle(detail, "Tourne la carte du doigt : sa légende est au dos.",
		Rect2(40, 110, 1000, 50), "italique", 34, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	detail_carte = Carte3D.new()
	detail_carte.position = Vector2((1080.0 - LARGEUR_GRANDE) * 0.5, 190)
	# un toucher sans glisser : la carte en plein écran
	detail_carte.touchee.connect(_ouvrir_plein)
	detail.add_child(detail_carte)
	var y := 190.0 + LARGEUR_GRANDE * 1.4 + 40.0
	detail_nom = Style.libelle(detail, "", Rect2(40, y, 1000, 84), "normal", 68, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	detail_info = Style.libelle(detail, "", Rect2(40, y + 84, 1000, 52), "italique", 38, Style.SOURD,
		HORIZONTAL_ALIGNMENT_CENTER)
	detail_variantes = HBoxContainer.new()
	detail_variantes.position = Vector2(40, y + 168)
	detail_variantes.size = Vector2(1000, 80)
	detail_variantes.alignment = BoxContainer.ALIGNMENT_CENTER
	detail_variantes.add_theme_constant_override("separation", 12)
	detail.add_child(detail_variantes)
	btn_niveau = Style.bouton(detail, "", Rect2(40, y + 290, 490, 140), true, 40)
	btn_niveau.pressed.connect(_monter_niveau)
	btn_niveau.set_meta("pourquoi", func():
		if selection == "":
			return ""
		if GS.est_sbire(selection):
			return "Un sbire garde toujours les mêmes chiffres"
		return "Il te faut %s poussière d'étoile" % Style.nombre(GS.cout_niveau(selection)))
	btn_evo = Style.bouton(detail, "", Rect2(550, y + 290, 490, 140), true, 40)
	btn_evo.pressed.connect(_evoluer)
	btn_evo.set_meta("pourquoi", func():
		if selection == "" or not GS.cartes.has(selection):
			return ""
		if int(GS.cartes[selection]["stade"]) >= GS.stade_max(selection):
			return "Elle est à son dernier stade"
		if int(GS.cartes[selection]["niveau"]) < GS.niveau_pour_evoluer(selection):
			return "Il faut qu'elle soit LVL %d" % GS.niveau_pour_evoluer(selection)
		return "Il te manque %s" % GS.pierre_demandee(selection))
	# le niveau, en or, sur le coin de la carte (Maxim, 26/09 : « LVL, c'est international »)
	lvl_badge = PanelContainer.new()
	var sb := Style.boite(Color("#121a17"), 24, Style.OR, 4)
	sb.shadow_color = Color("#3b2e17")
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 9)
	sb.content_margin_left = 33
	sb.content_margin_right = 33
	sb.content_margin_top = 4
	sb.content_margin_bottom = 2
	lvl_badge.add_theme_stylebox_override("panel", sb)
	lvl_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(lvl_badge)
	var rang := HBoxContainer.new()
	rang.add_theme_constant_override("separation", 14)
	rang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lvl_badge.add_child(rang)
	var l := Style.libelle(rang, "LVL", Rect2(0, 0, 10, 60), "etiquette", 30, Style.OR_VIF, HORIZONTAL_ALIGNMENT_LEFT, 4)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lvl_nombre = _chiffre_or(rang, 51)
	lvl_badge.position = Vector2(540, 190 - 39)
	btn_obtenir = Style.bouton(detail, "", Rect2(40, y + 290, 1000, 140), true, 46)
	btn_obtenir.pressed.connect(func(): _obtenir(btn_obtenir, "base"))
	btn_obtenir.set_meta("pourquoi", func():
		if selection == "":
			return ""
		return "Il te faut %s éclats (tu en as %s)" % [Style.nombre(GS.prix(selection, "base")), Style.nombre(GS.eclats)])
	var pe := Style.bouton(detail, "Plein écran", Rect2(40, y + 460, 490, 120), false, 46)
	pe.pressed.connect(_ouvrir_plein)
	var f := Style.bouton(detail, "Fermer", Rect2(550, y + 460, 490, 120), false, 46)
	f.pressed.connect(func():
		detail.visible = false
		selection = "")


# La carte seule, au plus grand : la lumière suit le doigt ; un toucher ferme.
func _construire_plein() -> void:
	plein = _plein_ecran()
	var v := _voile(plein)
	v.color = Color(0.008, 0.012, 0.011, 0.985)
	v.gui_input.connect(func(ev: InputEvent):
		var b := ev as InputEventMouseButton
		if b != null and b.button_index == MOUSE_BUTTON_LEFT and not b.pressed:
			plein.visible = false)
	plein_carte = CarteView.new()
	plein_carte.interactif = true
	plein_carte.position = Vector2((1080.0 - LARGEUR_PLEIN) * 0.5, (2400.0 - LARGEUR_PLEIN * 1.4) * 0.5)
	plein_carte.touchee.connect(func(): plein.visible = false)
	plein.add_child(plein_carte)
	Style.libelle(plein, "Glisse le doigt pour la lumière · touche pour revenir.", Rect2(40, 2250, 1000, 50), "italique", 32,
		Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)


func _ouvrir_plein() -> void:
	if selection == "" or not GS.cartes.has(selection):
		return
	var e: Dictionary = GS.cartes[selection]
	plein_carte.configurer(GS.heros(selection), int(e["stade"]), str(e["variante"]), LARGEUR_PLEIN, true)
	plein.visible = true
	couche.move_child(plein, -1)


func _construire_revelation() -> void:
	rev = _plein_ecran()
	# toucher l'écran pendant l'invocation : tout de suite la carte
	_voile(rev).gui_input.connect(_rev_toucher)
	rev.gui_input.connect(_rev_toucher)
	var y0 := 380.0
	rev_etiquette = Style.libelle(rev, "INVOCATION", Rect2(0, y0 - 20, 1080, 64), "etiquette", 28, Style.OR_FILET, HORIZONTAL_ALIGNMENT_CENTER, 8)
	rev_etiquette.pivot_offset = rev_etiquette.size * 0.5
	var carte_y := y0 + 70.0
	rev_lueur = _lueur(rev)
	rev_lueur.size = Vector2(1500, 1500)
	rev_lueur.position = Vector2(540, carte_y + LARGEUR_GRANDE * 0.7) - rev_lueur.size * 0.5
	rev_rituel_fond = Rituel.new()
	rev.add_child(rev_rituel_fond)
	rev_carte = CarteView.new()
	_rev_pos = Vector2((1080.0 - LARGEUR_GRANDE) * 0.5, carte_y)
	rev_carte.position = _rev_pos
	rev.add_child(rev_carte)
	rev_rituel = Rituel.new()
	rev.add_child(rev_rituel)
	var y := carte_y + LARGEUR_GRANDE * 1.4 + 40.0
	rev_titre = Style.libelle(rev, "", Rect2(40, y, 1000, 90), "normal", 76, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	rev_sous = Style.libelle(rev, "", Rect2(60, y + 90, 960, 110), "italique", 40, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER,
		0, true)
	btn_encore = Style.bouton(rev, "", Rect2(40, y + 240, 490, 140), true, 44)
	btn_encore.pressed.connect(_invoquer)
	btn_rev_fermer = Style.bouton(rev, "Fermer", Rect2(550, y + 240, 490, 140), false, 48)
	btn_rev_fermer.pressed.connect(func():
		rev.visible = false
		revelation_fermee.emit())
	rev_banniere = _nouvelle_banniere(rev)


# Les dix places de l'invocation ×10 : 3-2-3-2 en quinconce, sur tout l'écran.
static func _places_multi() -> Array:
	var w := LARGEUR_MULTI
	var g := (1080.0 - 3.0 * w) / 4.0
	var res: Array = []
	for rang in 4:
		var n := 3 if rang % 2 == 0 else 2
		var x0 := (1080.0 - n * w - (n - 1) * g) * 0.5
		for k in n:
			res.append(Vector2(x0 + k * (w + g), 236.0 + rang * (w * 1.4 + 20.0)))
	return res


func _construire_multi() -> void:
	multi = _plein_ecran()
	multi.mouse_filter = Control.MOUSE_FILTER_STOP
	multi.gui_input.connect(_multi_toucher)
	var v := _voile(multi)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	Style.libelle(multi, "Invocation ×10", Rect2(40, 54, 1000, 84), "normal", 66, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	multi_aide = Style.libelle(multi, "Touche l'écran pour tout retourner.", Rect2(40, 140, 1000, 60), "italique", 36,
		Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	multi_bilan = Style.libelle(multi, "", Rect2(40, 136, 1000, 90), "normal", 34, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	var places := _places_multi()
	for i in 10:
		var l := _lueur(multi)
		l.size = Vector2(LARGEUR_MULTI, LARGEUR_MULTI) * 2.0
		l.position = (places[i] as Vector2) + Vector2(LARGEUR_MULTI, LARGEUR_MULTI * 1.4) * 0.5 - l.size * 0.5
		multi_lueurs.append(l)
	multi_rituel_fond = Rituel.new()
	multi.add_child(multi_rituel_fond)
	for i in 10:
		var c := CarteView.new()
		c.position = places[i]
		c.touchee.connect(_multi_ouvrir.bind(i))
		multi.add_child(c)
		multi_cartes.append(c)
	multi_vedette = CarteView.new()
	multi_vedette.visible = false
	multi.add_child(multi_vedette)
	multi_rituel = Rituel.new()
	multi.add_child(multi_rituel)
	var bas := (places[9] as Vector2).y + LARGEUR_MULTI * 1.4
	multi_voir = Style.libelle(multi, "Touche une carte pour la voir en grand.", Rect2(40, bas + 18, 1000, 48), "italique", 34,
		Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	btn_multi_encore = Style.bouton(multi, "Encore ×10", Rect2(40, bas + 84, 490, 140), true, 48)
	btn_multi_encore.pressed.connect(_invoquer_dix)
	btn_multi_fermer = Style.bouton(multi, "Fermer", Rect2(550, bas + 84, 490, 140), false, 48)
	btn_multi_fermer.pressed.connect(func():
		multi.visible = false
		multi_ferme.emit())
	multi_banniere = _nouvelle_banniere(multi)


# Les probabilités d'un ciel (l'Astrolabe, « Les probabilités ») : refaites à chaque ouverture, pour le ciel demandé.
func montrer_probas(p_portail := "grand") -> void:
	for c in probas.get_children():
		probas.remove_child(c)
		c.queue_free()
	_voile(probas)
	# 🔴 Deux tirages à chaque carte (27/09) : son rang (sbire, héros, mythe, légende), puis sa variante.
	#    Les deux tables s'affichent dès le premier jour (Apple, Google Play), calculées depuis les poids — ceux du ciel.
	var cartes := GS.probas_cartes(p_portail)
	var variantes := GS.probas(p_portail)
	var fiche := Portails.fiche(p_portail)
	var regle := "Dans un rang, chaque carte a la même chance. Toute carte peut tomber dans chaque variante ; un prismatique ou un Full art tombe toujours sur une carte qui ne l'a pas encore, tant qu'il en reste dans son rang. Chaque carte donne 5 éclats, un doublon davantage. Le premier pack, offert, garantit au moins 5 cartes différentes, dont 3 héros."
	var haut_regle := 200.0
	if p_portail == "peintre":
		regle = "Le Full art y tombe deux fois plus, et toujours sur un Héros, un Mythe ou une Légende, qui ne l'a pas encore. Sans Full art, la centième invocation en donne un d'office. Au premier Full art, ce ciel se referme. La première invocation ×10 est offerte. Dans un rang, chaque carte a la même chance ; chaque carte donne 5 éclats, un doublon davantage."
		haut_regle = 250.0
	var h := 460.0 + (cartes.size() + variantes.size()) * 78.0 + 2.0 * 70.0 + haut_regle
	var p := Style.panneau(probas, Rect2(90, (2400.0 - h) * 0.5, 900, h), Color(0.047, 0.063, 0.059, 0.97), 44)
	Style.libelle(p, "PROBABILITÉS", Rect2(0, 54, 900, 40), "etiquette", 26, Style.OR_FILET, HORIZONTAL_ALIGNMENT_CENTER, 6)
	Style.libelle(p, str(fiche["nom"]), Rect2(0, 100, 900, 80), "italique", 58, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	var y := 200.0
	Style.libelle(p, "LA CARTE", Rect2(80, y, 740, 50), "etiquette", 24, Style.OR_FILET, HORIZONTAL_ALIGNMENT_LEFT, 5)
	y += 64.0
	for e in cartes:
		if int(e["n"]) == 0:
			continue
		_ligne_proba(p, y, "%s  ·  %d cartes" % [e["nom"], int(e["n"])], float(e["pct"]))
		y += 78.0
	y += 10.0
	Style.libelle(p, "SA VARIANTE", Rect2(80, y, 740, 50), "etiquette", 24, Style.OR_FILET, HORIZONTAL_ALIGNMENT_LEFT, 5)
	y += 64.0
	for e in variantes:
		_ligne_proba(p, y, str(e["nom"]), float(e["pct"]))
		y += 78.0
	Style.libelle(p, regle, Rect2(70, y + 16, 760, haut_regle), "italique", 30, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var f := Style.bouton(p, "Fermer", Rect2(80, h - 160, 740, 120), false, 46)
	f.pressed.connect(func(): probas.visible = false)
	probas.visible = true
	couche.visible = true
	couche.move_child(probas, -1)


func _ligne_proba(p: Control, y: float, nom: String, pct: float) -> void:
	var filet := ColorRect.new()
	filet.color = Style.OR_FILET_2
	filet.position = Vector2(70, y)
	filet.size = Vector2(760, 2)
	filet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(filet)
	Style.libelle(p, nom, Rect2(80, y + 6, 560, 66), "normal", 40, Style.IVOIRE)
	Style.libelle(p, _pct(pct), Rect2(560, y + 6, 260, 66), "fort", 40, Style.OR, HORIZONTAL_ALIGNMENT_RIGHT)


# ─────────────────────────────────────────────────────────────
# Mes decks, en haut de l'Atlas (27/09 : Maxim le voulait ici, à la place de l'invocation)
# ─────────────────────────────────────────────────────────────

# Le deck qui combat : son nom, son poids, ses 5 cartes en petit.
func _maj_deck() -> void:
	for c in _deck_contenu.get_children():
		_deck_contenu.remove_child(c)
		c.queue_free()
	var cartes := Decks.deck_actif()
	var ech := 104.0 / CarteCarre.LARGEUR
	for i in MoteurCarre.TAILLE_DECK:
		var centre := Vector2(98.0 + i * 118.0, 178.0)
		if i < cartes.size():
			var cc := CarteCarre.new()
			_deck_contenu.add_child(cc)
			cc.configurer(cartes[i], "j")
			cc.scale = Vector2(ech, ech)
			cc.position = centre - CarteCarre.TAILLE * 0.5
			cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			Dessin.ajouter(_deck_contenu, Rect2(centre - Vector2(52, 73), Vector2(104, 146)), func(ci: CanvasItem):
				ci.draw_rect(Rect2(Vector2(2, 2), Vector2(100, 142)), Color(Style.IVOIRE, 0.18), false, 2.0, true))
	var k := Decks.actif()
	Style.libelle(_deck_contenu, Decks.nom(k), Rect2(690, 58, 300, 62), "italique", 48, Style.IVOIRE)
	var raison := Decks.pourquoi(cartes)
	Style.libelle(_deck_contenu, "INCOMPLET" if raison != "" else "POIDS %d / %d" % [MoteurCarre.poids_deck(cartes), MoteurCarre.POIDS_MAX],
		Rect2(692, 118, 300, 40), "etiquette", 22, Color("#ec8f9a") if raison != "" else Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 4)


func _ouvrir_decks() -> void:
	_page.visible = false
	_decks.visible = true
	_decks.montrer_liste()
	_decks.modulate.a = 0.0
	_decks.create_tween().tween_property(_decks, "modulate:a", 1.0, 0.2)


func _fermer_decks() -> void:
	_decks.visible = false
	_page.visible = true
	_maj_deck()


# ─────────────────────────────────────────────────────────────
# La collection
# ─────────────────────────────────────────────────────────────

func _rafraichir() -> void:
	var n_sbires := 0
	for id in GS.cartes:
		if GS.est_sbire(str(id)):
			n_sbires += 1
	lbl_collection.text = "TA COLLECTION · %d HÉROS SUR %d" % [GS.cartes.size() - n_sbires, GS.HEROS.size()]
	lbl_eclats.text = Style.nombre(GS.eclats)
	for rg in ORDRE_RANGS:
		var ids := GS.ids_du_rang(rg)
		var eus := 0
		for id in ids:
			if GS.cartes.has(id):
				eus += 1
		(titres_rangs[rg] as Label).text = "%s · %d SUR %d" % [NOMS_SECTIONS[rg], eus, ids.size()]
	_maj_encore()
	if detail.visible and selection != "":
		_maj_detail()
	# La grille ne se reconstruit que si on la regarde : les gains de la
	# poussette déclenchent aussi « changed ».
	if not is_visible_in_tree():
		_sale = true
		return
	_sale = false
	_maj_deck()
	_maj_grille()
	# les photos qui manquent (une collection d'avant les photos, une carte qui a changé) :
	# demandées ici ; s'il en manque plusieurs, l'écran « Préparation » les attend
	for id in GS.cartes:
		var e: Dictionary = GS.cartes[id]
		vignettes.demander(GS.heros(str(id)), int(e["stade"]), str(e["variante"]))
	vignettes.demander(GS.HEROS[0], 1, "base", false)
	if vignettes.restantes() >= 3:
		_montrer_preparation()


# ─────────────────────────────────────────────────────────────
# LA GRILLE RECYCLÉE (25/09) — pensée pour des centaines de cartes.
# Il n'existe que les cases qu'on voit (et une rangée de chaque côté) : en défilant, celles
# qui sortent sont réutilisées pour celles qui entrent. La carte d'indice i va toujours dans
# la case i % nombre de cases : quand une rangée entre, seules ses cases sont refaites.
# Chaque case montre la PHOTO de sa carte (vignettes.gd) : rien ne se construit ni ne
# s'anime pendant qu'on défile.
# ─────────────────────────────────────────────────────────────

const COLONNES := 2
const GRILLE_HSEP := 28.0
var _cases: Array = []          # {"noeud", "image", "rangee", "niv", "var", "decouvrir", "id", "sig", "cle", ...}
var _ids: Array = []            # les héros, puis les sbires, dans l'ordre de la grille ("" : une case vide)
var titres_rangs := {}          # rang -> son titre dans la grille (28/09 : l'Atlas rangé par rang)
var _sections: Array = []        # [{rang, debut}] : où commence chaque rang dans _ids
const ORDRE_RANGS := ["legende", "mythe", "heros", "sbire"]
const NOMS_SECTIONS := {"legende": "LES LÉGENDES", "mythe": "LES MYTHES", "heros": "LES HÉROS", "sbire": "LES SBIRES"}
const TITRE_SBIRES_H := 110.0
var rev_etiquette: Label          # « INVOCATION », puis le rang de la carte, au retournement (28/09)
var _multi_etiquettes: Array = []  # les rangs posés sur les Mythes et les Légendes d'une ×10
var _premiere_ligne := -1
var _preparation: Control
var _prep_texte: Label
var _prep_barre: Control
var _prep_total := 0


func _pas_ligne() -> float:
	return LARGEUR_MINI * 1.4 + LEGENDE_H + GRILLE_VSEP


func _maj_grille() -> void:
	vignettes.echelle = get_viewport().get_final_transform().get_scale().x
	# 🔴 L'Atlas rangé par rang (28/09) : les Légendes, les Mythes, les Héros, les sbires — chacun sous son titre, sur une
	#    rangée neuve. (Avant : tous les héros, puis les sbires.)
	_ids.clear()
	_sections.clear()
	for rg in ORDRE_RANGS:
		while _ids.size() % COLONNES != 0:
			_ids.append("")
		_sections.append({"rang": rg, "debut": _ids.size()})
		_ids.append_array(GS.ids_du_rang(rg))
	var lignes := ceili(_ids.size() / float(COLONNES))
	grille.custom_minimum_size = Vector2(1000, lignes * _pas_ligne() + _sections.size() * TITRE_SBIRES_H)
	for k in _sections.size():
		var t: Label = titres_rangs[_sections[k]["rang"]]
		t.position.y = (int(_sections[k]["debut"]) / COLONNES) * _pas_ligne() + k * TITRE_SBIRES_H + 12.0
	var rangees := ceili(defil.size.y / _pas_ligne()) + 2
	while _cases.size() < rangees * COLONNES:
		_cases.append(_nouvelle_case())
	_placer_cases(true)


# Les cases à leur place, pour ce qu'on voit (et une rangée de chaque côté).
func _placer_cases(tout := false) -> void:
	if _cases.is_empty():
		return
	var l0 := maxi(0, int(float(defil.scroll_vertical) / _pas_ligne()) - 1)
	if l0 == _premiere_ligne and not tout:
		return
	_premiere_ligne = l0
	vignettes.oublier_demandes()
	var n := _cases.size()
	var montrees := {}
	for index in range(l0 * COLONNES, l0 * COLONNES + n):
		var c: Dictionary = _cases[index % n]
		montrees[index % n] = true
		var noeud: Control = c["noeud"]
		if index >= _ids.size() or str(_ids[index]) == "":
			noeud.visible = false
			c["id"] = ""
			continue
		noeud.visible = true
		noeud.position = Vector2((index % COLONNES) * (LARGEUR_MINI + GRILLE_HSEP),
			(index / COLONNES) * _pas_ligne() + (_section_de(index) + 1) * TITRE_SBIRES_H)
		_affecter(c, str(_ids[index]), tout)


# La section (0 : les Légendes… 3 : les sbires) où tombe une case de la grille.
func _section_de(index: int) -> int:
	var k := 0
	for i in _sections.size():
		if index >= int(_sections[i]["debut"]):
			k = i
	return k


func _nouvelle_case() -> Dictionary:
	var c := {"id": "", "sig": "", "cle": "", "stade": 1, "n": 1, "type": "aucun", "possedees": []}
	var noeud := Control.new()
	noeud.size = Vector2(LARGEUR_MINI, LARGEUR_MINI * 1.4 + LEGENDE_H)
	noeud.mouse_filter = Control.MOUSE_FILTER_PASS
	grille.add_child(noeud)
	c["noeud"] = noeud
	var m := vignettes.marge()
	var image := TextureRect.new()
	image.position = Vector2(-m, -m)
	image.size = Vector2(LARGEUR_MINI + 2.0 * m, LARGEUR_MINI * 1.4 + 2.0 * m)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_PASS
	noeud.add_child(image)
	c["image"] = image
	_toucher_pour_ouvrir(image, c)
	# la légende : les pastilles du stade, le niveau, la variante (à sa couleur), les gemmes
	var rangee := HBoxContainer.new()
	rangee.position = Vector2(0, LARGEUR_MINI * 1.4 + 10.0)
	rangee.size = Vector2(LARGEUR_MINI, LEGENDE_H - 10.0)
	rangee.alignment = BoxContainer.ALIGNMENT_CENTER
	rangee.add_theme_constant_override("separation", 14)
	rangee.mouse_filter = Control.MOUSE_FILTER_IGNORE
	noeud.add_child(rangee)
	c["rangee"] = rangee
	var pastilles := Control.new()
	pastilles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pastilles.draw.connect(func():
		for i in int(c["n"]):
			var p := Vector2(11.0 + i * 22.0, 20.0)
			if i < int(c["stade"]):
				pastilles.draw_circle(p, 7.0, Style.OR, true, -1.0, true)
			else:
				pastilles.draw_circle(p, 6.0, Style.OR_FILET, false, 2.0, true))
	rangee.add_child(pastilles)
	c["pastilles"] = pastilles
	c["niv"] = Style.libelle(rangee, "", Rect2(0, 0, 0, 40), "normal", 34, Style.IVOIRE)
	c["var"] = Style.libelle(rangee, "", Rect2(0, 0, 0, 40), "italique", 34, Style.IVOIRE)
	var gemmes := Control.new()
	gemmes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gemmes.draw.connect(func():
		var ps: Array = c["possedees"]
		for i in ps.size():
			var p := Vector2(9.0 + i * 18.0, 20.0)
			gemmes.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -8), p + Vector2(6, 0), p + Vector2(0, 8),
				p + Vector2(-6, 0)]), _couleur_variante(str(ps[i]), str(c["type"]))))
	rangee.add_child(gemmes)
	c["gemmes"] = gemmes
	c["decouvrir"] = Style.libelle(noeud, "À découvrir", Rect2(0, LARGEUR_MINI * 1.4 + 10.0, LARGEUR_MINI, LEGENDE_H - 10.0),
		"italique", 34, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	return c


# Ce qui fait qu'une case doit être refaite.
static func _signature(id: String) -> String:
	if not GS.cartes.has(id):
		return "?"
	var e: Dictionary = GS.cartes[id]
	return "%d|%s|%d|%d" % [int(e["stade"]), str(e["variante"]), int(e["niveau"]), (e["variantes"] as Array).size()]


func _affecter(c: Dictionary, id: String, tout: bool) -> void:
	var sig := _signature(id)
	if str(c["id"]) == id and str(c["sig"]) == sig and not tout:
		return
	c["id"] = id
	c["sig"] = sig
	var h: Dictionary = GS.heros(id)
	var possedee := GS.cartes.has(id)
	var stade := int(GS.cartes[id]["stade"]) if possedee else 1
	var variante := str(GS.cartes[id]["variante"]) if possedee else "base"
	var k := vignettes.cle(id, stade, variante, possedee)
	c["cle"] = k
	var tex := vignettes.texture(k)
	var image: TextureRect = c["image"]
	image.texture = tex if tex != null else vignettes.dos
	image.modulate = Color(1, 1, 1, 1) if possedee else Color(0.55, 0.58, 0.57, 0.7)
	(c["rangee"] as Control).visible = possedee
	(c["decouvrir"] as Control).visible = not possedee
	if not possedee:
		return
	var e: Dictionary = GS.cartes[id]
	var type_id := str(h["type"])
	c["stade"] = stade
	c["n"] = GS.stade_max(id)
	c["type"] = type_id
	var ps: Array = (e["variantes"] as Array).duplicate()
	ps.sort_custom(func(a, b) -> bool: return GS.rang_variante(str(a)) < GS.rang_variante(str(b)))
	c["possedees"] = ps if ps.size() > 1 else []
	var pastilles: Control = c["pastilles"]
	pastilles.custom_minimum_size = Vector2(int(c["n"]) * 22.0, 40.0)
	pastilles.queue_redraw()
	var gemmes: Control = c["gemmes"]
	gemmes.custom_minimum_size = Vector2((c["possedees"] as Array).size() * 18.0, 40.0)
	gemmes.visible = not (c["possedees"] as Array).is_empty()
	gemmes.queue_redraw()
	(c["niv"] as Label).text = "Sbire" if GS.est_sbire(id) else "LVL %d" % int(e["niveau"])
	var lv: Label = c["var"]
	lv.text = str(GS.variante(variante)["nom"])
	lv.add_theme_color_override("font_color", _couleur_variante(variante, type_id))


# Une photo est prête (relue ou prise) : la case qui l'attend la montre ; le dos, s'il vient
# d'arriver, va à toutes les cases qui attendent encore la leur.
func _vignette_prete(cle: String, tex: Texture2D) -> void:
	for c in _cases:
		var image: TextureRect = c["image"]
		if str(c["cle"]) == cle:
			image.texture = tex
		elif cle.begins_with("dos-") and image.texture == null:
			image.texture = tex


# Toucher une carte (sans faire défiler) l'ouvre en grand.
func _toucher_pour_ouvrir(image: Control, c: Dictionary) -> void:
	var appui := [Vector2.ZERO, false]
	image.gui_input.connect(func(ev: InputEvent):
		var b := ev as InputEventMouseButton
		if b != null and b.button_index == MOUSE_BUTTON_LEFT:
			if b.pressed:
				appui[0] = b.global_position
				appui[1] = true
			elif appui[1]:
				appui[1] = false
				if b.global_position.distance_to(appui[0]) < 24.0 and str(c["id"]) != "":
					_ouvrir(str(c["id"]))           # (28/09 : même une carte qu'on n'a pas — pour l'obtenir)
		var mv := ev as InputEventMouseMotion
		if mv != null and appui[1] and mv.global_position.distance_to(appui[0]) >= 24.0:
			appui[1] = false)


# ─────────────────────────────────────────────────────────────
# « Préparation de ta collection » : quand plusieurs photos manquent (la première fois, ou
# une collection d'avant les photos), on les prend d'affilée derrière un écran qui le dit,
# au lieu de laisser la grille ramer.
# ─────────────────────────────────────────────────────────────

func _construire_preparation() -> void:
	_preparation = Control.new()
	_preparation.position = defil.position
	_preparation.size = defil.size
	_preparation.mouse_filter = Control.MOUSE_FILTER_STOP
	_preparation.visible = false
	add_child(_preparation)
	var voile := ColorRect.new()
	voile.color = Color(0.03, 0.04, 0.035, 0.94)
	voile.size = defil.size
	voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preparation.add_child(voile)
	Style.libelle(_preparation, "Préparation de ta collection", Rect2(0, 520, defil.size.x, 80), "italique", 56,
		Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	_prep_texte = Style.libelle(_preparation, "", Rect2(0, 610, defil.size.x, 50), "etiquette", 26, Style.OR_FILET,
		HORIZONTAL_ALIGNMENT_CENTER, 5)
	var piste := ColorRect.new()
	piste.color = Color(1, 1, 1, 0.08)
	piste.position = Vector2(200, 690)
	piste.size = Vector2(defil.size.x - 400, 10)
	piste.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preparation.add_child(piste)
	var barre := Style.icone(_preparation, Style.degrade(PackedColorArray([Style.JADE_F, Style.JADE]), PackedFloat32Array([0.0, 1.0]), false),
		Rect2(200, 690, 0, 10))
	barre.stretch_mode = TextureRect.STRETCH_SCALE
	_prep_barre = barre
	Style.libelle(_preparation, "Une seule fois : chaque carte est ensuite gardée sur ton téléphone.",
		Rect2(60, 740, defil.size.x - 120, 50), "italique", 32, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	vignettes.photo_prise.connect(_photo_prise)


func _montrer_preparation() -> void:
	_prep_total = vignettes.restantes()
	_preparation.visible = true
	_photo_prise(_prep_total)


func _photo_prise(restantes: int) -> void:
	if _preparation == null or not _preparation.visible:
		return
	var faites := maxi(0, _prep_total - restantes)
	_prep_texte.text = "%d  CARTES  SUR  %d" % [faites, _prep_total]
	_prep_barre.size.x = (defil.size.x - 400.0) * (float(faites) / maxf(1.0, float(_prep_total)))
	if restantes == 0:
		var tw := create_tween()
		tw.tween_property(_preparation, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func():
			_preparation.visible = false
			_preparation.modulate.a = 1.0
			_placer_cases(true))


func _notification(what: int) -> void:
	# couche != null : l'écran peut changer de visibilité avant d'être construit.
	if what != NOTIFICATION_VISIBILITY_CHANGED or couche == null:
		return
	# Une CanvasLayer ne suit pas la visibilité de son parent : on la lui fait suivre — sauf ce que l'Astrolabe y montre
	# (28/09 : on invoque depuis l'Astrolabe, l'Atlas caché ; la révélation, la ×10, les probabilités vivent ici).
	couche.visible = is_visible_in_tree() or _couche_pour_astrolabe()
	if is_visible_in_tree() and _sale:
		_rafraichir()


# ─────────────────────────────────────────────────────────────
# La carte en grand
# ─────────────────────────────────────────────────────────────

func _ouvrir(id: String) -> void:
	selection = id
	detail.visible = true
	# au-dessus de tout, même de l'invocation ×10 d'où on vient peut-être
	couche.move_child(detail, -1)
	_maj_detail()
	# une carte qu'on ouvre se présente de face, même si on l'avait laissée sur son dos
	detail_carte.poser(0.0)


func _maj_detail() -> void:
	var h := GS.heros(selection)
	if h.is_empty():
		detail.visible = false
		return
	# 🔴 Une carte qu'on n'a pas (28/09, ⑧ lot B) : on la voit, au stade I, et « Obtenir » l'achète avec des éclats.
	var a := GS.cartes.has(selection)
	var e: Dictionary = GS.cartes[selection] if a else {"stade": 1, "variante": "base", "variantes": [], "niveau": 1}
	var st := int(e["stade"])
	var v := str(e["variante"])
	if detail_carte.h != h or detail_carte.stade != st or detail_carte.variante != v:
		detail_carte.configurer(h, st, v, LARGEUR_GRANDE)
	detail_carte.modulate = Color.WHITE if a else Color(0.72, 0.74, 0.73)
	detail_nom.text = str(h["nom"])
	var formes: Array = h["formes"]
	var sbire := GS.est_sbire(selection)
	var rang := GS.rang_nom(MoteurCarre.rang(selection))
	if not a:
		detail_info.text = "Pas encore à toi · %s" % ("Sbire" if sbire else rang)
	else:
		detail_info.text = ("Sbire · un seul stade" if sbire else "%s · stade %d sur %d · %s" % [formes[st - 1], st, GS.stade_max(selection), rang])
	# Les variantes : celles qu'on a (on choisit celle qu'on affiche), celles qu'on peut obtenir (leur prix en éclats,
	# deux touches), et le Full art, qui ne s'obtient qu'à l'invocation.
	for c in detail_variantes.get_children():
		detail_variantes.remove_child(c)
		c.queue_free()
	var possedees: Array = e["variantes"]
	for vv in GS.VARIANTES:
		var vid := str(vv["id"])
		var nom := str(vv["nom"])
		if possedees.has(vid):
			var active := vid == v
			var b := Style.bouton(detail_variantes, nom, Rect2(0, 0, 10, 80), active, 28)
			b.custom_minimum_size = Vector2(Style.police("normal").get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 44.0, 80)
			if not active:
				for c in ["font_color", "font_hover_color", "font_focus_color"]:
					b.add_theme_color_override(c, _couleur_variante(vid, str(h["type"])))
			b.pressed.connect(func():
				if GS.choisir_variante(selection, vid):
					_photographier_obtenue(GS.heros(selection)))
		elif a:
			# une variante qui manque : son prix (ou « chance », le Full art) — une pastille sombre, sur deux lignes
			var p := GS.prix(selection, vid)
			var texte := "%s\n%s" % [nom, Style.nombre(p) if p > 0 else "chance"]
			var b := Style.bouton(detail_variantes, texte, Rect2(0, 0, 10, 80), false, 22)
			b.custom_minimum_size = Vector2(Style.police("normal").get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 36.0, 80)
			b.modulate = Color(1, 1, 1, 0.78)
			for c in ["font_color", "font_hover_color", "font_focus_color"]:
				b.add_theme_color_override(c, _couleur_variante(vid, str(h["type"])))
			if p > 0:
				b.pressed.connect(func(): _obtenir(b, vid))
			else:
				b.pressed.connect(func(): Style.bulle(b, "Le Full art ne s'obtient qu'à l'invocation"))
	btn_obtenir.visible = not a
	btn_niveau.visible = a
	btn_evo.visible = a
	if not a:
		lvl_badge.visible = false
		var prix := GS.prix(selection, "base")
		btn_obtenir.text = "Obtenir · %s éclats" % Style.nombre(prix)
		btn_obtenir.disabled = GS.eclats < prix
		return
	# un sbire n'a pas de niveau (27/09) : ni badge, ni bouton qui promettrait autre chose ; au niveau maximum, rien à monter
	if sbire or GS.niveau_max(selection) <= 1:
		btn_niveau.text = "Pas de niveau\npour un sbire" if sbire else "Un seul stade :\npas de niveau"
	elif int(e["niveau"]) >= GS.niveau_max(selection):
		btn_niveau.text = "Niveau maximum\nLVL %d" % GS.niveau_max(selection)
	else:
		btn_niveau.text = "Monter d'un niveau\n%s poussière" % Style.nombre(GS.cout_niveau(selection))
	lvl_badge.visible = not sbire
	if not _lvl_anime and not sbire:
		_maj_badge(int(e["niveau"]))
	btn_niveau.disabled = not GS.peut_monter(selection)
	if st >= GS.stade_max(selection):
		btn_evo.text = "Stade maximum" if GS.stade_max(selection) > 1 else "Un seul stade"
		btn_evo.disabled = true
	else:
		# deux lignes courtes (« … 2 pierres de foudre » débordait du bouton, capture du 28/09)
		btn_evo.text = "Évoluer · LVL %d\n%s" % [GS.niveau_pour_evoluer(selection), GS.pierre_demandee(selection)]
		btn_evo.disabled = not GS.peut_evoluer(selection)


# Le badge « LVL n », épinglé sur le coin haut gauche de la carte en grand : le milieu du haut
# est à la pierre du chiffre du haut (la carte du Carré, v6).
func _maj_badge(n: int) -> void:
	lvl_nombre.text = str(n)
	lvl_badge.size = lvl_badge.get_minimum_size()
	var coin := (1080.0 - LARGEUR_GRANDE) * 0.5 + LARGEUR_GRANDE * 0.06
	lvl_badge.position = Vector2(coin - lvl_badge.size.x * 0.5 + 40.0, 190.0 - lvl_badge.size.y * 0.5)
	lvl_badge.pivot_offset = lvl_badge.size * 0.5


# Un chiffre de jeu : or, cerclé de sombre.
func _chiffre_or(parent: Control, taille: int) -> Label:
	var l := Style.libelle(parent, "", Rect2(0, 0, 10, taille + 20), "normal", taille, Style.OR_VIF)
	l.add_theme_color_override("font_outline_color", Color("#1a1208"))
	l.add_theme_constant_override("outline_size", maxi(6, taille / 7))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_y", maxi(3, taille / 16))
	return l


# 🔴 MONTER DE NIVEAU (FEATURES ⑮, 26/09) : la poussière file du bouton jusqu'à la carte — plus le
#    niveau coûte, plus il en entre (Maxim) —, la carte scintille, et le nouveau niveau éclate en
#    or avant de se ranger au-dessus de la carte.
func _monter_niveau() -> void:
	if selection == "" or not GS.peut_monter(selection) or _lvl_anime:
		return
	var cout := GS.cout_niveau(selection)
	_lvl_anime = true
	GS.monter_niveau(selection)
	Son.sonner("niveau")
	var neuf := int(GS.cartes[selection]["niveau"])
	var fx := Effets.pour(detail)
	var dep := btn_niveau.get_global_rect().get_center()
	var carte_r := Rect2(detail_carte.global_position, Vector2(LARGEUR_GRANDE, LARGEUR_GRANDE * 1.4))
	var cible := carte_r.get_center()
	var n := clampi(cout / 5, 12, 110)
	var etale := minf(1.0, 0.2 + n * 0.008)
	for g in n:
		fx.grain(dep + Vector2(randf_range(-150, 150), randf_range(-20, 20)), dep + Vector2(randf_range(-330, 330), randf_range(-600, -420)),
			cible + Vector2(randf_range(-150, 150), randf_range(-180, 180)), randf_range(0.56, 0.72), randf() * etale)
	await get_tree().create_timer(etale + 0.6).timeout
	if not detail.visible:
		_lvl_anime = false
		return
	detail_carte.pivot_offset = Vector2(LARGEUR_GRANDE, LARGEUR_GRANDE * 1.4) * 0.5
	var tp := detail_carte.create_tween()
	tp.tween_property(detail_carte, "scale", Vector2(1.05, 1.05), 0.14)
	tp.tween_property(detail_carte, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in 9:
		fx.etoile(carte_r.position + Vector2(randf() * carte_r.size.x, randf() * carte_r.size.y), randf_range(15, 33), 0.56, i * 0.07)
	for j in 5:
		fx.etoile(cible + Vector2(randf_range(-225, 225), randf_range(-105, 105)), randf_range(21, 36), 0.6, 0.12 + j * 0.06)
	# le nouveau niveau éclate en or, puis se range dans le badge
	var eclat := HBoxContainer.new()
	eclat.add_theme_constant_override("separation", 24)
	eclat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(eclat)
	var l := _chiffre_or(eclat, 78)
	l.text = "LVL"
	l.add_theme_font_override("font", Style.police("etiquette", 6))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nb := _chiffre_or(eclat, 192)
	nb.text = str(neuf)
	eclat.size = eclat.get_minimum_size()
	eclat.position = Vector2(540.0 - eclat.size.x * 0.5, carte_r.position.y + carte_r.size.y * 0.45 - eclat.size.y * 0.5)
	eclat.pivot_offset = eclat.size * 0.5
	eclat.scale = Vector2(2.6, 2.6)
	eclat.modulate.a = 0.0
	var vers := lvl_badge.get_global_rect().get_center() - eclat.size * 0.5
	var te := eclat.create_tween()
	te.set_parallel(true)
	te.tween_property(eclat, "scale", Vector2(0.92, 0.92), 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	te.tween_property(eclat, "modulate:a", 1.0, 0.2)
	te.chain().tween_property(eclat, "scale", Vector2(1.04, 1.04), 0.1)
	te.chain().tween_property(eclat, "scale", Vector2.ONE, 0.12)
	te.chain().tween_interval(0.8)
	te.chain().set_parallel(true)
	te.tween_property(eclat, "position", vers, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	te.tween_property(eclat, "scale", Vector2(0.3, 0.3), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	te.tween_property(eclat, "modulate:a", 0.2, 0.72)
	te.chain().tween_callback(func():
		eclat.queue_free()
		_lvl_anime = false
		_maj_badge(neuf)
		var tb := lvl_badge.create_tween()
		tb.tween_property(lvl_badge, "scale", Vector2(1.25, 1.25), 0.1)
		tb.tween_property(lvl_badge, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		fx.etincelles(lvl_badge.get_global_rect(), 3, 18.0))


# 🔴 ÉVOLUER (FEATURES ⑮, 26/09) : en plein écran (evolution.gd). La pierre utilisée est connue
#    AVANT l'évolution (elle la consomme).
# Obtenir une carte (ou une variante) avec ses éclats : deux touches — la première demande « Sûr ? », la seconde
# achète (une Légende prismatique, c'est 9 000 éclats : pas de faux pas).
func _obtenir(b: Button, v: String) -> void:
	if selection == "" or GS.prix(selection, v) <= 0:
		return
	if not b.has_meta("sur"):
		b.set_meta("sur", true)
		var avant := b.text
		b.text = "Sûr ?\n%s" % Style.nombre(GS.prix(selection, v)) if b != btn_obtenir else "Sûr ? · %s éclats" % Style.nombre(GS.prix(selection, v))
		var tw := b.create_tween()             # (lié au bouton : il s'arrête avec lui)
		tw.tween_interval(2.5)
		tw.tween_callback(func():
			b.remove_meta("sur")
			b.text = avant)
		return
	b.remove_meta("sur")
	if not GS.peut_obtenir(selection, v):
		Style.bulle(b, "Il te faut %s éclats" % Style.nombre(GS.prix(selection, v)))
		_maj_detail()
		return
	var r := GS.obtenir(selection, v)
	if r.is_empty():
		return
	var h := GS.heros(selection)
	_photographier_obtenue(h)
	Son.sonner("recevoir")
	Reglages.vibrer(30)
	Effets.pour(self).etincelles(Rect2(detail_carte.global_position, Vector2(LARGEUR_GRANDE, LARGEUR_GRANDE * 1.4)), 10, 30.0)
	_maj_detail()


func _evoluer() -> void:
	if selection == "" or not GS.peut_evoluer(selection):
		return
	var pierre := GS.pierre_pour_evoluer(selection)
	var e: Dictionary = GS.cartes[selection]
	var avant := int(e["stade"])
	if not GS.evoluer(selection):
		return
	var h := GS.heros(selection)
	_photographier_obtenue(h)
	var ev := Evolution.new()
	couche.add_child(ev)
	ev.lancer(h, avant, avant + 1, str(e["variante"]), pierre)


# ─────────────────────────────────────────────────────────────
# L'invocation simple : la carte arrive de dos, puis se retourne
# ─────────────────────────────────────────────────────────────

func _couche_pour_astrolabe() -> bool:
	return rev.visible or multi.visible or probas.visible


# L'Astrolabe lance une invocation dans un ciel ; « Encore » invoquera dans le même.
func invoquer_dans(p_portail: String, n: int) -> void:
	portail = p_portail
	couche.visible = true
	if n >= 10:
		_invoquer_dix()
	else:
		_invoquer()


func _invoquer() -> void:
	if not GS.peut_invoquer(1, portail):
		return
	var r := GS.invoquer(portail)
	if r.is_empty():
		return
	montrer_revelation(r)


# « Encore » : dans le même ciel ; un ciel refermé (le Full art du Peintre vient de tomber) n'en a plus.
func _maj_encore() -> void:
	var ouvert := Portails.ouvert(portail)
	btn_encore.text = "Encore · %s" % _etoiles(GS.etoiles)
	btn_encore.disabled = not GS.peut_invoquer(1, portail)
	btn_encore.visible = ouvert and _rev_fini and btn_rev_fermer.visible
	btn_multi_encore.disabled = not GS.peut_invoquer(10, portail)
	btn_multi_encore.visible = ouvert and _multi_fini and btn_multi_fermer.visible


# La teinte d'une carte révélée, pour ses constellations : ivoire quand rien n'est
# rare, or, argent, la couleur du type, irisé (prismatique et full art).
static func _portail_de(r: Dictionary) -> Array:
	match str(r["variante"]):
		"or":
			return [Color(1.0, 0.84, 0.5), "fixe"]
		"ombre":
			return [Color(0.82, 0.84, 0.9), "fixe"]
		"elem":
			return [GS.TYPES[str(r["heros"]["type"])]["clair"], "fixe"]
		"prisme", "full":
			return [Color.WHITE, "irise"]
	return [Style.IVOIRE, "fixe"]


# LA BANDE-SON DE L'INVOCATION (29/09 — Maxim : « ça doit être spectaculaire, ça doit marcher avec l'animation, le petit
# clap à la fin est horrible ») : une partition lue dans la scène du rituel, instant par instant — le souffle de l'astrolabe
# étiré jusqu'à son verrou, chaque étoile qui s'allume (de plus en plus haut), le verrou, les étoiles aspirées vers le cadran,
# le dos qui apparaît, la tension, la révélation au retournement. Les sons : design/sons/invocation.py ; la lecture : Son.partition.
func _partition_simple(ri: Rituel, tm: Dictionary, encore: Callable) -> void:
	var sc: Dictionary = ri._s
	var t_lock := float(sc["t_lock"])
	var ev: Array = [[0.0, "souffle", 0.0, Son.demi_tons_pour(t_lock)]]
	var ts: Array = []
	for e in sc["etoiles"]:
		ts.append(float(e["t_on"]))
	ev.append_array(Son.notes_etoiles(ts))
	ev.append([t_lock, "verrou", 0.0, 0.0])
	ev.append([t_lock + 0.25, "aspiration", 0.0, 0.0])        # à rebours : il finit quand les étoiles touchent le cadran
	ev.append([float(tm["t_carte"]), "apparition", 0.0, 0.0])
	ev.append([float(tm["t_carte"]), "tension", 0.0, 0.0])
	ev.append([float(tm["t_flip"]), "revelation", 0.0, 0.0])  # son accord tombe quand la carte montre sa face
	Son.partition(ev, encore)


# La ×10 : le souffle, les étoiles, le verrou ; les étoiles filent vers les dix places ; chaque dos arrive en montant la gamme.
# Les retournements sonnent un à un (_retourner) ; la vedette (une Légende, un Full art), la révélation.
func _partition_multi(ri: Rituel, tm: Dictionary, encore: Callable) -> void:
	var sc: Dictionary = ri._s
	var t_lock := float(sc["t_lock"])
	var ev: Array = [[0.0, "souffle", 0.0, Son.demi_tons_pour(t_lock)]]
	var ts: Array = []
	for e in sc["etoiles"]:
		ts.append(float(e["t_on"]))
	ev.append_array(Son.notes_etoiles(ts))
	ev.append([t_lock, "verrou", 0.0, 0.0])
	ev.append([t_lock + 0.35 + 0.05, "aspiration", 0.0, 0.0])
	var arr: Array = tm["arrivees"]
	for i in arr.size():
		ev.append([float(arr[i]), "arrivee", 0.0, float(Son.GAMME[mini(i, Son.GAMME.size() - 1)])])
	Son.partition(ev, encore)


# Une carte rare vient de se retourner : des éclats nets s'allument sur ses coins ;
# une très rare a son nom en grand.
func _eclat_rare(ri: Rituel, rect: Rect2, r: Dictionary, y_banniere: float) -> void:
	var rang := GS.rang_variante(str(r["variante"]))
	if rang == 0:
		return
	Son.rarete(rang)            # (29/09) plus la variante est rare, plus ses cloches sont riches
	var p := _portail_de(r)
	ri.coins(rect, p[0], p[1], 20.0 + 6.0 * rect.size.x / LARGEUR_GRANDE)
	if rang >= GS.rang_variante("prisme"):
		var ecran := ri.get_parent() as Control
		var full := rang >= GS.rang_variante("full")
		_banniere(rev_banniere if ecran == rev else multi_banniere, "FULL ART" if full else "PRISMATIQUE", y_banniere)


# Le nom d'une très rare, en grand, irisé : il claque, brille, s'efface.
func _nouvelle_banniere(parent: Control) -> Label:
	var l := Style.libelle(parent, "", Rect2(0, 0, 1080, 170), "etiquette", 104, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 16)
	l.pivot_offset = Vector2(540, 85)
	l.add_theme_constant_override("outline_size", 22)
	l.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.22))
	var m := ShaderMaterial.new()
	m.shader = SH_IRISE
	l.material = m
	l.visible = false
	return l


func _banniere(lbl: Label, texte: String, y: float) -> void:
	if _banniere_tween != null and _banniere_tween.is_valid():
		_banniere_tween.kill()
	lbl.text = texte
	lbl.position = Vector2(0, maxf(30.0, y))
	lbl.visible = true
	lbl.modulate = Color(1, 1, 1, 0)
	lbl.scale = Vector2(1.7, 1.7)
	var m := lbl.material as ShaderMaterial
	_banniere_tween = create_tween()
	_banniere_tween.tween_property(lbl, "modulate:a", 1.0, 0.18)
	_banniere_tween.parallel().tween_property(lbl, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banniere_tween.parallel().tween_method(func(x: float): m.set_shader_parameter("lumiere", Vector2(x, 0.3)), 0.0, 2.2, 2.4)
	_banniere_tween.tween_property(lbl, "modulate:a", 0.0, 0.4)
	_banniere_tween.tween_callback(func(): lbl.visible = false)


func _arreter_effets(ecran: Control) -> void:
	for t in [_secousse_tween, _banniere_tween]:
		if t != null and t.is_valid():
			t.kill()
	ecran.position = Vector2.ZERO
	rev_banniere.visible = false
	multi_banniere.visible = false


# Le retournement d'une carte : elle s'amincit, montre son recto, reprend sa largeur.
# « son » : celui de la bande-son de l'invocation (« flip », « revelation » ; vide : la partition s'en charge), lancé au
# début du retournement — son accent tombe quand la carte montre sa face.
func _retourner(tw: Tween, c: CarteView, echelle: float, duree: float, son := "", demi_tons := 0.0) -> void:
	if son != "":
		tw.tween_callback(func(): Son.inv(son, 0.0, demi_tons))
	tw.tween_property(c, "scale:x", 0.0, duree * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(c.montrer_recto.bind(true))
	tw.tween_property(c, "scale:x", echelle, duree * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Le rituel (FEATURES § ⑬) : l'astrolabe tourne et se verrouille, les constellations
# s'éparpillent sur l'écran — leur nombre dit la rareté —, leurs étoiles se posent sur
# le cadran, l'astrolabe se resserre en l'emblème du dos, et la carte se retourne.
func montrer_revelation(r: Dictionary) -> void:
	var h: Dictionary = r["heros"]
	var st := int(GS.cartes[h["id"]]["stade"]) if GS.cartes.has(h["id"]) else 1
	_rev_r = r
	_rev_fini = false
	rev.visible = true
	couche.visible = true        # (lancée de l'Astrolabe, l'Atlas caché)
	couche.move_child(rev, -1)
	rev_titre.text = ""
	rev_sous.text = ""
	rev_etiquette.text = "INVOCATION"
	rev_etiquette.add_theme_font_size_override("font_size", 28)
	rev_etiquette.add_theme_color_override("font_color", Style.OR_FILET)
	rev_etiquette.scale = Vector2.ONE
	btn_encore.visible = false
	btn_rev_fermer.visible = false
	rev_lueur.modulate = Color(1, 1, 1, 0)
	rev_rituel.effacer()
	rev_rituel_fond.effacer()
	_arreter_effets(rev)
	if _rev_tween != null and _rev_tween.is_valid():
		_rev_tween.kill()
	# 🔴 (28/09, « l'animation d'ouverture lag au début ») : 1. le voile paraît tout de suite (le doigt a sa réponse) ;
	#    2. l'illustration se décode sur ce voile immobile, puis part à la carte graphique (presque transparente, la carte
	#    est dessinée : envoyée) ; 3. le portail ne bouge qu'ensuite. Une pause sur un écran immobile ne se voit pas ; une
	#    saccade en plein mouvement, si. (Banc : tests/banc_invocation.)
	rev_carte.modulate = Color(1, 1, 1, 0)
	await get_tree().process_frame
	if _rev_fini or _rev_r != r:
		return                   # touché pendant l'attente (tout est déjà montré), ou une autre révélation a commencé
	rev_carte.configurer(h, st, str(r["variante"]), LARGEUR_GRANDE, false)
	rev_carte.position = _rev_pos
	rev_carte.pivot_offset = rev_carte.size * 0.5
	rev_carte.scale = Vector2(0.92, 0.92)
	rev_carte.modulate = Color(1, 1, 1, 0.004)
	await get_tree().process_frame
	if _rev_fini or _rev_r != r:
		return
	var centre := _rev_pos + rev_carte.size * 0.5
	var pc := _portail_de(r)
	var rang := GS.rang_variante(str(r["variante"]))
	# l'emblème du dos : son cercle extérieur fait 21 % de la largeur de la carte
	var tm := rev_rituel.simple(centre, 400.0, LARGEUR_GRANDE * 0.211, pc[0], pc[1], Rituel.nb_constellations(rang))
	_partition_simple(rev_rituel, tm, func() -> bool: return _rev_r == r and not _rev_fini)
	var tw := create_tween()
	_rev_tween = tw
	tw.tween_interval(tm["t_carte"])
	tw.tween_property(rev_carte, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(rev_carte, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(0.0, tm["t_flip"] - tm["t_carte"] - 0.3))
	_retourner(tw, rev_carte, 1.0, 0.4)
	tw.tween_callback(_annoncer_rang.bind(r, true))
	tw.tween_callback(_eclat_rare.bind(rev_rituel, Rect2(_rev_pos, rev_carte.size), r, _rev_pos.y - 200.0))
	tw.tween_callback(_fin_revelation.bind(r))


func _rev_toucher(ev: InputEvent) -> void:
	var b := ev as InputEventMouseButton
	if b == null or not b.pressed or _rev_fini:
		return
	if _rev_tween != null and _rev_tween.is_valid():
		_rev_tween.kill()
	rev_rituel.effacer()
	rev_rituel_fond.effacer()
	_arreter_effets(rev)
	rev_carte.position = _rev_pos
	rev_carte.scale = Vector2.ONE
	rev_carte.modulate = Color(1, 1, 1, 1)
	rev_carte.montrer_recto(true)
	Son.arreter_partition()
	Son.inv("revelation")
	Son.rarete(GS.rang_variante(str(_rev_r["variante"])))
	Son.rang(MoteurCarre.rang(str(_rev_r["heros"]["id"])))
	_fin_revelation(_rev_r)


# La photo de la carte telle qu'elle est maintenant dans la collection (sa variante affichée,
# son stade) : prise pendant l'écran de résultat, pour que la grille l'ait déjà.
func _photographier_obtenue(h: Dictionary) -> void:
	var id := str(h["id"])
	if GS.cartes.has(id):
		vignettes.echelle = get_viewport().get_final_transform().get_scale().x
		vignettes.demander(h, int(GS.cartes[id]["stade"]), str(GS.cartes[id]["variante"]))


static func _phrase(r: Dictionary) -> String:
	var nom_v := str(GS.variante(str(r["variante"]))["nom"])
	var ec := int(r.get("eclats", 0))
	if bool(r["nouvelle"]):
		return "Nouvelle carte · %s  ·  +%d éclats" % [nom_v, ec]
	if bool(r["amelioree"]):
		return "Nouvelle variante : elle passe en %s !  +%d éclats" % [nom_v, ec]
	if bool(r["nouvelle_variante"]):
		return "Nouvelle variante : %s rejoint ta collection.  +%d éclats" % [nom_v, ec]
	return "Déjà dans ta collection en %s : +%d éclats" % [nom_v, ec]


# Au retournement, « INVOCATION » devient le rang de la carte, dans sa couleur ; une Légende ou un Mythe claque (28/09).
func _annoncer_rang(r: Dictionary, anime: bool) -> void:
	var rg := MoteurCarre.rang(str(r["heros"]["id"]))
	var fort := rg == "legende" or rg == "mythe"
	rev_etiquette.text = Style.nom_rang(rg)
	rev_etiquette.add_theme_font_size_override("font_size", 52 if fort else 36)
	rev_etiquette.add_theme_color_override("font_color", Style.couleur_rang(rg))
	if not anime:
		return
	rev_etiquette.scale = Vector2(1.5, 1.5) if fort else Vector2(1.15, 1.15)
	rev_etiquette.create_tween().tween_property(rev_etiquette, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if fort:
		Effets.pour(self).etincelles(rev_etiquette.get_global_rect().grow(-10), 8 if rg == "legende" else 5, 26.0)
		Reglages.vibrer(40 if rg == "legende" else 20)
		Son.rang(rg)


func _fin_revelation(r: Dictionary) -> void:
	_rev_fini = true
	_annoncer_rang(r, false)
	var h: Dictionary = r["heros"]
	_photographier_obtenue(h)
	rev_titre.text = str(h["nom"])
	rev_sous.text = ("Le Full art garanti du Ciel du Peintre !  " if bool(r.get("garanti", false)) else "") + _phrase(r)
	btn_rev_fermer.visible = true
	_maj_encore()
	# le ciel s'est refermé sur ce Full art : « Fermer » seul, au milieu
	btn_rev_fermer.position.x = 550.0 if btn_encore.visible else 295.0


# ─────────────────────────────────────────────────────────────
# L'invocation ×10 : une constellation par carte, de la couleur de sa rareté.
# Ses étoiles filent vers la place de la carte, où son dos apparaît ; puis les
# cartes se retournent, les Base d'abord, la plus rare en dernier. Toucher
# l'écran retourne tout.
# ─────────────────────────────────────────────────────────────

func _invoquer_dix() -> void:
	if GS.premier_pack_du() and portail == "grand":
		var pack := GS.ouvrir_premier_pack()
		if pack.size() == 10:
			montrer_multi(pack)
		return
	if not GS.peut_invoquer(10, portail):
		return
	var lot := GS.invoquer_multi(10, portail)
	if lot.size() != 10:
		push_error("Invocation ×10 : %d cartes reçues au lieu de 10" % lot.size())
		return
	montrer_multi(lot)


func montrer_multi(lot: Array) -> void:
	_multi_lot = lot
	_multi_fini = false
	multi.visible = true
	couche.visible = true
	couche.move_child(multi, -1)
	multi_bilan.text = ""
	multi_aide.visible = true
	multi_voir.visible = false
	btn_multi_encore.visible = false
	btn_multi_fermer.visible = false
	multi_vedette.visible = false
	multi_rituel.effacer()
	multi_rituel_fond.effacer()
	_arreter_effets(multi)
	if _multi_tween != null and _multi_tween.is_valid():
		_multi_tween.kill()
	for l in _multi_etiquettes:
		if is_instance_valid(l):
			(l as Node).queue_free()
	_multi_etiquettes.clear()
	var places := _places_multi()
	# 🔴 (28/09) comme la révélation simple : le voile d'abord (les dix cartes cachées), puis les dix illustrations se
	#    décodent sur ce voile immobile, et le portail ne bouge qu'ensuite.
	for c in multi_cartes:
		(c as CanvasItem).modulate = Color(1, 1, 1, 0)
	await get_tree().process_frame
	if _multi_fini or _multi_lot != lot:
		return
	var meilleur: Dictionary = lot[0]
	for r in lot:
		if GS.rang_variante(str(r["variante"])) > GS.rang_variante(str(meilleur["variante"])):
			meilleur = r
	var pm := _portail_de(meilleur)
	var taille := Vector2(LARGEUR_MULTI, LARGEUR_MULTI * 1.4)
	var centres: Array = []
	var teintes: Array = []
	for i in 10:
		var r: Dictionary = lot[i]
		var h: Dictionary = r["heros"]
		var c: CarteView = multi_cartes[i]
		c.configurer(h, int(GS.cartes[h["id"]]["stade"]) if GS.cartes.has(h["id"]) else 1, str(r["variante"]), LARGEUR_MULTI, false)
		c.position = places[i]
		c.pivot_offset = taille * 0.5
		c.modulate = Color(1, 1, 1, 0.004)    # presque transparente : dessinée, donc envoyée à la carte graphique
		c.scale = Vector2(0.6, 0.6)
		(multi_lueurs[i] as TextureRect).modulate = Color(1, 1, 1, 0)
		centres.append(places[i] + taille * 0.5)
		teintes.append(_portail_de(r))
	# une Légende ou un Full art viendra au centre, en grand : son illustration pleine se charge ici, pas en plein vol
	for r in lot:
		if _en_vedette(r):
			var hv: Dictionary = r["heros"]
			CarteView.texture_art("res://cartes/%s-%d.jpg" % [hv["id"], int(GS.cartes[hv["id"]]["stade"]) if GS.cartes.has(hv["id"]) else 1])
	await get_tree().process_frame           # (envoyées à la carte graphique, sur le voile immobile)
	if _multi_fini or _multi_lot != lot:
		return
	var tm := multi_rituel.multiple(CENTRE_MULTI, 420.0, pm[0], pm[1], centres, teintes)
	_partition_multi(multi_rituel, tm, func() -> bool: return _multi_lot == lot and not _multi_fini)
	var tw := create_tween()
	_multi_tween = tw
	tw.tween_interval(0.01)
	# chaque dos apparaît quand les étoiles de sa constellation arrivent
	for i in 10:
		var c: CarteView = multi_cartes[i]
		var dl: float = tm["arrivees"][i] - 0.1
		tw.parallel().tween_property(c, "modulate:a", 1.0, 0.2).set_delay(dl)
		tw.parallel().tween_property(c, "scale", Vector2.ONE, 0.3).set_delay(dl).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(0.0, tm["t_retour"] - tm["arrivees"][9] - 0.2))
	# les retournements : de la moins rare à la plus rare
	var ordre := range(10)
	ordre.sort_custom(func(a, b):
		var ra := GS.rang_variante(str(lot[a]["variante"]))
		var rb := GS.rang_variante(str(lot[b]["variante"]))
		return ra < rb or (ra == rb and a < b))
	var rang_prisme := GS.rang_variante("prisme")
	var rang_full := GS.rang_variante("full")
	var prec := -1
	for i in ordre:
		var c: CarteView = multi_cartes[i]
		var r: Dictionary = lot[i]
		var rang := GS.rang_variante(str(r["variante"]))
		var place: Vector2 = places[i]
		if prec >= 0 and rang != prec:
			tw.tween_interval(0.3)
		prec = rang
		if _en_vedette(r):
			_vedette(tw, i, r, place)
			continue
		if rang >= rang_prisme:
			# les autres s'éteignent ; elle grandit, se retourne, son nom en grand
			tw.tween_callback(_assombrir.bind(i, 0.3))
			tw.tween_property(c, "scale", Vector2(1.12, 1.12), 0.25).set_trans(Tween.TRANS_SINE)
			_retourner(tw, c, 1.12, 0.36, "flip", 7.0)
			var y_nom := place.y - 175.0 if place.y > 500.0 else place.y + LARGEUR_MULTI * 1.4 + 12.0
			tw.tween_callback(_eclat_rare.bind(multi_rituel, Rect2(place - taille * 0.06, taille * 1.12), r, y_nom))
			tw.tween_interval(1.0)
			tw.tween_property(c, "scale", Vector2.ONE, 0.3)
			tw.tween_callback(_assombrir.bind(-1, 1.0))
			continue
		_retourner(tw, c, 1.0, 0.24 if rang == 0 else 0.34, "flip", float([0, 2, 4, 5, 7, 9][clampi(rang, 0, 5)]))
		if rang > 0:
			tw.tween_callback(_eclat_rare.bind(multi_rituel, Rect2(place, taille), r, 40.0))
			tw.tween_interval(0.25)
		else:
			tw.tween_interval(0.06)
	tw.tween_callback(_multi_fin)


# Les autres cartes s'éteignent pendant qu'une très rare se montre (v = 1 : elles
# se rallument). Son propre tween : on l'arrête si on touche l'écran.
func _assombrir(sauf: int, v: float) -> void:
	if _ombre_tween != null and _ombre_tween.is_valid():
		_ombre_tween.kill()
	_ombre_tween = create_tween().set_parallel(true)
	for j in 10:
		if j != sauf:
			_ombre_tween.tween_property(multi_cartes[j], "modulate", Color(v, v, v, (multi_cartes[j] as Control).modulate.a), 0.25)


# Le full art se montre en grand : la carte quitte sa place et vient au centre de
# l'écran (une carte à part, nette à cette taille), le reste s'éteint ; elle se
# retourne, son nom en grand, puis elle rejoint sa place.
# Qui vient au centre, en grand, dans une ×10 : un Full art, et (28/09) une Légende — sauf en prismatique, qui a déjà sa
# mise en scène.
func _en_vedette(r: Dictionary) -> bool:
	var rv := GS.rang_variante(str(r["variante"]))
	if rv >= GS.rang_variante("full"):
		return true
	return MoteurCarre.rang(str(r["heros"]["id"])) == "legende" and rv < GS.rang_variante("prisme")


func _vedette(tw: Tween, i: int, r: Dictionary, place: Vector2) -> void:
	var c: CarteView = multi_cartes[i]
	var h: Dictionary = r["heros"]
	var st := int(GS.cartes[h["id"]]["stade"]) if GS.cartes.has(h["id"]) else 1
	var taille_v := Vector2(LARGEUR_VEDETTE, LARGEUR_VEDETTE * 1.4)
	var ech := LARGEUR_MULTI / LARGEUR_VEDETTE
	var pos_centre := CENTRE_ECRAN - taille_v * 0.5
	var pos_place := place + Vector2(LARGEUR_MULTI, LARGEUR_MULTI * 1.4) * 0.5 - taille_v * 0.5
	tw.tween_callback(func():
		multi_vedette.configurer(h, st, str(r["variante"]), LARGEUR_VEDETTE, false)
		multi_vedette.pivot_offset = taille_v * 0.5
		multi_vedette.position = pos_place
		multi_vedette.scale = Vector2(ech, ech)
		multi_vedette.modulate = Color(1, 1, 1, 1)
		multi_vedette.visible = true
		c.modulate.a = 0.0
		_assombrir(i, 0.15))
	tw.tween_property(multi_vedette, "position", pos_centre, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(multi_vedette, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	_retourner(tw, multi_vedette, 1.0, 0.42, "revelation")
	tw.tween_callback(_eclat_rare.bind(multi_rituel, Rect2(pos_centre, taille_v), r, pos_centre.y - 190.0))
	# une Légende : son rang, en or, au-dessus d'elle (28/09)
	if MoteurCarre.rang(str(h["id"])) == "legende":
		tw.tween_callback(func():
			var l := Style.libelle(multi, "LÉGENDE", Rect2(0, pos_centre.y - 110.0, 1080, 90), "etiquette", 64, Style.couleur_rang("legende"),
				HORIZONTAL_ALIGNMENT_CENTER, 10)
			l.pivot_offset = l.size * 0.5
			l.scale = Vector2(1.5, 1.5)
			_multi_etiquettes.append(l)
			var tl := l.create_tween()
			tl.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tl.tween_interval(1.2)
			tl.tween_property(l, "modulate:a", 0.0, 0.3)
			Effets.pour(self).etincelles(Rect2(Vector2(300, pos_centre.y - 110.0), Vector2(480, 90)), 8, 26.0)
			Son.rang("legende")
			Reglages.vibrer(40))
	tw.tween_interval(1.7)
	tw.tween_property(multi_vedette, "position", pos_place, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(multi_vedette, "scale", Vector2(ech, ech), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		c.montrer_recto(true)
		c.modulate.a = 1.0
		multi_vedette.visible = false
		_assombrir(-1, 1.0))


func _multi_toucher(ev: InputEvent) -> void:
	var b := ev as InputEventMouseButton
	if b == null or not b.pressed or _multi_fini:
		return
	# tout retourner d'un coup, tout remettre en place
	if _multi_tween != null and _multi_tween.is_valid():
		_multi_tween.kill()
	if _ombre_tween != null and _ombre_tween.is_valid():
		_ombre_tween.kill()
	multi_rituel.effacer()
	multi_rituel_fond.effacer()
	_arreter_effets(multi)
	multi_vedette.visible = false
	var places := _places_multi()
	for i in 10:
		var c: CarteView = multi_cartes[i]
		c.position = places[i]
		c.modulate = Color(1, 1, 1, 1)
		c.scale = Vector2.ONE
		c.montrer_recto(true)
	Son.arreter_partition()
	Son.inv("revelation")
	_multi_fin()

func _multi_fin() -> void:
	_multi_fini = true
	for r in _multi_lot:
		_photographier_obtenue(r["heros"])
	_multi_fin_ms = Time.get_ticks_msec()
	multi_aide.visible = false
	var nouvelles := 0
	var variantes := 0
	var eclats := 0
	var rangs_vus := {}
	var meilleur: Dictionary = {}
	for r in _multi_lot:
		if bool(r["nouvelle"]):
			nouvelles += 1
		elif bool(r["nouvelle_variante"]):
			variantes += 1
		eclats += int(r.get("eclats", 0))
		if meilleur.is_empty() or GS.rang_variante(str(r["variante"])) > GS.rang_variante(str(meilleur["variante"])):
			meilleur = r
		var rg := MoteurCarre.rang(str(r["heros"]["id"]))
		rangs_vus[rg] = int(rangs_vus.get(rg, 0)) + 1
	var morceaux: Array = []
	if nouvelles > 0:
		morceaux.append("%d nouvelle%s carte%s" % [nouvelles, "s" if nouvelles > 1 else "", "s" if nouvelles > 1 else ""])
	if variantes > 0:
		morceaux.append("%d nouvelle%s variante%s" % [variantes, "s" if variantes > 1 else "", "s" if variantes > 1 else ""])
	if eclats > 0:
		morceaux.append("+%d éclats" % eclats)
	var txt := " · ".join(morceaux)
	# 🔴 le rang se dit (28/09) : les Légendes et les Mythes du tirage, comptés ; une étiquette sur chacune
	var rares: Array = []
	if int(rangs_vus.get("legende", 0)) > 0:
		rares.append("%d Légende%s" % [rangs_vus["legende"], "s" if int(rangs_vus["legende"]) > 1 else ""])
	if int(rangs_vus.get("mythe", 0)) > 0:
		rares.append("%d Mythe%s" % [rangs_vus["mythe"], "s" if int(rangs_vus["mythe"]) > 1 else ""])
	if not rares.is_empty():
		txt = " · ".join(rares) + " · " + txt
	var places := _places_multi()
	for i in _multi_lot.size():
		var rg := MoteurCarre.rang(str(_multi_lot[i]["heros"]["id"]))
		if rg != "legende" and rg != "mythe":
			continue
		# une pastille sur le coin haut gauche de SA carte (au-dessus, elle tombait sur la carte de la rangée d'avant :
		# quinconce ; au milieu, elle cachait le chiffre du haut — captures du 28/09)
		var pl: Vector2 = places[i]
		var l := Label.new()
		l.text = Style.nom_rang(rg)
		l.add_theme_font_override("font", Style.police("etiquette", 4))
		l.add_theme_font_size_override("font_size", 21)
		l.add_theme_color_override("font_color", Style.couleur_rang(rg))
		var sb := Style.boite(Color(0.043, 0.039, 0.063, 0.94), 16, Style.couleur_rang(rg), 2)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 4
		sb.content_margin_bottom = 2
		l.add_theme_stylebox_override("normal", sb)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		multi.add_child(l)
		l.size = l.get_minimum_size()
		l.position = Vector2(pl.x - 6.0, pl.y - l.size.y * 0.5 + 6.0)
		_multi_etiquettes.append(l)
	if not meilleur.is_empty() and GS.rang_variante(str(meilleur["variante"])) > 0:
		txt += "\nLe plus beau : %s en %s" % [meilleur["heros"]["nom"], GS.variante(str(meilleur["variante"]))["nom"]]
	multi_bilan.text = txt
	multi_voir.visible = true
	btn_multi_fermer.visible = true
	_maj_encore()
	btn_multi_fermer.position.x = 550.0 if btn_multi_encore.visible else 295.0


func _multi_ouvrir(i: int) -> void:
	# Le toucher qui a tout retourné finit par un relâcher sur une carte : il ne doit
	# pas l'ouvrir dans la foulée.
	if not _multi_fini or i >= _multi_lot.size() or Time.get_ticks_msec() - _multi_fin_ms < 400:
		return
	_ouvrir(str(_multi_lot[i]["heros"]["id"]))
