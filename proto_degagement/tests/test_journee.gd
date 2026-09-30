extends Node

# Le test de la journée (lot A de ⑧, 28/09) — sans écran.
#
#   1. Le plateau du jour : 12 objets connus d'avance (1 étoile, 3 pierres, 8 poussières), les pierres du
#      calendrier, le quota par rang (le refus au-delà ET le passage avant), minuit qui remet tout à neuf.
#   2. Les défis : 3 par jour, les mêmes pour un même jour, seulement ce que le joueur a ouvert (un nouveau
#      joueur : pas de duel), un de la Nébuleuse et un du Voyage ; ils ne changent plus dans la journée.
#   3. Les événements : ils font avancer le bon défi, sans dépasser ; le Duel ne fait pas avancer l'Aventure.
#   4. Recevoir : une fois ; le bonus des trois ; la semaine (5 jours, pas 4 ; une nouvelle semaine repart).
#   5. Les branchements : monter une carte, invoquer ; le cadeau du jour donne ses pièces ; plus de recharge.
#   6. La sauvegarde : l'aller-retour JSON ; une sauvegarde abîmée ne plante pas.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_journee.tscn
#
# Attendu : « RESULTAT: OK » et aucune ligne « SCRIPT ERROR ».

var erreurs := 0
var verifs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	_plateau()
	_choix()
	_evenements()
	_recevoir()
	_branchements()
	_sauvegarde()
	Plateau.date_test = ""
	Presages.date_test = ""
	print("%d vérifications" % verifs)
	print("RESULTAT: %s" % ("OK" if erreurs == 0 and verifs > 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	if not vrai:
		erreurs += 1
		if erreurs <= 30:
			print("  ✗ " + quoi)


func _jour(j: String) -> void:
	Plateau.date_test = j
	Presages.date_test = j


func _nouveau_joueur() -> void:
	GS.voyage = {}
	GS.cartes = {}
	GS.poussiere = 0
	GS.etoiles = 0
	GS.pierres = {}
	GS.main_pieces = 30


func _joueur_avance() -> void:
	GS.voyage = {"tuto_carre": true, "aventure": {"etoiles": {"10": 1}, "coffres": {}}}
	GS.cartes = {"thor": {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1}}
	GS.poussiere = 5000
	GS.etoiles = 5
	GS.pierres = {}
	GS.main_pieces = 30


# ─────────────────────────────────────────────────────────────

func _plateau() -> void:
	_nouveau_joueur()
	_jour("2026-09-28")
	_ok("12 objets", Plateau.total() == 12 and Plateau.restants() == 12)
	var l := Plateau.liste()
	_ok("la liste : l'étoile, 3 pierres, 8 poussières", l.size() == 12 and l[0]["image"] == "etoile-invocation"
		and str(l[1]["image"]).begins_with("pierre-") and l[4]["image"] == "poussiere-etoile" and l[11]["image"] == "poussiere-etoile")
	_ok("même jour, mêmes pierres", Plateau.pierres_du_jour("2026-09-28") == Plateau.pierres_du_jour("2026-09-28"))
	var differents := 0
	for j in 20:
		if Plateau.pierres_du_jour("2026-10-%02d" % (j + 1)) != Plateau.pierres_du_jour("2026-09-28"):
			differents += 1
	_ok("d'autres jours, d'autres pierres (%d sur 20)" % differents, differents >= 15)
	_ok("rang 0 : la poussière ; rang 1 : l'étoile ; rang 2 : la 1re pierre du jour",
		Plateau.prochain(0) == "poussiere" and Plateau.prochain(1) == "etoile"
		and Plateau.prochain(2) == "pierre-" + str(Plateau.pierres_du_jour("2026-09-28")[0]))
	Plateau.gagner("etoile")
	_ok("l'étoile gagnée : plus d'étoile aujourd'hui (le refus)", Plateau.prochain(1) == "" and Plateau.restant(1) == 0)
	_ok("… mais toujours de la poussière et des pierres (le passage)", Plateau.prochain(0) == "poussiere" and Plateau.restant(2) == 3)
	Plateau.gagner("pierre-feu")
	_ok("une pierre gagnée : la suivante est la 2e du jour", Plateau.prochain(2) == "pierre-" + str(Plateau.pierres_du_jour("2026-09-28")[1]))
	for k in 20:
		Plateau.gagner("poussiere")
	_ok("pas plus de 8 poussières comptées", Plateau.restant(0) == 0 and int(Plateau.donnees()["poussiere"]) == 8)
	Plateau.gagner("pierre-eau")
	Plateau.gagner("pierre-eau")
	Plateau.gagner("pierre-eau")
	_ok("tout gagné : 0, plus rien à poser", Plateau.restants() == 0 and Plateau.prochain(0) == "" and Plateau.prochain(2) == "")
	var l2 := Plateau.liste()
	var eteints := 0
	for e in l2:
		if bool(e["gagne"]):
			eteints += 1
	_ok("la liste : les 12 éteints", eteints == 12)
	# (29/09) TOUT le plateau posé : le ticket au fond, la moitié des pierres au hasard, les poussières (l'XP) devant
	_jour("2026-10-03")
	var ap := Plateau.a_poser()
	var places := {}
	for e in ap:
		places[str(e["place"])] = int(places.get(str(e["place"]), 0)) + 1
	_ok("à poser : 12, dont 1 ticket au fond, 8 poussières devant, les 3 pierres (1 ou 2 au hasard) : %s" % str(places),
		ap.size() == 12 and int(places.get("fond", 0)) == 1 and int(places.get("xp", 0)) == 8
		and int(places.get("hasard", 0)) + int(places.get("pierre", 0)) == 3 and int(places.get("hasard", 0)) in [1, 2])
	_ok("le même jour, les mêmes places", Plateau.pierres_au_hasard("2026-10-03") == Plateau.pierres_au_hasard("2026-10-03"))
	var ps3 := Plateau.pierres_du_jour("2026-10-03")
	Plateau.gagner("pierre-" + str(ps3[2]))                 # la 3ᵉ pierre du jour tombe la première
	var l3 := Plateau.liste()
	_ok("une pierre gagnée hors de l'ordre s'éteint, elle (par son nom)", bool(l3[3]["gagne"]) and not bool(l3[1]["gagne"])
		or str(ps3[2]) == str(ps3[0]))
	var reste_p := 0
	for e in Plateau.a_poser():
		if str(e["k"]).begins_with("pierre-"):
			reste_p += 1
	_ok("il reste 2 pierres à poser", reste_p == 2)
	_jour("2026-09-29")
	_ok("minuit : un plateau neuf", Plateau.restants() == 12 and Plateau.prochain(1) == "etoile")
	GS.voyage["plateau"] = "abîmé"
	_ok("abîmé : un plateau neuf, sans planter", Plateau.restants() == 12)
	GS.voyage["plateau"] = {"date": "2026-09-29", "poussiere": 99, "etoile": -3, "pierre": "x"}
	_ok("hors bornes : ramené (8 gagnées, 0, 0)", Plateau.restant(0) == 0 and Plateau.restant(1) == 1 and Plateau.restant(2) == 3)


func _choix() -> void:
	_nouveau_joueur()
	_jour("2026-09-28")
	var d := Presages.donnees()
	var ids := []
	for e in d["defis"]:
		ids.append(e["id"])
	_ok("un nouveau joueur : 3 défis (%s)" % str(ids), ids.size() == 3)
	for id in ids:
		_ok("… rien du Voyage avant le premier combat (%s)" % id, Presages.DEFIS[id]["groupe"] != "voyage")
	_ok("… et un de la Nébuleuse", Presages.DEFIS[ids[0]]["groupe"] == "nebuleuse")
	# un joueur qui a tout ouvert, sur 60 jours
	_joueur_avance()
	var vus := {}
	for j in 60:
		var jour := Time.get_date_string_from_unix_time(1790000000 + j * 86400)
		var c := Presages.choisir(jour)
		_ok("3 défis différents (%s)" % jour, c.size() == 3 and c[0] != c[1] and c[1] != c[2] and c[0] != c[2])
		_ok("un de la Nébuleuse, un du Voyage (%s : %s)" % [jour, str(c)], Presages.DEFIS[c[0]]["groupe"] == "nebuleuse"
			and Presages.DEFIS[c[1]]["groupe"] == "voyage")
		_ok("le même jour, le même tirage", c == Presages.choisir(jour))
		for id in c:
			vus[id] = true
	_ok("en 60 jours, presque tous les défis sortent (%d sur %d)" % [vus.size(), Presages.DEFIS.size()], vus.size() >= Presages.DEFIS.size() - 1)
	# ils ne changent plus dans la journée, même si le joueur ouvre de nouvelles choses
	_nouveau_joueur()
	_jour("2026-09-30")
	var avant := str(Presages.donnees()["defis"])
	GS.voyage["tuto_carre"] = true
	_ok("fixés pour la journée", str(Presages.donnees()["defis"]) == avant)
	_jour("2026-10-01")
	_ok("le lendemain : de nouveaux défis, qui voient ce qui est ouvert", str(Presages.donnees()["defis"]) != avant)
	_ok("la semaine : le lundi (dimanche 27/09 → lundi 21/09 ; lundi 28/09 → lui-même)",
		Presages.semaine_de("2026-09-27") == "2026-09-21" and Presages.semaine_de("2026-09-28") == "2026-09-28"
		and Presages.semaine_de("2026-10-04") == "2026-09-28")


# Force les 3 défis d'un jour (pour tester les événements sans dépendre du tirage).
func _forcer(ids: Array) -> void:
	var d := Presages.donnees()
	var l := []
	for id in ids:
		l.append({"id": id, "fait": 0, "recu": false})
	d["defis"] = l
	d["bonus"] = false


func _evenements() -> void:
	_joueur_avance()
	_jour("2026-09-28")
	_forcer(["objets", "duels", "aventure"])
	Presages.evenement("objet", 4)
	Presages.evenement("duel")
	var d := Presages.donnees()
	_ok("4 objets sur 6, 1 duel sur 2, rien à l'Aventure", d["defis"][0]["fait"] == 4 and d["defis"][1]["fait"] == 1 and d["defis"][2]["fait"] == 0)
	_ok("le Duel ne fait pas avancer l'Aventure ni les classés", d["defis"][2]["fait"] == 0)
	Presages.evenement("objet", 10)
	_ok("pas au-delà du but (6)", Presages.donnees()["defis"][0]["fait"] == 6)
	Presages.evenement("objet", 0)
	Presages.evenement("inconnu", 3)
	_ok("0, ou un événement inconnu : rien", Presages.donnees()["defis"][0]["fait"] == 6)
	_ok("pas encore les trois", not Presages.tous_finis() and (Presages.donnees()["semaine"]["jours"] as Array).is_empty())
	Presages.evenement("duel")
	Presages.evenement("aventure")
	_ok("les trois faits : la journée compte pour la semaine", Presages.tous_finis() and Presages.donnees()["semaine"]["jours"] == ["2026-09-28"])
	Presages.evenement("aventure")
	_ok("… une seule fois", (Presages.donnees()["semaine"]["jours"] as Array).size() == 1)
	_ok("3 choses à recevoir (les défis ; le bonus attend qu'ils soient reçus)", Presages.a_recevoir() == 3)


func _recevoir() -> void:
	_joueur_avance()
	_jour("2026-09-28")
	_forcer(["pieces", "combats", "invoque"])
	var p0 := GS.main_pieces
	_ok("pas fini : rien à recevoir", Presages.recevoir(0).is_empty() and GS.main_pieces == p0)
	Presages.evenement("piece", 80)
	var g := Presages.recevoir(0)
	_ok("fini : +%d pièces" % Presages.PIECES_DEFI, g.get("pieces", 0) == Presages.PIECES_DEFI and GS.main_pieces == p0 + Presages.PIECES_DEFI)
	_ok("une seule fois", Presages.recevoir(0).is_empty() and GS.main_pieces == p0 + Presages.PIECES_DEFI)
	_ok("un défi qui n'existe pas : rien", Presages.recevoir(7).is_empty() and Presages.recevoir("n'importe quoi").is_empty())
	Presages.evenement("combat", 3)
	Presages.evenement("invocation")
	_ok("le bonus attend les trois REÇUS", not Presages.bonus_pret() and Presages.recevoir("bonus").is_empty())
	Presages.recevoir(1)
	Presages.recevoir(2)
	var lune0 := GS.nb_pierres("lune")
	_ok("les trois reçus : le bonus, une pierre de lune", Presages.bonus_pret() and Presages.recevoir("bonus").get("pierre", "") == "lune"
		and GS.nb_pierres("lune") == lune0 + 1)
	_ok("le bonus, une seule fois", Presages.recevoir("bonus").is_empty() and GS.nb_pierres("lune") == lune0 + 1)
	_ok("plus rien à recevoir aujourd'hui", Presages.a_recevoir() == 0)
	# la semaine : 5 jours (4 ne suffisent pas)
	for j in ["2026-09-29", "2026-09-30", "2026-10-01"]:
		_jour(j)
		_forcer(["pieces", "objets", "plateau"])
		Presages.evenement("piece", 80)
		Presages.evenement("objet", 6)
		Presages.evenement("plateau_vide")
	_ok("4 jours : pas encore", not Presages.semaine_prete() and Presages.recevoir("semaine").is_empty())
	_jour("2026-10-02")
	_forcer(["pieces", "objets", "plateau"])
	Presages.evenement("piece", 80)
	Presages.evenement("objet", 6)
	Presages.evenement("plateau_vide")
	var e0 := GS.etoiles
	var p1 := GS.main_pieces
	_ok("5 jours : la semaine est prête", Presages.semaine_prete())
	var gs := Presages.recevoir("semaine")
	_ok("+3 étoiles et +%d pièces" % Presages.PIECES_SEMAINE, gs.get("etoiles", 0) == 3 and GS.etoiles == e0 + 3
		and GS.main_pieces == p1 + Presages.PIECES_SEMAINE)
	_ok("une seule fois", Presages.recevoir("semaine").is_empty() and GS.etoiles == e0 + 3)
	_jour("2026-10-05")
	_ok("lundi : une nouvelle semaine, vide", (Presages.donnees()["semaine"]["jours"] as Array).is_empty() and not bool(Presages.donnees()["semaine"]["recu"]))


func _branchements() -> void:
	_joueur_avance()
	_jour("2026-09-28")
	_forcer(["niveau", "invoque", "objets"])
	GS.monter_niveau("thor")
	_ok("monter une carte : le défi « niveau »", Presages.donnees()["defis"][0]["fait"] == 1)
	GS.invoquer_multi(2)
	_ok("invoquer : le défi « invocation »", Presages.donnees()["defis"][1]["fait"] == 1)
	GS.last_daily = ""
	var p0 := GS.main_pieces
	GS.claim_daily()
	_ok("le cadeau du jour : +%d pièces" % GS.PIECES_CADEAU, GS.main_pieces == p0 + GS.PIECES_CADEAU)
	var src: String = (load("res://pusher_screen.gd") as GDScript).source_code
	_ok("plus de recharge des pièces dans la Nébuleuse", not src.contains("REGEN_S") and not src.contains("MAIN_MAX"))


func _sauvegarde() -> void:
	_joueur_avance()
	_jour("2026-09-28")
	Plateau.gagner("etoile")
	Plateau.gagner("poussiere")
	_forcer(["objets", "duels", "aventure"])
	Presages.evenement("objet", 2)
	var texte := JSON.stringify(GS.donnees_sauvegarde())
	GS.voyage = {}
	GS.lire_sauvegarde(JSON.parse_string(texte), false)
	_ok("aller-retour : le plateau", Plateau.restant(1) == 0 and Plateau.restant(0) == 7)
	_ok("aller-retour : les défis (entiers, pas des flottants)", Presages.donnees()["defis"][0]["fait"] == 2
		and typeof(Presages.donnees()["defis"][0]["fait"]) == TYPE_INT)
	GS.voyage = {"presages": {"date": "2026-09-28", "defis": [{"id": "inconnu"}, 3, {"id": "duels", "fait": "x"}], "semaine": 5}}
	var d := Presages.donnees()
	_ok("abîmée : on garde ce qui se lit (le défi « duels », à 0)", (d["defis"] as Array).size() == 1 and d["defis"][0]["id"] == "duels"
		and d["defis"][0]["fait"] == 0)
	_ok("abîmée : une semaine neuve", (d["semaine"]["jours"] as Array).is_empty())
	GS.voyage = {"presages": "abîmé"}
	_ok("tout abîmé : 3 défis neufs", (Presages.donnees()["defis"] as Array).size() == 3)
