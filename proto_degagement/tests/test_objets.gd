extends Node

# Vérifie les objets de l'univers (FEATURES ⑭, 26/09) — les « valeurs fausses silencieuses » :
# une vieille sauvegarde convertie sans rien perdre, l'évolution qui prend une pierre de SON
# type puis de lune (jamais gratuite, jamais avec la pierre d'un autre type), le tirage des
# pierres au fond du plateau.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_objets.tscn
#
# ⛔ La sauvegarde est coupée : le test n'écrit rien sur le PC.

var erreurs := 0


func _verifier(ok: bool, quoi: String) -> void:
	print(("ok      " if ok else "ERREUR  ") + quoi)
	if not ok:
		erreurs += 1


func _ready() -> void:
	var gs = load("res://game_state.gd").new()
	gs.sauvegarde_active = false

	# 1. Une sauvegarde v2 (tickets, XP, éclats) : étoiles, poussière, pierres de lune, 1 pour 1.
	gs.lire_sauvegarde({"v": 2, "xp": 1240, "tickets": 12, "eclats": 3, "main_pieces": 90,
		"cartes": {"kitsune": {"stade": 1, "niveau": 3, "variante": "base", "variantes": ["base"]},
			"georges": {"stade": 1, "niveau": 3, "variante": "base", "variantes": ["base"]}}}, false)
	_verifier(gs.poussiere == 1240, "XP → poussière : %d (attendu 1240)" % gs.poussiere)
	_verifier(gs.etoiles == 12, "tickets → étoiles : %d (attendu 12)" % gs.etoiles)
	_verifier(gs.pierres == {"lune": 3}, "éclats → pierres de lune : %s (attendu {lune: 3})" % str(gs.pierres))
	_verifier(gs.cartes.size() == 2 and gs.main_pieces == 90, "les cartes et la réserve restent")

	# 2. L'aller-retour d'une sauvegarde v3 : plus aucun ancien nom.
	gs.pierres = {"esprit": 2, "lune": 1}
	var d: Dictionary = JSON.parse_string(JSON.stringify(gs.donnees_sauvegarde()))
	_verifier(not d.has("xp") and not d.has("tickets"), "la sauvegarde n'a plus xp / tickets")
	_verifier(gs.eclats == 0 and int(d["v"]) >= 4, "une v2 : ses « éclats » (des pierres) ne deviennent PAS la monnaie des cartes (%d)" % gs.eclats)
	var gs2 = load("res://game_state.gd").new()
	gs2.sauvegarde_active = false
	gs2.lire_sauvegarde(d, false)
	_verifier(gs2.poussiere == 1240 and gs2.etoiles == 12 and gs2.nb_pierres("esprit") == 2 and gs2.nb_pierres("lune") == 1,
		"aller-retour v3 : %d poussière, %d étoiles, %s" % [gs2.poussiere, gs2.etoiles, str(gs2.pierres)])
	gs2.lire_sauvegarde({"v": 3, "poussiere": 5, "etoiles": 1, "pierres": {"feu": 2, "roche": 4, "n'importe": 9}}, false)
	_verifier(gs2.pierres == {"feu": 2}, "une pierre inconnue n'entre pas : %s" % str(gs2.pierres))
	gs2.lire_sauvegarde({"v": 4, "eclats": 250, "pierres": {}}, false)
	_verifier(gs2.eclats == 250 and gs2.pierres.is_empty(), "une v4 : les éclats sont la monnaie (%d), rien ne part en pierres" % gs2.eclats)
	gs2.lire_sauvegarde({"v": 4, "eclats": "x"}, false)
	_verifier(gs2.eclats == 0, "des éclats illisibles : 0")

	# 3. L'évolution (28/09, ⑧ lot B) : le stade II au niveau 5 avec 1 pierre, le stade III au niveau 10 avec 2 ; celles de
	#    son type d'abord, la lune complète ; le refus ET le passage.
	gs.pierres = {"esprit": 1, "lune": 2}
	gs.cartes["kitsune"]["niveau"] = 4
	_verifier(not gs.peut_evoluer("kitsune"), "niveau 4 : pas encore le stade II (il faut le niveau 5)")
	gs.cartes["kitsune"]["niveau"] = 5
	_verifier(gs.pierre_pour_evoluer("kitsune") == "esprit" and gs.plan_evolution("kitsune") == {"esprit": 1},
		"Kitsune (esprit) prend d'abord une pierre d'esprit : %s" % str(gs.plan_evolution("kitsune")))
	_verifier(gs.evoluer("kitsune") and int(gs.cartes["kitsune"]["stade"]) == 2 and gs.nb_pierres("esprit") == 0 and gs.nb_pierres("lune") == 2,
		"évolue au stade II : %s" % str(gs.pierres))
	_verifier(gs.pierre_demandee("kitsune") == "2 pierres d'esprit", "le stade III : « %s »" % gs.pierre_demandee("kitsune"))
	_verifier(not gs.peut_evoluer("kitsune"), "niveau 5 : pas encore le stade III (il faut le niveau 10)")
	gs.cartes["kitsune"]["niveau"] = 10
	gs.pierres = {"esprit": 1, "lune": 1}
	_verifier(gs.plan_evolution("kitsune") == {"esprit": 1, "lune": 1}, "1 d'esprit + 1 de lune : %s" % str(gs.plan_evolution("kitsune")))
	_verifier(gs.evoluer("kitsune") and int(gs.cartes["kitsune"]["stade"]) == 3 and gs.total_pierres() == 0,
		"évolue au stade III, et prend les deux : %s" % str(gs.pierres))
	gs.cartes["kitsune"]["stade"] = 1
	_verifier(not gs.peut_evoluer("kitsune") and not gs.evoluer("kitsune") and int(gs.cartes["kitsune"]["stade"]) == 1,
		"sans pierre, pas d'évolution")
	gs.pierres = {"feu": 5}
	_verifier(not gs.peut_evoluer("kitsune"), "cinq pierres de feu ne font pas évoluer Kitsune")
	gs.cartes["georges"]["niveau"] = 99
	_verifier(not gs.peut_evoluer("georges"), "Saint Georges (sans type) : pas avec du feu")
	gs.pierres = {"lune": 1}
	_verifier(gs.evoluer("georges") and gs.total_pierres() == 0, "Saint Georges : avec la lune")
	_verifier(gs.pierre_demandee("kitsune") == "1 pierre d'esprit", "le bouton dit : « %s »" % gs.pierre_demandee("kitsune"))
	_verifier(gs.pierre_demandee("georges") == "2 pierres de lune", "Saint Georges, au stade II, pour le III : « %s »" % gs.pierre_demandee("georges"))
	gs.cartes["kitsune"]["stade"] = 2
	gs.pierres = {"lune": 1}
	_verifier(not gs.peut_evoluer("kitsune") and gs.plan_evolution("kitsune").is_empty(), "1 lune pour 2 pierres : non")
	gs.cartes["eau"] = null
	gs.cartes.erase("eau")
	gs.cartes["kelpie"] = {"stade": 2, "niveau": 10, "variante": "base", "variantes": ["base"]}
	_verifier(gs.pierre_demandee("kelpie") == "2 pierres d'eau", "le pluriel : « %s »" % gs.pierre_demandee("kelpie"))

	# 4. Les gains du plateau.
	var p0: int = gs.poussiere
	gs.gagner(60, 0)
	gs.gagner(0, 1)
	gs.gagner(0, 0, "nature")
	gs.gagner(0, 0, "nature")
	_verifier(gs.poussiere == p0 + 60 and gs.nb_pierres("nature") == 2, "gains : +60 poussière, 2 pierres de nature")

	# 5. Les pierres du plateau du jour (28/09 : écrites par le calendrier, plateau.gd) : six types à parts
	#    égales, la lune à 12 %, jamais la roche ; le même jour donne les mêmes pierres.
	var compte := {}
	var n := 0
	for j in 4000:
		var jour := Time.get_date_string_from_unix_time(1790000000 + j * 86400)
		var l: Array = Plateau.pierres_du_jour(jour)
		if j < 20:
			_verifier(l == Plateau.pierres_du_jour(jour), "même jour, mêmes pierres")
		for t in l:
			compte[t] = int(compte.get(t, 0)) + 1
			n += 1
	var lune := float(compte.get("lune", 0)) / n * 100.0
	_verifier(absf(lune - 12.0) < 1.0, "pierre de lune : %.2f %% (attendu 12)" % lune)
	for t in ["feu", "foudre", "eau", "glace", "nature", "esprit"]:
		var pc := float(compte.get(t, 0)) / n * 100.0
		_verifier(absf(pc - 88.0 / 6.0) < 1.0, "pierre de %s : %.2f %% (attendu %.2f)" % [t, pc, 88.0 / 6.0])
	_verifier(not compte.has("roche"), "jamais de pierre de roche (elle viendra avec la roue des types)")

	# Le premier pack offert (28/09 ; il remplace le cadeau de départ du 27/09) : dû à une partie de moins
	# de 5 cartes qui ne l'a jamais ouvert ; ouvert, 10 cartes sans dépenser d'étoile, une seule fois.
	var gs3 = load("res://game_state.gd").new()
	gs3.sauvegarde_active = false
	gs3.cartes = {}
	gs3.etoiles = 0
	gs3.voyage = {"decks": {"liste": [[]], "actif": 0}}
	_verifier(gs3.premier_pack_du(), "sans carte : le premier pack est dû")
	var lot3: Array = gs3.ouvrir_premier_pack()
	_verifier(lot3.size() == 10 and gs3.cartes.size() >= 5 and gs3.etoiles == 0,
		"ouvert : 10 cartes, 5 différentes au moins, sans étoile dépensée (%d cartes, %d différentes)" % [lot3.size(), gs3.cartes.size()])
	_verifier(not gs3.voyage.has("decks"), "le premier deck, né incomplet, se recompose avec le pack")
	_verifier(not gs3.premier_pack_du() and (gs3.ouvrir_premier_pack() as Array).is_empty(), "une seule fois")
	var gs4 = load("res://game_state.gd").new()
	gs4.sauvegarde_active = false
	gs4.cartes = {}
	for id in ["thor", "loki", "golem", "troll", "anansi"]:
		gs4.cartes[id] = {"stade": 1, "niveau": 1, "variante": "base", "variantes": ["base"]}
	gs4.voyage = {}
	_verifier(not gs4.premier_pack_du(), "une partie qui a déjà ses 5 cartes ne le reçoit pas")
	gs4.cartes.erase("anansi")
	_verifier(gs4.premier_pack_du(), "une partie de 4 cartes le reçoit (un cousin qui n'a pas fini ses 10 étoiles)")
	gs3.free()
	gs4.free()

	gs.free()
	gs2.free()
	print("RESULTAT: " + ("OK" if erreurs == 0 else "ÉCHEC (%d)" % erreurs))
	get_tree().quit(1 if erreurs > 0 else 0)
