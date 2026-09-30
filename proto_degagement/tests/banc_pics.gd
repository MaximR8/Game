extends Node

# Les à-coups de la poussette, image par image : un joueur lâche une pièce toutes les
# 0,3 s pendant 30 s ; pour chaque image anormalement longue, on dit ce qui s'y passait
# (pièces tombées au bord, corps éveillés, le bloc qui avance ou recule, le temps du
# script de physique, de la mise à jour du rendu).
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 --fixed-fps 60 res://tests/banc_pics.tscn

var main: Node
var p: PusherScreen
var gains := 0
var _t_fin_phys := 0
var pas_phys_ms := 0.0


class Fin extends Node:
	var banc
	func _physics_process(_d: float) -> void:
		banc._t_fin_phys = Time.get_ticks_usec()


class Debut extends Node:
	var banc
	func _process(_d: float) -> void:
		if banc._t_fin_phys > 0:
			banc.pas_phys_ms = (Time.get_ticks_usec() - banc._t_fin_phys) / 1000.0


func _ready() -> void:
	GS.sauvegarde_active = false
	GS.tas_geo = 0
	GS.main_pieces = 150
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	seed(11)
	main = load("res://main.tscn").instantiate()
	add_child(main)
	p = main.ecran_pousse
	p.tombe.connect(func(_g: String): gains += 1)
	var fin := Fin.new()
	fin.banc = self
	fin.process_physics_priority = 100000
	add_child(fin)
	var debut := Debut.new()
	debut.banc = self
	debut.process_priority = -100000
	add_child(debut)
	_banc()


func _banc() -> void:
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()
	for i in 240:
		await get_tree().process_frame
	var lignes: Array = []
	var dts: Array = []
	var avant := Time.get_ticks_usec()
	var t_semis := 0.0
	for k in 1800:
		var g0 := gains
		await get_tree().process_frame
		var t := Time.get_ticks_usec()
		var dt := (t - avant) / 1000.0
		avant = t
		dts.append(dt)
		t_semis += 1.0 / 60.0
		if t_semis >= 0.3:
			t_semis = 0.0
			GS.main_pieces = 150
			p.dernier_semis = Vector2(-9999, -9999)
			p._semer(Vector2(randf_range(80.0, 1000.0), randf_range(540.0, 700.0)))
		var eveilles := 0
		for b in p.pieces:
			if not b.sleeping:
				eveilles += 1
		var sens := "avance" if p.t_bloc < p.PERIODE * 0.5 else "recule"
		lignes.append([dt, gains - g0, eveilles, sens, p.face_z, pas_phys_ms, p.rendu.us_maj / 1000.0])
	var tri := dts.duplicate()
	tri.sort()
	var med: float = tri[tri.size() / 2]
	print("Image médiane %.2f ms · 95 %% %.2f · 99 %% %.2f · pire %.2f" % [med, tri[int(tri.size() * 0.95)], tri[int(tri.size() * 0.99)], tri[tri.size() - 1]])
	# les à-coups : plus de 1,6 fois la médiane
	var n := 0
	var avec_gain := 0
	var eveilles_pics := 0.0
	var eveilles_tous := 0.0
	for l in lignes:
		eveilles_tous += float(l[2])
		if float(l[0]) > med * 1.6:
			n += 1
			eveilles_pics += float(l[2])
			if int(l[1]) > 0:
				avec_gain += 1
			if n <= 12:
				print("  à-coup %.2f ms · %d pièce(s) gagnée(s) · %d corps éveillés · le bloc %s (face %.2f) · pas de physique %.2f · rendu %.2f" % l)
	var phys: Array = []
	for l in lignes:
		phys.append(float(l[5]))
	phys.sort()
	print("Pas de physique : médiane %.2f ms · 95 %% %.2f · pire %.2f" % [phys[phys.size() / 2], phys[int(phys.size() * 0.95)], phys[phys.size() - 1]])
	print("%d à-coups sur %d images · %d avec un gain dans l'image · corps éveillés : %.0f pendant les à-coups, %.0f en moyenne" % [
		n, lignes.size(), avec_gain, eveilles_pics / maxf(1.0, n), eveilles_tous / lignes.size()])
	get_tree().quit(0)
