extends Node

# Rend des cartes en PNG transparents, pour les maquettes (canevas) : le vrai
# rendu du jeu, sans fond. Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/cartes_png.tscn -- <dossier>

const LARGEUR := 440.0
const MARGE := 36


func _ready() -> void:
	GS.sauvegarde_active = false
	var dossier: String = OS.get_cmdline_user_args()[0]
	var h := GS.heros("kitsune")
	if OS.get_cmdline_user_args().has("multi"):
		# L'exemple de tirage ×10 du canevas : neuf autres héros
		for hv in [["thor", "or"], ["wukong", "base"], ["roc", "base"], ["fenrir", "base"], ["quetzalcoatl", "prisme"],
				["golem", "base"], ["banshee", "base"], ["loki", "or"], ["cerbere", "base"], ["kelpie", "base"]]:
			await _rendre(dossier, "m-%s-%s" % hv, GS.heros(hv[0]), str(hv[1]), true)
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("evo"):
		# Le canevas des gestes (⑮) : la même carte au stade 1 puis au stade 2
		for st in [1, 2]:
			await _rendre(dossier, "evo-%d" % st, h, "base", true, st)
		get_tree().quit(0)
		return
	for spec in [["dos-base", "base", false], ["dos-or", "or", false], ["dos-prisme", "prisme", false], ["dos-full", "full", false], ["recto-or", "or", true],
			["recto-base", "base", true], ["recto-prisme", "prisme", true], ["recto-full", "full", true]]:
		await _rendre(dossier, "carte-" + str(spec[0]), h, str(spec[1]), bool(spec[2]))
	get_tree().quit(0)


func _rendre(dossier: String, nom: String, h: Dictionary, variante: String, recto: bool, stade := 3) -> void:
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.size = Vector2i(int(LARGEUR) + 2 * MARGE, int(LARGEUR * 1.4) + 2 * MARGE)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var c := CarteView.new()
	vp.add_child(c)
	c.configurer(h, stade, variante, LARGEUR, recto)
	c.position = Vector2(MARGE, MARGE)
	await get_tree().create_timer(0.8).timeout
	vp.get_texture().get_image().save_png(dossier.path_join(nom + ".png"))
	print("carte %s : ok" % nom)
	remove_child(vp)
	vp.queue_free()
