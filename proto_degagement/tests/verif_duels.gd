extends Node

# Chaque duel du Carré montre-t-il les chiffres qui se battent vraiment ? (27/09)
#
# Maxim, 27/09 : « j'ai utilisé Bahamut contre Yéti, il avait moins de points et ça a retourné ma
# carte quand même ». Le moteur est celui du web (banc de parité) ; la question est ce que le
# joueur VOIT. Ce banc joue des milliers de parties (Bahamut dans ton deck, les niveaux de
# l'Aventure en face) et, à chaque retournement, compare les deux chiffres qui ont combattu à ceux
# que l'écran montre à cet instant :
#   · l'ANCIEN affichage (la fin du coup, montrée dès la pose) — le témoin qui doit échouer ;
#   · le NOUVEAU (la trace du moteur, pas à pas : carre_ecran._animer) — zéro écart attendu.
# Il compte aussi, pour information, les retournements que le joueur ne pouvait pas prévoir
# d'après les chiffres montrés AVANT le coup, par cause (chaîne, terre, pouvoir…).
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/verif_duels.tscn -- [parties]
#
# Attendu : « RESULTAT: OK » et aucune ligne « SCRIPT ERROR ».

var parties := 1500
var n_flips := 0
var ancien_faux := []        # l'ancien affichage contredit le duel
var nouveau_faux := []       # le nouveau montre d'autres chiffres que ceux qui combattent
var surprises := {}          # cause → nombre
var exemples := {}           # cause → un exemple lisible


func _ready() -> void:
	GS.sauvegarde_active = false
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		parties = int(args[0])
	var h := MoteurCarre.Hasard.new(20260927)
	var ids := []
	for x in GS.HEROS:
		ids.append(str(x["id"]))
	var niveaux := ["apprenti", "aventurier", "maitre"]
	for p in parties:
		# ton deck : Bahamut (stade 1 à 3) et quatre héros au hasard ; en face, un niveau de l'Aventure
		var deck_j := [{"id": "bahamut", "s": 1 + p % 3, "v": "base"}]
		while deck_j.size() < 5:
			var id: String = ids[int(floor(h.suivant() * ids.size()))]
			if id != "bahamut":
				deck_j.append({"id": id, "s": 1 + int(floor(h.suivant() * 3)), "v": "base"})
		var adv := Aventure.niveau(1 + (p * 7) % Aventure.NB_NIVEAUX)
		var st := MoteurCarre.nouvelle_partie(deck_j, adv["deck"], h, 3)
		var camp := "j" if p % 2 == 0 else "a"
		while not MoteurCarre.plein(st) and not ((st["main"]["j"] as Array).is_empty() and (st["main"]["a"] as Array).is_empty()):
			if (st["main"][camp] as Array).is_empty():
				camp = MoteurCarre.autre(camp)
				continue
			var m: Array
			if h.suivant() < 0.3:
				var cs := MoteurCarre.coups(st, camp)
				m = cs[int(floor(h.suivant() * cs.size()))]
			else:
				m = MoteurCarre.coup_ia(st, h, camp, niveaux[int(floor(h.suivant() * 3))])
			var avant := MoteurCarre.cloner(st)
			var carte: Dictionary = st["main"][camp][m[0]]
			var trace := {}
			var ev := MoteurCarre.jouer_coup(st, camp, m, trace)
			_examiner(avant, st, trace, carte, int(m[1]), ev)
			camp = MoteurCarre.autre(camp)

	print("%d parties, %d retournements examinés" % [parties, n_flips])
	print("— l'ANCIEN affichage (la fin du coup) contredit le duel : %d fois (le témoin : doit être > 0)" % ancien_faux.size())
	for t in ancien_faux.slice(0, 4):
		print("    ", t)
	print("— le NOUVEL affichage (pas à pas) montre d'autres chiffres que ceux qui combattent : %d fois" % nouveau_faux.size())
	for t in nouveau_faux.slice(0, 8):
		print("    ", t)
	print("— pour information : les retournements imprévisibles d'après les chiffres montrés AVANT le coup, par cause")
	for cause in surprises.keys():
		print("    %-46s %5d   ex. %s" % [cause, surprises[cause], exemples[cause]])
	var ok := n_flips > 0 and not ancien_faux.is_empty() and nouveau_faux.is_empty()
	print("RESULTAT: %s" % ("OK" if ok else "ECHEC"))
	get_tree().quit(0 if ok else 1)


func _cote(n: int, de: int, vers: int) -> int:
	if vers == de - n:
		return 0
	if vers == de + 1:
		return 1
	if vers == de + n:
		return 2
	return 3


func _examiner(avant: Dictionary, apres: Dictionary, trace: Dictionary, carte: Dictionary, pose: int, ev: Array) -> void:
	var n: int = apres["n"]
	var vue: Dictionary = trace["pose"]        # ce que l'écran montre : la pose, puis chaque événement
	for j in ev.size():
		var e: Dictionary = ev[j]
		if str(e["t"]) == "flip" and not e["diag"]:
			n_flips += 1
			var de: int = e["de"]
			var vers: int = e["vers"]
			var s := _cote(n, de, vers)
			var o: int = MoteurCarre.OPP[s]
			var lisible := "%s %s (case %d, côté %d : %d) → %s (case %d : %d)" % [
				apres["cases"][de]["id"], "en chaîne" if e["chaine"] else "posé", de, s, e["a"], apres["cases"][vers]["id"], vers, e["b"]]
			var a_fin: int = MoteurCarre.valeurs(apres, de)[s]
			var b_fin: int = MoteurCarre.valeurs(apres, vers)[o]
			if a_fin <= b_fin:
				ancien_faux.append("%s — l'ancien écran montrait %d contre %d" % [lisible, a_fin, b_fin])
			var a_vu: int = MoteurCarre.valeurs(vue, de)[s]
			var b_vu: int = MoteurCarre.valeurs(vue, vers)[o]
			if a_vu != int(e["a"]) or b_vu != int(e["b"]):
				nouveau_faux.append("%s — l'écran montre %d contre %d" % [lisible, a_vu, b_vu])
			_surprise(avant, apres, carte, pose, e, s, o, lisible)
		if trace.has(j):
			vue = trace[j]


# Le joueur pouvait-il le prévoir avant le coup ? (sa carte en main, ou déjà posée pour une chaîne)
func _surprise(avant: Dictionary, apres: Dictionary, carte: Dictionary, pose: int, e: Dictionary, s: int, o: int, lisible: String) -> void:
	var de: int = e["de"]
	var vers: int = e["vers"]
	if avant["cases"][vers] == null or (de != pose and avant["cases"][de] == null):
		return        # Anubis a repris la carte qu'on vient de poser, et une chaîne la reprend
	var a_avant: int = MoteurCarre.chiffres_de(str(carte["id"]), int(carte["s"]))[s] if de == pose else MoteurCarre.valeurs(avant, de)[s]
	var b_avant: int = MoteurCarre.valeurs(avant, vers)[o]
	if a_avant > b_avant:
		return
	var att: Dictionary = apres["cases"][de]
	var causes := []
	if e["chaine"]:
		causes.append("chaîne (la carte prise attaque à son tour)")
	else:
		if att.get("terre", false):
			causes.append("terre (+1)")
		if str(att["id"]) in ["thor", "loki", "fenrir"]:
			causes.append("pouvoir de %s" % att["id"])
		if int(e["a"]) != a_avant and causes.is_empty():
			causes.append("Marée gagnée pendant le coup")
		if int(e["b"]) != b_avant:
			causes.append("la victime a perdu sa Marée pendant le coup")
	var cause := " + ".join(causes) if not causes.is_empty() else "AUCUNE CAUSE CONNUE"
	surprises[cause] = int(surprises.get(cause, 0)) + 1
	if not exemples.has(cause):
		exemples[cause] = "%s ; vu avant : %d contre %d" % [lisible, a_avant, b_avant]
