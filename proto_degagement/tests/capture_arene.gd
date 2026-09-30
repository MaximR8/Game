extends Node

# Photographie le Duel et le Classé dans le vrai jeu (étape 3 du Carré, 28/09), en jouant pour de vrai :
#   1. le Voyage avec ses onglets, le Duel et le Classé scellés (la bulle dit qui battre) ;
#   2. le Duel ouvert (le Chevalier sans tête battu), vide ; un duel joué jusqu'au bout, son panneau
#      de fin (la cote, la poussière du jour) ; le Duel avec son historique ;
#   3. le Classé en Aurore I à 80 points ; un classé joué jusqu'au bout (la marche passée, si gagné) ;
#   4. « Quitter » en plein classé : deux touches, puis −20 ;
#   2 bis. une victoire parfaite au Duel : la constellation d'or, « Parfait » (28/09) ;
#   5. la saison finie : le panneau, la récompense donnée une fois.
# Vérifie en chemin ce que le joueur ne voit pas : le combat écrit « en cours », puis effacé.
# Lancé en fenêtre (--headless ne dessine rien). Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_arene.tscn -- <dossier>
#
# Ne sauvegarde rien : la sauvegarde est coupée pendant la séance.

var main: Node
var dossier := ""
var n_capture := 0
var _echecs := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	# une partie qui a fait le tuto et a de quoi composer un deck, sans cadeau du jour en attente
	GS.cartes = {}
	for id in ["thor", "kitsune", "golem", "korrigan", "kelpie", "banshee", "wukong", "minotaure", "troll", "yeti"]:
		GS.cartes[id] = {"stade": 2, "variante": "or" if id == "kitsune" else "base", "variantes": ["base"], "niveau": 1}
	for id in ["chinchin", "hommefeuilles", "follet"]:
		GS.cartes[id] = {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1}
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.etoiles = 4
	GS.poussiere = 320
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _scenario() -> void:
	await _attendre(1.2)
	main.barre._toucher("voyage")
	await _attendre(1.2)
	_capture("voyage_onglets_scelles")
	var v: VoyageEcran = main.ecran_voyage
	(v._boutons_onglets["duel"] as Button).pressed.emit()
	await _attendre(0.4)
	_capture("duel_scelle_bulle")
	_verifier("scellé : on reste sur l'Aventure", v._vue == "hub")

	# ── 2. le Duel
	Aventure._donnees()["etoiles"]["10"] = 1
	(v._boutons_onglets["duel"] as Button).pressed.emit()
	await _attendre(1.0)
	_verifier("ouvert : le Duel", v._vue == "duel")
	_capture("duel_vide")
	var cote0 := Duel.cote()
	var pous0 := GS.poussiere
	v._duel.combattre.emit(Arene.adversaire_suivant("duel"))
	await _attendre(1.5)
	_verifier("un combat commence, écrit « en cours »", main.combat != null and Arene.en_cours())
	_capture("duel_combat")
	# la lisibilité (29/09) : la carte sous le doigt grandit à la taille du plateau ; la main adverse descend en grand
	var cb: CarreEcran = main.combat
	var p2: Vector2 = cb._rect_main(2).get_center()
	cb._appui(p2)
	await _attendre(0.4)
	_verifier("le doigt posé : la carte grandit à la taille du plateau", is_equal_approx((cb._main_j[2] as CarteCarre).scale.x, CarreEcran.LOUPE))
	_capture("duel_loupe")
	cb._relache(p2)
	await _attendre(0.4)
	_verifier("lâchée sans glisser : elle devient la choisie, et reste grande", cb.choisie == 2
		and is_equal_approx((cb._main_j[2] as CarteCarre).scale.x, CarreEcran.LOUPE))
	# la voisine, touchée là où l'agrandie déborde : c'est la voisine qu'on prend
	var p3: Vector2 = cb._rect_main(3).get_center()
	_verifier("un doigt sur la voisine prend la voisine", cb._carte_main_sous(Vector2(cb._rect_main(3).position.x + 12.0, p3.y)) == 3)
	cb._relache(p2)            # un second toucher la repose
	await _attendre(0.4)
	_verifier("retouchée : elle reprend sa place", cb.choisie == -1 and is_equal_approx((cb._main_j[2] as CarteCarre).scale.x, CarreEcran.MAIN_ECHELLE))
	var pa: Vector2 = (cb._main_a[0] as CarteCarre).get_global_rect().get_center()
	cb._appui(pa)
	cb._relache(pa)
	await _attendre(0.5)
	_verifier("sa main, touchée : elle descend en grand", cb._adv_grande
		and is_equal_approx((cb._main_a[0] as CarteCarre).scale.x, CarreEcran.MAIN_ADV_GRANDE))
	_capture("duel_main_adverse")
	cb._appui(Vector2(540, 1500))
	cb._relache(Vector2(540, 1500))
	await _attendre(0.5)
	_verifier("touché ailleurs : elle remonte", not cb._adv_grande)
	await _jouer_jusqu_au_bout()
	await _attendre(3.2)
	_capture("duel_fin")
	var h: Array = Duel.donnees()["historique"]
	_verifier("fini : plus en cours, la cote a bougé, l'historique le garde", not Arene.en_cours() and Duel.cote() != cote0 and h.size() == 1)
	var gagne := int(h[0]["res"]) > 0
	_verifier("la poussière du jour : %s" % ("+30" if gagne else "rien (perdu)"), GS.poussiere == pous0 + (30 if gagne else 0))
	main.combat.fini.emit({"retour": "duel"})
	await _attendre(1.2)
	_capture("duel_historique")

	# ── 2 bis. la victoire parfaite (28/09 : elle n'était animée que dans l'Aventure) — les cartes d'en face
	#    passent à toi avant chacun de tes coups ; tu commences, donc ton dernier coup ferme le Carré, les 9 à toi
	var adv_p := Arene.adversaire_suivant("duel")
	adv_p["premier"] = "j"
	v._duel.combattre.emit(adv_p)
	await _attendre(1.5)
	await _jouer_jusqu_au_bout(true)
	_verifier("parfait : les 9 cartes à toi", Aventure.defi_reussi("parfait", main.combat.adversaire, main.combat.journal, main.combat.st))
	await _attendre(0.9)
	_capture("duel_parfait_constellation")
	await _attendre(2.6)
	_capture("duel_parfait_fin")
	main.combat.fini.emit({"retour": "duel"})
	await _attendre(1.2)

	# ── 3. le Classé
	Classe.verifier_saison()
	var c := Classe.donnees()
	c["palier"] = 8
	c["meilleur"] = 8
	c["points"] = 80
	c["joues"] = 6
	(v._boutons_onglets["classe"] as Button).pressed.emit()
	await _attendre(1.0)
	_capture("classe")
	v._classe.combattre.emit(Arene.adversaire_suivant("classe"))
	await _attendre(1.5)
	_capture("classe_combat")
	await _jouer_jusqu_au_bout()
	await _attendre(1.6)
	_capture("classe_fin_debut")
	await _attendre(1.6)
	_capture("classe_fin")
	_verifier("le Classé a compté le combat", int(Classe.donnees()["joues"]) == 7)

	# ── 4. « Quitter » en plein classé
	main.combat.fini.emit({"encore": "classe"})
	await _attendre(1.6)
	var pts := int(Classe.donnees()["points"])
	var pal := int(Classe.donnees()["palier"])
	var quitter: Button = null
	for b in main.combat.get_children():
		if b is Button and (b as Button).text == "Quitter":
			quitter = b
	_verifier("le bouton Quitter est là", quitter != null)
	quitter.pressed.emit()
	await _attendre(0.3)
	_capture("classe_quitter_sur")
	_verifier("une touche : on reste", main.combat != null and quitter.text == "Sûr ?")
	quitter.pressed.emit()
	await _attendre(1.2)
	var c2 := Classe.donnees()
	_verifier("deux touches : une défaite (%d/%d → %d/%d)" % [pal, pts, int(c2["palier"]), int(c2["points"])],
		main.combat == null and bool(c2["historique"][0]["interrompu"]) and int(c2["joues"]) == 8)

	# ── 5. la saison finie
	var e0 := GS.etoiles
	# ce que vaut le meilleur rang atteint : le classé joué plus haut est gagné ou perdu (adversaire tiré au sort)
	var attendu: int = int(Classe.recompense(Classe.rang_de(int(Classe.donnees()["meilleur"])))["etoiles"])
	var nom_rang := Classe.nom_rang(int(Classe.donnees()["meilleur"]))
	c2["saison"] = "2026-08" if Classe.saison_actuelle() != "2026-08" else "2026-07"
	(v._boutons_onglets["duel"] as Button).pressed.emit()
	await _attendre(0.6)
	(v._boutons_onglets["classe"] as Button).pressed.emit()
	await _attendre(1.2)
	_capture("saison_finie")
	_verifier("la récompense est donnée (%s : %d étoiles)" % [nom_rang, attendu], attendu > 0 and GS.etoiles == e0 + attendu)
	var bouton: Button = null
	for n in v._classe.find_children("*", "Button", true, false):
		if (n as Button).text == "Recevoir":
			bouton = n
	_verifier("« Recevoir »", bouton != null)
	bouton.pressed.emit()
	await _attendre(1.6)
	_capture("saison_nouvelle")
	_verifier("pas deux fois", GS.etoiles == e0 + attendu and (Classe.donnees()["fin"] as Dictionary).is_empty())
	print("RESULTAT: %s" % ("OK" if _echecs == 0 else "ÉCHEC (%d)" % _echecs))
	get_tree().quit(0 if _echecs == 0 else 1)


# Joue le combat en cours jusqu'au bout, comme un joueur (le Maître joue pour lui).
func _jouer_jusqu_au_bout(tout_a_moi := false) -> void:
	var c: CarreEcran = main.combat
	var h := MoteurCarre.Hasard.new(11)
	var limite := Time.get_ticks_msec() + 90000
	while is_instance_valid(c) and not c.termine and Time.get_ticks_msec() < limite:
		if c.tour == "j" and not c.occupe:
			if tout_a_moi:
				for i in (c.st["cases"] as Array).size():
					if c.st["cases"][i] != null:
						c.st["cases"][i]["camp"] = "j"
						(c._cases[i]["carte"] as CarteCarre).mettre_camp("j")
			var m := MoteurCarre.coup_ia(c.st, h, "j", "maitre")
			c._jouer(m[0], m[1])
		await get_tree().process_frame
	_verifier("le combat va au bout", is_instance_valid(c) and c.termine)


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _capture(nom: String) -> void:
	n_capture += 1
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("arene_%02d_%s.png" % [n_capture, nom]))
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _verifier(quoi: String, ok: bool) -> void:
	print("%s : %s" % [quoi, "OK" if ok else "ÉCHEC"])
	if not ok:
		_echecs += 1
