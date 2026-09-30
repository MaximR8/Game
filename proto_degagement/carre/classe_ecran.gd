class_name ClasseEcran
extends Control

# ─────────────────────────────────────────────────────────────
# L'ÉCRAN DU CLASSÉ (étape 3 du Carré, fiche acceptée le 28/09 — maquette « Classé » du canevas du
# Voyage) : la saison et ce qu'il en reste ; ton rang en grand (son emblème, sa marche, la barre des
# points) ; l'échelle des six rangs ; la récompense de fin de saison ; la poussière du jour ; ton deck ;
# et « Combattre en classé ». Les emblèmes sortent de la fabrique (design/objets/render_rangs.py).
#
# Une saison finie : sa récompense a été donnée par Classe.verifier_saison() ; un panneau la montre,
# une fois, et la fait s'envoler jusqu'au bandeau.
# ─────────────────────────────────────────────────────────────

signal combattre(adv: Dictionary)
signal decks

const FOND := DuelEcran.FOND

var bandeau: Bandeau
var _retenu := {}              # ce que le bandeau attend (la récompense d'une saison finie)


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func embleme(rang: int) -> Texture2D:
	return Style.texture("res://carre/rang-%s.png" % Classe.RANGS[clampi(rang, 0, Classe.RANGS.size() - 1)]["id"])


func montrer() -> void:
	# la saison : sa fin se donne ici (le bandeau retient d'abord ce qui va s'envoler)
	var g := Classe.recompense_en_attente()
	if not g.is_empty() and bandeau != null:
		bandeau.retenir("etoiles", int(g["etoiles"]))
		bandeau.retenir("poussiere", int(g["poussiere"]))
		_retenu = g
	Classe.verifier_saison()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_construire()
	var fin: Dictionary = Classe.donnees()["fin"]
	if not fin.is_empty():
		_fin_de_saison(fin)


func _construire() -> void:
	var c := Classe.donnees()
	var p: int = c["palier"]
	var s: String = c["saison"]

	# la saison
	Style.libelle(self, "%s  ·  %s" % [Classe.nom_saison(s).to_upper(), Classe.mois_de(s).to_upper()], Rect2(60, 350, 700, 44),
		"etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var j := Classe.jours_restants()
	Style.libelle(self, "dernier jour" if j <= 1 else "fin dans %d jours" % j, Rect2(640, 346, 380, 50), "italique", 34, Style.OR_VIF,
		HORIZONTAL_ALIGNMENT_RIGHT)

	# ton rang
	Style.icone(self, embleme(Classe.rang_de(p)), Rect2(50, 414, 300, 300))
	var m := Classe.marche_de(p)
	if m > 0:
		var tag := Style.panneau(self, Rect2(150, 676, 100, 58), Color("#070d0b"), 16)
		Style.libelle(tag, ["", "I", "II", "III"][m], Rect2(0, 0, 100, 58), "fort", 36, Style.OR_VIF, HORIZONTAL_ALIGNMENT_CENTER)
	Style.libelle(self, Classe.nom_palier(p), Rect2(380, 440, 660, 96), "italique", 76, Style.IVOIRE)
	var pts: int = c["points"]
	var plein := 1.0 if p >= Classe.ZENITH else float(pts) / Classe.POINTS_MARCHE
	Dessin.ajouter(self, Rect2(382, 556, 640, 34), func(ci: CanvasItem):
		var sb := Style.boite(Color("#0b1411"), 17, Color(Style.OR, 0.5), 2)
		ci.draw_style_box(sb, Rect2(0, 0, 640, 34))
		if plein > 0.0:
			var sb2 := Style.boite(Style.OR_VIF if p >= Classe.ZENITH else Style.JADE_F, 13, Color(0, 0, 0, 0), 0)
			ci.draw_style_box(sb2, Rect2(4, 4, maxf(26.0, 632.0 * plein), 26)))
	if p >= Classe.ZENITH:
		Style.libelle(self, "%s points" % Style.nombre(pts), Rect2(382, 600, 400, 50), "fort", 36, Style.OR_VIF)
		Style.libelle(self, "le sommet", Rect2(700, 600, 322, 50), "italique", 32, Style.SOURD, HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		Style.libelle(self, "%d / %d points" % [pts, Classe.POINTS_MARCHE], Rect2(382, 600, 400, 50), "fort", 36, Style.IVOIRE)
		Style.libelle(self, "vers %s" % Classe.nom_palier(p + 1), Rect2(640, 600, 382, 50), "italique", 32, Style.SOURD, HORIZONTAL_ALIGNMENT_RIGHT)
	Style.libelle(self, "+%d par victoire  ·  −%d par défaite" % [Classe.GAIN, Classe.PERTE], Rect2(382, 654, 640, 50), "normal", 30, Style.SOURD)

	_echelle(Rect2(40, 760, 1000, 380), p)
	_recompenses(Rect2(40, 1166, 1000, 300), int(c["meilleur"]), s)
	_poussiere_compacte(Rect2(40, 1486, 1000, 90))
	DuelEcran.panneau_deck(self, 1590.0, func(): decks.emit())

	var go := Style.bouton(self, "Combattre en classé", Rect2(120, 1996, 840, 130), true, 54)
	var raison := Decks.pourquoi(Decks.deck_actif())
	go.disabled = raison != ""
	go.set_meta("pourquoi", raison)
	go.pressed.connect(func():
		if not Classe.verifier_saison().is_empty():
			montrer()                   # le mois vient de changer : on montre d'abord la saison finie
			return
		combattre.emit(Arene.adversaire_suivant("classe")))


# Les six rangs : ceux qu'on a passés (jade), le sien (or, en grand), ceux qui attendent (éteints).
func _echelle(r: Rect2, p: int) -> void:
	var pan := Style.panneau(self, r, FOND, 34)
	Style.libelle(pan, "LES RANGS", Rect2(40, 24, 300, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	Style.libelle(pan, "plus tu montes, plus l'adversaire est fort", Rect2(300, 20, 660, 48), "italique", 30, Style.SOURD,
		HORIZONTAL_ALIGNMENT_RIGHT)
	var ici := Classe.rang_de(p)
	var n := Classe.RANGS.size()
	var pas := 920.0 / n
	var y := 150.0
	Dessin.ajouter(pan, Rect2(0, 0, 1000, 300), func(ci: CanvasItem):
		ci.draw_line(Vector2(40 + pas * 0.5, y), Vector2(40 + pas * (n - 0.5), y), Color(Style.OR, 0.45), 2.0, true)
		if ici > 0:
			ci.draw_line(Vector2(40 + pas * 0.5, y), Vector2(40 + pas * (ici + 0.5), y), Style.JADE, 6.0, true))
	for k in n:
		var cx := 40.0 + pas * (k + 0.5)
		var t := 132.0 if k == ici else 104.0
		var teinte := Color.WHITE if k <= ici else Color(0.55, 0.55, 0.58, 0.75)
		Style.icone(pan, embleme(k), Rect2(cx - t * 0.5, y - t * 0.5, t, t), teinte)
		var coul := Style.OR_VIF if k == ici else (Style.JADE if k < ici else Style.SOURD)
		Style.libelle(pan, str(Classe.RANGS[k]["nom"]), Rect2(cx - pas * 0.5, y + 76, pas, 40), "etiquette", 22, coul,
			HORIZONTAL_ALIGNMENT_CENTER, 2)
	if ici > 0:
		Style.libelle(pan, "Tu as atteint %s : tu n'en retomberas plus cette saison." % Classe.RANGS[ici]["nom"],
			Rect2(40, 296, 920, 60), "normal", 30, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	else:
		Style.libelle(pan, "Chaque rang atteint te protège jusqu'à la fin de la saison.",
			Rect2(40, 296, 920, 60), "normal", 30, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 0, true)


# La fin de saison : ce que vaut ton meilleur rang, et le suivant (plus pâle).
func _recompenses(r: Rect2, meilleur: int, s: String) -> void:
	var pan := Style.panneau(self, r, FOND, 34)
	Style.libelle(pan, "FIN DE SAISON  ·  TON MEILLEUR RANG", Rect2(40, 24, 900, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var rb := Classe.rang_de(meilleur)
	var lignes := [rb]
	if rb < Classe.RANGS.size() - 1:
		lignes.append(rb + 1)
	for k in lignes.size():
		var rang: int = lignes[k]
		var y := 78.0 + k * 74.0
		var a := 1.0 if k == 0 else 0.55
		Style.icone(pan, embleme(rang), Rect2(40, y, 64, 64), Color(1, 1, 1, a))
		Style.libelle(pan, str(Classe.RANGS[rang]["nom"]), Rect2(120, y, 280, 64), "italique", 38, Color(Style.IVOIRE, a))
		var g := Classe.recompense(rang)
		var x := 420.0
		for gain in [["etoile-invocation", int(g["etoiles"])], ["poussiere-etoile", int(g["poussiere"])]]:
			if gain[1] <= 0:
				continue
			Style.icone(pan, Style.objet(gain[0]), Rect2(x, y, 64, 64), Color(1, 1, 1, a))
			Style.libelle(pan, "× %d" % gain[1], Rect2(x + 72, y, 170, 64), "fort", 36, Color(Style.OR_VIF, a))
			x += 250.0
	var suivante := s
	var mois := int(s.split("-")[1])
	suivante = "%04d-%02d" % [int(s.split("-")[0]) + (1 if mois == 12 else 0), 1 if mois == 12 else mois + 1]
	Style.libelle(pan, "Le 1er %s, la %s commence : tu redescends d'un rang." % [Classe.mois_de(suivante), Classe.nom_saison_phrase(suivante)],
		Rect2(40, 226, 920, 50), "normal", 28, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 0, true)


func _poussiere_compacte(r: Rect2) -> void:
	var pan := Style.panneau(self, r, FOND, 30)
	var v := Arene.victoires_du_jour()
	Style.libelle(pan, "POUSSIÈRE DU JOUR", Rect2(36, 0, 420, 90), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var tex := Style.objet("poussiere-etoile")
	for k in Arene.VICTOIRES_JOUR:
		Style.icone(pan, tex, Rect2(430.0 + k * 62.0, 17, 56, 56), Color(1, 1, 1, 1.0 if k < v else 0.25))
	Style.libelle(pan, "%d / %d" % [v, Arene.VICTOIRES_JOUR], Rect2(760, 0, 200, 90), "fort", 36, Style.IVOIRE, HORIZONTAL_ALIGNMENT_RIGHT)


# ─────────────────────────────────────────────────────────────
# La saison finie : une fois, par-dessus l'écran
# ─────────────────────────────────────────────────────────────

func _fin_de_saison(fin: Dictionary) -> void:
	var couche := Control.new()
	couche.size = size
	couche.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(couche)
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.62)
	voile.size = size
	voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche.add_child(voile)
	var p := Style.panneau(couche, Rect2(70, 560, 940, 1100), Color(0.047, 0.063, 0.059, 0.98), 44)
	var s := str(fin.get("saison", ""))
	Style.libelle(p, "%s  ·  FINIE" % Classe.nom_saison(s).to_upper() if Classe._saison_valide(s) else "LA SAISON EST FINIE",
		Rect2(0, 50, 940, 44), "etiquette", 26, Style.OR_FILET, HORIZONTAL_ALIGNMENT_CENTER, 6)
	var rang := int(fin.get("rang", 0))
	var joue := int(fin.get("joues", 0)) > 0
	Style.icone(p, embleme(rang), Rect2(320, 120, 300, 300))
	Style.libelle(p, "Ton meilleur rang : %s" % Classe.RANGS[clampi(rang, 0, 5)]["nom"] if joue else "Tu n'as pas joué cette saison.",
		Rect2(40, 440, 860, 80), "italique", 50, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	var etoiles := int(fin.get("etoiles", 0))
	var poussiere := int(fin.get("poussiere", 0))
	var centres := {}
	var x := 470.0 - (250.0 if etoiles > 0 and poussiere > 0 else 125.0)
	for gain in [["etoiles", "etoile-invocation", etoiles], ["poussiere", "poussiere-etoile", poussiere]]:
		if gain[2] <= 0:
			continue
		Style.icone(p, Style.objet(gain[1]), Rect2(x, 550, 110, 110))
		Style.libelle(p, "× %d" % gain[2], Rect2(x + 118, 550, 180, 110), "fort", 50, Style.OR_VIF)
		centres[gain[0]] = p.position + Vector2(x + 55, 605)
		x += 300.0
	var nouveau := int(fin.get("nouveau", 0))
	Style.libelle(p, "La %s commence : tu repars de %s." % [Classe.nom_saison_phrase(Classe.donnees()["saison"]), Classe.nom_palier(nouveau)],
		Rect2(60, 700, 820, 130), "normal", 38, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var b := Style.bouton(p, "Recevoir" if etoiles + poussiere > 0 else "Continuer", Rect2(120, 900, 700, 130), true, 54)
	b.pressed.connect(func():
		Classe.fin_vue()
		couche.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tw := couche.create_tween()
		tw.tween_property(couche, "modulate:a", 0.0, 0.25)
		tw.tween_callback(couche.queue_free)
		_envoler(centres))


# Ce que le bandeau retenait s'envole jusqu'à lui (rien de retenu : c'était déjà donné et affiché).
func _envoler(centres: Dictionary) -> void:
	if _retenu.is_empty() or bandeau == null:
		return
	var g := _retenu
	_retenu = {}
	for cle in ["etoiles", "poussiere"]:
		var n := int(g.get(cle, 0))
		if n <= 0:
			continue
		var image := "etoile-invocation" if cle == "etoiles" else "poussiere-etoile"
		if Effets.global != null and bandeau.is_visible_in_tree():
			Effets.global.envoler(Style.objet(image), centres.get(cle, Vector2(540, 1200)), bandeau.centre_icone(cle), 120.0, 1.0,
				func(): bandeau.recevoir(cle, n, image))
		else:
			bandeau.recevoir(cle, n, image)
