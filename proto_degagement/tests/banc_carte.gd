extends Node

# Ce que coûte UNE carte de la grille, étape par étape (CarteView.profil), et sa première image.
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/banc_carte.tscn

func _ready() -> void:
	GS.sauvegarde_active = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await get_tree().process_frame
	for id in ["thor", "loki", "kitsune", "fenrir", "yeti", "troll", "thor", "loki"]:
		CarteView.profil.clear()
		var t := Time.get_ticks_usec()
		var c := CarteView.new()
		add_child(c)
		c.configurer(GS.heros(id), 1, "base", 486.0, true)
		var t_conf := (Time.get_ticks_usec() - t) / 1000.0
		t = Time.get_ticks_usec()
		await get_tree().process_frame
		await get_tree().process_frame
		var t_image := (Time.get_ticks_usec() - t) / 1000.0
		var detail := ""
		for k in CarteView.profil:
			detail += "%s %.1f · " % [k, CarteView.profil[k]]
		print("%-8s construire %6.1f ms [%s] · deux images %6.1f ms" % [id, t_conf, detail, t_image])
		c.queue_free()
		await get_tree().process_frame
	get_tree().quit(0)
