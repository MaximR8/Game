extends Node

# Photographie le plateau avec chaque matière du bloc (ivoire, nuit, nébuleuse, jade), au même
# instant : pour comparer. Lancé en fenêtre ; les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/capture_blocs.tscn -- <dossier>

var main: Node


func _ready() -> void:
	var dossier: String = OS.get_cmdline_user_args()[0]
	GS.sauvegarde_active = false
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.3).timeout
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()
	await get_tree().create_timer(2.4).timeout
	var p: PusherScreen = main.ecran_pousse
	# le bloc avancé : on voit tout son dessus
	var limite := Time.get_ticks_msec() + 8000
	while p.face_z < 9.1 and Time.get_ticks_msec() < limite:
		await get_tree().process_frame
	p.gel = true
	PhysicsServer3D.set_active(false)
	for st in ["ivoire", "nuit", "nebuleuse", "jade"]:
		p.style_bloc = st
		p.bloc2d.queue_redraw()
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(dossier.path_join("bloc_%s.png" % st))
		print("capture bloc %s : ok" % st)
	PhysicsServer3D.set_active(true)
	get_tree().quit(0)
