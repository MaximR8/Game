extends Node

# Photographie le vrai jeu (rendu GPU, shaders compris) : la collection pleine
# d'effets et un full art, une carte en feu, un full art et une carte ombre en
# grand, le plein écran, une invocation ×10 (le portail, un prismatique et un
# full art mis en scène, le bilan), une invocation simple de full art, les
# probabilités. Lancé en fenêtre (--headless ne dessine rien). Les images vont
# dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/capture_cartes.tscn -- <dossier>
#
# Ne sauvegarde rien : la sauvegarde est coupée pendant la séance.

var main: Node
var dossier := ""
var ecran: CollectionScreen


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	# rendre le jeu à sa taille de base (1080 × 2400), quelle que soit la fenêtre (bridée par l'écran)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.cartes = {
		"doudou": {"stade": 3, "variante": "elem", "variantes": ["base", "elem"], "niveau": 7},
		"thor": {"stade": 3, "variante": "elem", "variantes": ["elem", "prisme"], "niveau": 4},
		"bahamut": {"stade": 3, "variante": "full", "variantes": ["elem", "full"], "niveau": 1},
		"nian": {"stade": 3, "variante": "elem", "variantes": ["elem"], "niveau": 9},
		"kitsune": {"stade": 3, "variante": "elem", "variantes": ["elem"], "niveau": 2},
		"loki": {"stade": 3, "variante": "ombre", "variantes": ["base", "ombre"], "niveau": 3},
		"wukong": {"stade": 3, "variante": "elem", "variantes": ["elem"], "niveau": 5},
		"georges": {"stade": 1, "variante": "prisme", "variantes": ["prisme"], "niveau": 1},
		"korrigan": {"stade": 1, "variante": "or", "variantes": ["or"], "niveau": 1},
		"golem": {"stade": 2, "variante": "base", "variantes": ["base"], "niveau": 3},
		# des sbires (27/09) : leur rangée dans l'Atlas
		"chinchin": {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1},
		"hommefeuilles": {"stade": 1, "variante": "full", "variantes": ["base", "full"], "niveau": 1},
		"esprit_foudre": {"stade": 1, "variante": "or", "variantes": ["or"], "niveau": 1},
		"diable": {"stade": 1, "variante": "elem", "variantes": ["elem"], "niveau": 1},
	}
	GS.etoiles = 30
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


# 🔴 Chaque photo d'une animation attend SON moment (un état), pas une heure :
#    en fenêtre, les premières images sont lentes et une heure fixe tombe mal.
func _scenario() -> void:
	await _attendre(0.3)
	_ouvrir_collection()
	await _attendre(2.2)
	_capture("collection_1")
	_defiler(1700)
	await _attendre(1.5)
	_capture("collection_2")
	# la rangée des sbires, sous les héros
	_defiler(int(ecran.titre_sbires.position.y) - 40)
	await _attendre(2.5)
	_capture("collection_sbires")
	_grand("hommefeuilles")
	await _attendre(1.5)
	_capture("detail_sbire")
	ecran.detail_carte.poser(PI)
	await _attendre(1.0)
	_capture("detail_sbire_dos")
	ecran.detail_carte.poser(0.0)
	ecran.detail.visible = false
	_grand("doudou")
	await _attendre(2.0)
	_capture("detail_feu")
	# la carte en 3D (27/09) : inclinée sous le doigt, puis retournée — son dos, sa légende
	ecran.detail_carte.poser(-0.55, 0.14, true)
	await _attendre(0.8)
	_capture("detail_3d_inclinee")
	ecran.detail_carte.poser(PI)
	await _attendre(1.0)
	_capture("detail_dos_sans_pouvoir")
	ecran.detail_carte.poser(0.0)
	ecran._ouvrir_plein()
	await _attendre(1.2)
	_capture("plein_ecran")
	ecran.plein.visible = false
	_grand("bahamut")
	await _attendre(1.5)
	_capture("detail_full")
	_grand("thor")
	await _attendre(1.0)
	ecran.detail_carte.poser(PI * 0.5 + 0.45, -0.1, true)
	await _attendre(0.8)
	_capture("detail_3d_demi_tour")
	ecran.detail_carte.poser(PI)
	await _attendre(1.0)
	_capture("detail_dos_pouvoir")
	ecran.detail_carte.poser(0.0)
	# le prismatique (28/09 : son cadre de chrome irisé, son nom irisé) et la légende de Saint Georges
	_grand("georges")
	await _attendre(1.2)
	_capture("detail_prisme")
	ecran.detail_carte.poser(PI)
	await _attendre(1.0)
	_capture("detail_dos_georges")
	ecran.detail_carte.poser(0.0)
	_grand("golem")
	await _attendre(1.0)
	ecran.detail_carte.poser(PI)
	await _attendre(1.0)
	_capture("detail_dos_golem")
	ecran.detail_carte.poser(0.0)
	_grand("loki")
	await _attendre(1.2)
	_capture("detail_ombre")
	ecran.detail.visible = false

	# L'invocation ×10 (rituel des constellations) : une constellation par carte, en couleur
	# de sa rareté ; l'astrolabe se verrouille ; les étoiles filent vers les cartes.
	_multi()
	await _attendre(0.9)
	_capture("multi_constellations")
	await _attendre(0.75)
	_capture("multi_verrou")
	await _attendre(0.6)
	_capture("multi_envol")
	await _quand(func() -> bool: return ecran.multi_cartes[5].recto and ecran.multi_cartes[5].scale.x > 1.05)
	await _attendre(0.3)
	_capture("multi_prisme")
	await _quand(func() -> bool: return ecran.multi_vedette.visible and ecran.multi_vedette.recto)
	await _attendre(0.5)
	_capture("multi_full")
	await _quand(func() -> bool: return ecran._multi_fini)
	await _attendre(0.6)
	_capture("multi_fin")

	# Deux invocations simples : une Base (deux constellations), un full art (neuf).
	ecran.multi.visible = false
	for v in ["base", "full"]:
		ecran.montrer_revelation({"heros": GS.heros("thor"), "variante": v, "nouvelle": false,
			"nouvelle_variante": true, "amelioree": true, "poussiere": 25})
		await _attendre(0.9)
		_capture("simple_%s_ciel" % v)
		await _attendre(0.75 if v == "base" else 0.85)
		_capture("simple_%s_verrou" % v)
		await _attendre(0.55)
		_capture("simple_%s_cadran" % v)
		await _attendre(0.55)
		_capture("simple_%s_dos" % v)
		await _quand(func() -> bool: return ecran._rev_fini)
		await _attendre(0.4)
		_capture("simple_%s_fin" % v)

	ecran.rev.visible = false
	ecran.montrer_probas("grand")
	await _attendre(1.0)
	_capture("probas")
	get_tree().quit(0)


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _quand(condition: Callable) -> void:
	var limite := Time.get_ticks_msec() + 20000
	while not condition.call():
		if Time.get_ticks_msec() > limite:
			print("ERREUR : l'animation n'est jamais arrivée où la photo l'attendait")
			break
		await get_tree().process_frame


func _capture(nom: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var chemin := dossier.path_join("godot_%s.png" % nom)
	var err := img.save_png(chemin)
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _ouvrir_collection() -> void:
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()
	main._aller(false)
	ecran = main.ecran_collec


func _defiler(y: int) -> void:
	(ecran.grille.get_parent() as ScrollContainer).scroll_vertical = y


func _grand(id: String) -> void:
	ecran.detail.visible = false
	ecran._ouvrir(id)


func _multi() -> void:
	var lot: Array = []
	var tirage := [["thor", "base"], ["doudou", "or"], ["nian", "ombre"], ["bahamut", "elem"], ["kitsune", "base"],
		["loki", "prisme"], ["ifrit", "elem"], ["anansi", "full"], ["wukong", "base"], ["korrigan", "elem"]]
	for t in tirage:
		lot.append({"heros": GS.heros(t[0]), "variante": t[1], "nouvelle": not GS.cartes.has(t[0]),
			"nouvelle_variante": false, "amelioree": false, "poussiere": 0 if not GS.cartes.has(t[0]) else 25})
	ecran.montrer_multi(lot)
