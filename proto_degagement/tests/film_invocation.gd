extends Node

# LE FILM DE L'INVOCATION, AVEC SON SON (29/09 — pour que Maxim juge la bande-son SUR l'animation, pas des sons isolés).
# Godot enregistre la séquence (image et son mêlés, à 30 images par seconde) : quatre invocations — une Base, un Or, un
# Prismatique, un Full art — puis une ×10 avec une Légende et un Full art. L'ambiance de la bande-son : après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --write-movie <film>.avi --fixed-fps 30 res://tests/film_invocation.tscn -- celeste
#
# puis l'AVI de Godot → un MP4 qui se lit partout (le ffmpeg du paquet imageio-ffmpeg) :
#   F=$(python -c "import imageio_ffmpeg as i; print(i.get_ffmpeg_exe())"); "$F" -y -i film.avi -c:v libx264 -crf 26 -pix_fmt yuv420p -c:a aac film.mp4

var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	Son.ambiance_invocation = args[0] if args.size() > 0 else "celeste"
	GS.sauvegarde_active = false
	Reglages.actif = false
	Reglages.musique = 0.3
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.cartes = {}
	for id in ["golem", "kitsune", "bahamut", "thor", "chinchin", "follet"]:
		GS.cartes[id] = {"stade": mini(3, GS.stade_max(id)), "variante": "base", "variantes": ["base"], "niveau": 10}
	GS.etoiles = 50
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_film()


func _resultat(id: String, v: String) -> Dictionary:
	return {"heros": GS.heros(id), "variante": v, "nouvelle": false, "nouvelle_variante": true, "amelioree": false,
		"doublon": false, "eclats": 5}


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _quand(condition: Callable) -> void:
	var limite := Time.get_ticks_msec() + 60000
	while not condition.call() and Time.get_ticks_msec() < limite:
		await get_tree().process_frame


func _film() -> void:
	await _attendre(1.0)
	main.barre._toucher("astrolabe")
	await _attendre(1.2)
	var c: CollectionScreen = main.ecran_collec
	for e in [["golem", "base"], ["kitsune", "or"], ["bahamut", "prisme"], ["thor", "full"]]:
		c.montrer_revelation(_resultat(str(e[0]), str(e[1])))
		await _quand(func() -> bool: return c._rev_fini)
		await _attendre(1.8)
		c.btn_rev_fermer.pressed.emit()
		await _attendre(0.7)
	var lot := []
	for e in [["chinchin", "base"], ["follet", "base"], ["chinchin", "or"], ["golem", "base"], ["follet", "ombre"],
			["kitsune", "base"], ["golem", "elem"], ["bahamut", "prisme"], ["thor", "base"], ["kitsune", "full"]]:
		lot.append(_resultat(str(e[0]), str(e[1])))
	c.montrer_multi(lot)
	await _quand(func() -> bool: return c._multi_fini)
	await _attendre(2.5)
	get_tree().quit()
