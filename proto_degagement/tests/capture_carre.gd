extends Node

# Photographie le Carré des astres dans le vrai jeu (rendu GPU réel) : le Voyage et l'Aventure (une
# progression d'exemple : la 1ʳᵉ terre gagnée, un coffre prêt, qu'on ouvre), une terre, l'écran
# d'avant le combat, puis un niveau entier — la carte glissée, la pose, le duel, le retournement,
# la fin avec ses ★ et ses gains qui s'envolent —, la victoire parfaite, et le retour à la terre.
# Lancé en fenêtre (--headless ne dessine rien). Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_carre.tscn -- <dossier> [niveau 11-100] [graine] [tuto]
#
# Avec « tuto » : le tout premier combat, guidé, étape par étape.
#
# Ne sauvegarde rien : la sauvegarde est coupée pendant la séance.

var main: Node
var dossier := ""
var niveau := 14
var graine := 7
var n_capture := 0
var mode_tuto := false
var _echecs := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	if args.size() > 1:
		niveau = int(args[1])
	if args.size() > 2:
		graine = int(args[2])
	mode_tuto = args.size() > 3 and args[3] == "tuto"
	GS.sauvegarde_active = false
	# rendre le jeu à sa taille de base (1080 × 2400), quelle que soit la fenêtre (bridée par l'écran)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.cartes = {
		"kitsune": {"stade": 2, "niveau": 6, "variante": "prisme", "variantes": ["base", "prisme"]},
		"bahamut": {"stade": 2, "niveau": 6, "variante": "elem", "variantes": ["base", "elem"]},
		"thor": {"stade": 2, "niveau": 6, "variante": "full", "variantes": ["base", "full"]},
		"golem": {"stade": 1, "niveau": 2, "variante": "or", "variantes": ["or"]},
		"banshee": {"stade": 1, "niveau": 1, "variante": "base", "variantes": ["base"]},
		"doudou": {"stade": 1, "niveau": 1, "variante": "ombre", "variantes": ["ombre"]},
	}
	# une progression d'exemple : la 1ʳᵉ terre gagnée (26 ★, le coffre de 10 ouvert, celui de 20 prêt),
	# puis la 2ᵉ jusqu'au niveau d'avant celui qu'on joue
	var etoiles := {}
	var masques := [7, 7, 3, 7, 5, 7, 3, 7, 7, 3]
	for k in niveau - 1:
		etoiles[str(k + 1)] = masques[k % masques.size()]
	GS.voyage = {} if mode_tuto else {"tuto_carre": true, "aventure": {"etoiles": etoiles, "coffres": {"1": [10]}}}
	main = load("res://main.tscn").instantiate()
	add_child(main)
	if mode_tuto:
		_scenario_tuto()
	else:
		_scenario()


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout   # le temps du jeu : ralenti avec lui si la capture rame


func _capture(nom: String) -> void:
	n_capture += 1
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("carre_%02d_%s.png" % [n_capture, nom]))
	print("capture %s : %s (%d images/s)" % [nom, "ok" if err == OK else "erreur %d" % err, Engine.get_frames_per_second()])


func _scenario() -> void:
	await _attendre(0.3)
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()
	main._aller_vers("voyage")
	var ve: VoyageEcran = main.ecran_voyage
	ve.ouvrir_hub()
	await _attendre(1.0)
	_capture("voyage")
	ve.ouvrir_terre(1)
	await _attendre(0.8)
	_capture("terre_1")
	var etoiles_avant := GS.etoiles
	ve._chapitre._toucher_coffre(ve._chapitre._coffres[1])
	await _attendre(0.55)
	_capture("coffre")
	await _attendre(1.4)
	_verifier("le coffre de 20 ★ donne une étoile d'invocation, une fois", GS.etoiles == etoiles_avant + 1 and Aventure.coffre_ouvert(1, 20))
	ve.ouvrir_terre(Aventure.terre_de(niveau))
	await _attendre(0.8)
	_capture("terre")
	ve.ouvrir_avant(niveau)
	await _attendre(0.8)
	_capture("avant")

	# Mes decks : la liste, l'éditeur, une carte réglée ; puis une carte retirée, remise d'un VRAI toucher
	# dans la collection qui défile (le chemin du téléphone : ScrollContainer, puis la case)
	ve._avant.decks.emit()
	await _attendre(0.6)
	_capture("decks")
	var ed: DecksEcran = ve._decks
	ed.montrer_editeur(0)
	await _attendre(1.2)       # la collection se construit quelques cartes par image
	_capture("editeur")
	ed._choisie = 0
	ed._maj_deck()
	await _attendre(0.4)
	_capture("reglage")
	var retiree := str(ed._cartes[0]["id"])
	ed._cartes.remove_at(0)
	ed._choisie = -1
	ed._enregistrer()
	await _attendre(0.3)
	_verifier("retirée : le deck a 4 cartes, et « Combattre » s'éteindra", (Decks.liste()[0] as Array).size() == 4 and Decks.pourquoi(Decks.deck_actif()) != "")
	var cel: Control = ed._cases[retiree]["cellule"]
	var ou := cel.get_global_rect().get_center()
	_doigt(ou, true)
	await get_tree().process_frame
	_doigt(ou, false)
	await _attendre(0.4)
	var remise := false
	for cc in Decks.liste()[0]:
		remise = remise or cc["id"] == retiree
	_verifier("un toucher dans la collection remet la carte dans le deck", remise and (Decks.liste()[0] as Array).size() == 5)
	_capture("remise")
	ed.retour.emit()
	await _attendre(0.6)

	seed(graine)
	ve._avant.combattre.emit(niveau)
	var c: CarreEcran = main.combat
	_verifier("« Combattre » lance le niveau %d" % niveau, c != null and int(c.adversaire.get("n", 0)) == niveau)
	var ids_deck := []
	for cc in Decks.deck_actif():
		ids_deck.append(cc["id"])
	var ids_main := []
	for cc in c.st["main"]["j"]:
		ids_main.append(cc["id"])
	ids_deck.sort()
	ids_main.sort()
	_verifier("c'est le deck choisi qui combat", ids_deck == ids_main)
	_verifier("au combat, le temps suit la vraie horloge (8 pas de physique permis)", Engine.max_physics_steps_per_frame == main.PAS_AILLEURS)
	await _attendre(1.2)
	_capture("debut")

	var photos := 0
	while not c.termine:
		if c.tour != "j" or c.occupe:
			await _attendre(0.1)
			continue
		# mon coup : celui que choisirait le Maître ; on regarde d'abord s'il retourne quelque chose
		var m := MoteurCarre.coup_ia(c.st, MoteurCarre.Hasard.new(graine + photos), "j", "maitre")
		var essai := MoteurCarre.cloner(c.st)
		var ev := MoteurCarre.jouer_coup(essai, "j", m)
		var retourne := false
		for e in ev:
			if str(e["t"]) == "flip":
				retourne = true
		c.choisie = m[0]
		c._ranger_mains()
		c._maj_cibles()
		c._fiche(c.st["main"]["j"][m[0]])
		await _attendre(0.5)
		if photos == 0:
			_capture("choix")
			# le premier coup se joue au doigt : la carte glisse de la main à sa case
			c.choisie = -1
			c._ranger_mains()
			await _attendre(0.3)
			var avant: int = c._main_j.size()
			await _glisser((c._main_j[m[0]] as CarteCarre).get_global_rect().get_center(), Rect2(c._cases[m[1]]["pos"], CarreEcran.CASE).get_center() + Vector2(70, -90), "glisse")
			_verifier("glisser sur une case la pose", c._main_j.size() == avant - 1 and c.st["cases"][m[1]] != null)
		else:
			c._jouer(m[0], m[1])
		if retourne and photos < 2:
			await _attendre(0.42)
			_capture("pose")
			await _attendre(0.30)
			_capture("duel")
			await _attendre(0.27)
			_capture("retournement")
			await _attendre(0.5)
			_capture("apres")
		photos += 1
		await _attendre(0.2)
	await _attendre(1.9)
	_capture("fin_etoiles")
	await _attendre(1.6)
	_capture("fin")
	var gagne := MoteurCarre.compte(c.st, "j") > MoteurCarre.compte(c.st, "a")
	_verifier("les ★ du combat sont enregistrées", Aventure.masque(niveau) == Aventure.etoiles(c.adversaire, c.journal, c.st))
	_verifier("gagné : le niveau suivant s'ouvre", not gagne or Aventure.niveau_ouvert(niveau + 1))
	# la victoire parfaite, pour la voir : toutes les cartes passent à toi, et la constellation d'or les relie
	for i in (c._cases as Array).size():
		var cc = c._cases[i]["carte"]
		if cc != null:
			(cc as CarteCarre).mettre_camp("j")
	c._constellation_parfaite()
	await _attendre(0.45)      # ⚠️ les effets comptent en temps réel : hors écran, le temps du jeu peut aller 2× moins vite
	_capture("parfait")
	# « La terre » : retour à la constellation, l'étoile du niveau allumée
	c.fini.emit({"terre": Aventure.terre_de(niveau)})
	await _attendre(0.9)
	_capture("retour_terre")
	_verifier("retour à la terre du niveau", main.combat == null and ve._vue == "terre" and ve._chapitre.terre == Aventure.terre_de(niveau))
	_verifier("dans le Voyage, le temps suit la vraie horloge", Engine.max_physics_steps_per_frame == main.PAS_AILLEURS)
	main._aller_vers("nebuleuse")
	_verifier("dans la Nébuleuse, un seul pas de physique par image (la machine reste stable)", Engine.max_physics_steps_per_frame == main.PAS_NEBULEUSE)
	main._aller_vers("atlas")
	_verifier("dans l'Atlas, de nouveau la vraie horloge", Engine.max_physics_steps_per_frame == main.PAS_AILLEURS)
	_quitter()


# Un vrai glisser, par les événements du doigt (le chemin que prend le téléphone, pas un appel
# direct) : l'appui sur la carte, le glissement par petits pas, la photo au-dessus de la case, le lâcher.
func _glisser(de: Vector2, vers: Vector2, nom_capture := "") -> void:
	_doigt(de, true)
	for s in 12:
		await get_tree().process_frame
		var m := InputEventMouseMotion.new()
		m.position = de.lerp(vers, (s + 1) / 12.0)
		m.global_position = m.position
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		get_viewport().push_input(m, true)
	await _attendre(0.35)
	if nom_capture != "":
		_capture(nom_capture)
	_doigt(vers, false)


func _doigt(p: Vector2, appui: bool) -> void:
	var b := InputEventMouseButton.new()
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = appui
	b.position = p
	b.global_position = p
	b.button_mask = MOUSE_BUTTON_MASK_LEFT if appui else 0
	get_viewport().push_input(b, true)


func _verifier(quoi: String, ok: bool) -> void:
	print("%s : %s" % [quoi, "OK" if ok else "ÉCHEC"])
	if not ok:
		_echecs += 1


func _quitter() -> void:
	print("RESULTAT: %s" % ("OK" if _echecs == 0 else "ÉCHEC (%d)" % _echecs))
	get_tree().quit(0 if _echecs == 0 else 1)


# Le premier combat, guidé : on touche ce que le guide montre, comme un joueur.
func _scenario_tuto() -> void:
	await _attendre(0.3)
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()
	main._aller_vers("voyage")
	await _attendre(0.6)
	seed(graine)
	main._lancer_combat(VoyageEcran.deck_auto(), Aventure.niveau(1))
	var c: CarreEcran = main.combat
	await _attendre(1.3)
	_capture("tuto_carte")
	# lâchée à côté (sur la bande) : elle revient dans la main, et le guide sur elle
	var golem := (c._main_j[0] as CarteCarre).get_global_rect().get_center()
	await _glisser(golem, Vector2(540, 1770))
	await _attendre(0.6)
	_capture("tuto_rate")
	_verifier("lâchée à côté, la carte revient et le guide la remontre", c._main_j.size() == 5 and c._permis["case"] == -1 and c._permis["carte"] == 0)
	# puis glissée au centre, comme le guide le demande
	await _glisser(golem, Rect2(c._cases[CarreEcran.TUTO_CASE_1]["pos"], CarreEcran.CASE).get_center() + Vector2(-40, 60), "tuto_glisse")
	_verifier("glissée au centre, la carte y est posée", c._main_j.size() == 4 and c.st["cases"][CarreEcran.TUTO_CASE_1] != null)
	while c.tour != "j" or c.occupe:
		await _attendre(0.1)
	await _attendre(0.6)
	_capture("tuto_kitsune")
	c._relache((c._main_j[0] as CarteCarre).get_global_rect().get_center())
	await _attendre(0.6)
	_capture("tuto_dessus")
	c._relache(Rect2(c._cases[CarreEcran.TUTO_CASE_2]["pos"], CarreEcran.CASE).get_center())
	await _attendre(0.95)
	_capture("tuto_duel")
	await _attendre(0.27)
	_capture("tuto_retournement")
	await _attendre(1.2)
	_capture("tuto_message")
	await _attendre(4.0)
	_capture("tuto_libre")
	_quitter()
