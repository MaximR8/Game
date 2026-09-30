extends Node

# Photographie la Supernova (30/09) dans le vrai jeu : la frise de lunes à moitié allumée, puis l'animation — le flash et le
# mot qui jaillit, l'éclat de lumière sur les lettres, le mot rangé en haut pendant la pluie de pièces. Lancé en fenêtre
# (--headless ne dessine rien). Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/capture_supernova.tscn -- <dossier>

var main: Node
var dossier := ""
var n_capture := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	Reglages.actif = false
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.main_pieces = 200
	GS.jauge_supernova = PusherScreen.JAUGE_SUPERNOVA * 5 / 9 + 1
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _scenario() -> void:
	await get_tree().create_timer(2.0).timeout
	var p: PusherScreen = main.ecran_pousse
	_capture("jauge_5_sur_9")
	p.declencher_supernova()
	for t in [0.12, 0.45, 0.6, 1.0, 1.5, 3.4]:
		await get_tree().create_timer(t - (0.0 if n_capture == 1 else 0.0)).timeout
		_capture("supernova_%.2f" % t)
	print("RESULTAT: OK")
	get_tree().quit()


func _capture(nom: String) -> void:
	n_capture += 1
	var img := get_viewport().get_texture().get_image()
	img.save_png(dossier.path_join("supernova_%02d_%s.png" % [n_capture, nom]))
	print("capture %s" % nom)
