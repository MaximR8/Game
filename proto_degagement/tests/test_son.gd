extends Node

# Le test du son (29/09) — le vrai jeu, sans écran (le son passe par le pilote muet : on lit ce qui a SONNÉ, Son.journal).
#
#   1. Une pièce lâchée sonne à son premier contact — une fois, pas au geste ; en rafale, jamais deux dans la même image.
#   2. La cascade : les pièces qui se suivent montent, discrètement (29/09 : de vraies pièces, ~3,5 demi-tons au plus) ;
#      après 0,7 s de calme, elle repart d'en bas. Le PAQUET : à la 3ᵉ pièce d'un paquet, le petit ; à la 7ᵉ, le gros.
#   3. Un objet : l'étoile au ton juste, la poussière +2, une pierre −3, la lune +7 ; le plateau vidé sonne sa fanfare.
#   4. Le poussoir se tait (29/09) ; une pièce qui tombe sur le tas s'entrechoque ; la musique tourne, sur son bus.
#   6. Deux musiques hors combat (29/09) : la Nébuleuse a la sienne, les autres écrans l'autre ; chacune reprend où elle
#      en était quand on revient sur son écran.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_son.tscn

var main: Node
var erreurs := 0
var verifs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	Reglages.actif = false
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.main_pieces = 80
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	print("%s : %s" % [quoi, "OK" if vrai else "ÉCHEC"])
	if not vrai:
		erreurs += 1


# 5. Le reste du jeu (29/09, « du son dans tout le jeu ») : l'interface, l'invocation, le combat, la musique du combat.
func _reste_du_jeu() -> void:
	# l'interface : un onglet, un bouton, un bouton éteint
	var j0 := Son.journal.size()
	main.barre._toucher("atlas")
	await get_tree().create_timer(0.8).timeout
	var pos_neb := float(Son.global._positions.get("musique-nebuleuse", 0.0))
	_ok("l'Atlas : l'autre musique (First Light Particles)", Son.global._musique_nom == "musique")
	_ok("la musique de la Nébuleuse garde sa place (%.1f s)" % pos_neb, pos_neb > 1.0)
	_ok("un onglet : son tic", _compte("onglet", j0) == 1)
	var b := Style.bouton(self, "essai", Rect2(0, 0, 200, 100))
	b.button_up.emit()
	_ok("un bouton : son clic", _compte("bouton", j0) == 1)
	b.disabled = true
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	b.gui_input.emit(clic)
	_ok("un bouton éteint : le refus", _compte("refus", j0) == 1)
	b.queue_free()

	# l'invocation : le portail, le verrou de l'astrolabe, la carte qui se retourne ; un Full art : sa rareté (5)
	var c: CollectionScreen = main.ecran_collec
	GS.etoiles = 5
	j0 = Son.journal.size()
	c.invoquer_dans("grand", 1)
	await get_tree().create_timer(0.3).timeout
	_ok("l'invocation : le souffle de l'astrolabe", _compte("inv-celeste-souffle", j0) == 1)
	var limite := Time.get_ticks_msec() + 15000
	while not c._rev_fini and Time.get_ticks_msec() < limite:
		await get_tree().process_frame
	_ok("puis les étoiles (%d), le verrou, l'apparition, la révélation" % _compte("inv-celeste-etoile", j0),
		_compte("inv-celeste-etoile", j0) >= 2 and _compte("inv-celeste-verrou", j0) == 1 and _compte("inv-celeste-apparition", j0) == 1
		and _compte("inv-celeste-revelation", j0) == 1)
	c.btn_rev_fermer.pressed.emit()
	j0 = Son.journal.size()
	c.montrer_revelation(GS.donner_carte_test("full"))
	limite = Time.get_ticks_msec() + 15000
	while not c._rev_fini and Time.get_ticks_msec() < limite:
		await get_tree().process_frame
	_ok("un Full art : les cloches de la rareté 5", _compte("rarete-5", j0) == 1)
	c.btn_rev_fermer.pressed.emit()

	# le combat : sa musique, la pose, la fin ; au retour, la musique du jeu
	GS.cartes = {}
	for id in ["thor", "kitsune", "golem", "kelpie", "banshee", "wukong", "minotaure", "troll", "yeti", "cerbere"]:
		GS.cartes[id] = {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1}
	GS.voyage["tuto_carre"] = true
	j0 = Son.journal.size()
	var deck := Decks.nettoyer(VoyageEcran.deck_auto())
	_ok("un deck de 5 pour le duel (%d)" % deck.size(), deck.size() == 5)
	main._lancer_combat(deck, Arene.adversaire_suivant("duel"))
	await get_tree().create_timer(1.2).timeout
	_ok("un combat : sa musique", Son.global._musique_nom == "musique-combat")
	var cb: CarreEcran = main.combat
	var h := MoteurCarre.Hasard.new(3)
	limite = Time.get_ticks_msec() + 90000
	while is_instance_valid(cb) and not cb.termine and Time.get_ticks_msec() < limite:
		if cb.tour == "j" and not cb.occupe:
			if MoteurCarre.coups(cb.st, "j").is_empty():
				break
			var m := MoteurCarre.coup_ia(cb.st, h, "j", "maitre")
			cb._jouer(m[0], m[1])
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var flips := []
	for i in range(j0, Son.journal.size()):
		if Son.journal[i][0] == "retourne-combat":
			flips.append(int(Son.journal[i][1]))
	var fins := _compte("victoire", j0) + _compte("defaite", j0) + _compte("parfait", j0)
	_ok("le combat : %d poses, %d chocs, les retournements %s, une fin (%d)" % [_compte("carte-pose", j0), _compte("choc", j0), str(flips), fins],
		_compte("carte-pose", j0) == 9 and fins == 1 and (flips.is_empty() or _compte("choc", j0) >= 1))
	# (un retournement d'Anubis n'a pas de choc de chiffres : il peut y avoir plus de retournements que de chocs)
	_ok("chaque coup repart de do (le premier retournement d'un coup est à 0)", flips.is_empty() or flips[0] == 0)
	cb.fini.emit({"retour": "duel"})
	await get_tree().create_timer(1.5).timeout
	_ok("au retour : la musique du jeu", Son.global._musique_nom == "musique")
	main.barre._toucher("nebuleuse")
	await get_tree().create_timer(1.2).timeout
	_ok("de retour à la Nébuleuse : sa musique reprend où elle en était (%.1f s)" % Son.global._depart_pos,
		Son.global._musique_nom == "musique-nebuleuse" and absf(Son.global._depart_pos - pos_neb) < 0.5)


func _compte(nom: String, depuis := 0) -> int:
	var n := 0
	for i in range(depuis, Son.journal.size()):
		if Son.journal[i][0] == nom:
			n += 1
	return n


func _scenario() -> void:
	await get_tree().create_timer(1.5).timeout
	var p: PusherScreen = main.ecran_pousse
	_ok("la musique tourne, sur le bus Musique", Son.global._musique.playing and Son.global._musique.bus == "Musique")
	_ok("la Nébuleuse a sa musique (Starfield Romance)", Son.global._musique_nom == "musique-nebuleuse")

	# 1. une pièce lâchée : le son à son contact, pas au geste
	var j0 := Son.journal.size()
	var x := (p.X0 + p.X1) * 0.5 * p.U
	p._semer(Vector2(x, p.CADRE.position.y + 60.0))
	_ok("au geste : rien encore", _compte("pose", j0) == 0)
	await get_tree().create_timer(0.6).timeout
	_ok("au contact : la pose sonne, une fois (%d)" % _compte("pose", j0), _compte("pose", j0) == 1)
	# en rafale : 6 pièces lâchées dans la même image → au plus une par image
	j0 = Son.journal.size()
	for k in 6:
		p.dernier_semis = Vector2(-9999, -9999)
		p._semer(Vector2(p.X0 * p.U + 60.0 + k * 90.0, p.CADRE.position.y + 60.0))
	await get_tree().create_timer(0.8).timeout
	var poses := _compte("pose", j0)
	_ok("en rafale : des poses, jamais plus que de pièces (%d pour 6)" % poses, poses >= 1 and poses <= 6)

	# 2. la cascade — la machine gelée : une vraie pièce qui tomberait du bord ajouterait son cling (vu : un test sur deux)
	p.gel = true
	await get_tree().create_timer(Son.CASCADE_S + 0.2).timeout     # le calme : une cascade d'avant le gel retombe
	j0 = Son.journal.size()
	for k in 7:
		Son.gain()
		await get_tree().create_timer(0.1).timeout
	var tons := []
	for i in range(j0, Son.journal.size()):
		if Son.journal[i][0] == "gain":
			tons.append(snappedf(float(Son.journal[i][1]), 0.1))
	var monte := tons.size() == 7 and float(tons[-1]) > float(tons[0]) + 2.0 and float(tons[-1]) < 4.5
	for k in range(1, tons.size()):
		monte = monte and float(tons[k]) > float(tons[k - 1]) - 0.9
	_ok("la cascade monte, discrètement : %s" % str(tons), monte)
	_ok("un paquet de 7 : le petit à la 3ᵉ, le gros à la 7ᵉ, une fois chacun", _compte("paquet-1", j0) == 1 and _compte("paquet-2", j0) == 1)
	await get_tree().create_timer(0.8).timeout
	Son.gain()
	_ok("après le calme : d'en bas", absf(float(Son.journal[-1][1])) < 0.5)
	await get_tree().create_timer(0.8).timeout
	j0 = Son.journal.size()
	for k in 12:                                          # un gros paquet : 12 pièces en 0,24 s
		Son.gain()
		await get_tree().create_timer(0.02).timeout
	_ok("un gros paquet (12) : le petit puis le gros, et moins de 12 pièces qui sonnent (%d)" % _compte("gain", j0),
		_compte("paquet-1", j0) == 1 and _compte("paquet-2", j0) == 1 and _compte("gain", j0) < 12)
	p.gel = false

	# 3. les objets, le plateau vidé
	for e in [["etoile", 0], ["poussiere", 2], ["pierre-feu", -3], ["pierre-lune", 5]]:
		p.demo_gain(str(e[0]))
		_ok("l'objet %s sonne à %+d" % [e[0], e[1]], Son.journal[-1][0] == "objet" and int(Son.journal[-1][1]) == int(e[1]))
	for k in Plateau.total():
		Plateau.gagner("poussiere")
		Plateau.gagner("etoile")
		Plateau.gagner("pierre-feu")
	j0 = Son.journal.size()
	p.demo_gain("poussiere")
	await get_tree().create_timer(0.8).timeout
	_ok("le plateau vidé : sa fanfare", _compte("plateau-vide", j0) == 1)

	# 4. (29/09) le poussoir se tait ; une pièce qui tombe sur le tas s'entrechoque (de vraies pièces) — on en lâche sur le bloc
	j0 = Son.journal.size()
	for k in 16:
		p.dernier_semis = Vector2(-9999, -9999)
		p._semer(Vector2(randf_range(120.0, 960.0), randf_range(540.0, 700.0)))
		await get_tree().create_timer(0.25).timeout
	await get_tree().create_timer(2.0).timeout
	_ok("le poussoir se tait (plus de froissement)", _compte("froissement", j0) == 0)
	# une pièce qui tombe devant le bloc (pas lâchée par le joueur) : elle tinte en arrivant sur le tas
	await get_tree().create_timer(0.2).timeout
	j0 = Son.journal.size()
	p._piece(Vector3(5.2, 1.6, p.face_z + 0.4))
	await get_tree().create_timer(1.0).timeout
	_ok("une pièce qui tombe sur le tas s'entrechoque (%d)" % _compte("entrechoc", j0), _compte("entrechoc", j0) >= 1)
	j0 = Son.journal.size()
	Son.entrechoc()
	Son.entrechoc()
	_ok("deux entrechocs dans la même image : un seul", _compte("entrechoc", j0) == 1)
	await _reste_du_jeu()
	print("%d vérifications" % verifs)
	print("RESULTAT: %s" % ("OK" if erreurs == 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)
