extends Node

# Construit toutes les cartes — chaque héros, chaque stade, chaque variante
# qui peut tomber, recto et verso — et laisse tourner quelques images pour
# que leur dessin s'exécute. Le test échoue si une erreur de script sort.
#
# C'est une SCÈNE (pas un --script) : sinon l'autoload GS n'existe pas.
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_cartes.tscn

var images := 0
var cartes: Array = []
var attendu := 0
var ecran: CollectionScreen
var multi_ok := true


func _process(_delta: float) -> void:
	images += 1
	if images == 2:
		var gs = get_node_or_null("/root/GS")
		if gs == null:
			print("ERREUR : l'autoload GS est absent")
			get_tree().quit(1)
			return
		for h in gs.HEROS:
			for s in range(1, (h["formes"] as Array).size() + 1):
				for v in ["base", "or", "ombre", "elem", "prisme", "full"]:
					var c := CarteView.new()
					add_child(c)
					c.configurer(h, s, v, 486.0, true)
					cartes.append(c)
					attendu += 1
			var dos := CarteView.new()
			add_child(dos)
			dos.configurer(h, 1, "base", 486.0, false)
			cartes.append(dos)
			attendu += 1
		# Les dos : un par variante (chacun trahit un peu sa rareté)
		for v in ["base", "or", "ombre", "elem", "prisme", "full"]:
			var d := CarteView.new()
			add_child(d)
			d.configurer(gs.HEROS[0], 1, v, 486.0, false)
			cartes.append(d)
			attendu += 1
		# Une carte en grand, qui suit le doigt, puis se retourne
		var grande := CarteView.new()
		grande.interactif = true
		add_child(grande)
		grande.configurer(gs.HEROS[1], 3, "prisme", 820.0, false)
		grande.montrer_recto(true)
		grande._suivre(Vector2(700, 200))
		cartes.append(grande)
		attendu += 1
	# Une vraie invocation ×10, déroulée jusqu'au bilan, sans rien sauvegarder
	if images == 3:
		GS.sauvegarde_active = false
		GS.etoiles += 20
		ecran = CollectionScreen.new()
		add_child(ecran)
		ecran._invoquer_dix()
	if images == 30:
		var appui := InputEventMouseButton.new()
		appui.button_index = MOUSE_BUTTON_LEFT
		appui.pressed = true
		ecran._multi_toucher(appui)
		if not ecran._multi_fini:
			print("ERREUR : toucher l'écran n'a pas tout retourné")
			multi_ok = false
		for c in ecran.multi_cartes:
			if not (c as CarteView).recto:
				print("ERREUR : une carte du ×10 est restée de dos")
				multi_ok = false
		print("bilan ×10 : " + ecran.multi_bilan.text.replace("
", " | "))
		ecran._ouvrir(str(ecran._multi_lot[0]["heros"]["id"]))
	if images == 90:
		var construites := 0
		for c in cartes:
			if is_instance_valid(c) and c.get_child_count() > 10:
				construites += 1
		print("cartes construites : %d / %d" % [construites, attendu])
		# attendu > 0 : un test qui n'a rien construit n'a rien prouvé.
		var ok := attendu > 0 and construites == attendu and multi_ok and ecran != null and ecran._multi_lot.size() == 10
		print("RESULTAT: " + ("OK" if ok else "ECHEC"))
		get_tree().quit(0 if ok else 1)
