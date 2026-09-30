extends Node

# Le test de l'Aventure (étape 2 du Carré, 27/09) — sans écran.
#
#   1. Les 100 niveaux : tous construits deux fois à l'identique (aucun hasard), un deck de 5 cartes
#      connues et dessinables, un chef qui a son portrait, le poids visé, des terres valides, un défi.
#   2. Les étoiles : chaque défi, avec ses deux témoins (réussi, et raté de peu).
#   3. La progression : ce qui s'ouvre, les récompenses données UNE fois, les coffres, le boss, la
#      sauvegarde aller-retour, une sauvegarde abîmée qui ne plante pas.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_aventure.tscn
#
# Attendu : « RESULTAT: OK » et aucune ligne « SCRIPT ERROR ».

var erreurs := 0
var verifs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	_niveaux()
	_etoiles()
	_progression()
	print("%d vérifications" % verifs)
	print("RESULTAT: %s" % ("OK" if erreurs == 0 and verifs > 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	if not vrai:
		erreurs += 1
		if erreurs <= 20:
			print("  ✗ " + quoi)


# ─────────────────────────────────────────────────────────────

func _niveaux() -> void:
	var poids := {}
	var cartes_vues := {}
	for n in range(1, Aventure.NB_NIVEAUX + 1):
		var d := Aventure.niveau(n)
		_ok("niveau %d : le même à chaque fois" % n, d == Aventure.niveau(n))
		var deck: Array = d["deck"]
		_ok("niveau %d : 5 cartes" % n, deck.size() == MoteurCarre.TAILLE_DECK)
		var ids := {}
		for c in deck:
			var f := MoteurCarre.fiche(str(c["id"]))
			_ok("niveau %d : carte connue (%s)" % [n, c["id"]], not f.is_empty())
			if f.is_empty():
				continue
			ids[c["id"]] = true
			_ok("niveau %d : stade possible (%s %d)" % [n, c["id"], c["s"]], int(c["s"]) >= 1 and int(c["s"]) <= int(f["stades"]))
			cartes_vues["%s|%d|%s" % [c["id"], int(c["s"]), c["v"]]] = c
		_ok("niveau %d : pas deux fois la même carte" % n, ids.size() == deck.size())
		var chef := str(d["chef"])
		_ok("niveau %d : le chef est dans le deck" % n, ids.has(chef))
		_ok("niveau %d : le chef n'est pas un sbire" % n, not MoteurCarre.fiche(chef).get("sbire", true))
		_ok("niveau %d : le chef a son portrait" % n, ResourceLoader.exists("res://cartes/min/%s-%d.jpg" % [chef, int(d["chef_s"])]))
		_ok("niveau %d : le chef a son nom" % n, Aventure.NOMS.has(chef))
		_ok("niveau %d : un défi connu" % n, Aventure.DEFIS.has(str(d["defi"])))
		_ok("niveau %d : un ordinateur connu" % n, MoteurCarre.NIVEAUX.has(str(d["niveau"])))
		_ok("niveau %d : qui commence" % n, str(d["premier"]) in ["j", "a"])
		var terres: Dictionary = d["terres"]
		for i in terres:
			_ok("niveau %d : terre sur une case du plateau" % n, int(i) >= 0 and int(i) < 9)
			_ok("niveau %d : terre d'un type connu" % n, MoteurCarre.TYPES_TERRES.has(str(terres[i])))
		_ok("niveau %d : le défi se dit en une phrase" % n, not "%" in Aventure.texte_defi(d))
		_ok("niveau %d : « retourne sa carte » seulement s'il commence (il pose alors ses 5 cartes)" % n,
			d["defi"] != "chef" or d["premier"] == "a")
		if d["boss"]:
			_ok("niveau %d : un boss au rang 10, qui commence" % n, Aventure.rang_de(n) == 10 and d["premier"] == "a")
			_ok("niveau %d : le boss a sa réplique" % n, str(d.get("replique", "")) != "")
			_ok("niveau %d : 3 étoiles d'invocation au boss" % n, int(d["recompense"]["etoiles"]) == Aventure.ETOILES_BOSS)
		else:
			_ok("niveau %d : le chef mène (en tête du deck)" % n, deck[0]["id"] == chef)
			_ok("niveau %d : autant de terres que prévu" % n, terres.size() == Aventure.nb_terres_de(n))
			var ecart := absi(MoteurCarre.force_deck(deck) - Aventure.force_cible(n))
			poids[ecart] = int(poids.get(ecart, 0)) + 1
			_ok("niveau %d : force %d, cible %d" % [n, MoteurCarre.force_deck(deck), Aventure.force_cible(n)], ecart <= Aventure.FORCE_ECART_MAX)
			_ok("niveau %d : pas d'étoile d'invocation hors boss" % n, int(d["recompense"]["etoiles"]) == 0)
	print("les 100 niveaux : écart à la force visée %s ; %d cartes différentes à dessiner" % [poids, cartes_vues.size()])
	# Chaque carte d'adversaire se construit (l'écran de combat les dessinera)
	var construites := 0
	for cle in cartes_vues:
		var cc := CarteCarre.new()
		add_child(cc)
		cc.configurer(cartes_vues[cle], "a")
		construites += 1
		remove_child(cc)
		cc.free()
	_ok("toutes les cartes des adversaires se construisent", construites == cartes_vues.size() and construites > 0)
	# Chaque héros, à chaque stade, a l'illustration que la carte du combat dessinera (le défaut
	# Korrigan / Ifrit / Anansi du 27/09 : ils cherchaient une 3ᵉ illustration qu'ils n'ont pas)
	var dessins := 0
	for hh in GS.HEROS:
		for s in [1, 2, 3]:
			var chemin := "res://cartes/%s-%d.jpg" % [hh["id"], CarteCarre.forme_de({"id": hh["id"], "s": s})]
			_ok("illustration à dessiner : %s" % chemin, ResourceLoader.exists(chemin))
			dessins += 1
	_ok("témoin : un stade III de Korrigan sans la règle chercherait une image absente",
		not ResourceLoader.exists("res://cartes/korrigan-%d.jpg" % MoteurCarre.stade_eff("korrigan", 1)))
	_ok("la force des adversaires monte", Aventure.force_cible(95) > Aventure.force_cible(5))
	_ok("la 1ʳᵉ terre : l'Apprenti ; la 10ᵉ : le Maître", Aventure.ia_de(5) == "apprenti" and Aventure.ia_de(95) == "maitre")


# ─────────────────────────────────────────────────────────────
# Un plateau fabriqué à la main : 9 cases, « camps » donnés
func _plateau(camps: Array) -> Dictionary:
	var cases := []
	for k in 9:
		cases.append(null if camps[k] == "" else {"id": "farfadet", "camp": camps[k], "ch": [5, 5, 5, 5]})
	return {"n": 3, "cases": cases, "bloc": [], "terres": {}}


func _etoiles() -> void:
	var d := {"defi": "premiere", "chef": "loki"}
	var gagne6 := _plateau(["j", "j", "j", "j", "j", "j", "a", "a", "a"])
	var gagne5 := _plateau(["j", "j", "j", "j", "j", "a", "a", "a", "a"])
	var perdu := _plateau(["j", "j", "j", "j", "a", "a", "a", "a", "a"])
	var j_prem := [{"camp": "j", "case": 0, "id": "thor", "ev": []}]
	var j_prem_perdue := [{"camp": "j", "case": 6, "id": "thor", "ev": []}]
	_ok("gagné à 6, première gardée : 3 ★", Aventure.etoiles(d, j_prem, gagne6) == 7)
	_ok("gagné à 5 : pas la ★ des 6 cartes", Aventure.etoiles(d, j_prem, gagne5) == 5)
	_ok("première carte perdue : pas la ★ du défi", Aventure.etoiles(d, j_prem_perdue, gagne6) == 3)
	_ok("perdu : aucune ★, même défi tenu", Aventure.etoiles(d, j_prem, perdu) == 0)
	_ok("égalité impossible en 3×3, mais 4 contre 4 = aucune ★",
		Aventure.etoiles(d, j_prem, _plateau(["j", "j", "j", "j", "a", "a", "a", "a", ""])) == 0)
	# le chef : la carte adverse du chef finit chez toi
	var j_chef := [{"camp": "a", "case": 2, "id": "loki", "ev": []}]
	_ok("chef pris", Aventure.defi_reussi("chef", d, j_chef, gagne6))
	_ok("chef pas pris", not Aventure.defi_reussi("chef", d, j_chef, _plateau(["j", "j", "a", "j", "j", "j", "a", "a", "j"])))
	_ok("chef jamais posé", not Aventure.defi_reussi("chef", d, [{"camp": "a", "case": 2, "id": "oni", "ev": []}], gagne6))
	# la chaîne
	var flip := func(chaine: bool, camp: String) -> Dictionary:
		return {"t": "flip", "de": 0, "vers": 1, "a": 5, "b": 4, "chaine": chaine, "diag": false, "prev": "a", "camp": camp}
	_ok("une chaîne à toi", Aventure.defi_reussi("chaine", d, [{"camp": "j", "case": 0, "id": "x", "ev": [flip.call(false, "j"), flip.call(true, "j")]}], gagne6))
	_ok("pas de chaîne", not Aventure.defi_reussi("chaine", d, [{"camp": "j", "case": 0, "id": "x", "ev": [flip.call(false, "j")]}], gagne6))
	_ok("la chaîne de l'adversaire ne compte pas", not Aventure.defi_reussi("chaine", d, [{"camp": "a", "case": 0, "id": "x", "ev": [flip.call(true, "a")]}], gagne6))
	# trois d'un coup
	var trois := [flip.call(false, "j"), flip.call(false, "j"), flip.call(true, "j")]
	_ok("3 cartes en un coup", Aventure.defi_reussi("trois", d, [{"camp": "j", "case": 0, "id": "x", "ev": trois}], gagne6))
	_ok("2 cartes seulement", not Aventure.defi_reussi("trois", d, [{"camp": "j", "case": 0, "id": "x", "ev": trois.slice(0, 2)}], gagne6))
	_ok("3 cartes en deux coups ne comptent pas", not Aventure.defi_reussi("trois", d, [
		{"camp": "j", "case": 0, "id": "x", "ev": trois.slice(0, 2)}, {"camp": "j", "case": 3, "id": "y", "ev": trois.slice(0, 1)}], gagne6))
	# la victoire parfaite
	_ok("parfait : les 9 à toi", Aventure.defi_reussi("parfait", d, [], _plateau(["j", "j", "j", "j", "j", "j", "j", "j", "j"])))
	_ok("presque parfait : 8", not Aventure.defi_reussi("parfait", d, [], _plateau(["j", "j", "j", "j", "j", "j", "j", "j", "a"])))


# ─────────────────────────────────────────────────────────────

func _progression() -> void:
	GS.voyage = {}
	GS.poussiere = 0
	GS.etoiles = 0
	GS.pierres = {}
	_ok("au début : le niveau 1 ouvert, pas le 2", Aventure.niveau_ouvert(1) and not Aventure.niveau_ouvert(2))
	_ok("au début : la terre 1 ouverte, pas la 2", Aventure.terre_ouverte(1) and not Aventure.terre_ouverte(2))
	_ok("au début : le prochain combat est le 1", Aventure.prochain() == 1)

	var r := Aventure.enregistrer(1, Aventure.ETOILE_VICTOIRE)
	_ok("1ʳᵉ victoire : récompensée", r["premiere_victoire"] and GS.poussiere == 40 and r["poussiere"] == 40)
	_ok("1ʳᵉ victoire : le niveau 2 s'ouvre", Aventure.niveau_ouvert(2) and Aventure.prochain() == 2)
	r = Aventure.enregistrer(1, Aventure.ETOILE_VICTOIRE)
	_ok("rejouer sans ★ nouvelle : rien", r["nouvelles"] == 0 and GS.poussiere == 40)
	r = Aventure.enregistrer(1, 7)
	_ok("rejouer avec 2 ★ nouvelles : seulement elles, sans poussière", r["nouvelles"] == 6 and not r["premiere_victoire"] and GS.poussiere == 40)
	_ok("le niveau 1 a ses 3 ★", Aventure.masque(1) == 7 and Aventure.etoiles_terre(1) == 3)
	r = Aventure.enregistrer(2, 0)
	_ok("une défaite n'enregistre rien", r["nouvelles"] == 0 and not Aventure.gagne(2))

	for n in [2, 3]:
		Aventure.enregistrer(n, 7)
	_ok("9 ★ : aucun coffre", Aventure.coffres_prets(1).is_empty())
	Aventure.enregistrer(4, 1)
	_ok("10 ★ : le coffre de 10 est prêt", Aventure.coffres_prets(1) == [10])
	var pierre := str(Aventure.TERRES[0]["type"])
	var avant := GS.nb_pierres(pierre)
	var g := Aventure.ouvrir_coffre(1, 10)
	_ok("le coffre de 10 donne une pierre de la terre", g.get("pierre", "") == pierre and GS.nb_pierres(pierre) == avant + 1)
	_ok("un coffre ne s'ouvre qu'une fois", Aventure.ouvrir_coffre(1, 10).is_empty() and GS.nb_pierres(pierre) == avant + 1)
	_ok("le coffre de 20 n'est pas prêt", Aventure.ouvrir_coffre(1, 20).is_empty())

	var etoiles_avant := GS.etoiles
	r = Aventure.enregistrer(10, 1)
	_ok("le boss : 3 étoiles d'invocation", r["etoiles"] == 3 and GS.etoiles == etoiles_avant + 3)
	_ok("le boss battu : la terre 2 s'ouvre", Aventure.terre_ouverte(2) and not Aventure.terre_ouverte(3))
	_ok("le prochain combat : le premier pas gagné (5)", Aventure.prochain() == 5)

	# la sauvegarde aller-retour
	var sauvee = JSON.parse_string(JSON.stringify(GS.donnees_sauvegarde()))
	GS.voyage = {}
	_ok("témoin : sans la sauvegarde, plus rien", Aventure.masque(1) == 0)
	GS.lire_sauvegarde(sauvee, false)
	_ok("relue : les ★, les coffres, les terres ouvertes", Aventure.masque(1) == 7 and Aventure.coffre_ouvert(1, 10)
		and Aventure.terre_ouverte(2) and Aventure.etoiles_terre(1) == 11)

	# des sauvegardes abîmées ne plantent pas
	for abime in [{"aventure": "abc"}, {"aventure": {"etoiles": [1, 2], "coffres": 5}}, {"aventure": {"etoiles": {"1": "x"}, "coffres": {"1": "y"}}}]:
		GS.voyage = abime.duplicate(true)
		_ok("sauvegarde abîmée %s : une Aventure vierge" % str(abime), Aventure.masque(1) == 0 and not Aventure.coffre_ouvert(1, 10)
			and Aventure.prochain() == 1 and Aventure.coffres_prets(1).is_empty())
