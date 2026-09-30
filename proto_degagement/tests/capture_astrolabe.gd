extends Node

# Photographie l'Astrolabe dans le vrai jeu (⑩, 28/09), en jouant pour de vrai :
#   1. l'arrivée : le Ciel du Peintre, son cadeau (la pastille, « offerte », le point d'or sur l'onglet), le limbe à 100 ;
#   2. la ×10 offerte : aucune étoile prise, le compteur à 90, le cadeau parti ;
#   3. le Grand Ciel ; les probabilités de chaque ciel ;
#   4. « Plus que 7 » ; puis, le compteur à 95, un ×10 : le Full art garanti (au plus tard la 5ᵉ carte), jamais un sbire ;
#   5. la fermeture : le mot d'adieu, le Grand Ciel seul, sans onglets ; plus rien à invoquer au Peintre ;
#   6. sans étoile : les boutons éteints ;
#   7. l'Atlas : « Mes decks » en haut ; la liste des decks par-dessus, et son retour « ‹ L'Atlas ».
# Lancé en fenêtre (--headless ne dessine rien). Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_astrolabe.tscn -- <dossier>
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
	# un joueur de quelques jours : le pack ouvert, le tuto fait, 25 étoiles, pas encore passé par l'Astrolabe
	GS.cartes = {}
	for id in ["thor", "kitsune", "golem", "korrigan", "kelpie", "banshee", "wukong", "minotaure", "troll", "yeti"]:
		GS.cartes[id] = {"stade": mini(2, GS.stade_max(id)), "variante": "or" if id == "kitsune" else "base", "variantes": ["base"], "niveau": 3}
	for id in ["chinchin", "hommefeuilles", "follet"]:
		GS.cartes[id] = {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1}
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.etoiles = 25
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _scenario() -> void:
	await _attendre(1.2)
	_verifier("le point d'or sur l'onglet Astrolabe (le cadeau)", main.barre._tabs["astrolabe"]["point"].visible)
	main.barre._toucher("astrolabe")
	await _attendre(2.0)
	var a: AstrolabeEcran = main.ecran_astrolabe
	var c: CollectionScreen = main.ecran_collec
	_verifier("l'arrivée : le Ciel du Peintre (son cadeau attend)", a.portail == "peintre" and a._onglets.visible)
	_verifier("le cadeau : « offerte » sous le ×10, la pastille, le bouton allumé", a.lbl_cout_dix.text == "offerte" and a._cadeau.visible
		and not a.btn_dix.disabled and a.lbl_cout.text == "1 étoile")
	_verifier("le limbe : garanti dans 100 (« %s »)" % a._lbl_nombre.text, a._lbl_nombre.text == "100")
	_capture("peintre_cadeau")

	# ── 2. la ×10 offerte
	a.btn_dix.pressed.emit()
	_verifier("pendant la ×10, la bannière ne se dessine plus (la vitrine libérée)", not a._banniere.visible and a._vitrine == null)
	await _attendre(2.0)
	_capture("peintre_rituel")
	await _quand(func() -> bool: return c._multi_fini)
	await _attendre(1.2)
	_capture("peintre_x10_offerte")
	_verifier("offerte : aucune étoile prise, le compteur à 10", GS.etoiles == 25 and Portails.compte("peintre") == 10
		and not Portails.offerte_due("peintre"))
	c.btn_multi_fermer.pressed.emit()
	await _attendre(1.2)
	_verifier("retour : la bannière et sa vitrine reviennent", a._banniere.visible and a._vitrine != null)
	_verifier("le cadeau parti : plus de pastille, plus de point, « 10 étoiles »", not a._cadeau.visible and a.lbl_cout_dix.text == "10 étoiles"
		and not main.barre._tabs["astrolabe"]["point"].visible)
	_verifier("garanti dans 90 (« %s »)" % a._lbl_nombre.text, a._lbl_nombre.text == "90")
	_capture("peintre_90")

	# ── 3. le Grand Ciel, les probabilités
	(a._boutons_onglets["grand"] as Button).pressed.emit()
	await _attendre(1.6)
	_verifier("le Grand Ciel : la vitrine libérée", a.portail == "grand" and a._vitrine == null)
	_capture("grand_ciel")
	a.btn_invoquer.pressed.emit()
	await _quand(func() -> bool: return c._rev_fini)
	await _attendre(0.5)
	_verifier("au Grand Ciel : 1 étoile, le compteur du Peintre ne bouge pas", GS.etoiles == 24 and Portails.compte("peintre") == 10)
	c.btn_rev_fermer.pressed.emit()
	await _attendre(0.8)
	c.montrer_probas("grand")
	await _attendre(0.8)
	_capture("probas_grand")
	c.probas.visible = false
	c.montrer_probas("peintre")
	await _attendre(0.8)
	_capture("probas_peintre")
	c.probas.visible = false

	# ── 4. « Plus que 7 », puis le Full art garanti dans un ×10
	Portails.donnees("peintre")["n"] = 93
	(a._boutons_onglets["peintre"] as Button).pressed.emit()
	await _attendre(1.6)
	_verifier("à 93 : « PLUS QUE 7 » (%s %s)" % [a._lbl_garanti.text, a._lbl_nombre.text], a._lbl_garanti.text == "PLUS QUE" and a._lbl_nombre.text == "7")
	_capture("peintre_plus_que_7")
	Portails.donnees("peintre")["n"] = 95
	GS.changed.emit()
	await _attendre(0.3)
	a.btn_dix.pressed.emit()
	await _attendre(2.2)
	_capture("peintre_x10_rituel")
	await _quand(func() -> bool: return c._multi_fini)
	await _attendre(1.5)
	_capture("peintre_x10_garanti")
	var premier := -1
	for i in c._multi_lot.size():
		if c._multi_lot[i]["variante"] == "full":
			premier = i
			break
	_verifier("le Full art au plus tard à la 5ᵉ carte (la %dᵉ), jamais un sbire" % (premier + 1), premier >= 0 and premier <= 4
		and not GS.est_sbire(str(c._multi_lot[premier]["heros"]["id"])))
	_verifier("le ciel est refermé ; « Encore ×10 » a disparu", not Portails.ouvert("peintre") and not c.btn_multi_encore.visible)
	c.btn_multi_fermer.pressed.emit()
	await _attendre(1.6)

	# ── 5. la fermeture
	_verifier("le Grand Ciel seul, sans onglets", a.portail == "grand" and not a._onglets.visible)
	_verifier("le mot d'adieu, une fois", a._adieu != null and is_instance_valid(a._adieu) and not Portails.adieu_a_montrer("peintre"))
	_capture("adieu")
	_verifier("plus rien au Peintre (et rien de pris)", GS.invoquer_multi(1, "peintre").is_empty() and not GS.peut_invoquer(10, "peintre"))

	# ── 6. sans étoile
	GS.etoiles = 0
	GS.changed.emit()
	await _attendre(0.5)
	_verifier("sans étoile : les deux boutons éteints", a.btn_invoquer.disabled and a.btn_dix.disabled)
	_capture("sans_etoile")

	# ── 7. l'Atlas : « Mes decks » en haut
	main.barre._toucher("atlas")
	await _attendre(2.5)
	_verifier("l'Atlas : « Mes decks » en haut", c.btn_decks.visible and c._deck_contenu.get_child_count() > 0)
	_capture("atlas_mes_decks")
	c.btn_decks.pressed.emit()
	await _attendre(1.2)
	_verifier("la liste des decks par-dessus l'Atlas", c._decks.visible and not c._page.visible)
	var retour: Button = null
	for n in c._decks.find_children("*", "Button", true, false):
		if (n as Button).text.contains("L'Atlas"):
			retour = n
	_verifier("son retour : « ‹ L'Atlas »", retour != null)
	_capture("atlas_decks")
	if retour != null:
		retour.pressed.emit()
	await _attendre(0.8)
	_verifier("retour : l'Atlas", not c._decks.visible and c._page.visible)
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
	var err := img.save_png(dossier.path_join("astrolabe_%02d_%s.png" % [n_capture, nom]))
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _verifier(quoi: String, ok: bool) -> void:
	print("%s : %s" % [quoi, "OK" if ok else "ÉCHEC"])
	if not ok:
		_echecs += 1
