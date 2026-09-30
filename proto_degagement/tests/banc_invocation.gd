extends Node

# Le banc de l'ouverture des cartes (28/09 — Maxim : « l'animation d'ouverture de carte lag au début, après ça va ») :
# image par image, la révélation d'une invocation (les 4 premières de la session, puis d'autres), une ×10, et une carte
# ouverte en grand dans l'Atlas (la première fois, puis une autre). Pour chacune : l'image la plus longue, quand elle
# tombe, et combien d'images dépassent 33 ms. Et le temps, hors de l'écran, de ce qu'on fait au départ : construire la
# carte (son illustration se charge), lancer le portail.
# En fenêtre (le rendu compte), sans vsync ni plafond d'images : on voit le vrai coût.
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/banc_invocation.tscn

var main: Node
var _avant := 0
var _mesure := false
var _images: Array = []         # [ms, t depuis le départ]
var _t0 := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	GS.cartes = {}
	for id in ["kitsune", "golem"]:
		GS.cartes[id] = {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1}
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.etoiles = 60
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_banc()


func _process(_d: float) -> void:
	var t := Time.get_ticks_usec()
	if _mesure and _avant > 0:
		_images.append([(t - _avant) / 1000.0, (t - _t0) / 1000.0])
	_avant = t


func _debut() -> void:
	_images = []
	_t0 = Time.get_ticks_usec()
	_mesure = true


func _fin(nom: String) -> void:
	_mesure = false
	var pire := 0.0
	var quand := 0.0
	var lentes := 0
	for x in _images:
		if float(x[0]) > pire:
			pire = float(x[0])
			quand = float(x[1])
		if float(x[0]) > 33.0:
			lentes += 1
	# une fois l'animation partie : sans les 3 premières images (le toucher, et l'attente sur le voile immobile, 28/09)
	var pire_anim := 0.0
	var lentes_anim := 0
	for k in range(3, _images.size()):
		pire_anim = maxf(pire_anim, float(_images[k][0]))
		if float(_images[k][0]) > 33.0:
			lentes_anim += 1
	print("  %-34s pire image %6.1f ms (à %5.0f ms) · %d > 33 ms sur %d · UNE FOIS PARTIE : pire %5.1f ms, %d > 33 ms" % [
		nom, pire, quand, lentes, _images.size(), pire_anim, lentes_anim])


func _banc() -> void:
	await get_tree().create_timer(2.0).timeout
	# (28/09) on invoque dans l'Astrolabe, au Grand Ciel ; l'Atlas révèle
	main.barre._toucher("astrolabe")
	await get_tree().create_timer(1.0).timeout
	var a: AstrolabeEcran = main.ecran_astrolabe
	a._montrer("grand", false)
	await get_tree().create_timer(1.5).timeout
	var c: CollectionScreen = main.ecran_collec
	print("La révélation d'une invocation (images de la première seconde et demie) :")
	for i in 6:
		_debut()
		var t := Time.get_ticks_usec()
		a.btn_invoquer.pressed.emit()
		var ms := (Time.get_ticks_usec() - t) / 1000.0
		await get_tree().create_timer(1.5).timeout
		_fin("invocation %d (le départ : %.1f ms)" % [i + 1, ms])
		while not c._rev_fini:
			await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		c.btn_rev_fermer.pressed.emit()
		await get_tree().create_timer(0.5).timeout
	print("Une ×10 :")
	for i in 2:
		_debut()
		a.btn_dix.pressed.emit()
		await get_tree().create_timer(2.0).timeout
		_fin("×10 n° %d" % (i + 1))
		while not c._multi_fini:
			await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		c.btn_multi_fermer.pressed.emit()
		await get_tree().create_timer(0.5).timeout
	print("Une carte ouverte en grand :")
	var ids := GS.cartes.keys()
	for i in 3:
		_debut()
		c._ouvrir(str(ids[i]))
		await get_tree().create_timer(1.0).timeout
		_fin("carte en grand n° %d (%s)" % [i + 1, ids[i]])
		c.detail.visible = false
		await get_tree().create_timer(0.3).timeout
	# ce que coûte, seul, chaque morceau du départ (hors écran) : une carte jamais vue, puis la même
	print("Les morceaux du départ, seuls :")
	for id in ["bahamut", "bahamut", "anubis"]:
		var cv := CarteView.new()
		add_child(cv)
		var t := Time.get_ticks_usec()
		cv.configurer(GS.heros(id), 1, "base", CollectionScreen.LARGEUR_GRANDE, false)
		print("  construire la carte de %-10s : %.1f ms" % [id, (Time.get_ticks_usec() - t) / 1000.0])
		cv.queue_free()
	for i in 3:
		GS.sauvegarde_active = i > 0          # (la 1re sans écrire : pour voir ce que coûte l'écriture)
		var t := Time.get_ticks_usec()
		GS.invoquer()
		print("  le tirage%s : %.1f ms" % [" (avec la sauvegarde)" if GS.sauvegarde_active else " (sans sauvegarde)", (Time.get_ticks_usec() - t) / 1000.0])
	GS.sauvegarde_active = false
	for i in 2:
		var ri := Rituel.new()
		add_child(ri)
		var t := Time.get_ticks_usec()
		ri.simple(Vector2(540, 1200), 400.0, 170.0, Color.WHITE, "fixe", 3)
		print("  lancer le portail : %.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
		ri.queue_free()
	get_tree().quit(0)
