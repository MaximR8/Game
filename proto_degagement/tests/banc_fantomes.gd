extends Node

# Le banc des adversaires du Duel et du Classé (étape 3 du Carré, 28/09).
#
#   1. Les forces de deck possibles (un deck de joueur : 5 cartes, poids 14) : la plus faible, la plus
#      forte (calculée exactement), celle d'un premier pack ; et ce que le générateur atteint.
#   2. Des joueurs de remplacement contre les adversaires de chaque cote (800 → 1800) :
#        · « débutant »       : deck d'un premier pack, joue au hasard ;
#        · « moyen, départ »  : deck d'un premier pack, joue comme l'Aventurier (le meilleur coup immédiat) ;
#        · « moyen, milieu »  : deck à mi-chemin du meilleur, même jeu ;
#        · « moyen, max »     : le meilleur deck, même jeu ;
#        · « fort, max »      : le meilleur deck, joue comme le Maître (il regarde la réponse).
#      Le premier joueur alterne ; le deck du joueur change à chaque partie (même force).
#   3. Ce qu'on en tire : la cote où chacun gagne une partie sur deux (le Duel l'y amène), et, au Classé
#      (+25 / −20), la cote où il cale (il gagne moins de 44,4 %) et les parties pour y arriver.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/banc_fantomes.tscn -- [parties par case] [pas de cote]

const PROFILS := [
	["débutant", "depart", "hasard"],
	["moyen, départ", "depart", "aventurier"],
	["moyen, milieu", "milieu", "aventurier"],
	["moyen, max", "max", "aventurier"],
	["fort, max", "max", "maitre"],
]


func _ready() -> void:
	GS.sauvegarde_active = false
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0] == "echelle":
		_echelle(int(args[1]) if args.size() > 1 else 8, int(args[2]) if args.size() > 2 else 250)
		return
	var n_parties := int(args[0]) if args.size() > 0 else 40
	var pas := int(args[1]) if args.size() > 1 else 100
	var t0 := Time.get_ticks_msec()

	# ── 1. les forces
	var f_max := _force_max()
	var f_min := _force_min()
	var f_depart := _force_premier_pack(200)
	var forces := {"depart": f_depart, "milieu": roundi((f_depart + f_max) / 2.0), "max": f_max}
	print("forces de deck : la plus faible %d · premier pack (moyenne) %d · la plus forte %d" % [f_min, f_depart, f_max])
	var l := []
	for cible in range(70, 136, 5):
		var tot := 0
		var pire := 0
		for g in 20:
			var d := Fantomes.deck_de_force(cible, MoteurCarre.Hasard.new(g * 131 + cible))
			if not Fantomes.legal(d):
				print("  ✗ deck illégal pour la cible %d" % cible)
			var e := absi(MoteurCarre.force_deck(d) - cible)
			tot += e
			pire = maxi(pire, e)
		l.append("%d:±%.1f(%d)" % [cible, tot / 20.0, pire])
	print("le générateur, écart moyen (pire) : " + "  ".join(l))

	# ── 2. les parties
	var cotes := []
	for c in range(800, 1801, pas):
		cotes.append(c)
	var entete := "profil            "
	for c in cotes:
		entete += " %5d" % c
	print(entete)
	var taux := {}
	for p in PROFILS:
		var ligne := "%-18s" % p[0]
		var t := []
		for c in cotes:
			var w := _taux(c, int(forces[p[1]]), str(p[2]), n_parties)
			t.append(w)
			ligne += "  %3d%%" % roundi(w * 100.0)
		taux[p[0]] = t
		print(ligne)

	# ── 3. ce qu'on en tire
	print("— le Duel (où l'on gagne une partie sur deux) et le Classé (+25/−20 : où l'on cale, et en combien de parties) :")
	for p in PROFILS:
		var t: Array = taux[p[0]]
		var eq := "sous %d" % cotes[0]
		var cale := "jamais (au-delà de %d)" % cotes[-1]
		var trouve := false
		var parties := 0.0
		for k in cotes.size():
			if t[k] < 0.5 and eq.begins_with("sous") and k > 0:
				eq = "~%d" % roundi(lerpf(cotes[k - 1], cotes[k], (t[k - 1] - 0.5) / maxf(0.001, t[k - 1] - t[k])))
			elif t[k] < 0.5 and k == 0:
				pass
			var gain: float = 25.0 * t[k] - 20.0 * (1.0 - t[k])
			if gain <= 0.0 and not trouve:
				cale = "%d" % cotes[k]
				trouve = true
			if not trouve:
				parties += 100.0 * pas / 60.0 / gain      # 100 points par marche ; une marche ≈ 60 de cote (classe.gd)
		if t[0] < 0.5:
			eq = "sous %d" % cotes[0]
		elif t[-1] >= 0.5:
			eq = "au-delà de %d" % cotes[-1]
		print("  %-16s Duel : %-14s Classé : cale à %-22s (~%d parties pour y arriver)" % [p[0], eq, cale, roundi(parties)])
	print("en %d s" % ((Time.get_ticks_msec() - t0) / 1000))
	get_tree().quit(0)


# La part de victoires (une égalité compte une demie) d'un joueur contre les adversaires d'une cote.
func _taux(cote: int, force_j: int, jeu: String, n: int) -> float:
	var score := 0.0
	for k in n:
		var graine := cote * 1009 + k
		var r := _partie(Fantomes.adversaire(cote, graine), force_j, jeu, graine, k % 2 == 0)
		score += 1.0 if r > 0 else (0.5 if r == 0 else 0.0)
	return score / n


# Une partie : 1 gagnée, 0 égalité, −1 perdue.
func _partie(adv: Dictionary, force_j: int, jeu: String, graine: int, j_commence: bool) -> int:
	var hj := MoteurCarre.Hasard.new(graine * 7 + 3)
	var deck_j := Fantomes.deck_de_force(force_j, hj)
	var h := MoteurCarre.Hasard.new(int(adv["graine"]))
	var st := MoteurCarre.nouvelle_partie(deck_j, adv["deck"], h, 3)
	var tour := "j" if j_commence else "a"
	while not MoteurCarre.plein(st) and not ((st["main"]["j"] as Array).is_empty() and (st["main"]["a"] as Array).is_empty()):
		if (st["main"][tour] as Array).is_empty():
			tour = MoteurCarre.autre(tour)
			continue
		var m: Array
		if tour == "a":
			m = MoteurCarre.coup_ia(st, h, "a", str(adv["niveau"]))
		elif jeu == "hasard":
			var tous := MoteurCarre.coups(st, "j")
			m = tous[int(floor(hj.suivant() * tous.size()))]
		else:
			m = MoteurCarre.coup_ia(st, hj, "j", jeu)
		MoteurCarre.jouer_coup(st, tour, m)
		tour = MoteurCarre.autre(tour)
	var j := MoteurCarre.compte(st, "j")
	var a := MoteurCarre.compte(st, "a")
	return 1 if j > a else (0 if j == a else -1)


# L'échelle, jouée pour de vrai (classe.gd, duel.gd) : pour chaque profil, n_saisons saisons de
# n_parties parties. Au Classé : la marche après 50, 100, 150, 250 parties, et quand le Zénith tombe.
# Au Duel : la cote après 50 et 150 parties.
func _echelle(n_saisons: int, n_parties: int) -> void:
	var t0 := Time.get_ticks_msec()
	var forces := {"depart": _force_premier_pack(200), "max": _force_max()}
	forces["milieu"] = roundi((int(forces["depart"]) + int(forces["max"])) / 2.0)
	var reperes := [50, 100, 150, 250]
	print("Classé : %d saisons de %d parties par profil (la marche médiane après N parties ; le Zénith : en combien, et combien de fois)" % [n_saisons, n_parties])
	for p in PROFILS:
		var marches := {}
		for r in reperes:
			marches[r] = []
		var zenith := []
		var cotes_50 := []
		var cotes_150 := []
		for s in n_saisons:
			GS.voyage = {}
			Classe.date_test = {"year": 2026, "month": 10, "day": 1}
			Classe.verifier_saison()
			var z := -1
			for k in n_parties:
				var graine := s * 100003 + k
				var adv := Classe.adversaire_suivant(graine)
				Classe.enregistrer(_partie(adv, int(forces[p[1]]), str(p[2]), graine, k % 2 == 0))
				var pal: int = Classe.donnees()["palier"]
				if z < 0 and pal == Classe.ZENITH:
					z = k + 1
				if marches.has(k + 1):
					marches[k + 1].append(pal)
			zenith.append(z)
			# le Duel, depuis 1000
			for k in 150:
				var graine := s * 7919 + k
				var adv := Duel.adversaire_suivant(graine)
				Duel.enregistrer(_partie(adv, int(forces[p[1]]), str(p[2]), graine, k % 2 == 0), adv)
				if k + 1 == 50:
					cotes_50.append(Duel.cote())
			cotes_150.append(Duel.cote())
		var l := "%-16s" % p[0]
		for r in reperes:
			if r <= n_parties:
				var m: Array = marches[r]
				m.sort()
				l += "  %3d : %-13s" % [r, Classe.nom_palier(int(m[m.size() / 2]))]
		var atteints := zenith.filter(func(x): return x > 0)
		atteints.sort()
		l += "  Zénith : %d/%d%s" % [atteints.size(), n_saisons, (" (médiane %d parties)" % int(atteints[atteints.size() / 2])) if not atteints.is_empty() else ""]
		cotes_50.sort()
		cotes_150.sort()
		l += "  | Duel : %d après 50, %d après 150" % [int(cotes_50[cotes_50.size() / 2]), int(cotes_150[cotes_150.size() / 2])]
		print(l)
	Classe.date_test = {}
	print("en %d s" % ((Time.get_ticks_msec() - t0) / 1000))
	get_tree().quit(0)


# La force la plus haute d'un deck de joueur, exactement : un sac à dos (chaque carte à un seul stade,
# 5 cartes, poids 14 au plus).
func _force_max() -> int:
	# meilleur[nombre][poids] = force
	var meilleur := {}
	meilleur[Vector2i(0, 0)] = 0
	for id in Fantomes.pool():
		var suivant := meilleur.duplicate()
		for cle in meilleur:
			var n: int = cle.x
			var p: int = cle.y
			if n >= MoteurCarre.TAILLE_DECK:
				continue
			for s in range(1, int(MoteurCarre.fiche(id)["stades"]) + 1):
				var c := {"id": id, "s": s, "v": "base"}
				var p2 := p + MoteurCarre.poids(id, s)
				if p2 > MoteurCarre.POIDS_MAX:
					continue
				var k2 := Vector2i(n + 1, p2)
				var f2: int = int(meilleur[cle]) + MoteurCarre.force(c)
				if not suivant.has(k2) or int(suivant[k2]) < f2:
					suivant[k2] = f2
		meilleur = suivant
	var best := 0
	for cle in meilleur:
		if cle.x == MoteurCarre.TAILLE_DECK:
			best = maxi(best, int(meilleur[cle]))
	return best


# La plus faible : le héros le plus faible au stade I, et les quatre sbires les plus faibles.
func _force_min() -> int:
	var heros := 999
	var sbires := []
	for id in Fantomes.pool():
		var f := MoteurCarre.force({"id": id, "s": 1, "v": "base"})
		if MoteurCarre.fiche(id)["sbire"]:
			sbires.append(f)
		else:
			heros = mini(heros, f)
	sbires.sort()
	var t := heros
	for k in 4:
		t += int(sbires[k])
	return t


# La force moyenne du deck composé tout seul après le premier pack (tout au stade I).
func _force_premier_pack(n: int) -> int:
	var tot := 0
	var rng := RandomNumberGenerator.new()
	for k in n:
		rng.seed = 5000 + k
		GS.cartes = {}
		GS.voyage = {}
		for x in GS.tirer_premier_pack(rng):
			GS.cartes[str(x[0])] = {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1}
		tot += MoteurCarre.force_deck(VoyageEcran.deck_auto())
	GS.cartes = {}
	return roundi(float(tot) / n)
