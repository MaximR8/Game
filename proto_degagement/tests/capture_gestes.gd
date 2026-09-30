extends Node

# Photographie les gestes du lot ⑮ (rendu GPU réel) : la carte en grand, la montée de niveau
# (la poussière, le « LVL » qui éclate, le badge), puis l'évolution en plein écran (la pierre en
# 3D, la vibration, l'éclat, le blanc, l'évaporation, la fin). Lancé en fenêtre (--headless ne
# dessine rien). Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/capture_gestes.tscn -- <dossier>
#
# Ne sauvegarde rien : la sauvegarde est coupée pendant la séance.

var main: Node
var dossier := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	GS.poussiere = 5000
	GS.etoiles = 12
	GS.pierres = {"esprit": 2, "lune": 1}
	GS.cartes["kitsune"] = {"stade": 1, "niveau": 3, "variante": "base", "variantes": ["base"]}
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout   # le temps du jeu : ralenti avec lui si la capture rame


func _capture(nom: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("gestes_%s.png" % nom))
	print("capture %s : %s (%d images/s)" % [nom, "ok" if err == OK else "erreur %d" % err, Engine.get_frames_per_second()])


func _scenario() -> void:
	await _attendre(0.3)
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()
	main._aller(false)
	await _attendre(0.8)
	var c: CollectionScreen = main.ecran_collec
	c._ouvrir("kitsune")
	await _attendre(0.8)
	_capture("fiche")
	c._monter_niveau()
	await _attendre(0.45)
	_capture("niveau_poussiere")
	await _attendre(0.95)
	_capture("niveau_lvl")
	await _attendre(2.0)
	_capture("niveau_badge")
	c._evoluer()
	await _attendre(1.0)
	_capture("evo_pierre")
	await _attendre(1.8)
	_capture("evo_vibre")
	await _attendre(0.9)
	_capture("evo_eclat")
	await _attendre(0.9)
	_capture("evo_blanc")
	await _attendre(1.75)
	_capture("evo_evapore")
	await _attendre(2.05)
	_capture("evo_fin")
	get_tree().quit(0)
