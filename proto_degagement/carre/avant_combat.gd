class_name AvantCombat
extends Control

# ─────────────────────────────────────────────────────────────
# AVANT LE COMBAT (l'Aventure, étape 2 du Carré, 27/09 — maquette « Avant le combat ») : qui on
# affronte, tout son deck (rien n'est caché : pas de hasard), la règle du niveau (ses terres),
# les 3 ★ à gagner, ce que rapporte la 1ʳᵉ victoire, ton deck, et « Combattre ».
# Maxim joue sans lire : une ligne par chose, en gros ; les ★ déjà gagnées sont allumées.
# ─────────────────────────────────────────────────────────────

signal combattre(n: int)
signal retour
signal decks

const ECH_CARTE := 170.0 / CarteCarre.LARGEUR

var n := 1
var _d: Dictionary = {}


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func montrer(p_n: int) -> void:
	n = p_n
	_d = Aventure.niveau(n)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_construire()


func _construire() -> void:
	var t: int = _d["terre"]
	var b := Style.bouton(self, "‹  %s" % Aventure.TERRES[t - 1]["nom"], Rect2(36, 250, 460, 84), false, 32)
	b.pressed.connect(func(): retour.emit())

	# qui on affronte
	Dessin.medaillon(self, str(_d["chef"]), int(_d["chef_s"]), Rect2(46, 356, 190, 190))
	var tag := "BOSS · NIVEAU %d" % n if _d["boss"] else "NIVEAU %d" % n
	Style.libelle(self, tag, Rect2(262, 366, 760, 40), "etiquette", 26, Style.OR_VIF, HORIZONTAL_ALIGNMENT_LEFT, 5)
	Style.libelle(self, str(_d["nom"]), Rect2(262, 404, 790, 84), "italique", 58 if str(_d["nom"]).length() < 22 else 48, Style.IVOIRE)
	Style.libelle(self, str(MoteurCarre.NIVEAUX[_d["niveau"]]).to_upper(), Rect2(262, 488, 400, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var y := 566.0
	if _d["boss"]:
		Style.libelle(self, "« %s »" % _d["replique"], Rect2(60, y, 960, 100), "italique", 36, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
		y += 114.0

	# son deck : tout se voit
	Style.libelle(self, "SON DECK", Rect2(60, y, 400, 36), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	_rangee(_d["deck"], "a", y + 44.0)
	y += 44.0 + 170.0 * 1.4 + 26.0

	# la règle du niveau, et ses 3 ★
	var p := Style.panneau(self, Rect2(40, y, 1000, 330), Color(0.035, 0.05, 0.047, 0.92), 34)
	Style.libelle(p, Aventure.regle(_d), Rect2(40, 26, 920, 50), "normal", 32, Style.IVOIRE, HORIZONTAL_ALIGNMENT_LEFT, 0, true)
	var m := Aventure.masque(n)
	var lignes := ["Gagner", "Gagner avec 6 cartes ou plus", Aventure.texte_defi(_d)]
	for k in 3:
		var ly := 100.0 + k * 72.0
		var bit := 1 << k
		Dessin.ajouter(p, Rect2(40, ly, 60, 60), func(ci: CanvasItem):
			if m & bit:
				Effets.dessiner_etoile(ci, Vector2(30, 30), 26.0, 1.0, 0.0, Effets.OR_CLAIR)
			else:
				Effets.dessiner_etoile(ci, Vector2(30, 30), 22.0, 0.4, 0.0, Dessin.GRIS))
		Style.libelle(p, lignes[k], Rect2(116, ly, 860, 60), "normal", 34, Style.IVOIRE if m & bit == 0 else Style.OR_VIF)
	y += 350.0

	# ce que rapporte la 1ʳᵉ victoire
	if not Aventure.gagne(n):
		var r: Dictionary = _d["recompense"]
		Style.libelle(self, "PREMIÈRE VICTOIRE", Rect2(60, y, 400, 70), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
		var x := 420.0
		for gain in [["poussiere-etoile", int(r["poussiere"])], ["etoile-invocation", int(r["etoiles"])]]:
			if gain[1] <= 0:
				continue
			Style.icone(self, Style.objet(gain[0]), Rect2(x, y - 4, 78, 78))
			Style.libelle(self, "× %d" % gain[1], Rect2(x + 84, y, 150, 70), "fort", 40, Style.OR_VIF)
			x += 250.0
	else:
		Style.libelle(self, "Déjà gagné : seules les ★ qui manquent rapportent.", Rect2(60, y, 960, 70), "italique", 32, Style.SOURD)
	y += 90.0

	# ton deck : celui que tu as choisi dans « Mes decks »
	var deck := Decks.deck_actif()
	Style.libelle(self, "TON DECK  ·  %s" % Decks.nom(Decks.actif()).to_upper(), Rect2(60, y, 460, 36), "etiquette", 24, Style.JADE,
		HORIZONTAL_ALIGNMENT_LEFT, 5)
	Style.libelle(self, "POIDS %d / %d" % [MoteurCarre.poids_deck(deck), MoteurCarre.POIDS_MAX], Rect2(470, y, 270, 36), "etiquette", 24,
		Style.SOURD, HORIZONTAL_ALIGNMENT_RIGHT, 5)
	var changer := Style.bouton(self, "Changer", Rect2(770, y - 18, 250, 70), false, 30)
	changer.pressed.connect(func(): decks.emit())
	_rangee(deck, "j", y + 64.0)

	var go := Style.bouton(self, "Combattre", Rect2(190, 1990, 700, 140), true, 58)
	var raison := Decks.pourquoi(deck)
	go.disabled = raison != ""
	go.set_meta("pourquoi", raison)
	go.pressed.connect(func(): combattre.emit(n))


# Cinq cartes en rang, à 170 px (la carte du combat, réduite).
func _rangee(cartes: Array, camp: String, y: float) -> void:
	var l := 170.0
	var e := 22.0
	var x0 := 540.0 - (cartes.size() * l + (cartes.size() - 1) * e) * 0.5
	for k in cartes.size():
		var cc := CarteCarre.new()
		add_child(cc)
		cc.configurer(cartes[k], camp)
		cc.scale = Vector2(ECH_CARTE, ECH_CARTE)
		var centre := Vector2(x0 + k * (l + e) + l * 0.5, y + l * 1.4 * 0.5)
		cc.position = centre - CarteCarre.TAILLE * 0.5
