class_name VoyageEcran
extends Control

# ─────────────────────────────────────────────────────────────
# LE VOYAGE — l'Aventure (étape 2 du Carré, FEATURES ligne 4, fiche acceptée le 27/09).
#
# Quatre vues, dans cet écran : le Voyage (le prochain combat, en grand, et les 10 terres) →
# une terre (chapitre_ecran.gd : sa constellation, ses coffres) → avant le combat
# (avant_combat.gd) ⇄ Mes decks (decks_ecran.gd). « Combattre » part vers l'écran de combat
# (main.gd), avec le deck choisi.
# Le tout premier combat reste le combat guidé (Maxim joue sans lire).
# Ton premier deck est celui qu'on compose tout seul (deck_auto : les 5 cartes les plus fortes,
# poids ≤ 14). Plus de cartes prêtées depuis le premier pack offert (28/09) : il en donne 5 au moins.
#
# ÉTAPE 3 (28/09) : trois onglets en haut — Aventure · Duel · Classé (maquettes du canevas du Voyage).
# Le Duel et le Classé (duel_ecran.gd, classe_ecran.gd) s'ouvrent quand le boss de la 1ʳᵉ terre est
# battu (Arene.ouvert) ; avant, leur onglet a un cadenas et dit qui battre.
# ─────────────────────────────────────────────────────────────

signal combattre(deck: Array, adversaire: Dictionary)

const JADE_TXT := Color("#7fd0b0")
# Le visage, dans une illustration (480 × 600) : un carré centré, dans le haut de l'image.
const REGION_VISAGE := Vector4(0.22, 0.10, 0.56, 0.448)

var bandeau: Bandeau
var _hub: Control
var _chapitre: ChapitreEcran
var _avant: AvantCombat
var _decks: DecksEcran
var _duel: DuelEcran
var _classe: ClasseEcran
var _onglets: Control
var _boutons_onglets := {}
var _vue := "hub"                  # hub (l'Aventure) · duel · classe · terre · avant · decks
var _retour_decks := "avant"       # d'où l'on vient quand on ouvre Mes decks
var bouton_jouer: Button           # « Jouer » / « Continuer » du hub (l'accueil du premier pack le montre)
var _terre_vue := 1
var _n_vu := 1


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hub = Control.new()
	_hub.size = size
	_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hub)
	_chapitre = ChapitreEcran.new()
	add_child(_chapitre)
	_chapitre.choisir.connect(ouvrir_avant)
	_chapitre.retour.connect(ouvrir_hub)
	_avant = AvantCombat.new()
	add_child(_avant)
	_avant.combattre.connect(func(n: int): combattre.emit(Decks.deck_actif(), Aventure.niveau(n)))
	_avant.retour.connect(func(): ouvrir_terre(Aventure.terre_de(_n_vu)))
	_avant.decks.connect(func():
		_retour_decks = "avant"
		_montrer("decks"))
	_decks = DecksEcran.new()
	add_child(_decks)
	_decks.retour.connect(func():
		if _retour_decks == "avant":
			ouvrir_avant(_n_vu)
		else:
			_montrer(_retour_decks))
	_duel = DuelEcran.new()
	add_child(_duel)
	_duel.combattre.connect(func(adv: Dictionary): combattre.emit(Decks.deck_actif(), adv))
	_duel.decks.connect(func():
		_retour_decks = "duel"
		_montrer("decks"))
	_classe = ClasseEcran.new()
	add_child(_classe)
	_classe.combattre.connect(func(adv: Dictionary): combattre.emit(Decks.deck_actif(), adv))
	_classe.decks.connect(func():
		_retour_decks = "classe"
		_montrer("decks"))
	_construire_onglets()
	rafraichir()


# À chaque arrivée sur le Voyage (main.gd), et au retour d'un combat : tout se relit (★, coffres).
func rafraichir() -> void:
	_chapitre.bandeau = bandeau
	_classe.bandeau = bandeau
	if _vue in ["duel", "classe"] and not Arene.ouvert():
		_vue = "hub"
	_montrer(_vue, false)


func ouvrir_hub() -> void:
	_montrer("hub")


func ouvrir_terre(t: int) -> void:
	_terre_vue = t
	_montrer("terre")


func ouvrir_avant(n: int) -> void:
	_n_vu = n
	_terre_vue = Aventure.terre_de(n)
	_montrer("avant")


func _montrer(vue: String, anime := true) -> void:
	_vue = vue
	match vue:
		"hub":
			_construire_hub()
		"terre":
			_chapitre.montrer(_terre_vue)
		"avant":
			_avant.montrer(_n_vu)
		"decks":
			_decks.montrer_liste()
		"duel":
			_duel.montrer()
		"classe":
			_classe.montrer()
	if vue == "classe" and _outils:
		_bouton_test_saison()
	var actif: Control = {"hub": _hub, "terre": _chapitre, "avant": _avant, "decks": _decks, "duel": _duel, "classe": _classe}[vue]
	for c in [_hub, _chapitre, _avant, _decks, _duel, _classe]:
		(c as Control).visible = c == actif
	_maj_onglets()
	if anime:
		actif.modulate.a = 0.0
		actif.position.y = 40.0
		var tw := actif.create_tween().set_parallel(true)
		tw.tween_property(actif, "modulate:a", 1.0, 0.2)
		tw.tween_property(actif, "position:y", 0.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ─────────────────────────────────────────────────────────────
# Les outils de test (D1, réseau local seulement : main.gd § outils_permis)
# ─────────────────────────────────────────────────────────────

var _outils := false


# « Ouvrir le Duel » : le Duel et le Classé s'ouvrent sans toucher la partie (rien n'est écrit).
func montrer_outils(v: bool) -> void:
	_outils = v
	Arene.ouvert_pour_test = v
	_montrer(_vue, false)


# « Fin de saison » : la saison retenue recule d'un mois — l'écran du Classé la clôt comme au 1er du mois
# (récompense comprise : elle est donnée pour de vrai, comme « +10 étoiles »).
func _bouton_test_saison() -> void:
	var b := Style.bouton(_classe, "Test : fin de saison", Rect2(760, 704, 280, 52), false, 22)
	b.pressed.connect(func():
		var c := Classe.donnees()
		var m := Classe.saison_actuelle().split("-")
		var an := int(m[0])
		var mois := int(m[1]) - 1
		if mois == 0:
			an -= 1
			mois = 12
		c["saison"] = "%04d-%02d" % [an, mois]
		c["joues"] = maxi(1, int(c["joues"]))
		_montrer("classe", false))


# ─────────────────────────────────────────────────────────────
# Les onglets : Aventure · Duel · Classé
# ─────────────────────────────────────────────────────────────

const ONGLETS := [["hub", "Aventure"], ["duel", "Duel"], ["classe", "Classé"]]


func _construire_onglets() -> void:
	_onglets = Control.new()
	_onglets.position = Vector2(40, 236)
	_onglets.size = Vector2(1000, 96)
	_onglets.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_onglets)
	var l := (1000.0 - 2 * 20.0) / 3.0
	for k in ONGLETS.size():
		var id: String = ONGLETS[k][0]
		var b := Style.bouton(_onglets, ONGLETS[k][1], Rect2(k * (l + 20.0), 0, l, 96), false, 40)
		_boutons_onglets[id] = b
		b.pressed.connect(func():
			if id != "hub" and not Arene.ouvert():
				Style.bulle(b, "Bats d'abord %s" % Arene.boss_a_battre())
				return
			if _vue != id:
				_montrer(id))
		# le cadenas des onglets scellés (redessiné à chaque changement de vue)
		if id != "hub":
			var cad := Dessin.ajouter(b, Rect2(0, 0, l, 96), func(ci: CanvasItem):
				if not Arene.ouvert():
					Dessin.cadenas(ci, Vector2(l - 44, 44), 1.1))
			b.set_meta("cadenas", cad)


func _maj_onglets() -> void:
	_onglets.visible = _vue in ["hub", "duel", "classe"]
	for id in _boutons_onglets:
		var b: Button = _boutons_onglets[id]
		Style.habiller(b, "jade" if id == _vue else "sombre")
		var ouvert: bool = id == "hub" or Arene.ouvert()
		b.modulate = Color.WHITE if ouvert else Color(0.7, 0.7, 0.7, 1.0)
		if b.has_meta("cadenas"):
			(b.get_meta("cadenas") as CanvasItem).queue_redraw()


# ─────────────────────────────────────────────────────────────
# Le Voyage : le prochain combat, puis les 10 terres
# ─────────────────────────────────────────────────────────────

func _construire_hub() -> void:
	for c in _hub.get_children():
		_hub.remove_child(c)
		c.queue_free()
	# (le titre « Le Voyage » a cédé sa place aux onglets, 28/09)
	Style.libelle(_hub, "10 TERRES DE LÉGENDES  ·  100 COMBATS  ·  ★ %d / 300" % Aventure.etoiles_total(),
		Rect2(0, 340, 1080, 44), "etiquette", 26, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 5)

	# le prochain combat
	var p := Style.panneau(_hub, Rect2(40, 404, 1000, 318), Color(0.035, 0.05, 0.047, 0.94), 40)
	var guide := not bool(GS.voyage.get("tuto_carre", false))
	var n := Aventure.prochain()
	var d := Aventure.niveau(n)
	if guide:
		Dessin.medaillon(p, "wukong", 1, Rect2(34, 44, 200, 200))
		Style.libelle(p, "TON PREMIER COMBAT", Rect2(262, 40, 700, 40), "etiquette", 25, JADE_TXT, HORIZONTAL_ALIGNMENT_LEFT, 5)
		Style.libelle(p, "Wukong l'espiègle", Rect2(262, 82, 700, 76), "italique", 54, Style.IVOIRE)
		Style.libelle(p, "GUIDÉ, PAS À PAS", Rect2(262, 158, 400, 40), "etiquette", 23, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	else:
		Dessin.medaillon(p, str(d["chef"]), int(d["chef_s"]), Rect2(34, 44, 200, 200))
		Style.libelle(p, "PROCHAIN COMBAT  ·  NIVEAU %d" % n, Rect2(262, 40, 700, 40), "etiquette", 25, JADE_TXT, HORIZONTAL_ALIGNMENT_LEFT, 5)
		Style.libelle(p, str(d["nom"]), Rect2(262, 82, 710, 76), "italique", 54 if str(d["nom"]).length() < 22 else 44, Style.IVOIRE)
		Style.libelle(p, "%s  ·  %s" % [str(Aventure.TERRES[d["terre"] - 1]["nom"]).to_upper(), str(MoteurCarre.NIVEAUX[d["niveau"]]).to_upper()],
			Rect2(262, 158, 720, 40), "etiquette", 23, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var b := Style.bouton(p, "Jouer" if guide else "Continuer", Rect2(560, 204, 400, 94), true, 44)
	bouton_jouer = b
	b.pressed.connect(func():
		if guide:
			combattre.emit(deck_auto(), CarreEcran.ADV_TUTO.duplicate(true))
		else:
			ouvrir_avant(n))

	# les 10 terres
	for t in range(1, Aventure.NB_TERRES + 1):
		_ligne_terre(t, 758.0 + (t - 1) * 138.0)


func _ligne_terre(t: int, y: float) -> void:
	var def: Dictionary = Aventure.TERRES[t - 1]
	var ouverte := Aventure.terre_ouverte(t)
	var boss := Aventure.niveau(t * Aventure.PAR_TERRE)
	var ligne := Control.new()
	ligne.position = Vector2(40, y)
	ligne.size = Vector2(1000, 126)
	ligne.pivot_offset = ligne.size * 0.5
	ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hub.add_child(ligne)
	var fond := Panel.new()
	fond.size = ligne.size
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond.add_theme_stylebox_override("panel", Style.boite(Color(0.035, 0.05, 0.047, 0.86 if ouverte else 0.55), 30,
		Style.OR_FILET if ouverte else Color(Style.OR_FILET, 0.25), 2))
	ligne.add_child(fond)
	if ouverte:
		Dessin.medaillon(ligne, str(boss["chef"]), int(boss["chef_s"]), Rect2(14, 11, 104, 104))
	else:
		Style.icone(ligne, Style.texture("res://interface/medaillon-sombre.png"), Rect2(14, 11, 104, 104), Color(1, 1, 1, 0.5))
		Dessin.ajouter(ligne, Rect2(14, 11, 104, 104), func(ci: CanvasItem): Dessin.cadenas(ci, Vector2(52, 56), 1.4))
	var coul := Style.IVOIRE if ouverte else Style.SOURD
	Style.libelle(ligne, str(def["nom"]), Rect2(142, 12, 600, 62), "italique", 44, coul)
	var etat := ""
	if not ouverte:
		etat = "SCELLÉE · BATS %s" % str(Aventure.niveau((t - 1) * Aventure.PAR_TERRE)["prenom"]).to_upper()
	elif Aventure.gagne(t * Aventure.PAR_TERRE):
		etat = "TERMINÉE"
	else:
		etat = "EN COURS"
	Style.libelle(ligne, "TERRE %d  ·  %s" % [t, etat], Rect2(144, 74, 640, 36), "etiquette", 21,
		Style.OR_VIF if ouverte and etat == "EN COURS" else Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 4)
	if ouverte:
		Style.libelle(ligne, "★ %d / 30" % Aventure.etoiles_terre(t), Rect2(760, 30, 210, 66), "fort", 38, Style.OR_VIF, HORIZONTAL_ALIGNMENT_RIGHT)
	var zone := Button.new()
	zone.flat = true
	zone.focus_mode = Control.FOCUS_NONE
	zone.size = ligne.size
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		zone.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	ligne.add_child(zone)
	Style.jeu(zone, ligne)
	zone.pressed.connect(func():
		if Aventure.terre_ouverte(t):
			ouvrir_terre(t)
		else:
			Style.bulle(ligne, "Bats d'abord %s" % Aventure.niveau((t - 1) * Aventure.PAR_TERRE)["nom"]))


# ─────────────────────────────────────────────────────────────
# Ton deck, composé tout seul
# ─────────────────────────────────────────────────────────────

# Les 5 cartes les plus fortes de la collection (MoteurCarre.force), poids ≤ 14 ; au besoin,
# des cartes prêtées (stade I) pour arriver à 5.
static func deck_auto() -> Array:
	# chaque carte à chacun des stades qu'elle a atteints : baisser le stade d'une carte forte vaut
	# souvent mieux que de la laisser dehors (les Légendes pèsent plus lourd, 27/09)
	var dispo := []
	for id in GS.cartes.keys():
		var e: Dictionary = GS.cartes[id]
		for s in range(Decks.stade_max(str(id)), 0, -1):
			dispo.append({"id": str(id), "s": s, "v": str(e["variante"])})
	dispo = MoteurCarre.trier(dispo, func(a, b): return float(MoteurCarre.force(b) - MoteurCarre.force(a)))
	dispo = dispo.slice(0, 16)
	var meilleur: Array = []
	var meilleur_f := -1
	var n := dispo.size()
	# toutes les combinaisons de 5 cartes distinctes parmi (au plus) 16 : 4 368 essais
	for a in n:
		for b in range(a + 1, n):
			for c in range(b + 1, n):
				for d in range(c + 1, n):
					for e in range(d + 1, n):
						var main := [dispo[a], dispo[b], dispo[c], dispo[d], dispo[e]]
						var vus := {}
						for x in main:
							vus[x["id"]] = true
						if vus.size() < MoteurCarre.TAILLE_DECK or MoteurCarre.poids_deck(main) > MoteurCarre.POIDS_MAX:
							continue
						var f := MoteurCarre.force_deck(main)
						if f > meilleur_f:
							meilleur_f = f
							meilleur = main
	if meilleur.is_empty():
		# rien ne tient dans le poids : les cinq plus légères, au stade I
		var vus := {}
		for x in dispo:
			if vus.has(x["id"]) or meilleur.size() >= MoteurCarre.TAILLE_DECK:
				continue
			vus[x["id"]] = true
			meilleur.append({"id": x["id"], "s": 1, "v": x["v"]})
	return meilleur
