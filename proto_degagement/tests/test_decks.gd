extends Node

# Le test de « Mes decks » (27/09) — sans écran. Chaque règle a ses deux témoins (ce qui passe,
# ce qui est refusé) :
#   · le premier deck est le deck composé tout seul ;
#   · ajouter une carte : au stade le plus haut qui tient dans le poids ; trop lourde, en double,
#     ou une 6ᵉ : refusée, et on dit pourquoi ;
#   · une sauvegarde abîmée est nettoyée (carte inconnue ou pas à toi, stade trop haut, variante
#     qu'on n'a pas, doublon, 6 cartes, n'importe quoi) sans planter ;
#   · 6 decks au plus, il en reste toujours un, le choisi suit ; la sauvegarde aller-retour ;
#   · le deck qui combat est une copie.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_decks.tscn
#
# Attendu : « RESULTAT: OK » et aucune ligne « SCRIPT ERROR ».

var erreurs := 0
var verifs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	# la mécanique des decks, aux poids d'avant les rangs (Thor pèse s + 1) ; les rangs : à la fin
	MoteurCarre.rangs_actifs = false
	GS.cartes = {
		"thor": {"stade": 2, "niveau": 6, "variante": "or", "variantes": ["base", "or"]},
		"kitsune": {"stade": 3, "niveau": 9, "variante": "prisme", "variantes": ["base", "prisme"]},
		"bahamut": {"stade": 3, "niveau": 9, "variante": "base", "variantes": ["base"]},
		"golem": {"stade": 1, "niveau": 1, "variante": "base", "variantes": ["base"]},
		"korrigan": {"stade": 1, "niveau": 1, "variante": "base", "variantes": ["base"]},
		"banshee": {"stade": 1, "niveau": 1, "variante": "base", "variantes": ["base"]},
		"doudou": {"stade": 2, "niveau": 3, "variante": "ombre", "variantes": ["ombre"]},
	}
	GS.voyage = {}

	# le premier deck
	var l := Decks.liste()
	_ok("un premier deck, et un seul", l.size() == 1 and Decks.actif() == 0)
	_ok("le premier deck est le deck composé tout seul", l[0] == Decks.nettoyer(VoyageEcran.deck_auto()))
	_ok("il est complet et tient dans le poids", Decks.valide(l[0]) and Decks.pourquoi(l[0]) == "")

	# ajouter
	var d := []
	var r := Decks.ajouter_carte(d, "kitsune")
	_ok("Kitsune entre à son stade (III, poids 4)", r["ok"] and d[0]["s"] == 3 and d[0]["v"] == "prisme")
	Decks.ajouter_carte(d, "bahamut")
	Decks.ajouter_carte(d, "doudou")
	_ok("3 cartes, poids 11", d.size() == 3 and MoteurCarre.poids_deck(d) == 11)
	r = Decks.ajouter_carte(d, "thor")
	_ok("Thor (stade II, poids 3) tient juste : 14", r["ok"] and d[3]["s"] == 2 and MoteurCarre.poids_deck(d) == 14)
	r = Decks.ajouter_carte(d, "golem")
	_ok("Golem (poids 2) ne tient plus : refusé, et on dit le poids", not r["ok"] and "16 / 14" in str(r["raison"]) and d.size() == 4)
	d[3]["s"] = 1
	r = Decks.ajouter_carte(d, "golem")
	_ok("Thor redescendu au stade I (13) : Golem ne tient toujours pas (15)", not r["ok"] and "15 / 14" in str(r["raison"]))
	d[2]["s"] = 1
	r = Decks.ajouter_carte(d, "golem")
	_ok("El Biète aussi au stade I (12) : Golem tient (14)", r["ok"] and MoteurCarre.poids_deck(d) == 14 and d.size() == 5)
	r = Decks.ajouter_carte(d, "banshee")
	_ok("une 6ᵉ carte : refusée", not r["ok"] and "5 cartes" in str(r["raison"]))
	var d2 := [{"id": "kitsune", "s": 3, "v": "base"}]
	r = Decks.ajouter_carte(d2, "kitsune")
	_ok("en double : refusée", not r["ok"] and d2.size() == 1)
	r = Decks.ajouter_carte(d2, "cerbere")
	_ok("une carte qu'on n'a pas : refusée", not r["ok"])
	var d3 := [{"id": "kitsune", "s": 3, "v": "base"}, {"id": "bahamut", "s": 3, "v": "base"}, {"id": "doudou", "s": 2, "v": "base"}]
	r = Decks.ajouter_carte(d3, "thor")
	_ok("au stade le plus haut qui tient : Thor entre au stade II si 11 + 3 = 14", r["ok"] and d3[3]["s"] == 2)
	d3 = [{"id": "kitsune", "s": 3, "v": "base"}, {"id": "bahamut", "s": 3, "v": "base"}, {"id": "doudou", "s": 2, "v": "base"},
		{"id": "golem", "s": 1, "v": "base"}]
	r = Decks.ajouter_carte(d3, "thor")
	_ok("…et au stade I s'il ne reste que 2 : 13 + 2 = 15 → refusé, 12 + 2 = 14 → stade I", not r["ok"])
	d3[2]["s"] = 1
	r = Decks.ajouter_carte(d3, "thor")
	_ok("Thor entre au stade I (poids 2)", r["ok"] and d3[4]["s"] == 1 and MoteurCarre.poids_deck(d3) == 14)

	# pourquoi
	_ok("il manque des cartes : on le dit", Decks.pourquoi([{"id": "thor", "s": 1, "v": "base"}]) == "Il manque 4 cartes à ton deck")
	var lourd := [{"id": "kitsune", "s": 3, "v": "base"}, {"id": "bahamut", "s": 3, "v": "base"}, {"id": "doudou", "s": 2, "v": "base"},
		{"id": "thor", "s": 2, "v": "base"}, {"id": "golem", "s": 1, "v": "base"}]
	_ok("trop lourd : on le dit", Decks.pourquoi(lourd) == "Trop lourd : 16 / 14" and not Decks.valide(lourd))

	# nettoyer
	var sale := [{"id": "thor", "s": 3, "v": "full"}, {"id": "cerbere", "s": 1}, {"id": "inconnu"}, {"id": "thor", "s": 1},
		"n'importe quoi", {"id": "golem", "s": "x"}, {"id": "doudou", "s": 2, "v": "ombre"}, {"id": "kitsune", "s": 3, "v": "prisme"},
		{"id": "bahamut", "s": 3}, {"id": "banshee", "s": 1}]
	var propre := Decks.nettoyer(sale)
	_ok("nettoyé : Thor redescend au stade II, sa variante qu'on n'a pas devient celle qu'on affiche",
		propre[0] == {"id": "thor", "s": 2, "v": "or"})
	_ok("nettoyé : ni carte pas à toi, ni inconnue, ni doublon, ni n'importe quoi ; 5 au plus",
		propre.size() == 5 and propre[1]["id"] == "golem" and propre[1]["s"] == 1)
	# plus de cartes prêtées (28/09, le premier pack offert) : une carte qu'on n'a pas quitte le deck
	_ok("une carte prêtée d'avant le 28/09 quitte le deck",
		Decks.nettoyer([{"id": "cerbere", "s": 3, "v": "full", "prete": true}]).is_empty())

	# les decks
	var k := Decks.nouveau()
	_ok("un nouveau deck, vide", k == 1 and (Decks.liste()[1] as Array).is_empty())
	Decks.remplacer(1, sale)
	_ok("remplacer nettoie", Decks.liste()[1] == propre)
	Decks.choisir(1)
	var combat := Decks.deck_actif()
	combat[0]["s"] = 1
	_ok("le deck qui combat est une copie", Decks.liste()[1][0]["s"] == 2 and Decks.actif() == 1)
	for i in 10:
		Decks.nouveau()
	_ok("6 decks au plus", Decks.liste().size() == Decks.MAX_DECKS and Decks.nouveau() == -1)
	Decks.supprimer(0)
	_ok("supprimer un deck avant le choisi : le choisi suit", Decks.actif() == 0 and Decks.liste()[0] == propre)
	for i in 10:
		Decks.supprimer(0)
	_ok("il en reste toujours un", Decks.liste().size() == 1)

	# la sauvegarde aller-retour
	Decks.remplacer(0, lourd.slice(0, 4))
	Decks.nouveau()
	Decks.choisir(1)
	var sauvee = JSON.parse_string(JSON.stringify(GS.donnees_sauvegarde()))
	GS.voyage = {}
	_ok("témoin : sans la sauvegarde, on repart du deck automatique", Decks.liste().size() == 1)
	GS.lire_sauvegarde(sauvee, false)
	_ok("relue : les decks et le choix", Decks.liste().size() == 2 and Decks.actif() == 1 and Decks.liste()[0] == Decks.nettoyer(lourd.slice(0, 4)))

	# des sauvegardes abîmées ne plantent pas
	for abime in [{"decks": "abc"}, {"decks": {"liste": "x", "actif": "y"}}, {"decks": {"liste": [[1, 2], "z", {"a": 1}], "actif": 99}}]:
		GS.voyage = abime.duplicate(true)
		var ll := Decks.liste()
		_ok("sauvegarde abîmée %s : des decks utilisables" % str(abime), ll.size() >= 1 and Decks.actif() < ll.size())

	print("%d vérifications" % verifs)
	# Les rangs (27/09) : une Légende pèse 1 de plus, à chaque stade ; un Mythe, non ; un sbire pèse 1.
	MoteurCarre.rangs_actifs = true
	_ok("une Légende (Thor) pèse 1 de plus : stade I = 3, stade III = 5", MoteurCarre.poids("thor", 1) == 3 and MoteurCarre.poids("thor", 3) == 5)
	_ok("un Mythe (Golem) pèse comme un héros : stade I = 2", MoteurCarre.poids("golem", 1) == 2)
	_ok("un sbire pèse 1, même le Chinchin", MoteurCarre.poids("chinchin", 1) == 1 and MoteurCarre.poids("farfadet", 1) == 1)
	_ok("le deck composé tout seul tient toujours dans le poids", Decks.valide(Decks.nettoyer(VoyageEcran.deck_auto())))
	print("RESULTAT: %s" % ("OK" if erreurs == 0 and verifs > 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	if not vrai:
		erreurs += 1
		print("  ✗ " + quoi)
