extends Node

# La planche des héros : chaque héros sur une ligne, ses stades côte à côte, en
# vrai rendu — pour régler d'un coup d'œil le cadrage de chaque illustration.
# Cinq héros par page ; les pages vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/planche_heros.tscn -- <dossier> [id,id,…]

const LARGEUR := 300.0


func _ready() -> void:
	GS.sauvegarde_active = false
	var args := OS.get_cmdline_user_args()
	var dossier: String = args[0] if args.size() > 0 else OS.get_user_data_dir()
	var ids: Array = []
	if args.size() > 1:
		ids = Array(args[1].split(","))
	else:
		for h in GS.HEROS:
			ids.append(h["id"])
	var fond := ColorRect.new()
	fond.color = Color("#0c0f0e")
	fond.size = Vector2(1080, 2400)
	add_child(fond)
	var page := 0
	for debut in range(0, ids.size(), 5):
		var cartes: Array = []
		for ligne in range(mini(5, ids.size() - debut)):
			var h := GS.heros(str(ids[debut + ligne]))
			for s in range(1, (h["formes"] as Array).size() + 1):
				var c := CarteView.new()
				add_child(c)
				c.configurer(h, s, "base", LARGEUR, true)
				c.position = Vector2(30 + (s - 1) * (LARGEUR + 45), 40 + ligne * (LARGEUR * 1.4 + 42))
				cartes.append(c)
		await get_tree().create_timer(1.2).timeout
		get_viewport().get_texture().get_image().save_png(dossier.path_join("planche_heros_%d.png" % page))
		print("planche %d : ok" % page)
		for c in cartes:
			remove_child(c)
			c.queue_free()
		page += 1
	get_tree().quit(0)
