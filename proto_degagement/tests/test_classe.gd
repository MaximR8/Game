extends Node

# Le test du Duel et du Classé (étape 3 du Carré, 28/09) — sans écran.
#
#   1. Les adversaires : des decks de joueur (5 cartes, poids 14, un héros en tête), toujours les mêmes
#      pour une même graine, de plus en plus forts avec la cote.
#   2. Le Classé : les noms des marches, +25 / −20, le surplus et le manque, le plancher (qui retient ET
#      qui laisse descendre au-dessus de lui), le Zénith.
#   3. Les saisons : la récompense donnée UNE fois, −1 rang par mois, rien sans avoir joué, une horloge
#      qui recule, plusieurs mois d'absence.
#   4. Le Duel : la formule d'Elo, l'adversaire à ±100.
#   5. Ce qu'ils partagent : la poussière du jour (5, pas 6 ; un nouveau jour), le combat interrompu
#      (perdu, une seule fois), l'ouverture après le 1er boss.
#   6. La sauvegarde : l'aller-retour en JSON, une sauvegarde abîmée qui ne plante pas.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_classe.tscn
#
# Attendu : « RESULTAT: OK » et aucune ligne « SCRIPT ERROR ».

var erreurs := 0
var verifs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	_adversaires()
	_classe()
	_saisons()
	_duel()
	_arene()
	_sauvegarde()
	print("%d vérifications" % verifs)
	print("RESULTAT: %s" % ("OK" if erreurs == 0 and verifs > 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	if not vrai:
		erreurs += 1
		if erreurs <= 30:
			print("  ✗ " + quoi)


func _vierge() -> void:
	GS.voyage = {}
	GS.poussiere = 0
	GS.etoiles = 0
	Classe.date_test = {"year": 2026, "month": 9, "day": 15}


# ─────────────────────────────────────────────────────────────

func _adversaires() -> void:
	var niveaux := {}
	var forces_bas := 0
	var forces_haut := 0
	for g in 150:
		for cote in [700, 1000, 1300, 1600, 1900]:
			var adv := Fantomes.adversaire(cote, g)
			var deck: Array = adv["deck"]
			_ok("deck de joueur (cote %d, graine %d)" % [cote, g], Fantomes.legal(deck))
			_ok("un héros en tête (cote %d, graine %d)" % [cote, g], not MoteurCarre.fiche(str(deck[0]["id"]))["sbire"])
			_ok("le chef est la carte de tête", adv["chef"] == deck[0]["id"] and int(adv["chef_s"]) == int(deck[0]["s"]))
			_ok("un ordinateur connu", MoteurCarre.NIVEAUX.has(adv["niveau"]))
			_ok("un nom", str(adv["nom"]) != "")
			niveaux[adv["niveau"]] = true
			if cote == 700:
				forces_bas += MoteurCarre.force_deck(deck)
			elif cote == 1900:
				forces_haut += MoteurCarre.force_deck(deck)
				_ok("tout en haut : la carte de tête en full art", deck[0]["v"] == "full")
			var encore := Fantomes.adversaire(cote, g)
			_ok("même cote, même graine : même adversaire", str(encore) == str(adv))
	_ok("les trois ordinateurs servent", niveaux.size() == 3)
	_ok("plus fort en haut (%d contre %d)" % [forces_haut / 150, forces_bas / 150], forces_haut > forces_bas + 5 * 30)
	# les parts d'ordinateur glissent : aucune cote n'a d'Apprenti ET de Maître ; tout en bas, que l'Apprenti
	_ok("tout en bas : l'Apprenti", Fantomes.parts_ia(700) == Vector2(1, 0))
	_ok("tout en haut : le Maître", Fantomes.parts_ia(1900) == Vector2(0, 1))
	for c in range(700, 1900, 25):
		var p := Fantomes.parts_ia(c)
		_ok("jamais l'Apprenti et le Maître à la fois (%d)" % c, p.x == 0.0 or p.y == 0.0)


func _classe() -> void:
	_ok("noms", Classe.nom_palier(0) == "Météore III" and Classe.nom_palier(2) == "Météore I" and Classe.nom_palier(3) == "Comète III"
		and Classe.nom_palier(14) == "Galaxie I" and Classe.nom_palier(15) == "Zénith")
	_ok("marches", Classe.marche_de(0) == 3 and Classe.marche_de(1) == 2 and Classe.marche_de(2) == 1 and Classe.marche_de(15) == 0)
	_ok("planchers", Classe.plancher_de(0) == 0 and Classe.plancher_de(5) == 3 and Classe.plancher_de(9) == 9 and Classe.plancher_de(15) == 15)
	_ok("cote des marches qui monte", Classe.cote_adversaire(0) < Classe.cote_adversaire(8) and Classe.cote_adversaire(8) < Classe.cote_adversaire(15))

	_vierge()
	for k in 4:
		Classe.enregistrer(1)
	var c := Classe.donnees()
	_ok("4 victoires : Météore II, 0 point", c["palier"] == 1 and c["points"] == 0)
	c["points"] = 90
	var r := Classe.enregistrer(1)
	_ok("le surplus passe à la marche suivante (90 + 25)", r["monte"] and r["apres"] == 2 and r["points"] == 15)
	# le plancher retient : Météore est le 1er rang, on ne descend pas sous Météore III
	_vierge()
	Classe.enregistrer(-1)
	c = Classe.donnees()
	_ok("0 point, perdu : on reste à 0 (le plancher)", c["palier"] == 0 and c["points"] == 0)
	# au-dessus du plancher, on redescend d'une marche
	c["palier"] = 5
	c["meilleur"] = 5
	c["points"] = 10
	r = Classe.enregistrer(-1)
	_ok("Comète I, 10 points, perdu : Comète II à 90", r["descend"] and r["apres"] == 4 and r["points"] == 90)
	c["points"] = 10
	r = Classe.enregistrer(-1)
	_ok("Comète II, perdu : Comète III", r["apres"] == 3)
	c["points"] = 10
	r = Classe.enregistrer(-1)
	_ok("Comète III, perdu : le plancher retient (Comète atteint)", r["plancher"] and r["apres"] == 3 and r["points"] == 0)
	# le Zénith
	c["palier"] = 14
	c["meilleur"] = 14
	c["points"] = 90
	r = Classe.enregistrer(1)
	_ok("Galaxie I → Zénith", r["apres"] == 15 and r["points"] == 0)
	Classe.enregistrer(1)
	Classe.enregistrer(1)
	_ok("au Zénith, les points s'accumulent", Classe.donnees()["points"] == 50)
	for k in 5:
		Classe.enregistrer(-1)
	_ok("au Zénith, on n'en retombe pas", Classe.donnees()["palier"] == 15 and Classe.donnees()["points"] == 0)
	_ok("une égalité ne change rien", Classe.enregistrer(0)["delta"] == 0)
	_ok("l'historique garde 5 combats", (Classe.donnees()["historique"] as Array).size() == 5)


func _saisons() -> void:
	_vierge()
	_ok("la saison commence", Classe.verifier_saison().is_empty() and Classe.donnees()["saison"] == "2026-09")
	_ok("son nom", Classe.nom_saison("2026-09") == "Saison de la Lyre" and Classe.nom_saison("2026-10") == "Saison du Cygne")
	_ok("les jours qui restent (15 septembre : 16)", Classe.jours_restants() == 16)
	Classe.date_test = {"year": 2026, "month": 9, "day": 30}
	_ok("le dernier jour : 1", Classe.jours_restants() == 1)
	var c := Classe.donnees()
	c["palier"] = 7
	c["meilleur"] = 8
	c["joues"] = 12
	var fin := Classe.verifier_saison()
	_ok("même mois : rien", fin.is_empty())
	Classe.date_test = {"year": 2026, "month": 10, "day": 1}
	fin = Classe.verifier_saison()
	_ok("octobre : la saison de la Lyre finit, meilleur rang Aurore", fin.get("rang", -1) == 2 and fin.get("saison", "") == "2026-09")
	_ok("sa récompense est donnée (1 étoile, 200 poussières)", GS.etoiles == 1 and GS.poussiere == 200)
	c = Classe.donnees()
	_ok("on redescend d'un rang : Comète III, 0 point", c["palier"] == 3 and c["points"] == 0 and c["meilleur"] == 3 and c["joues"] == 0)
	_ok("« fin » attend l'écran", not (c["fin"] as Dictionary).is_empty())
	_ok("pas deux fois", Classe.verifier_saison().is_empty() and GS.etoiles == 1 and GS.poussiere == 200)
	Classe.fin_vue()
	_ok("vue : effacée", (Classe.donnees()["fin"] as Dictionary).is_empty())
	# l'horloge recule : rien ne revient
	Classe.date_test = {"year": 2026, "month": 9, "day": 20}
	_ok("horloge reculée : rien", Classe.verifier_saison().is_empty() and Classe.donnees()["saison"] == "2026-10" and GS.etoiles == 1)
	# un mois sans jouer : aucune récompense (témoin : on descend quand même)
	Classe.date_test = {"year": 2026, "month": 11, "day": 2}
	fin = Classe.verifier_saison()
	_ok("octobre sans jouer : rien de donné", int(fin.get("etoiles", -1)) == 0 and int(fin.get("poussiere", -1)) == 0 and GS.etoiles == 1)
	_ok("… mais on descend d'un rang : Météore III", Classe.donnees()["palier"] == 0)
	# trois mois d'absence, du Zénith : trois rangs
	c = Classe.donnees()
	c["palier"] = 15
	c["meilleur"] = 15
	c["joues"] = 40
	Classe.date_test = {"year": 2027, "month": 2, "day": 10}
	fin = Classe.verifier_saison()
	_ok("3 mois plus tard, du Zénith : Aurore III", Classe.donnees()["palier"] == 6 and fin.get("rang", -1) == 5)
	_ok("la récompense du Zénith (5 étoiles), une seule", GS.etoiles == 6 and GS.poussiere == 700)
	_ok("changement d'année", Classe.donnees()["saison"] == "2027-02")
	_ok("de Météore, on ne descend pas sous zéro", _descente_de(0, 5) == 0)


func _descente_de(p: int, mois: int) -> int:
	_vierge()
	Classe.verifier_saison()
	Classe.donnees()["palier"] = p
	Classe.donnees()["meilleur"] = p
	Classe.date_test = {"year": 2026, "month": 9 + mois, "day": 1} if 9 + mois <= 12 else {"year": 2027, "month": 9 + mois - 12, "day": 1}
	Classe.verifier_saison()
	return Classe.donnees()["palier"]


func _duel() -> void:
	_vierge()
	_ok("cote de départ", Duel.cote() == 1000)
	_ok("à égalité de cote : +12 / −12", Duel.variation(1000, 1000, 1.0) == 12 and Duel.variation(1000, 1000, 0.0) == -12)
	_ok("battre plus fort rapporte plus", Duel.variation(1000, 1100, 1.0) > Duel.variation(1000, 900, 1.0))
	_ok("égalité contre plus fort : on gagne un peu", Duel.variation(1000, 1100, 0.5) > 0)
	for g in 200:
		var adv := Duel.adversaire_suivant(g)
		_ok("adversaire à ±100 (%d)" % int(adv["cote"]), absi(int(adv["cote"]) - 1000) <= Duel.ECART and adv["mode"] == "duel")
	var r := Duel.enregistrer(1, {"cote": 1000, "chef": "thor", "nom": "Thor le tonnant"})
	_ok("gagné : 1012", r["apres"] == 1012 and Duel.cote() == 1012)
	r = Duel.enregistrer(-1, {"cote": 1012})
	_ok("perdu : 1000", Duel.cote() == 1000)


func _arene() -> void:
	_vierge()
	_ok("fermé avant le 1er boss", not Arene.ouvert())
	Aventure._donnees()["etoiles"]["10"] = 1
	_ok("ouvert après le Chevalier sans tête", Arene.ouvert())
	GS.voyage = {}
	Arene.ouvert_pour_test = true
	_ok("l'outil de test l'ouvre", Arene.ouvert())
	Arene.ouvert_pour_test = false

	# la poussière du jour : 5 victoires, en Duel ou en Classé
	_vierge()
	var donnee := 0
	for k in 3:
		var adv := Duel.adversaire_suivant(k)
		donnee += int(Arene.terminer(adv, 6, 3)["poussiere"])
	for k in 3:
		var adv := Classe.adversaire_suivant(k)
		donnee += int(Arene.terminer(adv, 5, 4)["poussiere"])
	_ok("6 victoires (3 duels, 3 classés) : 5 × 30", donnee == 150 and GS.poussiere == 150 and Arene.victoires_du_jour() == 5)
	_ok("prévue : 0", Arene.poussiere_prevue() == 0)
	_ok("une défaite ne rapporte rien", int(Arene.terminer(Duel.adversaire_suivant(9), 3, 6)["poussiere"]) == 0)
	GS.voyage["jour"]["date"] = "2000-01-01"
	_ok("un nouveau jour : 0 sur 5, 30 prévues", Arene.victoires_du_jour() == 0 and Arene.poussiere_prevue() == 30)
	_ok("le Classé a compté ses combats", Classe.donnees()["joues"] == 3 and Classe.donnees()["points"] == 75)

	# le combat interrompu
	_vierge()
	_ok("rien en cours : rien à solder", Arene.solder_interrompu().is_empty())
	var adv := Classe.adversaire_suivant(42)
	Classe.donnees()["points"] = 50
	Arene.commencer(adv)
	_ok("commencé : en cours", Arene.en_cours())
	var r := Arene.solder_interrompu()
	_ok("interrompu : perdu (−20)", r.get("resultat", 0) == -1 and Classe.donnees()["points"] == 30)
	_ok("… une seule fois", not Arene.en_cours() and Arene.solder_interrompu().is_empty() and Classe.donnees()["points"] == 30)
	_ok("l'historique le dit", bool(Classe.donnees()["historique"][0]["interrompu"]))
	adv = Duel.adversaire_suivant(43)
	Arene.commencer(adv)
	r = Arene.solder_interrompu()
	_ok("un duel interrompu : la cote baisse", Duel.cote() < 1000 and r["mode"] == "duel")
	adv = Duel.adversaire_suivant(44)
	Arene.commencer(adv)
	Arene.terminer(adv, 6, 3)
	_ok("un combat fini n'est plus en cours", not Arene.en_cours())
	GS.voyage["en_cours"] = {"mode": "n'importe quoi"}
	_ok("un « en cours » illisible s'efface sans rien compter", Arene.solder_interrompu().is_empty() and not Arene.en_cours())


func _sauvegarde() -> void:
	_vierge()
	Classe.verifier_saison()
	for k in 6:
		Classe.enregistrer(1)
	Duel.enregistrer(1, {"cote": 1050})
	Arene.commencer(Classe.adversaire_suivant(3))
	var texte := JSON.stringify(GS.donnees_sauvegarde())
	var avant_c := Classe.donnees().duplicate(true)
	var avant_d := Duel.cote()
	GS.voyage = {}
	GS.lire_sauvegarde(JSON.parse_string(texte), false)
	var c := Classe.donnees()
	_ok("aller-retour : le Classé", c["palier"] == avant_c["palier"] and c["points"] == avant_c["points"] and c["saison"] == avant_c["saison"]
		and typeof(c["palier"]) == TYPE_INT)
	_ok("aller-retour : le Duel", Duel.cote() == avant_d)
	_ok("aller-retour : le combat en cours", Arene.en_cours())

	# abîmée
	GS.voyage = {"classe": "abc", "duel": [1, 2], "jour": 7, "en_cours": "x"}
	_ok("abîmée : un Classé vierge", Classe.donnees()["palier"] == 0 and Classe.donnees()["saison"] == "")
	_ok("abîmée : un Duel vierge", Duel.cote() == 1000)
	_ok("abîmée : 0 victoire du jour", Arene.victoires_du_jour() == 0)
	_ok("abîmée : rien en cours", not Arene.en_cours())
	GS.voyage = {"classe": {"palier": 99, "points": -5, "meilleur": 2, "saison": "2026-13", "historique": "x"}}
	var c2 := Classe.donnees()
	_ok("valeurs hors bornes ramenées", c2["palier"] == 15 and c2["points"] == 0 and c2["meilleur"] == 15 and c2["saison"] == "")
	GS.voyage = {"classe": {"palier": 4, "points": 250}}
	_ok("des points de trop sous le Zénith : 99 au plus", Classe.donnees()["points"] == 99)
	Classe.date_test = {}
