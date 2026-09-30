extends Node

# Le banc de parité du Carré (FEATURES ②, 27/09) — côté JEU.
#
# Rejoue, avec carre/moteur_carre.gd, les parties que le moteur web a jouées
# (tests/parite_carre.json, écrit par tests/parite_carre.js), et compare coup par coup :
# le coup choisi par l'ordinateur, chaque événement (retournement, pouvoir, chaîne), l'état
# final. Compare aussi les chiffres de chaque carte à chaque stade.
#
#   node proto_degagement/tests/parite_carre.js 400
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_carre.tscn
#
# Attendu : « RESULTAT: OK » et aucune ligne « SCRIPT ERROR ».

var erreurs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	# le prototype web n'a pas de rangs (Mythe, Légende : MoteurCarre.RANGS) : on compare sans eux
	MoteurCarre.rangs_actifs = false
	var f := FileAccess.open("res://tests/parite_carre.json", FileAccess.READ)
	if f == null:
		print("RESULTAT: ECHEC — tests/parite_carre.json introuvable (lancer d'abord tests/parite_carre.js)")
		get_tree().quit(1)
		return
	var ref = JSON.parse_string(f.get_as_text())
	f.close()
	ref = _entiers(ref)
	var t0 := Time.get_ticks_msec()

	# 1. Les chiffres de chaque carte, à chaque stade
	var nb_ch := 0
	for cle in (ref["chiffres"] as Dictionary).keys():
		var id := str(cle).substr(0, str(cle).length() - 1)
		var s := int(str(cle).right(1))
		var attendu: Array = ref["chiffres"][cle]
		var obtenu := MoteurCarre.chiffres_de(id, s)
		nb_ch += 1
		if obtenu != attendu:
			_ko("chiffres de %s (stade %d) : %s au lieu de %s" % [id, s, obtenu, attendu])

	# 2. Les parties, coup par coup
	var nb_coups := 0
	var parties: Array = ref["parties"]
	for k in parties.size():
		var p: Dictionary = parties[k]
		var h := MoteurCarre.Hasard.new(int(p["graine"]))
		var st := MoteurCarre.nouvelle_partie(p["mj"], p["ma"], h, int(p["n"]))
		var terres := {}
		for c in (p["terres"] as Dictionary).keys():
			terres[int(c)] = p["terres"][c]
		if st["terres"] != terres or st["bloc"] != p["bloc"]:
			_ko("partie %d : terres %s / %s au lieu de %s / %s" % [k, st["terres"], st["bloc"], terres, p["bloc"]])
			continue
		var tour := str(p["premier"])
		var niveaux: Dictionary = p["niveaux"]
		var i := 0
		var ok := true
		while not MoteurCarre.plein(st) and (not (st["main"]["j"] as Array).is_empty() or not (st["main"]["a"] as Array).is_empty()):
			if (st["main"][tour] as Array).is_empty():
				tour = MoteurCarre.autre(tour)
				continue
			var m := MoteurCarre.coup_ia(st, h, tour, str(niveaux[tour]))
			var ev := MoteurCarre.jouer_coup(st, tour, m)
			nb_coups += 1
			if i >= (p["coups"] as Array).size():
				_ko("partie %d : un coup de trop (%s)" % [k, m])
				ok = false
				break
			var att: Dictionary = p["coups"][i]
			if m != att["m"]:
				_ko("partie %d, coup %d (%s, %s) : %s au lieu de %s" % [k, i, tour, niveaux[tour], m, att["m"]])
				ok = false
				break
			if ev != att["ev"]:
				_ko("partie %d, coup %d : événements\n    jeu : %s\n    web : %s" % [k, i, ev, att["ev"]])
				ok = false
				break
			tour = MoteurCarre.autre(tour)
			i += 1
		if not ok:
			continue
		if i != (p["coups"] as Array).size():
			_ko("partie %d : %d coups au lieu de %d" % [k, i, (p["coups"] as Array).size()])
			continue
		for c in (st["cases"] as Array).size():
			var a = p["final"][c]
			var o = st["cases"][c]
			var o2 = null if o == null else {"id": o["id"], "camp": o["camp"], "ch": o["ch"]}
			if o2 != a:
				_ko("partie %d, case %d à la fin : %s au lieu de %s" % [k, c, o2, a])
				break
		if MoteurCarre.compte(st, "j") != int(p["score"]["j"]) or MoteurCarre.compte(st, "a") != int(p["score"]["a"]):
			_ko("partie %d : score faux" % k)

	# 3. La sauvegarde : la clé du Voyage fait l'aller-retour ; une sauvegarde d'avant (sans elle)
	#    se charge telle quelle, collection comprise, et le premier combat guidé reste à faire.
	GS.cartes = {"thor": {"stade": 2, "niveau": 4, "variante": "or", "variantes": ["base", "or"]}}
	GS.voyage = {"tuto_carre": true}
	var sauvee = JSON.parse_string(JSON.stringify(GS.donnees_sauvegarde()))
	GS.voyage = {}
	GS.lire_sauvegarde(sauvee, false)
	if not bool(GS.voyage.get("tuto_carre", false)):
		_ko("sauvegarde : le premier combat guidé fait n'est pas relu")
	var ancienne: Dictionary = sauvee.duplicate(true)
	ancienne.erase("voyage")
	GS.lire_sauvegarde(ancienne, false)
	if not GS.voyage.is_empty() or not GS.cartes.has("thor") or int(GS.cartes["thor"]["stade"]) != 2:
		_ko("sauvegarde : une sauvegarde sans Voyage se charge mal (%s, %s)" % [GS.voyage, GS.cartes])

	# 4. Les deux témoins du banc : il sait refuser (un coup faussé est vu)
	var p0: Dictionary = parties[0]
	var h0 := MoteurCarre.Hasard.new(int(p0["graine"]) + 1)
	var st0 := MoteurCarre.nouvelle_partie(p0["mj"], p0["ma"], h0, int(p0["n"]))
	var m0 := MoteurCarre.coup_ia(st0, h0, str(p0["premier"]), "maitre")
	var temoin_refus: bool = st0["terres"] != p0["terres"] or m0 != p0["coups"][0]["m"]
	if not temoin_refus:
		_ko("témoin : une autre graine donne la même partie — le banc ne verrait rien")

	var ms := Time.get_ticks_msec() - t0
	print("%d chiffres, %d parties, %d coups comparés en %d ms" % [nb_ch, parties.size(), nb_coups, ms])
	print("RESULTAT: %s" % ("OK" if erreurs == 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)


func _ko(t: String) -> void:
	erreurs += 1
	if erreurs <= 12:
		print("  ✗ " + t)


# Le JSON rend des flottants : 3.0 redevient 3, pour comparer avec les entiers du moteur.
func _entiers(x):
	match typeof(x):
		TYPE_FLOAT:
			return int(x) if x == floor(x) else x
		TYPE_ARRAY:
			var a := []
			for e in x:
				a.append(_entiers(e))
			return a
		TYPE_DICTIONARY:
			var d := {}
			for k in x.keys():
				d[k] = _entiers(x[k])
			return d
	return x
