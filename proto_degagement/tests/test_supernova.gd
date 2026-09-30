extends Node

# Le test de la Supernova (30/09 — DECISIONS 30/09) : la jauge (les pièces tombées dans les fentes) la déclenche ; pendant
# 30 s, le poussoir va deux fois plus vite, une pluie de pièces offertes tombe sur le bloc, tout ce qui tombe devant compte
# double ; le son part ; à la fin, un cœur d'étoile tombe sur le plateau ; gagné, il compte (GS.coeurs) ; la frise de lunes
# suit la jauge ; la sauvegarde garde la jauge et les cœurs.
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
	p._nourrir_jauge()
	_ok("la jauge pleine : la Supernova part (30 s), la jauge repart de zéro",
		p.supernova_t > 29.0 and GS.jauge_supernova == 0 and p.supernovas == 1)
	_ok("toutes les lunes allumées pendant la Supernova", p._lunes_allumees() == 9)
	# le poussoir ×2 : en 30 images (0,5 s), le bloc avance d'une seconde de son cycle
	var t0 := p.t_bloc
	await _images(30)
	var avance := fposmod(p.t_bloc - t0, PusherScreen.PERIODE)
	_ok("le poussoir deux fois plus vite (%.2f s de cycle en 0,5 s)" % avance, absf(avance - 1.0) < 0.1)
	await get_tree().create_timer(0.6).timeout
	var noms := []
	for i in range(j0, Son.journal.size()):
		noms.append(str(Son.journal[i][0]))
	_ok("le son : l'aspiration, puis la révélation et les cloches", noms.has("inv-celeste-aspiration")
		and noms.has("inv-celeste-revelation") and noms.has("rarete-5"))
	await get_tree().create_timer(3.5).timeout
	_ok("la pluie : des pièces offertes sur le bloc (+%d)" % (p.pieces.size() - n0), p.pieces.size() - n0 >= 20)
	# tout compte double
	var m0 := GS.main_pieces
	var b := p._piece(Vector3(5.0, 0.1, PusherScreen.BORD + 0.2))
	b.set_meta("gagne", true)
	p._sur_gain(b)
	_ok("une pièce tombée devant compte double (+%d)" % (GS.main_pieces - m0), GS.main_pieces - m0 == 2)
	# la fin : le cœur d'étoile tombe sur le plateau
	p.supernova_t = 0.05
	await _images(10)
	var coeur := false
	for l in p.lots:
		coeur = coeur or str(l.get_meta("lot")) == "coeur-etoile"
	_ok("la fin : la Supernova s'arrête, un cœur d'étoile tombe sur le plateau", p.supernova_t == 0.0 and coeur)
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
