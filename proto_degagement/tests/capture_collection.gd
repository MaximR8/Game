extends Node

# Photographie la collection dans le vrai jeu (⑧ lot B, 28/09) :
#   l'Atlas et ses éclats ; une carte qu'on n'a pas (« Obtenir · 900 éclats », deux touches) ; la même, obtenue, et
#   les variantes qui lui manquent avec leur prix (le Full art : « chance ») ; une carte au niveau maximum, qui demande
#   2 pierres pour son stade III ; les probabilités (la règle sans double) ; une invocation et une ×10 (leurs éclats).
# Vérifie en chemin : le prix payé, la carte entrée, les éclats reçus.
# Lancé en fenêtre (--headless ne dessine rien). Les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_collection.tscn -- <dossier>
#
# Ne sauvegarde rien : la sauvegarde est coupée pendant la séance.

var main: Node
var dossier := ""
var n_capture := 0
var _echecs := 0
var legende := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	GS.sauvegarde_active = false
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.cartes = {}
	for id in ["kitsune", "golem", "korrigan", "kelpie", "banshee", "yeti", "minotaure"]:
		GS.cartes[id] = {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 2}
	GS.cartes["thor"] = {"stade": 2, "variante": "or", "variantes": ["base", "or"], "niveau": 10}
	for id in ["chinchin", "hommefeuilles"]:
		GS.cartes[id] = {"stade": 1, "variante": "base", "variantes": ["base"], "niveau": 1}
	for id in GS.ids_du_rang("legende"):
		if not GS.cartes.has(id):
			legende = str(id)
			break
	GS.voyage = {"tuto_carre": true, "premier_pack": true}
	GS.last_daily = Time.get_date_string_from_system()
	GS.etoiles = 12
	GS.poussiere = 3000
	GS.eclats = 1250
	GS.pierres = {"foudre": 1}
	main = load("res://main.tscn").instantiate()
	add_child(main)
	_scenario()


func _scenario() -> void:
	await _attendre(1.2)
	main.barre._toucher("atlas")
	await _attendre(2.5)
	var c: CollectionScreen = main.ecran_collec
	_capture("atlas_eclats")
	_verifier("les éclats au-dessus de la grille (« %s »)" % c.lbl_eclats.text, c.lbl_eclats.text == Style.nombre(1250))

	c._ouvrir(legende)
	await _attendre(1.2)
	_capture("carte_a_obtenir")
	_verifier("une carte qu'on n'a pas : « Obtenir » (%s)" % c.btn_obtenir.text, c.btn_obtenir.visible and not c.btn_niveau.visible)
	c.btn_obtenir.pressed.emit()
	await _attendre(0.4)
	_capture("obtenir_sur")
	_verifier("une touche : « Sûr ? », rien n'est payé", GS.eclats == 1250 and not GS.cartes.has(legende))
	c.btn_obtenir.pressed.emit()
	await _attendre(1.2)
	_capture("obtenue")
	_verifier("deux touches : la Légende est à toi, 900 éclats payés", GS.cartes.has(legende) and GS.eclats == 350)

	c._ouvrir("thor")
	await _attendre(1.2)
	_capture("niveau_max")
	_verifier("Thor au niveau 10 : « Niveau maximum » (%s)" % c.btn_niveau.text.replace("\n", " "), c.btn_niveau.text.begins_with("Niveau maximum"))
	_verifier("son stade III demande 2 pierres (%s)" % c.btn_evo.text.replace("\n", " "), c.btn_evo.text.contains("2 pierres"))
	c.detail.visible = false
	c.selection = ""

	c.montrer_probas("grand")
	await _attendre(0.8)
	_capture("probas")
	c.probas.visible = false

	var e0 := GS.eclats
	c.invoquer_dans("grand", 1)        # (28/09 : on invoque dans l'Astrolabe ; ici, l'Atlas révèle)
	await _quand(func() -> bool: return c._rev_fini)
	await _attendre(1.0)
	_capture("revelation_eclats")
	_verifier("une invocation : +5 éclats au moins", GS.eclats >= e0 + 5)
	c.btn_rev_fermer.pressed.emit()
	await _attendre(0.8)
	var e1 := GS.eclats
	c.invoquer_dans("grand", 10)
	await _quand(func() -> bool: return c._multi_fini)
	await _attendre(1.2)
	_capture("multi_eclats")
	_verifier("une ×10 : +50 éclats au moins (%d)" % (GS.eclats - e1), GS.eclats >= e1 + 50 and c.multi_bilan.text.contains("éclats"))
	c.btn_multi_fermer.pressed.emit()
	await _attendre(0.6)

	# ── les rangs se voient (28/09) : la grille par sections, une Légende et un Héros révélés, une ×10 avec une Légende
	c.defil.scroll_vertical = 0
	await _attendre(1.5)
	_capture("rangs_grille")
	_verifier("la grille : les Légendes d'abord (« %s »)" % c.titres_rangs["legende"].text, c.titres_rangs["legende"].text.begins_with("LES LÉGENDES"))
	c.montrer_revelation(_resultat(legende, "base"))
	await _quand(func() -> bool: return c._rev_fini)
	await _attendre(0.5)
	_capture("rangs_revelation_legende")
	_verifier("révélée : « LÉGENDE » au-dessus de la carte (%s)" % c.rev_etiquette.text, c.rev_etiquette.text == "LÉGENDE")
	c.btn_rev_fermer.pressed.emit()
	await _attendre(0.4)
	c.montrer_revelation(_resultat("korrigan", "base"))
	await _quand(func() -> bool: return c._rev_fini)
	await _attendre(0.5)
	_capture("rangs_revelation_heros")
	_verifier("un Héros : « HÉROS »", c.rev_etiquette.text == "HÉROS")
	c.btn_rev_fermer.pressed.emit()
	await _attendre(0.4)
	var mythe := str(GS.ids_du_rang("mythe")[0])
	var lot := []
	for id in ["chinchin", "follet", "korrigan", "hommefeuilles", legende, "kelpie", mythe, "diable", "banshee", "yeti"]:
		lot.append(_resultat(id, "base"))
	c.montrer_multi(lot)
	await _quand(func() -> bool: return c._multi_etiquettes.size() > 0)
	await _attendre(0.45)
	_capture("rangs_multi_vedette_legende")
	await _quand(func() -> bool: return c._multi_fini)
	await _attendre(1.0)
	_capture("rangs_multi_fin")
	_verifier("la ×10 : le bilan compte la Légende et le Mythe (« %s »)" % c.multi_bilan.text.replace("
", " / "),
		c.multi_bilan.text.begins_with("1 Légende · 1 Mythe"))
	c.btn_multi_fermer.pressed.emit()
	await _attendre(0.4)
	c._ouvrir(legende)
	await _attendre(1.2)
	_capture("rangs_carte_grand")
	print("RESULTAT: %s" % ("OK" if _echecs == 0 else "ÉCHEC (%d)" % _echecs))
	get_tree().quit(0 if _echecs == 0 else 1)


# Un résultat d'invocation fabriqué (pour montrer un rang précis sans en tirer mille).
func _resultat(id: String, v: String) -> Dictionary:
	return {"heros": GS.heros(id), "variante": v, "nouvelle": false, "nouvelle_variante": false, "amelioree": false,
		"doublon": true, "eclats": 10}


func _attendre(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _quand(condition: Callable) -> void:
	var limite := Time.get_ticks_msec() + 40000
	while not condition.call():
		if Time.get_ticks_msec() > limite:
			_verifier("l'animation arrive où la photo l'attend", false)
			break
		await get_tree().process_frame


func _capture(nom: String) -> void:
	n_capture += 1
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(dossier.path_join("collection_%02d_%s.png" % [n_capture, nom]))
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _verifier(quoi: String, ok: bool) -> void:
	print("%s : %s" % [quoi, "OK" if ok else "ÉCHEC"])
	if not ok:
		_echecs += 1
