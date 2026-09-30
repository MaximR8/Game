extends Node

# Photographie le poussoir dans le look « Conte mystique » (rendu GPU réel) :
# le plateau au repos, des pièces lâchées au pied du mur, le tas écrasé contre
# lui quand le bloc recule, un objet gagné qui s'envole, les outils de test, puis la
# collection sur le ciel. Lancé en fenêtre (--headless ne dessine rien). Les
# images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/capture_poussoir.tscn -- <dossier>
#
# Ne sauvegarde rien : la sauvegarde est coupée pendant la séance.

var main: Node
var dossier := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	GS.poussiere = 1240
	GS.etoiles = 12
	GS.pierres = {"lune": 3}
	GS.main_pieces = 132
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


# 🔴 Les photos du bloc se déclenchent sur SA position, pas sur l'horloge : en
#    fenêtre, la physique prend du retard au démarrage et une heure fixe tombe
#    n'importe où dans son aller-retour.
func _scenario() -> void:
	await _attendre(0.3)
	_sans_cadeau()
	await _attendre(2.7)
	_capture("poussoir_repos")
	var p: PusherScreen = main.ecran_pousse
	# Presque sorti : de la place au pied du mur.
	await _quand(func() -> bool: return p.face_z >= 9.0 and p.t_bloc < p.PERIODE * 0.5)
	_semer()
	await _attendre(0.4)
	_capture("poussoir_seme")
	# Presque reculé : le tas écrasé contre le mur, l'avant qui déborde.
	await _quand(func() -> bool: return p.face_z <= 7.8 and p.t_bloc > p.PERIODE * 0.5)
	_capture("poussoir_tas")
	_gain()
	await _attendre(0.9)
	_capture("poussoir_envol")
	_outils()
	await _attendre(1.1)
	_capture("poussoir_outils")
	_collection()
	await _attendre(1.5)
	_capture("collection_ciel")
	get_tree().quit(0)


# Minuteurs en temps réel (ignore_time_scale) : la séance ne suit pas le jeu.
func _attendre(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _quand(condition: Callable) -> void:
	var limite := Time.get_ticks_msec() + 8000
	while not condition.call():
		if Time.get_ticks_msec() > limite:
			print("ERREUR : le bloc n'est jamais arrivé où la photo l'attendait")
			break
		await get_tree().process_frame


func _capture(nom: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var chemin := dossier.path_join("godot_%s.png" % nom)
	var err := img.save_png(chemin)
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _sans_cadeau() -> void:
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()


func _semer() -> void:
	var p: PusherScreen = main.ecran_pousse
	# au pied du fronton, puis sur le bloc, par-dessus les pièces qui y sont
	for x in [200.0, 330.0, 470.0, 610.0, 760.0, 880.0]:
		for y in [520.0, 660.0]:
			p.dernier_semis = Vector2(-9999, -9999)
			p._semer(Vector2(x, y))


func _gain() -> void:
	var p: PusherScreen = main.ecran_pousse
	p.demo_gain("pierre-esprit")


func _outils() -> void:
	main._basculer_outils()


func _collection() -> void:
	main._aller(false)
