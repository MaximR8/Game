class_name DuelEcran
extends Control

# ─────────────────────────────────────────────────────────────
# L'ÉCRAN DU DUEL (étape 3 du Carré, fiche acceptée le 28/09 — maquette « Duel » du canevas du
# Voyage) : ta cote, la poussière du jour (5 cases), ton deck, tes derniers duels, et « Chercher un
# adversaire », qui lance le combat tout de suite (rapide : pas d'écran de plus).
# Il prête au Classé ses panneaux communs : la poussière du jour, ton deck.
# ─────────────────────────────────────────────────────────────

signal combattre(adv: Dictionary)
signal decks

const ECH_CARTE := 170.0 / CarteCarre.LARGEUR
const FOND := Color(0.035, 0.05, 0.047, 0.92)
const CARMIN := Color("#ec8f9a")


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func montrer() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_construire()


func _construire() -> void:
	Style.libelle(self, "Le Duel", Rect2(60, 352, 600, 100), "italique", 84, Style.IVOIRE)
	Style.libelle(self, "UN ADVERSAIRE DE TA FORCE", Rect2(64, 452, 640, 36), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	Style.libelle(self, "TA COTE", Rect2(620, 370, 400, 36), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_RIGHT, 5)
	Style.libelle(self, Style.nombre(Duel.cote()), Rect2(560, 400, 460, 90), "fort", 80, Style.OR_VIF, HORIZONTAL_ALIGNMENT_RIGHT)

	poussiere_du_jour(self, Rect2(40, 520, 1000, 220))
	panneau_deck(self, 770.0, func(): decks.emit())
	_derniers(1180.0)

	var go := Style.bouton(self, "Chercher un adversaire", Rect2(120, 1960, 840, 140), true, 54)
	var raison := Decks.pourquoi(Decks.deck_actif())
	go.disabled = raison != ""
	go.set_meta("pourquoi", raison)
	go.pressed.connect(func(): combattre.emit(Arene.adversaire_suivant("duel")))


# Tes derniers duels : le portrait, le nom, sa cote ; le score, ce que la cote a gagné ou perdu.
# Le panneau a la hauteur de ce qu'il montre (vide, il ne fait qu'une ligne).
func _derniers(y: float) -> void:
	var h: Array = Duel.donnees()["historique"]
	var p := Style.panneau(self, Rect2(40, y, 1000, 110.0 + maxi(1, h.size()) * 124.0), FOND, 34)
	Style.libelle(p, "TES DERNIERS DUELS", Rect2(40, 26, 700, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	if h.is_empty():
		Style.libelle(p, "Ton premier duel t'attend.", Rect2(40, 90, 920, 80), "italique", 40, Style.SOURD)
		return
	for k in h.size():
		var e: Dictionary = h[k]
		ligne_combat(p, e, 90.0 + k * 124.0, "COTE %s" % Style.nombre(int(e.get("cote", 0))), "%+d" % int(e.get("delta", 0)))


# Une ligne d'historique (le Duel ; le Classé s'en servira aussi).
static func ligne_combat(p: Control, e: Dictionary, y: float, sous_titre: String, chiffre: String) -> void:
	var res := int(e.get("res", 0))
	var coul := Style.JADE if res > 0 else (Style.SOURD if res == 0 else CARMIN)
	var chef := str(e.get("chef", ""))
	if MoteurCarre.fiche(chef).is_empty():
		chef = "wukong"
	Dessin.medaillon(p, chef, maxi(1, int(e.get("chef_s", 1))), Rect2(34, y, 104, 104))
	# le nom court (« Cerbère ») : « Cerbère, gardien des Enfers » mordait sur le score (capture du 28/09)
	Style.libelle(p, MoteurCarre.nom(chef), Rect2(160, y + 6, 440, 56), "italique", 42, Style.IVOIRE)
	Style.libelle(p, sous_titre, Rect2(162, y + 60, 470, 36), "etiquette", 22, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var texte := ""
	if bool(e.get("interrompu", false)):
		texte = "Abandon"
	elif res > 0:
		texte = "Victoire %d – %d" % [int(e.get("j", 0)), int(e.get("a", 0))]
	elif res < 0:
		texte = "Défaite %d – %d" % [int(e.get("j", 0)), int(e.get("a", 0))]
	else:
		texte = "Égalité"
	Style.libelle(p, texte, Rect2(600, y + 14, 250, 76), "normal", 34, coul, HORIZONTAL_ALIGNMENT_RIGHT)
	Style.libelle(p, chiffre.replace("-", "−"), Rect2(850, y + 14, 120, 76), "fort", 38, coul, HORIZONTAL_ALIGNMENT_RIGHT)


# ─────────────────────────────────────────────────────────────
# Les panneaux communs au Duel et au Classé
# ─────────────────────────────────────────────────────────────

# La poussière du jour : 5 cases, une par victoire (Duel ou Classé), et ce qu'il reste.
static func poussiere_du_jour(parent: Control, r: Rect2) -> Panel:
	var p := Style.panneau(parent, r, FOND, 34)
	var v := Arene.victoires_du_jour()
	Style.libelle(p, "LA POUSSIÈRE DU JOUR", Rect2(40, 24, 560, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	Style.libelle(p, "revient demain à minuit" if v >= Arene.VICTOIRES_JOUR else "Duel ou Classé",
		Rect2(560, 22, 400, 44), "italique", 30, Style.SOURD, HORIZONTAL_ALIGNMENT_RIGHT)
	var tex := Style.objet("poussiere-etoile")
	for k in Arene.VICTOIRES_JOUR:
		var gagne := k < v
		var c := Vector2(90.0 + k * 104.0, 130.0)
		Dessin.ajouter(p, Rect2(c - Vector2(46, 46), Vector2(92, 92)), func(ci: CanvasItem):
			ci.draw_circle(Vector2(46, 46), 42.0, Color(Style.OR_VIF, 0.14) if gagne else Color(0, 0, 0, 0.25))
			ci.draw_arc(Vector2(46, 46), 42.0, 0.0, TAU, 48, Style.OR_VIF if gagne else Color(Style.OR, 0.35), 3.0, true))
		Style.icone(p, tex, Rect2(c - Vector2(32, 32), Vector2(64, 64)), Color(1, 1, 1, 1.0 if gagne else 0.28))
	var texte := "%d victoire%s sur %d" % [v, "s" if v > 1 else "", Arene.VICTOIRES_JOUR]
	Style.libelle(p, texte, Rect2(620, 86, 360, 50), "fort", 36, Style.IVOIRE, HORIZONTAL_ALIGNMENT_RIGHT)
	Style.libelle(p, "× %d à chacune" % Arene.POUSSIERE_VICTOIRE, Rect2(620, 134, 360, 44), "normal", 30, Style.SOURD, HORIZONTAL_ALIGNMENT_RIGHT)
	return p


# Ton deck : celui que tu as choisi dans « Mes decks », ses 5 cartes, et « Changer ».
static func panneau_deck(parent: Control, y: float, changer: Callable) -> Panel:
	var p := Style.panneau(parent, Rect2(40, y, 1000, 380), FOND, 34)
	var deck := Decks.deck_actif()
	Style.libelle(p, "TON DECK  ·  %s" % Decks.nom(Decks.actif()).to_upper(), Rect2(40, 26, 460, 40), "etiquette", 24, Style.JADE,
		HORIZONTAL_ALIGNMENT_LEFT, 5)
	Style.libelle(p, "POIDS %d / %d" % [MoteurCarre.poids_deck(deck), MoteurCarre.POIDS_MAX], Rect2(440, 26, 260, 40), "etiquette", 24,
		Style.SOURD, HORIZONTAL_ALIGNMENT_RIGHT, 5)
	var b := Style.bouton(p, "Changer", Rect2(730, 12, 240, 70), false, 30)
	b.pressed.connect(changer)
	var l := 170.0
	var e := 18.0
	var x0 := 500.0 - (deck.size() * l + (deck.size() - 1) * e) * 0.5
	for k in deck.size():
		var cc := CarteCarre.new()
		p.add_child(cc)
		cc.configurer(deck[k], "j")
		cc.scale = Vector2(ECH_CARTE, ECH_CARTE)
		var centre := Vector2(x0 + k * (l + e) + l * 0.5, 100.0 + l * 1.4 * 0.5)
		cc.position = centre - CarteCarre.TAILLE * 0.5
	return p
