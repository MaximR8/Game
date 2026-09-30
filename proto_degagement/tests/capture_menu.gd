extends Node

# Photographie le Menu des Présages dans le vrai jeu (29/09) : les quatre médaillons sous les défis ; Compte scellé (sa
# bulle) ; les Réglages (les curseurs bougent le son, les vibrations se coupent) ; le Code cadeau (un bon code : reçu ;
# le même : « déjà » ; un faux : refusé).
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_menu.tscn -- <dossier>

var main: Node
var dossier := ""
var n_capture := 0
var _echecs := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	Reglages.actif = false
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.cartes = {}
	for id in ["thor", "kitsune", "golem", "korrigan", "kelpie", "banshee"]:
		GS.cartes[id] = {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1}
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.etoiles = 3
	Codes.table_test = {"v": 1, "sel": "s", "codes": {Codes.empreinte("BIENVENUE", "s"): {"recompense": {"etoiles": 5, "pierres": {"lune": 1}}, "fin": ""}}}
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _scenario() -> void:
	await _attendre(1.2)
	main.barre._toucher("presages")
	await _attendre(1.2)
	var e: PresagesEcran = main.ecran_presages
	_capture("menu")
	var boutons := []
	for n in e.get_children():
		if n is Button and (n as Button).flat:
			boutons.append(n)
	_verifier("quatre médaillons sous les défis (%d)" % boutons.size(), boutons.size() == 4)
	(boutons[0] as Button).pressed.emit()
	await _attendre(0.6)
	_verifier("le Compte s'ouvre (29/09)", e._panneau != null)
	_capture("compte")
	e._ouvrir_lier()
	await _attendre(0.6)
	_verifier("Lier mon compte : deux champs", e._champs.size() == 2)
	_capture("compte_lier")
	e._ouvrir_retrouver()
	await _attendre(0.6)
	_capture("compte_retrouver")
	e._confirmer_reprise({"partie": {"etoiles": 12, "poussiere": 480, "cartes": {"thor": {}, "golem": {}}}})
	await _attendre(0.6)
	_capture("compte_reprendre")

	# ── les réglages
	(boutons[2] as Button).pressed.emit()
	await _attendre(0.6)
	_verifier("les Réglages s'ouvrent", e._panneau != null)
	_capture("reglages")
	var curseurs := e._panneau.find_children("*", "HSlider", true, false)
	_verifier("deux curseurs", curseurs.size() == 2)
	(curseurs[0] as HSlider).value = 0.3
	(curseurs[1] as HSlider).value = 0.0
	_verifier("la musique à 30 %%, les effets muets", is_equal_approx(Reglages.musique, 0.3)
		and AudioServer.is_bus_mute(AudioServer.get_bus_index("Effets")))
	var vib: Button = null
	for n in e._panneau.find_children("*", "Button", true, false):
		if (n as Button).text == "Oui":
			vib = n
	_verifier("les vibrations : « Oui »", vib != null)
	vib.pressed.emit()
	await _attendre(0.3)
	_verifier("touchées : « Non », coupées", vib.text == "Non" and not Reglages.vibrations)
	_capture("reglages_changes")
	e._fermer_panneau()
	await _attendre(0.3)

	# ── le code cadeau
	(boutons[3] as Button).pressed.emit()
	await _attendre(0.6)
	_capture("code_vide")
	e._champ.text = "bien-venue"
	e._valider.pressed.emit()
	await _attendre(0.8)
	_verifier("un bon code : reçu (« %s »)" % e._message.text, e._message.text.begins_with("Reçu") and GS.etoiles == 8
		and int(GS.pierres.get("lune", 0)) == 1)
	_capture("code_recu")
	e._valider.pressed.emit()
	await _attendre(0.6)
	_verifier("le même : « déjà » (%s)" % e._message.text, e._message.text.contains("déjà") and GS.etoiles == 8)
	e._champ.text = "FAUX9999"
	e._valider.pressed.emit()
	await _attendre(0.6)
	_verifier("un faux : refusé (%s)" % e._message.text, e._message.text.contains("n'existe pas"))
	_capture("code_faux")
	print("RESULTAT: %s" % ("OK" if _echecs == 0 else "ÉCHEC (%d)" % _echecs))
	get_tree().quit(0 if _echecs == 0 else 1)


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _capture(nom: String) -> void:
	n_capture += 1
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("menu_%02d_%s.png" % [n_capture, nom]))
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _verifier(quoi: String, ok: bool) -> void:
	print("%s : %s" % [quoi, "OK" if ok else "ÉCHEC"])
	if not ok:
		_echecs += 1
