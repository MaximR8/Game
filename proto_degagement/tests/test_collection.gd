extends Node

# Le test de la collection (⑧ lot B, 28/09) — sans écran.
#
#   1. Jamais en double : un prismatique ou un Full art tiré tombe sur une carte qui ne l'a pas (tant qu'il en reste
#      dans le rang) — et le rang, la variante, eux, gardent leurs taux (les pourcentages affichés restent vrais).
#   2. Les éclats : 5 par carte, un vrai doublon davantage selon sa variante ; plus de poussière.
#   3. Les prix, « Obtenir » : le refus (pas assez, déjà là, le Full art, une carte inconnue) ET le passage.
#   4. Les niveaux : 100 × le niveau, un plafond (10 ; 1 pour un sbire ou un héros à un stade).
#   5. La sauvegarde : les éclats font l'aller-retour.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_collection.tscn
#
# Attendu : « RESULTAT: OK » et aucune ligne « SCRIPT ERROR ».

var erreurs := 0
var verifs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	_sans_double()
	_eclats()
	_obtenir()
	_niveaux()
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


func _carte(id: String, variantes: Array, stade := 1, niveau := 1) -> Dictionary:
	return {"stade": stade, "niveau": niveau, "variante": str(variantes[0]), "variantes": variantes.duplicate()}


# ─────────────────────────────────────────────────────────────

func _sans_double() -> void:
	# Toutes les cartes de chaque rang ont le prismatique ET le Full art, sauf UNE par rang.
	GS.cartes = {}
	var seules := {}
	for r in ["sbire", "heros", "mythe", "legende"]:
		var ids := GS.ids_du_rang(r)
		for k in ids.size():
			GS.cartes[ids[k]] = _carte(ids[k], ["base", "prisme", "full"] if k > 0 else ["base"])
		seules[r] = ids[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 280928
	var n := 200000
	var par_rang := {}
	var par_variante := {}
	var rares := 0
	var rares_bien := 0
	for i in n:
		var x := GS.tirer(rng)
		var id := str(x[0])
		var v := str(x[1])
		var r := MoteurCarre.rang(id)
		par_rang[r] = int(par_rang.get(r, 0)) + 1
		par_variante[v] = int(par_variante.get(v, 0)) + 1
		if v == "prisme" or v == "full":
			rares += 1
			if id == seules[r]:
				rares_bien += 1
	_ok("un prismatique ou un Full art tombe toujours sur la carte qui ne l'a pas (%d sur %d)" % [rares_bien, rares], rares > 1000 and rares_bien == rares)
	# les taux, eux, ne bougent pas
	for e in GS.probas_cartes():
		var pct := 100.0 * int(par_rang.get(str(e["id"]), 0)) / n
		_ok("le rang %s : %.2f %% (affiché %.2f)" % [e["id"], pct, float(e["pct"])], absf(pct - float(e["pct"])) < 0.35)
	for e in GS.probas():
		var pct := 100.0 * int(par_variante.get(str(e["id"]), 0)) / n
		_ok("la variante %s : %.3f %% (affiché %.3f)" % [e["id"], pct, float(e["pct"])], absf(pct - float(e["pct"])) < 0.35)
	# le témoin : quand toutes les cartes du rang l'ont, le doublon redevient possible (rien n'est bloqué)
	for r in ["sbire", "heros", "mythe", "legende"]:
		(GS.cartes[seules[r]]["variantes"] as Array).append_array(["prisme", "full"])
	var tires := {}
	for i in 60000:
		var x := GS.tirer(rng)
		if str(x[1]) == "prisme" and MoteurCarre.rang(str(x[0])) == "heros":
			tires[str(x[0])] = true
	_ok("tout le rang l'a : n'importe quelle carte (%d Héros prismatiques différents)" % tires.size(), tires.size() >= 6)


func _eclats() -> void:
	GS.cartes = {}
	GS.eclats = 0
	GS.poussiere = 0
	var r := GS._recevoir(GS.heros("thor"), "base")
	_ok("une nouvelle carte : +5 éclats", r["nouvelle"] and int(r["eclats"]) == 5 and GS.eclats == 5)
	r = GS._recevoir(GS.heros("thor"), "or")
	_ok("une nouvelle variante : +5 éclats, gardée", r["nouvelle_variante"] and int(r["eclats"]) == 5 and GS.possede("thor", "or"))
	r = GS._recevoir(GS.heros("thor"), "or")
	_ok("un vrai doublon (Or) : 5 + 10", r["doublon"] and int(r["eclats"]) == 15 and GS.eclats == 25)
	r = GS._recevoir(GS.heros("thor"), "base")
	_ok("un doublon de base : 5 + 5", int(r["eclats"]) == 10)
	_ok("plus aucune poussière pour un doublon", GS.poussiere == 0)
	GS.etoiles = 10
	var e0 := GS.eclats
	var lot: Array = GS.invoquer_multi(10)
	_ok("une ×10 : 10 cartes, au moins 50 éclats", lot.size() == 10 and GS.eclats >= e0 + 50 and GS.etoiles == 0)
	# le premier pack aussi
	GS.cartes = {}
	GS.voyage = {}
	GS.eclats = 0
	var pack: Array = GS.ouvrir_premier_pack()
	_ok("le premier pack : 10 cartes, au moins 50 éclats (%d)" % GS.eclats, pack.size() == 10 and GS.eclats >= 50)


func _obtenir() -> void:
	GS.cartes = {}
	GS.eclats = 0
	var legende := str(GS.ids_du_rang("legende")[0])
	var sbire := str(GS.ids_du_rang("sbire")[0])
	_ok("les prix : sbire 60, Héros 200 (Or 400), Légende 900 (prismatique 9 000)",
		GS.prix(sbire, "base") == 60 and GS.prix("korrigan", "base") == 200 and GS.prix("korrigan", "or") == 400
		and GS.prix(legende, "base") == 900 and GS.prix(legende, "prisme") == 9000)
	_ok("le Full art ne s'achète pas ; une carte inconnue non plus", GS.prix(legende, "full") == -1 and GS.prix("inconnu", "base") == -1)
	_ok("sans éclats : refusé", not GS.peut_obtenir(legende, "base") and GS.obtenir(legende, "base").is_empty() and not GS.cartes.has(legende))
	GS.eclats = 1000
	var r := GS.obtenir(legende, "base")
	_ok("900 éclats : la Légende entre dans la collection, il en reste 100", not r.is_empty() and r["nouvelle"] and GS.cartes.has(legende)
		and GS.eclats == 100)
	_ok("déjà là : refusé", not GS.peut_obtenir(legende, "base") and GS.obtenir(legende, "base").is_empty() and GS.eclats == 100)
	GS.eclats = 99999
	_ok("le Full art, même riche : refusé", GS.obtenir(legende, "full").is_empty() and GS.eclats == 99999)
	r = GS.obtenir(legende, "prisme")
	_ok("une variante : le prismatique rejoint la carte, et passe devant", not r.is_empty() and GS.possede(legende, "prisme")
		and GS.cartes[legende]["variante"] == "prisme" and GS.eclats == 99999 - 9000)


func _niveaux() -> void:
	GS.cartes = {"thor": _carte("thor", ["base"], 1, 9), "chinchin": _carte("chinchin", ["base"])}
	GS.poussiere = 5000
	_ok("un niveau coûte 100 × le niveau", GS.cout_niveau("thor") == 900)
	_ok("le plafond : 10 pour Thor, 1 pour un sbire", GS.niveau_max("thor") == 10 and GS.niveau_max("chinchin") == 1)
	_ok("du niveau 9 au 10 : oui", GS.monter_niveau("thor") and int(GS.cartes["thor"]["niveau"]) == 10 and GS.poussiere == 4100)
	_ok("au-delà du 10 : non, même avec la poussière", not GS.peut_monter("thor") and not GS.monter_niveau("thor") and GS.poussiere == 4100)
	_ok("un sbire : pas de niveau", not GS.peut_monter("chinchin"))
	var un_seul := ""
	for h in GS.HEROS:
		if (h["formes"] as Array).size() == 1:
			un_seul = str(h["id"])
			break
	GS.cartes[un_seul] = _carte(un_seul, ["base"])
	_ok("un héros à un seul stade (%s) : pas de niveau" % un_seul, GS.niveau_max(un_seul) == 1 and not GS.peut_monter(un_seul))


func _sauvegarde() -> void:
	GS.eclats = 321
	var texte := JSON.stringify(GS.donnees_sauvegarde())
	GS.eclats = 0
	GS.lire_sauvegarde(JSON.parse_string(texte), false)
	_ok("les éclats font l'aller-retour (%d)" % GS.eclats, GS.eclats == 321)
