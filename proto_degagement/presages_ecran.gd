class_name PresagesEcran
extends Control

# ─────────────────────────────────────────────────────────────
# L'ÉCRAN DES PRÉSAGES (lot A de ⑧, 28/09) : les 3 défis du jour, le bonus des trois, le défi de la semaine.
# Depuis le 29/09, c'est aussi le MENU (Maxim : « la page Présages pourrait être un peu la page Menu ») : sous les défis
# (ce qu'on vient y chercher chaque jour), quatre médaillons — Compte (29/09 : la partie en ligne), Amis (scellé : il arrive plus tard),
# Réglages (reglages.gd : musique, effets, vibrations) et Code cadeau (codes.gd).
# Maxim joue sans lire : une ligne par défi, en gros ; sa barre ; ce qu'il rapporte (une icône, un
# chiffre) ; un seul bouton — « Y aller » (l'onglet où le faire), « Recevoir » (c'est fait), « Reçu ».
# Ce qu'on reçoit s'envole : les pièces vers l'onglet de la Nébuleuse (c'est là qu'elles servent), les
# étoiles et les pierres vers le bandeau.
# ─────────────────────────────────────────────────────────────

signal aller(id: String)

const FOND := Color(0.035, 0.05, 0.047, 0.92)
const JOURS := ["L", "M", "M", "J", "V", "S", "D"]

var bandeau: Bandeau
var barre: BarreNav


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func montrer() -> void:
	_fermer_panneau()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_construire()


func _construire() -> void:
	var d := Presages.donnees()
	Style.libelle(self, "Présages", Rect2(60, 240, 600, 110), "italique", 88, Style.IVOIRE)
	Style.libelle(self, "LES DÉFIS DU JOUR", Rect2(64, 344, 600, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var t := Time.get_time_dict_from_system()
	var heures := 23 - int(t["hour"])
	Style.libelle(self, "nouveaux dans %d h" % heures if heures >= 1 else "nouveaux à minuit", Rect2(600, 330, 420, 60), "italique", 36,
		Style.OR_VIF, HORIZONTAL_ALIGNMENT_RIGHT)
	var defis: Array = d["defis"]
	for k in defis.size():
		_defi(k, defis[k], 410.0 + k * 282.0)
	_bonus(d, 1262.0)
	_semaine(d, 1500.0)
	_menu(1864.0)


func _defi(k: int, e: Dictionary, y: float) -> void:
	var def: Dictionary = Presages.DEFIS[e["id"]]
	var p := Style.panneau(self, Rect2(40, y, 1000, 258), FOND, 34)
	var fait := Presages.fini(e)
	var recu := bool(e["recu"])
	# le médaillon de l'onglet où l'on fait ce défi
	var med := Control.new()
	med.position = Vector2(30, 40)
	med.size = Vector2(170, 170)
	med.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(med)
	Style.icone(med, Style.texture("res://interface/medaillon-%s.png" % ("jade" if fait else "sombre")), Rect2(0, 0, 170, 170))
	Style.icone(med, Style.texture("res://interface/nav-%s.png" % def["groupe"]), Rect2(38, 38, 94, 94))
	Style.libelle(p, str(def["texte"]), Rect2(228, 30, 750, 70), "italique", 46, Style.IVOIRE if not recu else Style.SOURD)
	var n := int(def["n"])
	var f := float(e["fait"]) / n
	Dessin.ajouter(p, Rect2(230, 112, 470, 30), func(ci: CanvasItem):
		ci.draw_style_box(Style.boite(Color("#0b1411"), 15, Color(Style.OR, 0.5), 2), Rect2(0, 0, 470, 30))
		if f > 0.0:
			ci.draw_style_box(Style.boite(Style.JADE_F if not fait else Style.OR_VIF, 11, Color(0, 0, 0, 0), 0),
				Rect2(4, 4, maxf(22.0, 462.0 * f), 22)))
	Style.libelle(p, "%d / %d" % [int(e["fait"]), n], Rect2(716, 98, 250, 58), "fort", 36, Style.IVOIRE, HORIZONTAL_ALIGNMENT_RIGHT)
	Style.icone(p, Style.objet("piece-etoile"), Rect2(230, 168, 64, 64))
	Style.libelle(p, "× %d" % Presages.PIECES_DEFI, Rect2(302, 168, 200, 64), "fort", 38, Style.OR_VIF)
	var b: Button
	if recu:
		Style.libelle(p, "Reçu", Rect2(690, 164, 280, 76), "italique", 40, Style.JADE, HORIZONTAL_ALIGNMENT_RIGHT)
		return
	if fait:
		b = Style.bouton(p, "Recevoir", Rect2(660, 158, 310, 84), true, 38)
		b.pressed.connect(func(): _recevoir(k, b))
	else:
		b = Style.bouton(p, "Y aller", Rect2(660, 158, 310, 84), false, 36)
		b.pressed.connect(func(): aller.emit(str(def["groupe"])))


# Les trois défis reçus : une pierre de lune.
func _bonus(d: Dictionary, y: float) -> void:
	var p := Style.panneau(self, Rect2(40, y, 1000, 210), FOND, 34)
	Style.libelle(p, "LES 3 DÉFIS DU JOUR", Rect2(40, 26, 600, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var defis: Array = d["defis"]
	for k in defis.size():
		var ok := bool(defis[k]["recu"])
		Dessin.ajouter(p, Rect2(44 + k * 66.0, 96, 56, 56), func(ci: CanvasItem):
			ci.draw_circle(Vector2(28, 28), 24.0, Color(Style.JADE, 0.9) if ok else Color(0, 0, 0, 0.3))
			ci.draw_arc(Vector2(28, 28), 24.0, 0.0, TAU, 32, Style.JADE if ok else Color(Style.OR, 0.4), 3.0, true))
	Style.icone(p, Style.objet("pierre-lune"), Rect2(290, 86, 80, 80))
	Style.libelle(p, "× %d" % Presages.LUNE_BONUS, Rect2(378, 86, 160, 80), "fort", 40, Style.OR_VIF)
	if bool(d["bonus"]):
		Style.libelle(p, "Reçu", Rect2(690, 90, 280, 76), "italique", 40, Style.JADE, HORIZONTAL_ALIGNMENT_RIGHT)
	elif Presages.bonus_pret():
		var b := Style.bouton(p, "Recevoir", Rect2(660, 84, 310, 84), true, 38)
		b.pressed.connect(func(): _recevoir("bonus", b))
	else:
		Style.libelle(p, "les trois reçus", Rect2(600, 90, 370, 76), "italique", 34, Style.SOURD, HORIZONTAL_ALIGNMENT_RIGHT)


# La semaine : les jours où les trois défis ont été faits (du lundi au dimanche) ; à 5, 3 étoiles et 200 pièces.
func _semaine(d: Dictionary, y: float) -> void:
	var s: Dictionary = d["semaine"]
	var p := Style.panneau(self, Rect2(40, y, 1000, 330), FOND, 34)
	Style.libelle(p, "LE DÉFI DE LA SEMAINE", Rect2(40, 26, 600, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	Style.libelle(p, "Tes 3 défis, %d jours cette semaine" % Presages.JOURS_SEMAINE, Rect2(40, 70, 920, 64), "italique", 42, Style.IVOIRE)
	var faits: Array = s["jours"]
	var lundi := Time.get_unix_time_from_datetime_string(str(s["id"]) + "T12:00:00")
	for k in 7:
		var jour := Time.get_date_string_from_unix_time(lundi + k * 86400)
		var ok := faits.has(jour)
		var c := Vector2(70.0 + k * 74.0, 186.0)
		Dessin.ajouter(p, Rect2(c - Vector2(30, 30), Vector2(60, 60)), func(ci: CanvasItem):
			ci.draw_circle(Vector2(30, 30), 27.0, Color(Style.OR_VIF, 0.2) if ok else Color(0, 0, 0, 0.3))
			ci.draw_arc(Vector2(30, 30), 27.0, 0.0, TAU, 32, Style.OR_VIF if ok else Color(Style.OR, 0.35), 3.0, true))
		Style.libelle(p, JOURS[k], Rect2(c.x - 30, c.y - 30, 60, 60), "fort", 28, Style.OR_VIF if ok else Style.SOURD,
			HORIZONTAL_ALIGNMENT_CENTER)
	Style.libelle(p, "%d / %d" % [mini(faits.size(), Presages.JOURS_SEMAINE), Presages.JOURS_SEMAINE], Rect2(560, 156, 120, 60), "fort", 36,
		Style.IVOIRE)
	Style.icone(p, Style.objet("etoile-invocation"), Rect2(40, 240, 64, 64))
	Style.libelle(p, "× %d" % Presages.ETOILES_SEMAINE, Rect2(112, 240, 120, 64), "fort", 38, Style.OR_VIF)
	Style.icone(p, Style.objet("piece-etoile"), Rect2(240, 240, 64, 64))
	Style.libelle(p, "× %d" % Presages.PIECES_SEMAINE, Rect2(312, 240, 160, 64), "fort", 38, Style.OR_VIF)
	if bool(s["recu"]):
		Style.libelle(p, "Reçu", Rect2(690, 236, 280, 76), "italique", 40, Style.JADE, HORIZONTAL_ALIGNMENT_RIGHT)
	elif Presages.semaine_prete():
		var b := Style.bouton(p, "Recevoir", Rect2(660, 230, 310, 84), true, 38)
		b.pressed.connect(func(): _recevoir("semaine", b))


# Recevoir : le bandeau retient d'abord ce qui va s'envoler (sinon son compteur sauterait), on donne,
# puis tout s'envole — les pièces vers l'onglet de la Nébuleuse, le reste vers le bandeau.
func _recevoir(quoi, b: Button) -> void:
	var prevu := {}
	if typeof(quoi) == TYPE_STRING and quoi == "bonus":
		prevu = {"pierres": Presages.LUNE_BONUS}
	elif typeof(quoi) == TYPE_STRING and quoi == "semaine":
		prevu = {"etoiles": Presages.ETOILES_SEMAINE}
	var en_vol := bandeau != null and bandeau.is_visible_in_tree() and Effets.global != null
	if en_vol:
		for cle in prevu:
			bandeau.retenir(cle, int(prevu[cle]))
	var g := Presages.recevoir(quoi)
	var depart := b.get_global_rect().get_center()
	if g.is_empty():
		if en_vol:
			for cle in prevu:
				bandeau.retenir(cle, -int(prevu[cle]))
		montrer()
		return
	Reglages.vibrer(25)
	Son.sonner("recevoir")
	if Effets.global != null:
		Effets.global.etincelles(Rect2(depart - Vector2(150, 40), Vector2(300, 80)), 6, 24.0)
		var pieces := int(g.get("pieces", 0))
		if pieces > 0 and barre != null:
			var cible := barre.rect_onglet("nebuleuse").get_center()
			for i in 5:
				get_tree().create_timer(0.06 * i).timeout.connect(func():
					Effets.global.envoler(Style.objet("piece-etoile"), depart, cible, 70.0, 0.7, func(): pass))
	if en_vol:
		for cle in prevu:
			var n := int(prevu[cle])
			var image := "etoile-invocation" if cle == "etoiles" else "pierre-lune"
			Effets.global.envoler(Style.objet(image), depart, bandeau.centre_icone(cle), 110.0, 1.0,
				func(): bandeau.recevoir(cle, n, image))
	montrer()



# ─────────────────────────────────────────────────────────────
# LE MENU (29/09) : quatre médaillons sous les défis. Le Compte dit où est la partie ; les Amis sont scellés ;
# Réglages et Code cadeau ouvrent chacun leur panneau, par-dessus la page.
# ─────────────────────────────────────────────────────────────

const MENU := [["compte", "Compte"], ["amis", "Amis"], ["reglages", "Réglages"], ["code", "Code cadeau"]]
var _panneau: Control            # le panneau ouvert (Réglages, Code cadeau), ou null


func _menu(y: float) -> void:
	var l := 1000.0 / MENU.size()
	for k in MENU.size():
		var id: String = MENU[k][0]
		var scelle := id == "amis"            # (29/09 : le Compte s'ouvre — le serveur est là ; les Amis, plus tard)
		var cx := 40.0 + l * (k + 0.5)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(cx - 90, y)
		b.size = Vector2(180, 196)
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		add_child(b)
		var med := Control.new()
		med.position = Vector2(25, 0)
		med.size = Vector2(130, 130)
		med.mouse_filter = Control.MOUSE_FILTER_IGNORE
		med.modulate = Color(0.55, 0.55, 0.55, 1.0) if scelle else Color.WHITE
		b.add_child(med)
		Style.icone(med, Style.texture("res://interface/medaillon-sombre.png"), Rect2(0, 0, 130, 130))
		Dessin.ajouter(med, Rect2(0, 0, 130, 130), func(ci: CanvasItem): _icone_menu(ci, id, Vector2(65, 65)))
		if scelle:
			Dessin.ajouter(b, Rect2(118, 88, 40, 40), func(ci: CanvasItem): Dessin.cadenas(ci, Vector2(20, 20), 1.0))
		Style.libelle(b, str(MENU[k][1]), Rect2(-10, 138, 200, 50), "normal", 32, Style.SOURD if scelle else Style.IVOIRE,
			HORIZONTAL_ALIGNMENT_CENTER)
		Style.jeu(b, med)
		b.pressed.connect(func():
			if id == "compte":
				_ouvrir_compte()
			elif id == "reglages":
				_ouvrir_reglages()
			elif id == "code":
				_ouvrir_code()
			else:
				Style.bulle(med, "Arrive avec les comptes"))


# Les icônes du menu, tracées à l'or, net (pas d'image) : une silhouette, deux, une roue dentée, un paquet noué.
func _icone_menu(ci: CanvasItem, id: String, c: Vector2) -> void:
	var o := Style.OR_VIF
	match id:
		"compte":
			ci.draw_arc(c + Vector2(0, -13), 14.0, 0.0, TAU, 32, o, 5.0, true)
			ci.draw_arc(c + Vector2(0, 30), 25.0, PI * 1.08, PI * 1.92, 24, o, 5.0, true)
		"amis":
			for dx in [-14.0, 16.0]:
				ci.draw_arc(c + Vector2(dx, -13), 11.0, 0.0, TAU, 28, o, 4.5, true)
				ci.draw_arc(c + Vector2(dx, 26), 19.0, PI * 1.1, PI * 1.9, 20, o, 4.5, true)
		"reglages":
			for i in 8:
				var d := Vector2.from_angle(i * TAU / 8.0)
				ci.draw_line(c + d * 17.0, c + d * 27.0, o, 8.0, true)
			ci.draw_arc(c, 19.0, 0.0, TAU, 40, o, 5.0, true)
			ci.draw_arc(c, 7.0, 0.0, TAU, 20, o, 4.0, true)
		"code":
			ci.draw_rect(Rect2(c + Vector2(-24, -6), Vector2(48, 32)), o, false, 4.5, true)
			ci.draw_rect(Rect2(c + Vector2(-28, -16), Vector2(56, 11)), o, false, 4.5, true)
			ci.draw_line(c + Vector2(0, -16), c + Vector2(0, 26), o, 4.5, true)
			ci.draw_arc(c + Vector2(-9, -22), 8.0, PI * 0.2, PI * 1.6, 16, o, 4.0, true)
			ci.draw_arc(c + Vector2(9, -22), 8.0, PI * -0.6, PI * 0.8, 16, o, 4.0, true)


# Un panneau par-dessus la page (voile, panneau à double filet, « Fermer »).
func _nouveau_panneau(titre: String, h: float) -> Panel:
	_fermer_panneau()
	_panneau = Control.new()
	_panneau.size = size
	add_child(_panneau)
	var voile := ColorRect.new()
	voile.color = Color(0.016, 0.024, 0.022, 0.9)
	voile.size = size
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	_panneau.add_child(voile)
	var p := Style.panneau(_panneau, Rect2(60, (2400.0 - h) * 0.5 - 60.0, 960, h), Color(0.047, 0.063, 0.059, 0.98), 44)
	Style.libelle(p, titre, Rect2(0, 44, 960, 100), "italique", 76, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	var f := Style.bouton(p, "Fermer", Rect2(230, h - 150, 500, 110), false, 44)
	f.pressed.connect(_fermer_panneau)
	p.pivot_offset = p.size * 0.5
	p.scale = Vector2(0.94, 0.94)
	p.create_tween().tween_property(p, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return p


func _fermer_panneau() -> void:
	_champ_web(false)
	if _panneau != null and is_instance_valid(_panneau):
		remove_child(_panneau)
		_panneau.queue_free()
	_panneau = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_fermer_panneau()


# ── Le compte (29/09, ⑥) ─────────────────────────────────────
# Ce que le joueur a besoin de savoir : sa partie est-elle à l'abri, et depuis quand. Et, pour la retrouver sur un autre
# téléphone : « Lier mon compte » (un mail, un mot de passe) sur celui qui a la partie, « J'ai déjà un compte » sur l'autre
# (Compte.lier_mail, retrouver, adopter). Google : la suite.

const RAISONS_COMPTE := {"reseau": "Pas de connexion : réessaie dans un instant.",
	"pris": "Ce mail a déjà un compte : sur ce téléphone, touche « J'ai déjà un compte ».",
	"mail": "Ce mail n'a pas l'air juste. Vérifie-le.", "mdp_court": "Le mot de passe : 8 caractères au moins.",
	"mdp": "Mot de passe faux.", "inconnu": "Aucun compte n'a ce mail.", "autre": "Ça n'a pas marché : réessaie."}


func _ouvrir_compte() -> void:
	var p := _nouveau_panneau("Compte", 1180.0)
	var etat := Style.libelle(p, "", Rect2(60, 170, 840, 110), "normal", 40, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var quand := Style.libelle(p, "", Rect2(60, 285, 840, 60), "italique", 34, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	var qui := Style.libelle(p, "", Rect2(60, 350, 840, 50), "etiquette", 24, Style.OR_FILET, HORIZONTAL_ALIGNMENT_CENTER, 5)
	var lie := Style.libelle(p, "", Rect2(60, 440, 840, 200), "italique", 36, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var lier := Style.bouton(p, "Lier mon compte", Rect2(180, 470, 600, 120), true, 44)
	var deja := Style.bouton(p, "J'ai déjà un compte", Rect2(180, 620, 600, 110), false, 40)
	var aide := Style.libelle(p, "Retrouve ta partie sur un autre téléphone, avec ton mail.", Rect2(80, 750, 800, 110),
		"italique", 32, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	lier.pressed.connect(_ouvrir_lier)
	deja.pressed.connect(_ouvrir_retrouver)
	var maj := func():
		var c := Compte.global
		var actif := c != null and c.actif
		if not actif:
			etat.text = "Ta partie est sur ce téléphone."
			quand.text = ""
			qui.text = ""
		else:
			etat.text = "Ta partie est sauvegardée en ligne." if c.en_ligne and c.envoye_le > 0 \
				else "Pas de réseau : ta partie reste sur ce téléphone, elle partira dès que possible."
			quand.text = "Dernière sauvegarde en ligne : %s" % Compte.depuis(c.envoye_le) if c.envoye_le > 0 else ""
			qui.text = ("JOUEUR N° " + c.utilisateur.substr(0, 8).to_upper()) if c.utilisateur != "" else ""
		var est_lie := actif and c.mail != ""
		lie.visible = est_lie
		lie.text = ("Compte lié à %s.\nSur un autre téléphone : « J'ai déjà un compte », ce mail, ton mot de passe." % Compte.masquer(c.mail)) if est_lie else ""
		for n in [lier, deja, aide]:
			n.visible = not est_lie
	maj.call()
	if Compte.global != null:
		Compte.global.change.connect(maj)
		p.tree_exiting.connect(func():
			if Compte.global != null and Compte.global.change.is_connected(maj):
				Compte.global.change.disconnect(maj))
		if Compte.global.actif and Compte.global._a_envoyer:
			Compte.global.envoyer()                       # ouvrir le panneau : la partie part tout de suite


# Deux champs (le mail, le mot de passe), un bouton, un message — pour lier et pour retrouver.
func _formulaire(titre: String, phrase: String, action: String) -> Dictionary:
	var p := _nouveau_panneau(titre, 1260.0)
	Style.libelle(p, phrase, Rect2(60, 160, 840, 110), "italique", 34, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	_saisie(p, "champ-mail", Rect2(100, 300, 760, 96), "ton mail", false, "email")
	_saisie(p, "champ-mdp", Rect2(100, 450, 760, 96), "mot de passe (8 caractères ou plus)", true, "password")
	var b := Style.bouton(p, action, Rect2(180, 610, 600, 120), true, 44)
	var m := Style.libelle(p, "", Rect2(60, 760, 840, 150), "italique", 34, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var retour := Style.bouton(p, "Retour", Rect2(330, 940, 300, 90), false, 36)
	retour.pressed.connect(_ouvrir_compte)
	return {"panneau": p, "bouton": b, "message": m}


func _ouvrir_lier() -> void:
	var f := _formulaire("Lier mon compte", "Ta partie, attachée à ton mail : tu la retrouveras sur un autre téléphone.", "Lier")
	var b: Button = f["bouton"]
	var m: Label = f["message"]
	b.pressed.connect(func():
		if Compte.global == null or not Compte.global.actif:
			return
		var adresse := _valeur("champ-mail")
		var mdp := _valeur("champ-mdp")
		if not adresse.contains("@") or mdp.length() < 8:
			_dire_dans(m, RAISONS_COMPTE["mail" if not adresse.contains("@") else "mdp_court"], Color("#ec8f9a"))
			Style.trembler(b)
			return
		b.disabled = true
		_dire_dans(m, "Je lie ton compte…", Style.SOURD)
		var raison: String = await Compte.global.lier_mail(adresse, mdp)
		if not is_instance_valid(b):
			return
		b.disabled = false
		if raison != "":
			_dire_dans(m, str(RAISONS_COMPTE.get(raison, RAISONS_COMPTE["autre"])), Color("#ec8f9a"))
			Style.trembler(b)
			return
		Son.sonner("recevoir")
		_dire_dans(m, "C'est fait : ta partie te suit. Garde bien ton mot de passe.", Style.JADE)
		get_tree().create_timer(1.8).timeout.connect(func():
			if is_instance_valid(b):
				_ouvrir_compte()))


func _ouvrir_retrouver() -> void:
	var f := _formulaire("J'ai déjà un compte", "Le mail et le mot de passe de ton compte : ta partie revient ici.", "Retrouver ma partie")
	var b: Button = f["bouton"]
	var m: Label = f["message"]
	b.pressed.connect(func():
		if Compte.global == null or not Compte.global.actif:
			return
		var adresse := _valeur("champ-mail")
		var mdp := _valeur("champ-mdp")
		if not adresse.contains("@") or mdp == "":
			_dire_dans(m, "Ton mail et ton mot de passe.", Color("#ec8f9a"))
			Style.trembler(b)
			return
		b.disabled = true
		_dire_dans(m, "Je cherche ta partie…", Style.SOURD)
		var t: Dictionary = await Compte.global.retrouver(adresse, mdp)
		if not is_instance_valid(b):
			return
		b.disabled = false
		if str(t.get("erreur", "")) != "":
			_dire_dans(m, str(RAISONS_COMPTE.get(str(t["erreur"]), RAISONS_COMPTE["autre"])), Color("#ec8f9a"))
			Style.trembler(b)
			return
		_confirmer_reprise(t))


# Avant de remplacer : ce que contient la partie du compte, et ce qu'on quitte. Deux boutons, rien d'irréversible avant.
func _confirmer_reprise(t: Dictionary) -> void:
	var partie: Dictionary = t.get("partie", {})
	var p := _nouveau_panneau("Ta partie", 1080.0)
	var cartes := (partie.get("cartes", {}) as Dictionary).size() if typeof(partie.get("cartes")) == TYPE_DICTIONARY else 0
	var texte := ("Sur ton compte : %d étoiles · %d poussières · %d cartes." % [int(partie.get("etoiles", 0)),
		int(partie.get("poussiere", 0)), cartes]) if not partie.is_empty() else "Ton compte n'a pas encore de partie."
	Style.libelle(p, texte, Rect2(60, 180, 840, 120), "normal", 38, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	Style.libelle(p, "Elle remplace la partie de ce téléphone (%d étoiles · %d cartes)." % [GS.etoiles, GS.cartes.size()],
		Rect2(60, 320, 840, 110), "italique", 34, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var oui := Style.bouton(p, "Reprendre ma partie", Rect2(160, 480, 640, 120), true, 42)
	var non := Style.bouton(p, "Annuler", Rect2(330, 640, 300, 90), false, 36)
	var m := Style.libelle(p, "", Rect2(60, 760, 840, 110), "italique", 34, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	non.pressed.connect(_ouvrir_compte)
	oui.disabled = partie.is_empty()
	oui.pressed.connect(func():
		oui.disabled = true
		_dire_dans(m, "Un instant…", Style.SOURD)
		if not await Compte.global.adopter(t):
			if is_instance_valid(oui):
				oui.disabled = false
				_dire_dans(m, RAISONS_COMPTE["autre"], Color("#ec8f9a"))
			return
		GS.lire_sauvegarde(partie, true)            # la machine à pièces de CE téléphone reste la sienne
		GS.save_game()
		get_tree().reload_current_scene())           # tout l'écran repart de la partie reprise


func _dire_dans(m: Label, texte: String, couleur: Color) -> void:
	if is_instance_valid(m):
		m.text = texte
		m.add_theme_color_override("font_color", couleur)


# Un champ de texte : hors du web, un champ Godot ; sur le web, un VRAI champ de la page par-dessus (le clavier du téléphone
# ne vient que pour lui) — comme le code cadeau. Ils partent avec le panneau (_fermer_panneau → _champ_web(false)).
var _champs := {}


func _saisie(p: Control, id: String, r: Rect2, indice: String, secret: bool, type: String) -> void:
	var cadre := Panel.new()
	cadre.position = r.position - Vector2(20, 12)
	cadre.size = r.size + Vector2(40, 24)
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cadre.add_theme_stylebox_override("panel", Style.boite(Color(0.02, 0.03, 0.03, 1.0), 24, Style.OR, 3))
	p.add_child(cadre)
	var le := LineEdit.new()
	le.position = r.position
	le.size = r.size
	le.alignment = HORIZONTAL_ALIGNMENT_CENTER
	le.placeholder_text = indice
	le.secret = secret
	le.add_theme_font_override("font", Style.police("normal"))
	le.add_theme_font_size_override("font_size", 40)
	le.add_theme_color_override("font_color", Style.OR_VIF)
	le.add_theme_color_override("font_placeholder_color", Color(Style.SOURD, 0.5))
	for st in ["normal", "focus", "read_only"]:
		le.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	p.add_child(le)
	_champs[id] = le
	if OS.has_feature("web"):
		le.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(cadre):
			_champ_html(id, cadre.get_global_rect(), type, indice)


func _champ_html(id: String, r: Rect2, type: String, indice: String) -> void:
	var t := get_viewport().get_final_transform()
	var a := t * r.position
	var b := t * r.end
	var f := Vector2(DisplayServer.window_get_size())
	var js := "(function(){ var c = document.querySelector('canvas'); var r = c.getBoundingClientRect();"
	js += " var i = document.getElementById('%s'); if (!i) { i = document.createElement('input'); i.id = '%s'; i.className = 'champ-jeu'; document.body.appendChild(i); }" % [id, id]
	js += " i.type = '%s'; i.autocomplete = '%s'; i.setAttribute('autocapitalize', 'none'); i.spellcheck = false; i.maxLength = 80;" % [type, "email" if type == "email" else "current-password"]
	js += " i.placeholder = '%s'; i.value = ''; var s = i.style; s.position = 'fixed'; s.zIndex = '10'; s.boxSizing = 'border-box';" % indice.replace("'", "’")
	js += " s.left = (r.left + %f * r.width) + 'px'; s.top = (r.top + %f * r.height) + 'px';" % [a.x / f.x, a.y / f.y]
	js += " s.width = (%f * r.width) + 'px'; s.height = (%f * r.height) + 'px';" % [(b.x - a.x) / f.x, (b.y - a.y) / f.y]
	js += " s.fontSize = (%f * r.height) + 'px'; s.fontFamily = 'Georgia, serif'; s.textAlign = 'center';" % [0.3 * (b.y - a.y) / f.y]
	js += " s.color = '#f1d28a'; s.background = 'transparent'; s.border = '0'; s.outline = 'none'; s.userSelect = 'text'; s.webkitUserSelect = 'text';"
	js += " s.touchAction = 'auto'; s.caretColor = '#7fd0b0'; })();"
	JavaScriptBridge.eval(js, true)


func _valeur(id: String) -> String:
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(document.getElementById('%s') || {}).value || ''" % id, true)
		return str(v).strip_edges() if v != null else ""
	var le = _champs.get(id)
	return (le as LineEdit).text.strip_edges() if le != null and is_instance_valid(le) else ""


# ── Les réglages ─────────────────────────────────────────────

func _ouvrir_reglages() -> void:
	var p := _nouveau_panneau("Réglages", 1040.0)
	_curseur(p, 190.0, "MUSIQUE", Reglages.musique, func(v: float):
		Reglages.musique = v
		Reglages.sauver())
	_curseur(p, 400.0, "EFFETS", Reglages.effets, func(v: float):
		Reglages.effets = v
		Reglages.sauver())
	Style.libelle(p, "VIBRATIONS", Rect2(80, 620, 400, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var vb := Style.bouton(p, "", Rect2(560, 598, 320, 90), false, 38)
	var maj_vb := func():
		vb.text = "Oui" if Reglages.vibrations else "Non"
		Style.habiller(vb, "jade" if Reglages.vibrations else "sombre")
	maj_vb.call()
	vb.pressed.connect(func():
		Reglages.vibrations = not Reglages.vibrations
		Reglages.sauver()
		maj_vb.call()
		Reglages.vibrer(30))
	Style.libelle(p, "Sons : Kenney et OpenGameArt (CC0) · Police : Castoro", Rect2(60, 760, 840, 90), "italique", 28, Style.SOURD,
		HORIZONTAL_ALIGNMENT_CENTER, 0, true)


# Un curseur : son nom, sa valeur en %, la glissière (une piste d'or, la part remplie en jade, une bille d'or au bout).
func _curseur(p: Control, y: float, nom: String, v0: float, changer: Callable) -> void:
	Style.libelle(p, nom, Rect2(80, y, 400, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var pct := Style.libelle(p, "%d %%" % roundi(v0 * 100.0), Rect2(580, y - 10, 300, 60), "fort", 44, Style.OR_VIF, HORIZONTAL_ALIGNMENT_RIGHT)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = v0
	s.position = Vector2(80, y + 60)
	s.size = Vector2(800, 90)
	s.focus_mode = Control.FOCUS_NONE
	var piste := Style.boite(Color(0.02, 0.03, 0.03, 1.0), 12, Style.OR_FILET, 2)
	piste.content_margin_top = 10
	piste.content_margin_bottom = 10
	var plein := Style.boite(Color("#3f9c7d"), 12, Style.JADE, 2)
	plein.content_margin_top = 10
	plein.content_margin_bottom = 10
	s.add_theme_stylebox_override("slider", piste)
	s.add_theme_stylebox_override("grabber_area", plein)
	s.add_theme_stylebox_override("grabber_area_highlight", plein)
	var bille := _bille(56)
	s.add_theme_icon_override("grabber", bille)
	s.add_theme_icon_override("grabber_highlight", bille)
	p.add_child(s)
	s.value_changed.connect(func(v: float):
		pct.text = "%d %%" % roundi(v * 100.0)
		changer.call(v))


static var _bille_tex: Texture2D


static func _bille(d: int) -> Texture2D:
	if _bille_tex != null:
		return _bille_tex
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var c := Vector2(d, d) * 0.5
	for y in d:
		for x in d:
			var r := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var a := clampf(d * 0.5 - r, 0.0, 1.0)
			var col := Style.OR_VIF.lerp(Color("#8a6a2e"), clampf((r - d * 0.36) / (d * 0.12), 0.0, 1.0))
			img.set_pixel(x, y, Color(col, a))
	_bille_tex = ImageTexture.create_from_image(img)
	return _bille_tex


# ── Le code cadeau ───────────────────────────────────────────

var _champ: LineEdit             # hors du web (les tests, le PC) : un champ Godot ; sur le web, un vrai champ HTML
var _message: Label
var _valider: Button


func _ouvrir_code() -> void:
	var p := _nouveau_panneau("Code cadeau", 900.0)
	Style.libelle(p, "Un code reçu ? Tape-le ici.", Rect2(60, 160, 840, 60), "italique", 34, Style.SOURD,
		HORIZONTAL_ALIGNMENT_CENTER)
	var cadre := Panel.new()
	cadre.position = Vector2(80, 250)
	cadre.size = Vector2(800, 120)
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cadre.add_theme_stylebox_override("panel", Style.boite(Color(0.02, 0.03, 0.03, 1.0), 24, Style.OR, 3))
	p.add_child(cadre)
	_champ = LineEdit.new()
	_champ.position = Vector2(100, 262)
	_champ.size = Vector2(760, 96)
	_champ.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_champ.placeholder_text = "TON CODE"
	_champ.max_length = 24
	_champ.add_theme_font_override("font", Style.police("fort", 6))
	_champ.add_theme_font_size_override("font_size", 52)
	_champ.add_theme_color_override("font_color", Style.OR_VIF)
	_champ.add_theme_color_override("font_placeholder_color", Color(Style.SOURD, 0.5))
	for st in ["normal", "focus", "read_only"]:
		_champ.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	p.add_child(_champ)
	_valider = Style.bouton(p, "Valider", Rect2(230, 420, 500, 120), true, 48)
	_valider.pressed.connect(_valider_code)
	_message = Style.libelle(p, "", Rect2(60, 570, 840, 120), "italique", 36, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	# 🔴 Sur le téléphone (le jeu web), le clavier ne vient que pour un VRAI champ de la page : on en pose un, en HTML, sur
	#    la place du champ (l'option « clavier virtuel » de Godot est expérimentale). Il part avec le panneau.
	if OS.has_feature("web"):
		_champ.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(cadre):
			_champ_web(true, cadre.get_global_rect())


func _champ_web(ouvrir: bool, r := Rect2()) -> void:
	if not ouvrir:
		_champs.clear()
	if not OS.has_feature("web"):
		return
	if not ouvrir:
		JavaScriptBridge.eval("var i = document.getElementById('champ-code'); if (i) i.remove();"
			+ " document.querySelectorAll('.champ-jeu').forEach(function(e){ e.remove(); });", true)
		return
	var t := get_viewport().get_final_transform()
	var a := t * r.position
	var b := t * r.end
	var f := Vector2(DisplayServer.window_get_size())
	var js := "(function(){ var c = document.querySelector('canvas'); var r = c.getBoundingClientRect();"
	js += " var i = document.getElementById('champ-code'); if (!i) { i = document.createElement('input'); i.id = 'champ-code'; document.body.appendChild(i); }"
	js += " i.type = 'text'; i.autocomplete = 'off'; i.setAttribute('autocapitalize', 'characters'); i.spellcheck = false; i.maxLength = 24;"
	js += " i.placeholder = 'TON CODE'; i.value = ''; var s = i.style; s.position = 'fixed'; s.zIndex = '10'; s.boxSizing = 'border-box';"
	js += " s.left = (r.left + %f * r.width) + 'px'; s.top = (r.top + %f * r.height) + 'px';" % [a.x / f.x, a.y / f.y]
	js += " s.width = (%f * r.width) + 'px'; s.height = (%f * r.height) + 'px';" % [(b.x - a.x) / f.x, (b.y - a.y) / f.y]
	js += " s.fontSize = (%f * r.height) + 'px'; s.fontFamily = 'Georgia, serif'; s.letterSpacing = '0.12em'; s.textAlign = 'center';" % [0.4 * (b.y - a.y) / f.y]
	js += " s.color = '#f1d28a'; s.background = 'transparent'; s.border = '0'; s.outline = 'none'; s.userSelect = 'text'; s.webkitUserSelect = 'text';"
	js += " s.touchAction = 'auto'; s.caretColor = '#7fd0b0'; i.focus(); })();"
	JavaScriptBridge.eval(js, true)


func _code_tape() -> String:
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(document.getElementById('champ-code') || {}).value || ''", true)
		return str(v) if v != null else ""
	return _champ.text if _champ != null else ""


func _valider_code() -> void:
	var code := _code_tape()
	if Codes.normaliser(code).length() < 4:
		_dire("Tape le code en entier.", Style.SOURD)
		return
	_valider.disabled = true
	_dire("Je vérifie…", Style.SOURD)
	var table: Dictionary = await Codes.lire_table(get_tree())
	if not is_instance_valid(_valider):
		return                  # le panneau s'est fermé pendant la lecture
	_valider.disabled = false
	if table.is_empty():
		_dire("Pas de connexion : réessaie dans un instant.", Style.SOURD)
		return
	var v := Codes.verifier(table, code, Time.get_date_string_from_system())
	if not bool(v["ok"]):
		var raisons := {"inconnu": "Ce code n'existe pas. Vérifie les lettres.", "expire": "Ce code a expiré.",
			"deja": "Tu as déjà utilisé ce code.", "vide": "Tape le code en entier.", "table": "Les codes sont illisibles : réessaie plus tard."}
		_dire(str(raisons.get(v["raison"], "Ce code ne marche pas.")), Color("#ec8f9a"))
		Style.trembler(_valider)
		return
	var donne := Codes.encaisser(v)
	_dire("Reçu : %s !" % Codes.phrase(donne), Style.OR_VIF)
	Son.sonner("recevoir")
	Reglages.vibrer(40)
	if Effets.global != null:
		Effets.global.etincelles(_message.get_global_rect(), 8, 26.0)


func _dire(texte: String, couleur: Color) -> void:
	_message.text = texte
	_message.add_theme_color_override("font_color", couleur)
