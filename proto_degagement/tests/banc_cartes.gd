extends Node

# LE BANC DE LA PUISSANCE DES CARTES (27/09) — combien chaque carte fait gagner, pour dire qui est
# fort (la rareté d'un héros en dépend : Maxim, « rendre plus difficile à avoir les plus forts »).
#
# Des milliers de parties 3 × 3 entre deux decks tirés au hasard (5 cartes distinctes, toutes au
# stade III, sans limite de poids : on mesure la carte, pas le deck), jouées par deux Aventuriers
# (le meilleur coup immédiat), le premier joueur en alternance, les terres tirées comme au jeu.
# Pour chaque carte : sa part de victoires quand elle est dans un deck. 50 % = dans la moyenne.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/banc_cartes.tscn -- [parties] [départ] [sbires] [poids] [trace]
#
# Avec « sbires » : les sbires invocables jouent aussi.
# Avec « poids » : les decks d'une vraie collection — chaque héros à un stade au hasard, sbires compris,
# 14 de poids au plus (le jeu) ; le banc donne aussi la part de victoires par RANG (sbire, héros, mythe,
# légende). La promesse des rangs : « plus fort mais plus lourd » — une carte rare n'est pas un deck gagnant.

func _ready() -> void:
	GS.sauvegarde_active = false
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 4000
	var au_poids := args.has("poids")
	var avec_sbires := args.has("sbires") or au_poids
	var ids := []
	for x in GS.HEROS:
		ids.append(str(x["id"]))
	if avec_sbires:
		for s in MoteurCarre.sbires_invocables():
			ids.append(str(s))
	var joue := {}
	var gagne := {}
	for id in ids:
		joue[id] = 0
		gagne[id] = 0
	var t0 := Time.get_ticks_msec()
	var bloquees := 0
	var depart := int(args[1]) if args.size() > 1 and args[1].is_valid_int() else 0
	for k in range(depart, depart + n):
		if args.has("trace"):
			printerr("PARTIE;%d" % k)
		elif k % (10 if args.has("fin") else 1000) == 0:
			printerr("… partie %d (%d s, %d Mo)" % [k, (Time.get_ticks_msec() - t0) / 1000, OS.get_static_memory_usage() / 1048576])
		var h := MoteurCarre.Hasard.new(1000003 + k * 7919)
		var decks := [_deck_poids(ids, h), _deck_poids(ids, h)] if au_poids else [_deck(ids, h), _deck(ids, h)]
		var st := MoteurCarre.nouvelle_partie(decks[0], decks[1], h, 3)
		if args.has("trace"):
			print("DECKS;%s | %s · terres %s" % [_ids_de(decks[0]), _ids_de(decks[1]), st["terres"]])
		var tour := "j" if k % 2 == 0 else "a"
		var pas := 0
		while not MoteurCarre.plein(st) and not ((st["main"]["j"] as Array).is_empty() and (st["main"]["a"] as Array).is_empty()):
			pas += 1
			if pas > 40:
				# 🔴 une partie qui ne finit pas : un blocage du moteur, qui figerait aussi le jeu
				print("BLOQUEE;%d;%s;%s;cases %s;main j %s;main a %s;gel %s" % [k, _ids_de(decks[0]), _ids_de(decks[1]),
					_ids_cases(st), _ids_de(st["main"]["j"]), _ids_de(st["main"]["a"]), st["gel"]])
				bloquees += 1
				break
			if (st["main"][tour] as Array).is_empty():
				tour = MoteurCarre.autre(tour)
				continue
			var coup := MoteurCarre.coup_ia(st, h, tour, "aventurier")
			if args.has("trace"):
				print("COUP;%s joue %s en %d · cases %s · gel %s" % [tour, st["main"][tour][coup[0]]["id"], coup[1], _ids_cases(st), st["gel"]])
			MoteurCarre.jouer_coup(st, tour, coup)
			tour = MoteurCarre.autre(tour)
		if pas > 40:
			continue
		var vainqueur := 0 if MoteurCarre.compte(st, "j") > MoteurCarre.compte(st, "a") else 1
		for d in 2:
			for c in decks[d]:
				joue[c["id"]] += 1
				if d == vainqueur:
					gagne[c["id"]] += 1
	var lignes := []
	for id in ids:
		var p := 100.0 * float(gagne[id]) / float(maxi(1, joue[id]))
		var marge := 196.0 * sqrt(p / 100.0 * (1.0 - p / 100.0) / float(maxi(1, joue[id])))
		lignes.append({"id": id, "p": p, "marge": marge, "n": joue[id]})
	lignes.sort_custom(func(a, b): return float(a["p"]) > float(b["p"]))
	print("carte           victoires   (± marge à 95 %%)   parties   force III   pouvoir")
	for l in lignes:
		var id := str(l["id"])
		print("BANC;%s;%.1f;%.1f;%d;%d;%s" % [id, l["p"], l["marge"], l["n"], MoteurCarre.force({"id": id, "s": 3}),
			"oui" if MoteurCarre.POUVOIRS.has(id) else "non"])
	print("parties bloquées : %d" % bloquees)
	var par_rang := {}
	for id in ids:
		var r := MoteurCarre.rang(id)
		if not par_rang.has(r):
			par_rang[r] = [0, 0]
		par_rang[r][0] += gagne[id]
		par_rang[r][1] += joue[id]
	for r in ["sbire", "heros", "mythe", "legende"]:
		if par_rang.has(r):
			print("RANG;%s;%.1f;%d" % [r, 100.0 * float(par_rang[r][0]) / float(maxi(1, par_rang[r][1])), par_rang[r][1]])
	print("%d parties en %d s · mémoire %d Mo · objets %d" % [n, (Time.get_ticks_msec() - t0) / 1000,
		OS.get_static_memory_usage() / 1048576, Performance.get_monitor(Performance.OBJECT_COUNT)])
	get_tree().quit(0)


func _ids_de(cartes: Array) -> String:
	var l := []
	for c in cartes:
		l.append("%s%d" % [c["id"], int(c["s"])])
	return ",".join(l)


func _ids_cases(st: Dictionary) -> String:
	var l := []
	for c in st["cases"]:
		l.append("." if c == null else "%s/%s" % [c["id"], c["camp"]])
	return " ".join(l)


# Un deck de collection : 5 cartes distinctes, chaque héros à un stade au hasard ; trop lourd, on descend
# le stade d'une carte au hasard, puis, au stade I, on la remplace par un sbire.
func _deck_poids(ids: Array, h: MoteurCarre.Hasard) -> Array:
	var deck := _deck(ids, h)
	for c in deck:
		var st := int(MoteurCarre.fiche(str(c["id"]))["stades"])
		c["s"] = 1 + int(floor(h.suivant() * st))
	var sbires := MoteurCarre.sbires_invocables()
	for garde in 30:
		if MoteurCarre.poids_deck(deck) <= MoteurCarre.POIDS_MAX:
			break
		# une carte au hasard (pas la plus lourde : ce serait toujours la Légende qu'on rabaisse)
		var k := int(floor(h.suivant() * deck.size()))
		if int(deck[k]["s"]) > 1 and not MoteurCarre.un_seul(str(deck[k]["id"])):
			deck[k]["s"] = int(deck[k]["s"]) - 1
		else:
			var remplacant: String = sbires[int(floor(h.suivant() * sbires.size()))]
			var deja := false
			for c in deck:
				deja = deja or c["id"] == remplacant
			if not deja:
				deck[k] = {"id": remplacant, "s": 1, "v": "base"}
	return deck


func _deck(ids: Array, h: MoteurCarre.Hasard) -> Array:
	var pris := []
	var deck := []
	while deck.size() < MoteurCarre.TAILLE_DECK:
		var id: String = ids[int(floor(h.suivant() * ids.size()))]
		if pris.has(id):
			continue
		pris.append(id)
		deck.append({"id": id, "s": 3, "v": "base"})
	return deck
