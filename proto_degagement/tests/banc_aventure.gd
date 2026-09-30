extends Node

# Le banc de la courbe de l'Aventure (étape 2 du Carré, 27/09).
#
# Chaque niveau est joué comme dans le jeu (ses terres, qui commence, l'ordinateur tiré de sa graine)
# par deux joueurs de remplacement :
#   · le « joueur moyen » joue comme l'Aventurier (le meilleur coup immédiat) ;
#   · le « débutant » joue au hasard (la 1ʳᵉ terre seulement : c'est le tuto).
# Son deck : 5 héros au hasard, au poids qu'une collection a à ce stade (10 à la 1ʳᵉ terre, puis +1
# par terre, 14 au plus — le plafond du jeu).
# Les cibles de la fiche du 27/09 (joueur moyen) : ~90 % au niveau 1, ~60 % aux boss du milieu,
# ~40 % au boss final ; aucun niveau impossible.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/banc_aventure.tscn -- [parties par niveau] [premier niveau] [dernier niveau]

var ids_heros := []


func _ready() -> void:
	GS.sauvegarde_active = false
	var args := OS.get_cmdline_user_args()
	var n_parties := int(args[0]) if args.size() > 0 else 20
	var de := int(args[1]) if args.size() > 1 else 1
	var a := int(args[2]) if args.size() > 2 else Aventure.NB_NIVEAUX
	for x in GS.HEROS:
		ids_heros.append(str(x["id"]))
	var t0 := Time.get_ticks_msec()
	var par_terre := {}
	var hors_bornes := []
	print("niv  terre rang  ordi        force  1er  défi      | moyen : gagne  6+  défi | débutant")
	for n in range(de, a + 1):
		var d := Aventure.niveau(n)
		var moyen := _jouer(d, n_parties, "moyen")
		var debutant := _jouer(d, n_parties, "hasard") if Aventure.terre_de(n) == 1 else {}
		var t := Aventure.terre_de(n)
		if not par_terre.has(t):
			par_terre[t] = []
		par_terre[t].append(moyen["gagne"])
		print("%3d  %4d  %3d%s  %-10s  %4d   %s   %-9s |        %3d %%  %3d %%  %3d %% | %s" % [n, t, Aventure.rang_de(n), "B" if d["boss"] else " ",
			d["niveau"], MoteurCarre.force_deck(d["deck"]), d["premier"], d["defi"], moyen["gagne"], moyen["six"], moyen["defi"],
			("%3d %%" % debutant["gagne"]) if not debutant.is_empty() else ""])
		if moyen["gagne"] < 15 or (t > 1 and moyen["gagne"] > 97):
			hors_bornes.append(n)
	print("— moyenne du joueur moyen, par terre :")
	for t in par_terre:
		var s := 0
		for v in par_terre[t]:
			s += v
		print("    terre %2d : %3d %%" % [t, s / (par_terre[t] as Array).size()])
	print("— niveaux hors bornes (moins de 15 %%, ou plus de 97 %% après la 1ʳᵉ terre) : %s" % str(hors_bornes))
	var a_montrer := hors_bornes.duplicate()
	for n in range(de, a + 1):
		if Aventure.rang_de(n) == Aventure.PAR_TERRE:
			a_montrer.append(n)
	for n in a_montrer:
		var d := Aventure.niveau(n)
		var l := []
		for c in d["deck"]:
			l.append("%s %d (force %d)" % [c["id"], int(c["s"]), MoteurCarre.somme(MoteurCarre.chiffres_de(str(c["id"]), int(c["s"])))])
		print("    %d : %s ; terres %s" % [n, ", ".join(l), d["terres"]])
	print("en %d s" % ((Time.get_ticks_msec() - t0) / 1000))
	get_tree().quit(0)


# Le deck d'un joueur à la terre t : 5 héros au hasard, montés en stade jusqu'au poids d'une collection de ce stade.
func _deck_joueur(t: int, h: MoteurCarre.Hasard) -> Array:
	var cible := mini(MoteurCarre.POIDS_MAX, 9 + t)
	var pris := []
	var deck := []
	while deck.size() < MoteurCarre.TAILLE_DECK:
		var id: String = ids_heros[int(floor(h.suivant() * ids_heros.size()))]
		if pris.has(id):
			continue
		pris.append(id)
		deck.append({"id": id, "s": 1, "v": "base"})
	for garde in 20:
		if MoteurCarre.poids_deck(deck) >= cible:
			break
		var k := int(floor(h.suivant() * deck.size()))
		var id := str(deck[k]["id"])
		if not MoteurCarre.un_seul(id) and int(deck[k]["s"]) < int(MoteurCarre.fiche(id)["stades"]):
			deck[k]["s"] = int(deck[k]["s"]) + 1
	return deck


# Joue un niveau n_parties fois ; rend les pourcentages {gagne, six, defi} (six et défi : parmi les victoires).
func _jouer(d: Dictionary, n_parties: int, joueur: String) -> Dictionary:
	var gagne := 0
	var six := 0
	var defi := 0
	for k in n_parties:
		var hj := MoteurCarre.Hasard.new(7919 * int(d["n"]) + k)
		var deck_j := _deck_joueur(int(d["terre"]), hj)
		# comme l'écran : le hasard de l'ordinateur vient de la graine du niveau, rien d'autre
		var h := MoteurCarre.Hasard.new(int(d["graine"]))
		var st := MoteurCarre.nouvelle_partie(deck_j, d["deck"], h, 3)
		st["terres"] = (d["terres"] as Dictionary).duplicate()
		var tour := str(d["premier"])
		var journal := []
		while not MoteurCarre.plein(st) and not ((st["main"]["j"] as Array).is_empty() and (st["main"]["a"] as Array).is_empty()):
			if (st["main"][tour] as Array).is_empty():
				tour = MoteurCarre.autre(tour)
				continue
			var m: Array
			if tour == "a":
				m = MoteurCarre.coup_ia(st, h, "a", str(d["niveau"]))
			elif joueur == "hasard":
				var tous := MoteurCarre.coups(st, "j")
				m = tous[int(floor(hj.suivant() * tous.size()))]
			else:
				m = MoteurCarre.coup_ia(st, hj, "j", "aventurier")
			var id := str(st["main"][tour][m[0]]["id"])
			var ev := MoteurCarre.jouer_coup(st, tour, m)
			journal.append({"camp": tour, "case": m[1], "id": id, "ev": ev})
			tour = MoteurCarre.autre(tour)
		var masque := Aventure.etoiles(d, journal, st)
		if masque & Aventure.ETOILE_VICTOIRE:
			gagne += 1
			if masque & Aventure.ETOILE_SIX:
				six += 1
			if masque & Aventure.ETOILE_DEFI:
				defi += 1
	return {"gagne": 100 * gagne / n_parties, "six": 100 * six / maxi(1, gagne), "defi": 100 * defi / maxi(1, gagne)}
