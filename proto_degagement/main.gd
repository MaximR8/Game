extends Node2D

# Routeur d'écrans + bandeau du haut (bandeau.gd) + barre du bas (barre_nav.gd), sur le ciel
# commun, et la couche d'effets par-dessus tout (effets.gd). Le cadeau du jour se réclame au
# lancement. Un appui long sur l'onglet « Nébuleuse » montre ou cache les outils de test
# (dette D1) — dans les deux écrans.

var ciel: Ciel
var ecran_pousse: PusherScreen
var ecran_collec: CollectionScreen
var ecran_astrolabe: AstrolabeEcran     # les portails (28/09) : on y invoque ; l'Atlas révèle
var ecran_voyage: VoyageEcran
var ecran_presages: PresagesEcran
var combat: CarreEcran
var _combats := 0
var bandeau: Bandeau
var barre: BarreNav
var effets: Effets
var daily: Control
var accueil: Accueil               # le premier pack offert, guidé (28/09) ; null une fois fini
var outils_visibles := false
var _perf: Label                   # le compteur d'images, sur tous les écrans (outils de test, D4)
var _perf_t0 := 0
var _perf_images := 0
var _perf_pire := 0
var _perf_avant := 0


func _ready() -> void:
	# ⑦ L'essai 3D de la poussette : le même projet, exporté à part avec le drapeau
	# « essai3d » (préréglage « Web essai 3D », servi sur /essai/). Le jeu n'y passe jamais.
	if OS.has_feature("essai3d"):
		get_tree().change_scene_to_file.call_deferred("res://essais/essai_3d.tscn")
		return
	randomize()
	Input.set_use_accumulated_input(false)
	Reglages.charger()           # le son (ses deux bus) et les vibrations de CET appareil (29/09)

	ciel = Ciel.new()
	add_child(ciel)

	ecran_pousse = PusherScreen.new()
	ecran_pousse.size = Vector2(1080, 2400)
	add_child(ecran_pousse)

	ecran_collec = CollectionScreen.new()
	ecran_collec.size = Vector2(1080, 2400)
	ecran_collec.visible = false
	add_child(ecran_collec)

	ecran_astrolabe = AstrolabeEcran.new()
	ecran_astrolabe.visible = false
	ecran_astrolabe.atlas = ecran_collec
	add_child(ecran_astrolabe)
	ecran_collec.revelation_fermee.connect(ecran_astrolabe.apres_invocation)
	ecran_collec.multi_ferme.connect(ecran_astrolabe.apres_invocation)

	ecran_voyage = VoyageEcran.new()
	ecran_voyage.visible = false
	add_child(ecran_voyage)
	ecran_voyage.combattre.connect(_lancer_combat)

	bandeau = Bandeau.new()
	add_child(bandeau)
	ecran_pousse.bandeau = bandeau
	ecran_voyage.bandeau = bandeau
	barre = BarreNav.new()
	add_child(barre)
	barre.aller.connect(_aller_vers)
	# les Présages (28/09, ⑧) : les défis du jour ; l'onglet porte un point tant qu'il y a à recevoir
	ecran_presages = PresagesEcran.new()
	ecran_presages.visible = false
	ecran_presages.bandeau = bandeau
	ecran_presages.barre = barre
	ecran_presages.aller.connect(func(id: String): _aller_vers(id))
	add_child(ecran_presages)
	move_child(ecran_presages, ecran_voyage.get_index() + 1)
	GS.changed.connect(_maj_point_presages)
	_maj_point_presages()
	# l'Astrolabe porte un point tant que le cadeau du Ciel du Peintre attend (28/09)
	GS.changed.connect(_maj_point_astrolabe)
	_maj_point_astrolabe()
	barre.appui_long.connect(func(id: String):
		if id == "nebuleuse":
			_basculer_outils())
	effets = Effets.new()
	effets.size = Vector2(1080, 2400)
	add_child(effets)
	Effets.global = effets
	# le son (29/09) : un lecteur pour tout le jeu ; la musique démarre (le navigateur la libère au premier toucher)
	var son := Son.new()
	add_child(son)
	Son.global = son
	son.musique()
	# le compte (29/09, ⑥) : créé ou retrouvé en arrière-plan ; la partie part au serveur après chaque sauvegarde
	var compte := Compte.new()
	add_child(compte)
	Compte.global = compte
	_aller(true)
	_cadeau_du_jour()
	# un duel ou un classé resté en cours (app fermée en plein combat) compte comme perdu (arene.gd)
	Arene.solder_interrompu()
	_prechauffer_cartes()
	# le premier pack offert (28/09) : l'accueil montre le chemin, après le cadeau du jour s'il y en a un
	if GS.premier_pack_du():
		if daily != null and is_instance_valid(daily):
			daily.tree_exited.connect(func(): _accueillir.call_deferred(), CONNECT_ONE_SHOT)
		else:
			_accueillir()


func _accueillir() -> void:
	accueil = Accueil.new()
	accueil.jeu = self
	add_child(accueil)
	accueil.fini.connect(func(): accueil = null)
	accueil.commencer()


# 🔴 Les shaders des cartes se compilent à leur premier dessin : 150 à 300 ms d'arrêt, en
#    pleine ouverture de la collection ou en pleine invocation (mesuré le 25/09). On dessine
#    donc une carte de chaque variante, recto et verso, dès le démarrage, presque
#    transparentes, puis on les jette.
func _prechauffer_cartes() -> void:
	var boite := Control.new()
	boite.modulate = Color(1, 1, 1, 0.01)
	boite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boite.position = Vector2(20, 2000)
	add_child(boite)
	var h: Dictionary = GS.HEROS[0]
	var i := 0
	for v in ["base", "or", "ombre", "elem", "prisme", "full"]:
		for recto in [true, false]:
			var c := CarteView.new()
			boite.add_child(c)
			c.configurer(h, 1, v, 140.0, recto)
			c.position = Vector2(i * 70.0, 0)
			i += 1
	# 🔴 (28/09, « l'animation d'ouverture lag au début ») : l'élémentaire a ses effets propres à chaque type (fusion,
	#    brume, caustiques, rayons…) — une carte de chaque type ; et la carte en grand (Carte3D) a son shader.
	var types_vus := {str(h["type"]): true}
	for hh in GS.HEROS:
		var t := str(hh["type"])
		if types_vus.has(t):
			continue
		types_vus[t] = true
		var c := CarteView.new()
		boite.add_child(c)
		c.configurer(hh, 1, "elem", 140.0, true)
		c.position = Vector2(i * 70.0, 0)
		i += 1
	var c3 := Carte3D.new()
	boite.add_child(c3)
	c3.configurer(h, 1, "base", 140.0)
	c3.position = Vector2(i * 70.0, 0)
	for k in 4:
		await get_tree().process_frame
	boite.queue_free()


var _premier_aller := true
var _ecran_actif := ""
const ORDRE_ECRANS := ["nebuleuse", "astrolabe", "atlas", "voyage", "presages"]


func _aller(poussette: bool) -> void:
	_aller_vers("nebuleuse" if poussette else "atlas")


func _ecrans() -> Dictionary:
	return {"nebuleuse": ecran_pousse, "astrolabe": ecran_astrolabe, "atlas": ecran_collec, "voyage": ecran_voyage,
		"presages": ecran_presages}


func _aller_vers(id: String) -> void:
	var avant := _ecran_actif
	_ecran_actif = id
	var ecrans := _ecrans()
	for k in ecrans:
		(ecrans[k] as Control).visible = k == id
	_regler_temps()
	barre.montrer(id)
	if Son.global != null:
		Son.global.changer_musique(Son.musique_de(id), not _premier_aller)   # (29/09) la Nébuleuse a la sienne
	if id == "atlas":
		ecran_collec._rafraichir()
	elif id == "astrolabe":
		ecran_astrolabe.montrer()
	elif id == "voyage":
		ecran_voyage.rafraichir()
	elif id == "presages":
		ecran_presages.montrer()
	if accueil != null:
		accueil.ecran(id)
	if _premier_aller:
		_premier_aller = false
		return
	# 🔴 Un jeu ne « saute » pas d'une page à l'autre : l'écran arrive en glissant du côté
	#    de son onglet.
	if avant == id:
		return
	var ecran: Control = ecrans[id]
	ecran.position.x = -60.0 if ORDRE_ECRANS.find(id) < ORDRE_ECRANS.find(avant) else 60.0
	ecran.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ecran, "position:x", 0.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ecran, "modulate:a", 1.0, 0.2)


# ─────────────────────────────────────────────────────────────
# Le combat (le Carré des astres) : plein écran, sur le ciel ; ni bandeau ni barre
# ─────────────────────────────────────────────────────────────

func _lancer_combat(deck: Array, adversaire: Dictionary) -> void:
	_fermer_combat()
	_combats += 1
	if Son.global != null:
		Son.global.changer_musique("musique-combat")      # (29/09) le combat a sa musique
	if accueil != null:
		accueil.finir()
	# 🔴 Le tout premier combat est guidé (Maxim joue sans lire) : des cartes prêtées, un
	#    adversaire distrait, et un retournement dès le deuxième coup.
	if not bool(GS.voyage.get("tuto_carre", false)):
		deck = CarreEcran.DECK_TUTO.duplicate(true)
		adversaire = CarreEcran.ADV_TUTO.duplicate(true)
	# le Duel et le Classé : le combat est écrit dès qu'il commence (quitter ou fermer l'app = perdu)
	var arene := str(adversaire.get("mode", "")) in ["duel", "classe"]
	if arene:
		Arene.commencer(adversaire)
	combat = CarreEcran.new()
	add_child(combat)
	move_child(effets, -1)
	bandeau.visible = false
	barre.visible = false
	ecran_voyage.visible = false
	combat.modulate.a = 0.0
	combat.create_tween().tween_property(combat, "modulate:a", 1.0, 0.25)
	combat.quitte.connect(func():
		if arene and Arene.en_cours():
			Arene.terminer(adversaire, 0, 1, true)       # un abandon : une défaite
		_fermer_combat(true))
	combat.bandeau = bandeau
	combat.montrer_bandeau = _bandeau_par_dessus
	combat.fini.connect(func(r: Dictionary):
		if bool(r.get("rejouer", false)):
			_lancer_combat(deck, adversaire)
		elif r.has("encore"):
			# un nouvel adversaire, tout de suite ; un mois qui vient de changer : d'abord le Classé (sa saison finie)
			var mode := str(r["encore"])
			if mode == "classe" and Classe.saison_changee():
				_fermer_combat(true)
			else:
				_lancer_combat(Decks.deck_actif(), Arene.adversaire_suivant(mode))
		elif r.has("suivant"):
			_fermer_combat(true)
			ecran_voyage.ouvrir_avant(int(r["suivant"]))
		elif r.has("terre"):
			_fermer_combat(true)
			ecran_voyage.ouvrir_terre(int(r["terre"]))
		else:
			_fermer_combat(true))
	# Un niveau de l'Aventure est toujours le même : sa graine, et qui commence. Sinon, le premier
	# joueur alterne d'un combat à l'autre (le premier, c'est toi).
	var graine := int(adversaire["graine"]) if adversaire.has("graine") else randi()
	var premier := str(adversaire["premier"]) if adversaire.has("premier") else ("j" if _combats % 2 == 1 else "a")
	combat.lancer(deck, adversaire, graine, premier)
	_regler_temps()


# 🔴 LE TEMPS DU JEU NE RALENTIT QUE DANS LA NÉBULEUSE (27/09 — Maxim : « les cartes se retournent à des
#    vitesses différentes, des fois vite, des fois lent ; ça casse la dynamique »). Un seul pas de physique
#    par image (project.godot) garde la machine stable ; mais alors, quand une image dépasse 16 ms, TOUT le
#    temps du jeu n'avance que de 16 ms (INFRA § pièges) : les animations ralentissent avec l'image. Hors de
#    la machine, aucune physique ne tourne (elle se met en pause, pusher_screen § _visibilite) : le temps
#    suit la vraie horloge, une animation garde sa durée même si une image rame.
const PAS_NEBULEUSE := 1
const PAS_AILLEURS := 8


func _regler_temps() -> void:
	var machine := combat == null and _ecran_actif == "nebuleuse"
	Engine.max_physics_steps_per_frame = PAS_NEBULEUSE if machine else PAS_AILLEURS


# Le compteur d'images (outils de test, D4, réseau local seulement) : sur tous les écrans, combat compris,
# les images de la dernière seconde et la pire (en vraie horloge : le temps du jeu, lui, peut ralentir).
func _process(_delta: float) -> void:
	if not outils_visibles:
		if _perf != null and _perf.visible:
			_perf.visible = false
		return
	if _perf == null:
		_perf = Style.libelle(effets, "", Rect2(24, 4, 1000, 34), "fort", 26, Style.OR_VIF)
		_perf.add_theme_color_override("font_outline_color", Color("#0b0a10"))
		_perf.add_theme_constant_override("outline_size", 8)
	_perf.visible = true
	var t := Time.get_ticks_usec()
	if _perf_avant > 0:
		_perf_pire = maxi(_perf_pire, t - _perf_avant)
	_perf_avant = t
	_perf_images += 1
	if t - _perf_t0 >= 1_000_000:
		_perf.text = "%d images/s · pire image %d ms · %s" % [_perf_images, _perf_pire / 1000,
			"combat" if combat != null else _ecran_actif]
		_perf_t0 = t
		_perf_images = 0
		_perf_pire = 0


# À la fin d'un niveau : le bandeau revient, par-dessus le combat, pour recevoir les gains qui s'envolent.
func _bandeau_par_dessus() -> void:
	bandeau.visible = true
	move_child(bandeau, -1)
	move_child(effets, -1)


func _fermer_combat(revenir := false) -> void:
	if combat != null and is_instance_valid(combat):
		remove_child(combat)
		combat.queue_free()
		if revenir and Son.global != null:
			Son.global.changer_musique(Son.musique_de("voyage"))
	combat = null
	_regler_temps()
	if revenir:
		bandeau.visible = true
		barre.visible = true
		_aller_vers("voyage")


# 🔴 Dans le navigateur, le jeu passe en plein écran au premier toucher : plus de barre
#    d'adresse ni de boutons du navigateur (sauf installé sur l'écran d'accueil : il l'est déjà).
var _plein_ecran_demande := false


func _input(ev: InputEvent) -> void:
	if _plein_ecran_demande or not OS.has_feature("web"):
		return
	var b := ev as InputEventMouseButton
	if b == null or not b.pressed:
		return
	_plein_ecran_demande = true
	var installe = JavaScriptBridge.eval("window.matchMedia('(display-mode: standalone)').matches || window.matchMedia('(display-mode: fullscreen)').matches", true)
	if not bool(installe):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _maj_point_presages() -> void:
	if barre != null:
		barre.marquer("presages", Presages.a_recevoir() > 0)


func _maj_point_astrolabe() -> void:
	if barre != null:
		barre.marquer("astrolabe", Portails.offerte_due("peintre"))


# 🔴 Les outils de test (dettes D1, D4) ne s'ouvrent que chez Maxim : sur son réseau local
#    (192.168.…), jamais sur le jeu public des cousins (⑯, jeu.naspoizot.synology.me).
static func outils_permis() -> bool:
	if not OS.has_feature("web"):
		return true
	var hote := str(JavaScriptBridge.eval("window.location.hostname", true))
	return hote.begins_with("192.168.") or hote == "localhost" or hote == "127.0.0.1"


func _basculer_outils() -> void:
	if not outils_permis():
		return
	outils_visibles = not outils_visibles
	ecran_pousse.montrer_outils(outils_visibles)
	ecran_astrolabe.montrer_outils(outils_visibles)
	ecran_voyage.montrer_outils(outils_visibles)


# ─────────────────────────────────────────────────────────────
# Le cadeau du jour
# ─────────────────────────────────────────────────────────────

func _cadeau_du_jour() -> void:
	if not GS.daily_en_attente():
		return
	GS.claim_daily()

	daily = Control.new()
	daily.size = Vector2(1080, 2400)
	add_child(daily)
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.6)
	voile.size = Vector2(1080, 2400)
	daily.add_child(voile)

	var p := Style.panneau(daily, Rect2(90, 800, 900, 700), Color(0.047, 0.063, 0.059, 0.97), 44)
	Style.libelle(p, "CADEAU DU JOUR", Rect2(0, 56, 900, 40), "etiquette", 26, Style.OR_FILET, HORIZONTAL_ALIGNMENT_CENTER, 6)
	Style.icone(p, Style.objet("etoile-invocation"), Rect2(290, 130, 150, 150))
	Style.icone(p, Style.objet("poussiere-etoile"), Rect2(470, 142, 128, 128))
	# (29/09 : sur une ligne, à 50, la phrase débordait du panneau — « … poussières d'é » : elle passe sur deux lignes)
	Style.libelle(p, "Une étoile d'invocation et 30 poussières d'étoile", Rect2(60, 292, 780, 130), "normal", 48, Style.IVOIRE,
		HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	Style.libelle(p, "Ton plateau t'attend tel que tu l'as laissé.", Rect2(60, 428, 780, 90), "italique", 40,
		Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var ok := Style.bouton(p, "Merci", Rect2(80, 540, 740, 120), true, 52)
	ok.pressed.connect(func():
		Son.sonner("recevoir")
		daily.queue_free())
