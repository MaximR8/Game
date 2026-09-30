extends Node

# Ce que coûte le chargement d'une illustration de carte (28/09, la saccade de l'ouverture) : l'image pleine
# (800 × 1000), la vignette (480 × 600), chacune jamais vue puis déjà chargée ; et, une fois chargée, ce que coûte sa
# première image à l'écran (l'envoi à la carte graphique).
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/banc_image.tscn

var _t := 0


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await get_tree().process_frame
	var garde := []
	for chemin in ["res://cartes/anubis-1.jpg", "res://cartes/anubis-1.jpg", "res://cartes/min/anubis-2.jpg",
			"res://cartes/thor-1.jpg", "res://cartes/min/thor-2.jpg", "res://cartes/loki-1.jpg"]:
		var t := Time.get_ticks_usec()
		var tex: Texture2D = load(chemin)
		var ms_charge := (Time.get_ticks_usec() - t) / 1000.0
		garde.append(tex)
		# sa première image à l'écran
		var tr := TextureRect.new()
		tr.texture = tex
		tr.size = Vector2(400, 500)
		add_child(tr)
		await get_tree().process_frame
		t = Time.get_ticks_usec()
		await get_tree().process_frame
		var ms_image := (Time.get_ticks_usec() - t) / 1000.0
		print("  %-32s charger %6.1f ms · l'image suivante %6.1f ms (%d × %d)" % [chemin.get_file() if not chemin.contains("/min/") else "min/" + chemin.get_file(),
			ms_charge, ms_image, tex.get_width(), tex.get_height()])
		tr.queue_free()
	# le décodage seul : la même image rechargée sans le cache de Godot (le fichier, lui, est déjà en mémoire du système)
	for chemin in ["res://cartes/thor-1.jpg", "res://cartes/min/thor-2.jpg", "res://cartes/bahamut-3.jpg"]:
		var ms := []
		for k in 4:
			var t := Time.get_ticks_usec()
			var tex = ResourceLoader.load(chemin, "", ResourceLoader.CACHE_MODE_IGNORE)
			ms.append("%.1f" % ((Time.get_ticks_usec() - t) / 1000.0))
		print("  décodage seul, %-22s : %s ms" % [chemin.get_file(), " · ".join(ms)])
	get_tree().quit(0)
