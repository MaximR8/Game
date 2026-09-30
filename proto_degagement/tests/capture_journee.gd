extends Node

# Photographie la journée dans le vrai jeu (lot A de ⑧, 28/09) :
#   1. la Nébuleuse et son plateau du jour : 12 objets connus d'avance ; entamé ; vidé (« Revient demain ») ;
#   2. les Présages : les 3 défis (le point sur l'onglet), « Recevoir » (les pièces s'envolent vers la
#      Nébuleuse), le bonus des trois, la semaine prête ;
#   3. la Nébuleuse sans pièce : ce qu'elle dit.
# Vérifie en chemin : le plateau vidé ne pose plus d'objet ; recevoir donne une fois ; le point s'éteint.
# Lancé en fenêtre (--headless ne dessine rien). Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_journee.tscn -- <dossier>
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
	# une partie qui a fait l'Aventure jusqu'au 1er boss, sans cadeau du jour en attente
	GS.cartes = {}
	for id in ["thor", "kitsune", "golem", "korrigan", "kelpie", "banshee", "yeti", "minotaure"]:
		GS.cartes[id] = {"stade": 2, "variante": "base", "variantes": ["base"], "niveau": 3}
	GS.voyage = {"tuto_carre": true, "premier_pack": true, "aventure": {"etoiles": {"10": 1}, "coffres": {}}}
	GS.last_daily = Time.get_date_string_from_system()
	GS.etoiles = 3
	GS.poussiere = 400
	GS.main_pieces = 120
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _scenario() -> void:
	await _attendre(2.0)
	_capture("plateau_neuf")
	var p: PusherScreen = main.ecran_pousse
	# (29/09 : TOUT le plateau du jour est posé — plus trois objets qui reviennent)
	_verifier("le plateau neuf : 12 objets à gagner, les 12 sur le tas", Plateau.restants() == 12 and p.lots.size() == 12)
	for i in 5:
		await _gagner_un(p)
	await _attendre(1.0)
	_capture("plateau_entame")
	_verifier("entamé : 7 à gagner, 7 sur le tas, l'étoile ne revient pas",
		Plateau.restants() == 7 and p.lots.size() == 7 and Plateau.prochain(1) == "")
	while Plateau.restants() > 0:
		await _gagner_un(p)
	await _attendre(1.5)
	_capture("plateau_vide")
	var sur_tas := 0
	for l in p.lots:
		if not l.get_meta("gagne", false):
			sur_tas += 1
	_verifier("vidé : « Revient demain », et plus aucun objet posé (%d sur le tas, %d en route)" % [sur_tas, p.a_rendre.size()],
		Plateau.restants() == 0 and p.lbl_pj_fin.visible and p.a_rendre.is_empty() and sur_tas == 0)

	# ── 2. les Présages
	var d := Presages.donnees()
	Presages.evenement("combat", 3)
	Presages.evenement("duel", 2)
	Presages.evenement("aventure")
	Presages.evenement("retournement", 12)
	await _attendre(0.3)
	var a_recevoir := Presages.a_recevoir()
	_verifier("des défis à recevoir (%d) : le point est allumé" % a_recevoir, a_recevoir > 0 and main.barre._tabs["presages"].has("point")
		and (main.barre._tabs["presages"]["point"] as Control).visible)
	main.barre._toucher("presages")
	await _attendre(1.2)
	_capture("presages")
	var pieces0 := GS.main_pieces
	var bouton: Button = null
	for n in main.ecran_presages.find_children("*", "Button", true, false):
		if (n as Button).text == "Recevoir":
			bouton = n
			break
	_verifier("un « Recevoir »", bouton != null)
	bouton.pressed.emit()
	await _attendre(0.25)
	_capture("presages_recu_envol")
	await _attendre(1.2)
	_capture("presages_recu")
	_verifier("+%d pièces, et la réserve de la Nébuleuse le montre (« %s »)" % [Presages.PIECES_DEFI, main.ecran_pousse.lbl_main.text],
		GS.main_pieces == pieces0 + Presages.PIECES_DEFI and main.ecran_pousse.lbl_main.text == str(GS.main_pieces))
	# tout recevoir, puis la semaine prête
	for i in 4:
		for n in main.ecran_presages.find_children("*", "Button", true, false):
			if (n as Button).text == "Recevoir":
				(n as Button).pressed.emit()
				await _attendre(0.4)
				break
	var s: Dictionary = Presages.donnees()["semaine"]
	var lundi := Time.get_unix_time_from_datetime_string(str(s["id"]) + "T12:00:00")
	for k in 5:
		var j := Time.get_date_string_from_unix_time(lundi + k * 86400)
		if not (s["jours"] as Array).has(j):
			s["jours"].append(j)
	main.ecran_presages.montrer()
	main._maj_point_presages()
	await _attendre(0.8)
	_capture("semaine_prete")
	_verifier("la semaine prête", Presages.semaine_prete())

	# ── 3. la Nébuleuse sans pièce
	GS.main_pieces = 0
	GS.changed.emit()             # (comme le ferait n'importe quel gain : la réserve se relit)
	main.barre._toucher("nebuleuse")
	await _attendre(1.2)
	p.dernier_semis = Vector2(-9999, -9999)
	p._semer(Vector2(540, 620))
	await _attendre(0.4)
	_capture("sans_piece")
	_verifier("sans pièce : rien n'est lâché, et la réserve dit 0 (« %s »)" % p.lbl_main.text, GS.main_pieces == 0 and p.lbl_main.text == "0")
	print("RESULTAT: %s" % ("OK" if _echecs == 0 else "ÉCHEC (%d)" % _echecs))
	get_tree().quit(0 if _echecs == 0 else 1)


# Gagne un objet du plateau comme la machine : il passe le bord (_sur_gain), puis il quitte le plateau ; son
# remplaçant (s'il en reste aujourd'hui) arrive 1,4 s plus tard. (demo_gain, lui, laisse l'objet sur le tas.)
func _gagner_un(p: PusherScreen) -> void:
	for b in p.lots:
		if b.get_meta("gagne", false):
			continue
		b.set_meta("gagne", true)
		p._sur_gain(b)
		p.lots.erase(b)
		p.rendu.oublier(b)
		p.monde.remove_child(b)
		b.queue_free()
		break
	await _attendre(1.6)


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _capture(nom: String) -> void:
	n_capture += 1
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("journee_%02d_%s.png" % [n_capture, nom]))
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _verifier(quoi: String, ok: bool) -> void:
	print("%s : %s" % [quoi, "OK" if ok else "ÉCHEC"])
	if not ok:
		_echecs += 1
