extends Node

# Le test de la Supernova (30/09 — DECISIONS 30/09) : la jauge (les pièces tombées dans les fentes) la déclenche ; pendant
# 30 s, le poussoir va deux fois plus vite, une pluie de pièces offertes tombe sur le bloc, tout ce qui tombe devant compte
# double ; le son part ; à la fin, un cœur d'étoile tombe sur le plateau ; gagné, il compte (GS.coeurs) ; la frise de lunes
# suit la jauge ; la sauvegarde garde la jauge et les cœurs.
# (02/10) Dans le décor peint : la pluie d'or et le cœur jaillissent de l'astrolabe et volent jusqu'au plateau, devant le
# bloc, dès le début (machines/machine_decor.gd) ; rien ne reste en l'air.
# (02/10 au soir) Plus de mode de 30 s : un gros lot d'un coup (le spectacle ~6 s) — plus de poussoir ×2 ni de « tout compte
# double » ; trois poussières d'étoile offertes, hors du plateau du jour ; la pluie ne bloque pas le joueur (la marge).
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_supernova.tscn

var main: Node
var erreurs := 0
var verifs := 0


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	print("%s : %s" % [quoi, "OK" if vrai else "ÉCHEC"])
	if not vrai:
		erreurs += 1


func _ready() -> void:
	GS.sauvegarde_active = false
	Reglages.actif = false
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.main_pieces = 200
	GS.coeurs = 0
	GS.jauge_supernova = 0
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _images(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _scenario() -> void:
	await get_tree().create_timer(1.5).timeout
	var p: PusherScreen = main.ecran_pousse
	var J := PusherScreen.JAUGE_SUPERNOVA
	# la frise suit la jauge
	GS.jauge_supernova = J / 2
	_ok("la jauge à moitié : 4 lunes allumées sur 9 (%d)" % p._lunes_allumees(), p._lunes_allumees() == 4)
	# la dernière pièce dans une fente la déclenche
	GS.jauge_supernova = J - 1
	var j0 := Son.journal.size()
	var n0 := p.pieces.size()
	var avant := p.pieces.duplicate()
	p._nourrir_jauge()
	_ok("la jauge pleine : la Supernova part (le spectacle, ~6 s), la jauge repart de zéro",
		p.supernova_t > 5.0 and p.supernova_t < 10.0 and GS.jauge_supernova == 0 and p.supernovas == 1)
	_ok("toutes les lunes allumées pendant la Supernova", p._lunes_allumees() == 9)
	# plus de ×2 : en 30 images (0,5 s), le bloc avance d'une demi-seconde de son cycle
	var t0 := p.t_bloc
	await _images(30)
	var avance := fposmod(p.t_bloc - t0, PusherScreen.PERIODE)
	_ok("le poussoir garde son pas (%.2f s de cycle en 0,5 s)" % avance, absf(avance - 0.5) < 0.1)
	await get_tree().create_timer(0.6).timeout
	var noms := []
	for i in range(j0, Son.journal.size()):
		noms.append(str(Son.journal[i][0]))
	_ok("le son : l'aspiration, puis la révélation et les cloches", noms.has("inv-celeste-aspiration")
		and noms.has("inv-celeste-revelation") and noms.has("rarete-5"))
	await get_tree().create_timer(4.6).timeout
	_ok("la pluie : des pièces offertes (+%d)" % (p.pieces.size() - n0), p.pieces.size() - n0 >= 20)
	if p.decor_peint != null:
		var neuves := 0
		var devant := 0
		var en_l_air := 0
		for q in p.pieces:
			if avant.has(q):
				continue
			neuves += 1
			if q.position.z > PusherScreen.MILIEU + PusherScreen.COURSE - 0.3:
				devant += 1
			if q.has_meta("vol") or q.freeze:
				en_l_air += 1
		_ok("la pluie d'or a volé jusqu'au plateau, devant le bloc (%d / %d), plus rien en l'air (%d)" % [devant, neuves, en_l_air],
			neuves >= 30 and devant >= neuves * 0.8 and en_l_air == 0)
		var coeur_tot := false
		for l in p.lots:
			coeur_tot = coeur_tot or (str(l.get_meta("lot")) == "coeur-etoile" and not l.has_meta("vol") and not l.freeze)
		_ok("le cœur d'étoile est sorti de l'astrolabe : posé sur le plateau pendant la Supernova", coeur_tot)
		var offertes: Array = []
		for l in p.lots:
			if str(l.get_meta("lot")) == "poussiere" and l.has_meta("bonus") and not l.has_meta("vol") and not l.freeze:
				offertes.append(l)
		_ok("%d poussières d'étoile offertes, posées sur le plateau" % offertes.size(),
			offertes.size() == PusherScreen.POUSSIERES_SUPERNOVA)
		if not offertes.is_empty():
			var reste0 := Plateau.restants()
			var pou0 := GS.poussiere
			var o: RigidBody3D = offertes[0]
			o.set_meta("gagne", true)
			p._sur_gain(o)
			_ok("une poussière offerte gagnée : +60, et le plateau du jour n'a pas bougé (%d → %d)" % [reste0, Plateau.restants()],
				GS.poussiere - pou0 == 60 and Plateau.restants() == reste0)
	# plus de « tout compte double »
	var m0 := GS.main_pieces
	var b := p._piece(Vector3(5.0, 0.1, PusherScreen.BORD + 0.2))
	b.set_meta("gagne", true)
	p._sur_gain(b)
	_ok("une pièce tombée compte une fois (+%d)" % (GS.main_pieces - m0), GS.main_pieces - m0 == 1)
	# la pluie ne bloque pas le joueur : machine au-dessus du plafond, la marge de la Supernova le laisse lâcher
	var k := 0
	while p.pieces.size() < PusherScreen.MAX_PIECES + 5:
		p._piece(Vector3(1.0 + fmod(k * 0.97, 8.8), 2.0 + 0.14 * (k / 9), 10.2 + fmod(k * 0.53, 2.0)))
		k += 1
	p.marge_supernova = PusherScreen.PLUIE_SUPERNOVA
	_ok("au-dessus du plafond, après la Supernova : le joueur lâche encore (%d pièces)" % p.pieces.size(), p.refus_lacher() == "")
	p.marge_supernova = 0
	_ok("sans la Supernova, la machine pleine refuse", p.refus_lacher() != "")
	# la fin : le cœur d'étoile tombe sur le plateau
	p.supernova_t = 0.05
	await _images(10)
	var coeurs := 0
	for l in p.lots:
		if str(l.get_meta("lot")) == "coeur-etoile":
			coeurs += 1
	_ok("la fin : la Supernova s'arrête, UN cœur d'étoile sur le plateau (%d)" % coeurs, p.supernova_t == 0.0 and coeurs == 1)
	var m1 := GS.main_pieces
	var b2 := p._piece(Vector3(5.0, 0.1, PusherScreen.BORD + 0.2))
	b2.set_meta("gagne", true)
	p._sur_gain(b2)
	_ok("après : une pièce compte de nouveau une fois", GS.main_pieces - m1 == 1)
	# le cœur gagné
	p._gagner_objet("coeur-etoile", Vector2(540, 1400))
	_ok("le cœur gagné compte (%d)" % GS.coeurs, GS.coeurs == 1)
	var d := GS.donnees_sauvegarde()
	_ok("la sauvegarde garde la jauge et les cœurs", d.has("jauge_supernova") and int(d["coeurs"]) == 1)
	var restants := Plateau.restants()
	_ok("le cœur n'est pas du plateau du jour", Plateau.restants() == restants)
	print("%d vérifications" % verifs)
	print("RESULTAT: %s" % ("OK" if erreurs == 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)
