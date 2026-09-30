extends Node

# Le banc de performance : le vrai jeu, rendu compris, image par image.
# --fixed-fps 60 : chaque image vaut 1/60 s de jeu et s'enchaîne sans attendre —
# le temps réel d'une image est donc TOUT son travail (physique, scripts, dessin,
# rendu). Au téléphone, ce travail doit tenir sous 16,7 ms.
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 --fixed-fps 60 res://tests/banc_perf.tscn
#
# Les chiffres sont ceux du PC : ils se comparent ENTRE EUX (quel poste coûte quoi).

var main: Node
var p: PusherScreen
var _t0 := 0
var _dessin_us := 0
var _dessin_n := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	GS.tas_geo = 0
	GS.main_pieces = 150
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	seed(7)
	main = load("res://main.tscn").instantiate()
	add_child(main)
	p = main.ecran_pousse
	# le dessin 2D du bloc (redessiné à chaque image), chronométré : [début, dessin, fin]
	p.bloc2d.draw.disconnect(p._dessiner_bloc)
	p.bloc2d.draw.connect(func(): _t0 = Time.get_ticks_usec())
	p.bloc2d.draw.connect(p._dessiner_bloc)
	p.bloc2d.draw.connect(func():
		_dessin_us += Time.get_ticks_usec() - _t0
		_dessin_n += 1)
	_banc()


func _images(n: int) -> Array:
	var dts: Array = []
	var avant := Time.get_ticks_usec()
	for i in n:
		await get_tree().process_frame
		var t := Time.get_ticks_usec()
		dts.append((t - avant) / 1000.0)
		avant = t
	dts.sort()
	var somme := 0.0
	for d in dts:
		somme += d
	return [somme / n, dts[int(n * 0.5)], dts[int(n * 0.95)], dts[n - 1]]


func _mesure(nom: String, n := 240) -> void:
	_dessin_us = 0
	_dessin_n = 0
	var r: Array = await _images(n)
	var dessin := (_dessin_us / 1000.0) / maxf(1.0, _dessin_n)
	print("%-44s moy %6.2f ms · médiane %6.2f · 95 %% %6.2f · pire %6.2f · dessin du bloc %5.2f ms" % [
		nom, r[0], r[1], r[2], r[3], dessin])


func _banc() -> void:
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()
	await _images(180)          # le tas se pose
	print("— La poussette : %d pièces" % p.pieces.size())
	await _mesure("complète")
	PhysicsServer3D.set_active(false)
	await _mesure("sans physique (dessin seul)")
	PhysicsServer3D.set_active(true)
	p.rendu.visible = false
	p.rendu.actif(false)
	await _mesure("sans le rendu 3D (physique seule)")
	PhysicsServer3D.set_active(false)
	await _mesure("ni physique ni rendu 3D (ciel, décor)")
	PhysicsServer3D.set_active(true)
	p.rendu.visible = true
	p.rendu.actif(true)
	for n in [240, 200, 150]:
		p._garnir(n)
		await _images(180)
		await _mesure("complète, %d pièces" % p.pieces.size())
	p._garnir(300)
	await _images(180)
	# la sauvegarde (toutes les 4 s en jeu) et le lâcher d'une pièce
	var t := Time.get_ticks_usec()
	for i in 10:
		p._sauver()
	print("sauvegarde du tas (%d pièces) : %.2f ms" % [p.pieces.size(), (Time.get_ticks_usec() - t) / 10000.0])
	GS.sauvegarde_active = true
	t = Time.get_ticks_usec()
	GS.save_game()
	print("écriture de la sauvegarde sur le disque : %.2f ms" % [(Time.get_ticks_usec() - t) / 1000.0])
	GS.sauvegarde_active = false
	t = Time.get_ticks_usec()
	for i in 20:
		p._lacher(randf_range(1.0, 9.8), 6.6)
	print("lâcher une pièce (recherche de l'endroit le plus bas) : %.2f ms" % [(Time.get_ticks_usec() - t) / 20000.0])
	await _images(120)
	# la collection
	print("— La collection")
	t = Time.get_ticks_usec()
	main._aller(false)
	print("ouvrir la collection (reconstruire la grille) : %.1f ms" % [(Time.get_ticks_usec() - t) / 1000.0])
	var detail := ""
	var avant := Time.get_ticks_usec()
	for i in 16:
		var reste: int = main.ecran_collec.vignettes.restantes()
		await get_tree().process_frame
		var mt := Time.get_ticks_usec()
		detail += "%.0f(%d) " % [(mt - avant) / 1000.0, reste]
		avant = mt
	print("  image par image (ms, photos de cartes restant à prendre) : " + detail)
	var r: Array = await _images(30)
	print("les 30 images suivantes : moy %.2f ms · pire %.2f ms" % [r[0], r[3]])
	await _mesure("collection affichée")
	main._aller(true)
	t = Time.get_ticks_usec()
	main._aller(false)
	print("la rouvrir : %.1f ms" % [(Time.get_ticks_usec() - t) / 1000.0])
	r = await _images(30)
	print("les 30 images suivantes : moy %.2f ms · pire %.2f ms" % [r[0], r[3]])
	get_tree().quit(0)
