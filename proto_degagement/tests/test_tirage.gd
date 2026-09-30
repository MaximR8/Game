extends Node

# Vérifie le tirage des variantes : sur 100 000 tirages, chaque variante
# tombe à moins d'un point de la probabilité affichée au joueur ; puis par
# le VRAI chemin du jeu (invoquer_multi, 20 000 ×10), à moins de 0,3 point.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_tirage.tscn
#
# (Une scène, plus un --script depuis le 27/09 : le tirage passe par MoteurCarre, qui a besoin de GS.)
#
# ⛔ N'appelle jamais invoquer() ici : il écrit la sauvegarde.

func _ready() -> void:
	var gs = load("res://game_state.gd").new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260923
	var n := 100000
	var compte := {}
	var ok := true
	for i in n:
		var h: Dictionary = gs.HEROS[i % gs.HEROS.size()]
		var v: String = gs.tirer_variante(h, rng)
		compte[v] = int(compte.get(v, 0)) + 1
	for p in gs.probas():
		var obs := 100.0 * float(compte.get(p["id"], 0)) / float(n)
		var ecart := absf(obs - float(p["pct"]))
		print("%-12s affiché %6.2f %%   observé %6.2f %%   écart %.2f" % [p["nom"], p["pct"], obs, ecart])
		if ecart > 1.0:
			ok = false
	var somme := 0.0
	for p in gs.probas():
		somme += float(p["pct"])
	if absf(somme - 100.0) > 0.01:
		print("ERREUR : les probabilités affichées font %.3f %%" % somme)
		ok = false
	# Chaque héros a une illustration par stade, et un cadrage par stade.
	for h in gs.HEROS:
		var formes: Array = h["formes"]
		var cadrage: Array = h["cadrage"]
		if cadrage.size() != formes.size():
			print("ERREUR : %s a %d stades mais %d cadrages" % [h["id"], formes.size(), cadrage.size()])
			ok = false
		for s in range(1, formes.size() + 1):
			var chemin := "res://cartes/%s-%d.jpg" % [h["id"], s]
			if not ResourceLoader.exists(chemin):
				print("ERREUR : illustration manquante %s" % chemin)
				ok = false
		if not gs.TYPES.has(h["type"]):
			print("ERREUR : type inconnu pour %s" % h["id"])
			ok = false
	# L'invocation ×10 : exactement 10 tickets pour 10 cartes, refus sans rien
	# dépenser sous 10 tickets, et une collection de variantes cohérente.
	gs.sauvegarde_active = false
	gs.etoiles = 1000
	var recues := 0
	for i in 100:
		recues += (gs.invoquer_multi(10) as Array).size()
	if gs.etoiles != 0 or recues != 1000:
		print("ERREUR : ×10 — %d étoiles restantes, %d cartes reçues (attendu 0 et 1000)" % [gs.etoiles, recues])
		ok = false
	gs.etoiles = 9
	if (gs.invoquer_multi(10) as Array).size() != 0 or gs.etoiles != 9:
		print("ERREUR : ×10 accepté ou payé avec seulement 9 étoiles")
		ok = false
	var avec_plusieurs := ""
	for id in gs.cartes.keys():
		var e: Dictionary = gs.cartes[id]
		var vs: Array = e["variantes"]
		if not vs.has(e["variante"]):
			print("ERREUR : %s affiche une variante qu'il n'a pas" % id)
			ok = false
		var vues := {}
		for v in vs:
			if vues.has(v):
				print("ERREUR : %s a deux fois la variante %s" % [id, v])
				ok = false
			vues[v] = true
		if vs.size() > 1:
			avec_plusieurs = id
	print("×10 : %d cartes, %d héros, %s a plusieurs variantes" % [recues, gs.cartes.size(), avec_plusieurs])
	# Le vrai chemin du jeu : 20 000 invocations ×10, comme le bouton.
	gs.etoiles = 200000
	var vrai := {}
	var rangs := {}
	var cartes_vraies := 0
	for i in 20000:
		for r in gs.invoquer_multi(10):
			vrai[r["variante"]] = int(vrai.get(r["variante"], 0)) + 1
			var rg := "sbire" if bool(r["heros"].get("sbire", false)) else str(MoteurCarre.RANGS.get(str(r["heros"]["id"]), "heros"))
			rangs[rg] = int(rangs.get(rg, 0)) + 1
			cartes_vraies += 1
	# Le rang d'une carte (27/09) : chaque rang tombe à moins de 0,3 point de ce qu'on affiche, et ne
	# donne que ses cartes (un sbire invocable, un héros de ce rang).
	var somme_rangs := 0.0
	for p in gs.probas_cartes():
		somme_rangs += float(p["pct"])
		var obs3 := 100.0 * float(rangs.get(p["id"], 0)) / float(cartes_vraies)
		var ecart3 := absf(obs3 - float(p["pct"]))
		print("par le jeu · rang %-8s (%2d cartes) affiché %6.2f %%   observé %6.3f %%   écart %.3f" % [p["nom"], p["n"], p["pct"], obs3, ecart3])
		if ecart3 > 0.3:
			ok = false
	if absf(somme_rangs - 100.0) > 0.01:
		print("ERREUR : les rangs affichés font %.3f %%" % somme_rangs)
		ok = false
	for id in gs.cartes.keys():
		if gs.heros(str(id)).is_empty():
			print("ERREUR : une carte inconnue est entrée dans la collection : %s" % id)
			ok = false
	for sb in MoteurCarre.sbires_invocables():
		if not ResourceLoader.exists("res://cartes/%s-1.jpg" % sb):
			print("ERREUR : sbire invocable sans illustration : %s" % sb)
			ok = false
	# Le premier pack offert (28/09) : 1 000 packs — toujours 10 cartes, au moins 5 différentes, dont
	# au moins 3 héros différents ; et il reste un tirage (des sbires, des doublons, des Légendes parfois).
	var rngp := RandomNumberGenerator.new()
	rngp.seed = 20260928
	var mini_diff := 10
	var mini_heros := 10
	var avec_legende := 0
	var avec_doublon := 0
	for i in 1000:
		var pack: Array = gs.tirer_premier_pack(rngp)
		var diff := {}
		var hs := {}
		var leg := false
		for x in pack:
			diff[x[0]] = true
			if not gs.est_sbire(str(x[0])):
				hs[x[0]] = true
				leg = leg or str(MoteurCarre.RANGS.get(str(x[0]), "heros")) == "legende"
		if pack.size() != 10:
			print("ERREUR : un premier pack de %d cartes" % pack.size())
			ok = false
		mini_diff = mini(mini_diff, diff.size())
		mini_heros = mini(mini_heros, hs.size())
		avec_legende += 1 if leg else 0
		avec_doublon += 1 if diff.size() < 10 else 0
	print("premier pack · 1 000 packs : au moins %d cartes différentes, au moins %d héros ; %d avec une Légende, %d avec un doublon" % [mini_diff, mini_heros, avec_legende, avec_doublon])
	if mini_diff < gs.PACK_DIFFERENTES or mini_heros < gs.PACK_HEROS:
		print("ERREUR : la garantie du premier pack n'est pas tenue")
		ok = false
	for p in gs.probas():
		var obs2 := 100.0 * float(vrai.get(p["id"], 0)) / float(cartes_vraies)
		var ecart2 := absf(obs2 - float(p["pct"]))
		print("par le jeu · %-12s affiché %6.2f %%   observé %6.3f %%   écart %.3f" % [p["nom"], p["pct"], obs2, ecart2])
		if ecart2 > 0.3:
			ok = false
	if cartes_vraies != 200000:
		print("ERREUR : %d cartes par le vrai chemin au lieu de 200 000" % cartes_vraies)
		ok = false
	if avec_plusieurs == "":
		print("ERREUR : aucun héros n'a plusieurs variantes après 1000 cartes")
		ok = false
	else:
		var e: Dictionary = gs.cartes[avec_plusieurs]
		var autre: String = (e["variantes"] as Array)[0] if (e["variantes"] as Array)[0] != e["variante"] else (e["variantes"] as Array)[1]
		if not gs.choisir_variante(avec_plusieurs, autre) or gs.cartes[avec_plusieurs]["variante"] != autre:
			print("ERREUR : impossible d'afficher une variante possédée")
			ok = false
		# une variante qu'il n'a pas (s'il les a toutes, rien à vérifier)
		for v in gs.VARIANTES:
			if not (e["variantes"] as Array).has(v["id"]):
				if gs.choisir_variante(avec_plusieurs, str(v["id"])):
					print("ERREUR : on a pu afficher une variante non possédée")
					ok = false
				break
	print("RESULTAT: " + ("OK" if ok else "ECHEC"))
	gs.free()
	get_tree().quit(0 if ok else 1)
