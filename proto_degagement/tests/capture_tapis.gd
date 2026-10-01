extends Node

# LE TAPIS « BASE CÉLESTE » DU CARRÉ, EN APERÇU (01/10 — Maxim : « les skins pour les plateaux de jeu ; fais-moi
# celui de base dans le même esprit que la Base céleste »). Un PROTOTYPE, rien n'est changé dans le jeu : un vrai
# combat de l'Aventure, photographié avec le tapis d'aujourd'hui, puis avec le tapis céleste (rendu par la
# fabrique : design/objets/render_carre.py --celeste), posé à la place, le temps des photos.
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_tapis.tscn -- <dossier>

const NIVEAU := 14
const GRAINE := 7

var main: Node
var dossier := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.cartes = {
		"kitsune": {"stade": 2, "niveau": 6, "variante": "prisme", "variantes": ["base", "prisme"]},
		"bahamut": {"stade": 2, "niveau": 6, "variante": "elem", "variantes": ["base", "elem"]},
		"thor": {"stade": 2, "niveau": 6, "variante": "full", "variantes": ["base", "full"]},
		"golem": {"stade": 1, "niveau": 2, "variante": "or", "variantes": ["or"]},
		"banshee": {"stade": 1, "niveau": 1, "variante": "base", "variantes": ["base"]},
		"doudou": {"stade": 1, "niveau": 1, "variante": "ombre", "variantes": ["ombre"]},
	}
	var etoiles := {}
	for k in NIVEAU - 1:
		etoiles[str(k + 1)] = 7
	GS.voyage = {"tuto_carre": true, "aventure": {"etoiles": etoiles, "coffres": {"1": [10]}}}
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _scenario() -> void:
	await _attendre(0.3)
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()
	main._aller_vers("voyage")
	var ve: VoyageEcran = main.ecran_voyage
	ve.ouvrir_hub()
	await _attendre(0.6)
	ve.ouvrir_terre(Aventure.terre_de(NIVEAU))
	await _attendre(0.6)
	ve.ouvrir_avant(NIVEAU)
	await _attendre(0.6)
	seed(GRAINE)
	ve._avant.combattre.emit(NIVEAU)
	var c: CarreEcran = main.combat
	await _attendre(1.4)
	_capture("tapis_actuel_debut")
	var tapis := _tapis(c)
	var ancien: Texture2D = tapis.texture
	var chemin := ProjectSettings.globalize_path("res://").path_join("../design/objets/carre/tapis-carre-celeste.png")
	var img := Image.load_from_file(chemin)
	img.generate_mipmaps()
	var neuf := ImageTexture.create_from_image(img)
	tapis.texture = neuf
	await _attendre(0.2)
	_capture("tapis_celeste_debut")
	# quelques coups (ceux que jouerait le Maître), puis la même partie avec les deux tapis
	var coups := 0
	while not c.termine and coups < 3:
		if c.tour != "j" or c.occupe:
			await _attendre(0.1)
			continue
		var m := MoteurCarre.coup_ia(c.st, MoteurCarre.Hasard.new(GRAINE + coups), "j", "maitre")
		c._jouer(m[0], m[1])
		coups += 1
		await _attendre(0.3)
	while c.tour != "j" or c.occupe:
		await _attendre(0.1)
	await _attendre(0.6)
	_capture("tapis_celeste_partie")
	tapis.texture = ancien
	await _attendre(0.2)
	_capture("tapis_actuel_partie")
	get_tree().quit(0)


# Le tapis : l'image du jeu (res://carre/tapis-carre.png) posée dans l'écran du combat.
func _tapis(c: Node) -> TextureRect:
	for n in c.get_children():
		if n is TextureRect and (n as TextureRect).texture != null and (n as TextureRect).texture.resource_path == "res://carre/tapis-carre.png":
			return n
	push_error("le tapis est introuvable")
	return null


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _capture(nom: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("godot_%s.png" % nom))
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])
