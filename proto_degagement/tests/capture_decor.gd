extends Node

# LA MACHINE DANS SON DÉCOR PEINT, PHOTOGRAPHIÉE ET FILMÉE (02/10) — le vrai jeu (machines/machine_decor.gd, posé par la
# Nébuleuse) : le décor, la vue 3D calée dessus, les lunes, la Supernova dans l'emblème, le lance-pièces. Un doigt simulé
# touche en bas de la machine et glisse (un rond clair le montre, pour la démonstration : le jeu, lui, n'en dessine pas).
# Lancé en fenêtre ; les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_decor.tscn -- <dossier> [theme=BaseCeleste] [fov=80|90] [film]
#
# theme= : un décor exporté pour le jeu (design/machines/analyser.py --jeu …) ; « film » : pour --write-movie (--fixed-fps 30).

const DECOR := preload("res://machines/machine_decor.gd")
const Y_DOIGT := 1290.0

var main: Node
var p: PusherScreen
var dossier := ""
var film := false
var theme := "BaseCeleste"
var doigt_la := false
var doigt_x := 540.0
var calque: Control


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	film = args.has("film")
	for a in args:
		if a.begins_with("theme="):
			theme = a.trim_prefix("theme=")
			DECOR.theme = theme
		elif a.begins_with("fov="):
			DECOR.champ = a.trim_prefix("fov=")
	GS.sauvegarde_active = false
	if not film:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.poussiere = 1240
	GS.etoiles = 12
	GS.pierres = {"lune": 3}
	GS.main_pieces = 148
	GS.jauge_supernova = 86          # 4 lunes sur 7
	main = load("res://main.tscn").instantiate()
	add_child(main)
	p = main.ecran_pousse
	if not film:
		# dans une fenêtre réduite, la vue 3D se calculerait plus petite : au plein du jeu pour les photos
		p.rendu.vue.size = Vector2i(int(p.rendu.size.x), int(p.rendu.size.y))
	# le doigt simulé (la démonstration) : un rond clair, par-dessus tout
	calque = Control.new()
	calque.size = Vector2(1080, 2400)
	calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	calque.draw.connect(func():
		if doigt_la:
			calque.draw_circle(Vector2(doigt_x, Y_DOIGT), 44.0, Color(1.0, 0.97, 0.88, 0.30))
			calque.draw_arc(Vector2(doigt_x, Y_DOIGT), 44.0, 0.0, TAU, 64, Color(1.0, 0.95, 0.80, 0.85), 3.0, true))
	main.add_child(calque)
	if film:
		_film()
	else:
		_scenario()


func _process(_d: float) -> void:
	if calque != null:
		calque.queue_redraw()


func _poser(x: float) -> void:
	doigt_la = true
	doigt_x = x
	p.decor_peint.toucher(Vector2(x, Y_DOIGT), true)


func _glisser(x: float) -> void:
	doigt_x = x
	p.decor_peint.glisser(Vector2(x, Y_DOIGT))


func _lever() -> void:
	doigt_la = false
	p.decor_peint.toucher(Vector2(doigt_x, Y_DOIGT), false)


func _scenario() -> void:
	await _attendre(0.3)
	_sans_cadeau()
	await _attendre(5.0)
	_capture("repos")
	_poser(250.0)
	await _attendre(0.18)
	_capture("chute")
	for i in 60:
		_glisser(540.0 + 300.0 * sin(-1.0 + float(i) / 60.0 * 3.0))
		await _attendre(1.0 / 30.0)
	_capture("glisse")
	_lever()
	await _attendre(0.8)
	_capture("pieces")
	GS.jauge_supernova = PusherScreen.JAUGE_SUPERNOVA - 1
	await _attendre(0.2)
	p.declencher_supernova()
	await _attendre(1.4)
	_capture("sn_mot")
	await _attendre(5.0)
	_capture("sn_compte")
	get_tree().quit(0)


func _film() -> void:
	await _images(10)
	_sans_cadeau()
	await _images(80)
	_poser(250.0)
	await _images(20)
	for i in 300:
		_glisser(540.0 + 330.0 * sin(-0.9 + float(i) / 300.0 * TAU * 1.5))
		await _images(1)
	_lever()
	await _images(40)
	_poser(780.0)
	await _images(10)
	_lever()
	await _images(30)
	_poser(330.0)
	await _images(10)
	_lever()
	await _images(60)
	p.declencher_supernova()
	await _images(300)
	get_tree().quit(0)


func _images(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _attendre(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _capture(nom: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("machine_%s_%s.png" % [theme, nom]))
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _sans_cadeau() -> void:
	var dd = main.get("daily")
	if dd != null and is_instance_valid(dd):
		dd.queue_free()
