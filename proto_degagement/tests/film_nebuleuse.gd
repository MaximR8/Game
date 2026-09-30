extends Node

# LE FILM DE LA NÉBULEUSE, AVEC SON SON (29/09 — pour que Maxim juge le plateau du jour tout posé, les fentes, les vraies
# pièces et les PAQUETS en jeu, pas des sons isolés). Une machine neuve : les 12 objets du jour sur leurs amas ; un joueur
# lâche une pièce toutes les RYTHME secondes, au hasard le long du bloc, pendant DUREE secondes. Godot enregistre l'image et
# le son ensemble.
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --write-movie <film>.avi --fixed-fps 30 res://tests/film_nebuleuse.tscn
#
# (puis l'AVI → MP4 : voir film_invocation.gd)

var DUREE := 45.0                # duree=<secondes> après « -- »
const RYTHME := 0.22

var main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("duree="):
			DUREE = a.trim_prefix("duree=").to_float()
	GS.sauvegarde_active = false
	Reglages.actif = false
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.tas_geo = 0                  # une machine neuve : garnie, les 12 objets du jour posés sur leurs amas
	GS.main_pieces = 400
	seed(29)
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_film()


func _film() -> void:
	await get_tree().create_timer(2.0).timeout
	var p: PusherScreen = main.ecran_pousse
	var t := 0.0
	while t < DUREE:
		GS.main_pieces = 400
		p.dernier_semis = Vector2(-9999, -9999)
		p._semer(Vector2(randf_range(120.0, 960.0), randf_range(540.0, 700.0)))
		await get_tree().create_timer(RYTHME).timeout
		t += RYTHME
	await get_tree().create_timer(2.5).timeout
	var n1 := 0
	var n2 := 0
	for e in Son.journal:
		n1 += 1 if e[0] == "paquet-1" else 0
		n2 += 1 if e[0] == "paquet-2" else 0
	print("film fini : %d objets gagnés, %d pièces perdues dans les fentes, %d petits paquets, %d gros" % [
		Plateau.total() - Plateau.restants(), p.perdues, n1, n2])
	get_tree().quit()
