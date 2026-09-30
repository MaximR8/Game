extends Node

# Photographie le tout premier lancement dans le vrai jeu (28/09) : le cadeau du jour, puis l'accueil
# du premier pack — l'onglet Astrolabe montré du doigt (l'Atlas avant le 28/09), le pack offert, l'invocation ×10, l'onglet Voyage,
# « Jouer », et le premier combat guidé qui prend le relais. Vérifie en chemin : la garantie du pack,
# qu'il ne coûte rien, qu'il ne revient pas, que le reste de l'écran ne répond pas.
# Lancé en fenêtre (--headless ne dessine rien). Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_accueil.tscn -- <dossier>
#
# Ne sauvegarde rien : la sauvegarde est coupée pendant la séance.

var main: Node
var dossier := ""
var n_capture := 0
var _echecs := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	# une partie neuve : aucune carte, aucune étoile, le cadeau du jour en attente
	GS.cartes = {}
	GS.voyage = {}
	GS.etoiles = 0
	GS.last_daily = ""
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _scenario() -> void:
	await _attendre(1.0)
	_capture("cadeau_du_jour")
	_verifier("l'accueil attend la fin du cadeau du jour", main.accueil == null)
	main.daily.queue_free()
	await _attendre(1.0)
	_verifier("puis il commence : l'onglet Astrolabe", main.accueil != null and main.accueil.etape == "astrolabe")
	_capture("montre_astrolabe")
	# le reste de l'écran ne répond pas ; le trou, si
	var bloc: Control = main.accueil._bloc
	var onglet: Rect2 = main.barre.rect_onglet("astrolabe")
	_verifier("le trou laisse passer le doigt, le reste non",
		not bloc._has_point(onglet.get_center()) and bloc._has_point(main.barre.rect_onglet("voyage").get_center()))

	main.barre._toucher("astrolabe")
	await _attendre(1.2)
	_verifier("dans l'Astrolabe, au Grand Ciel : le pack offert, gratuit", main.accueil.etape == "ouvrir"
		and main.ecran_astrolabe.portail == "grand" and not main.ecran_astrolabe.btn_dix.disabled
		and main.ecran_astrolabe.btn_dix.text == "Premier pack")
	_capture("montre_pack")

	main.ecran_astrolabe.btn_dix.pressed.emit()
	await _quand(func() -> bool: return main.ecran_collec._multi_fini)
	await _attendre(0.8)
	_capture("pack_ouvert")
	var diff := GS.cartes.size()
	var heros := 0
	for id in GS.cartes:
		if not GS.est_sbire(str(id)):
			heros += 1
	_verifier("le pack : %d cartes différentes (5 au moins), %d héros (3 au moins), 0 étoile dépensée" % [diff, heros],
		diff >= 5 and heros >= 3 and GS.etoiles == 1)
	_verifier("il ne revient pas", not GS.premier_pack_du())
	_verifier("le Ciel du Peintre n'a pas bougé : son cadeau attend (le point d'or sur l'Astrolabe)",
		Portails.offerte_due("peintre") and Portails.compte("peintre") == 0 and main.barre._tabs["astrolabe"]["point"].visible)

	main.ecran_collec.btn_multi_fermer.pressed.emit()
	await _attendre(0.8)
	_verifier("puis l'onglet Voyage", main.accueil.etape == "voyage")
	_capture("montre_voyage")

	main.barre._toucher("voyage")
	await _attendre(1.2)
	_verifier("puis « Jouer »", main.accueil.etape == "jouer")
	_capture("montre_jouer")

	main.ecran_voyage.bouton_jouer.pressed.emit()
	await _attendre(2.0)
	_verifier("le premier combat, guidé : l'accueil s'efface", main.accueil == null and main.combat != null)
	_capture("premier_combat")
	_verifier("le premier deck : 5 cartes du pack, dans le poids", Decks.valide(Decks.deck_actif()))
	print("RESULTAT: %s" % ("OK" if _echecs == 0 else "ÉCHEC (%d)" % _echecs))
	get_tree().quit(0 if _echecs == 0 else 1)


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _quand(condition: Callable) -> void:
	var limite := Time.get_ticks_msec() + 30000
	while not condition.call():
		if Time.get_ticks_msec() > limite:
			_verifier("l'animation arrive où la photo l'attend", false)
			break
		await get_tree().process_frame


func _capture(nom: String) -> void:
	n_capture += 1
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("accueil_%02d_%s.png" % [n_capture, nom]))
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _verifier(quoi: String, ok: bool) -> void:
	print("%s : %s" % [quoi, "OK" if ok else "ÉCHEC"])
	if not ok:
		_echecs += 1
