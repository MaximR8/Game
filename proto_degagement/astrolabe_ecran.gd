class_name AstrolabeEcran
extends Control

# ─────────────────────────────────────────────────────────────
# L'ASTROLABE — la page des invocations (FEATURES ⑩, fiche acceptée le 28/09 ; Maxim : « on peut débloquer la dernière
# page maintenant »). On y choisit son ciel (portails.gd) : le Grand Ciel, permanent, et le Ciel du Peintre — le Full
# art ×2, garanti à la centième invocation, refermé au premier Full art ; sa première ×10 est offerte.
# L'invocation elle-même (le rituel, les révélations, la ×10) reste dans l'Atlas (collection_screen.gd : sa couche passe
# au-dessus de tout) : cette page choisit le ciel, et lance.
#
# La page : deux onglets en haut (comme le Voyage), une grande bannière — son fond rendu à sa taille par la fabrique
# (design/objets/render_objets.py --bannieres), ses coins arrondis par interface/arrondi.gdshader —, et en bas, sous le
# pouce, « Invoquer » et « Invoquer ×10 ».
#   · Le Grand Ciel : un astrolabe qui tourne lentement, trois cartes en éventail devant lui (une Légende au centre).
#   · Le Ciel du Peintre : un Full art en vitrine (Carte3D : il se balance, sa matière joue ; il se tourne au doigt) ;
#     sous lui, le limbe de l'astrolabe — 100 graduations qui s'allument en or, une par invocation — et « GARANTI DANS ».
# Les cartes montrées changent chaque jour.
# 🔴 La vitrine a deux SubViewports qui dessinent à chaque image : elle n'existe que quand la page se voit, sur le
#    Peintre (libérée sinon : la Nébuleuse ne la paie pas).
# ─────────────────────────────────────────────────────────────

# Un ciel, c'est UN panneau : sa bannière porte ses boutons (sur le ciel animé, leurs prix se lisaient mal — capture du 28/09).
const BANNIERE := Rect2(30, 352, 1020, 1700)
const RAYON := 38
const Y_BOUTONS := 1838.0
const SH_ARRONDI := preload("res://interface/arrondi.gdshader")
const LARGEUR_VITRINE := 470.0
const Y_VITRINE := 232.0
# Le limbe (la jauge du Peintre) : un arc de cercle très ouvert, sous la vitrine.
const LIMBE_C := Vector2(510, 1840)
const LIMBE_R := 872.0
const LIMBE_X := 420.0          # demi-largeur de l'arc

var atlas: CollectionScreen          # main.gd : c'est lui qui invoque et révèle
var portail := ""                    # le ciel montré (vide : pas encore choisi)
var btn_invoquer: Button
var btn_dix: Button
var lbl_cout: Label
var lbl_cout_dix: Label
var _onglets: Control
var _boutons_onglets := {}
var _points := {}
var _banniere: Control
var _vitrine: Carte3D
var _astro: Dessin
var _jauge: Dessin
var _lbl_garanti: Label
var _lbl_nombre: Label
var _lbl_unite: Label
var _cadeau: Label
var _adieu: Label
var _outils: Array = []
var _t := 0.0


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_construire_onglets()
	btn_invoquer = Style.bouton(self, "Invoquer", Rect2(70, Y_BOUTONS, 460, 130), true, 52)
	btn_invoquer.pressed.connect(func(): _invoquer(1))
	btn_dix = Style.bouton(self, "Invoquer ×10", Rect2(550, Y_BOUTONS, 460, 130), true, 52)
	btn_dix.pressed.connect(func(): _invoquer(10))
	for b in [btn_invoquer, btn_dix]:
		b.set_meta("pourquoi", "Les étoiles se gagnent dans la Nébuleuse et les Présages")
	lbl_cout = Style.libelle(self, "", Rect2(70, Y_BOUTONS + 136, 460, 44), "italique", 32, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_cout_dix = Style.libelle(self, "", Rect2(550, Y_BOUTONS + 136, 460, 44), "italique", 32, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	# le cadeau (le premier ×10 du Peintre) : une pastille d'or posée sur son bouton, qui flotte
	_cadeau = Label.new()
	_cadeau.text = "CADEAU"
	_cadeau.add_theme_font_override("font", Style.police("etiquette", 5))
	_cadeau.add_theme_font_size_override("font_size", 27)
	_cadeau.add_theme_color_override("font_color", Style.TEXTE_SUR_OR)
	var sb := Style.boite(Style.OR_VIF, 22, Color("#fff4d2"), 3)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 6
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	_cadeau.add_theme_stylebox_override("normal", sb)
	_cadeau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cadeau)
	_cadeau.size = _cadeau.get_minimum_size()
	_cadeau.pivot_offset = _cadeau.size * 0.5
	_construire_outils()
	GS.changed.connect(_rafraichir)
	set_process(false)


# À chaque arrivée sur l'Astrolabe (main.gd). La première fois : le Grand Ciel si le premier pack attend, le Peintre si
# son cadeau attend ; ensuite, le ciel qu'on regardait (s'il est encore ouvert).
func montrer() -> void:
	var voulu := portail
	if voulu == "":
		voulu = "peintre" if Portails.offerte_due("peintre") and not GS.premier_pack_du() else "grand"
	if GS.premier_pack_du():
		voulu = "grand"
	if not Portails.ouvert(voulu):
		voulu = "grand"
	_montrer(voulu, false)
	_adieu_si_besoin()


# Après une invocation (la révélation ou la ×10 refermée : collection_screen.gd) : un ciel refermé laisse la place.
func apres_invocation() -> void:
	if not is_visible_in_tree():
		return
	if not Portails.ouvert(portail):
		_montrer("grand", true)
	else:
		_montrer(portail, false)
	_adieu_si_besoin()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_visible_in_tree():
			set_process(true)
		else:
			set_process(false)
			_liberer_vitrine()


func _process(delta: float) -> void:
	_t += delta
	if _astro != null and is_instance_valid(_astro):
		_astro.queue_redraw()
	if _onglets.visible:
		for id in _points:
			(_points[id] as CanvasItem).queue_redraw()
	if _jauge != null and is_instance_valid(_jauge):
		_jauge.queue_redraw()
		# plus que 10 : le nombre bat
		if Portails.restant("peintre") <= Portails.ALERTE_GARANTIE:
			var s := 1.0 + 0.05 * sin(_t * 5.0)
			_lbl_nombre.scale = Vector2(s, s)
	if _cadeau.visible:
		_cadeau.position = Vector2(btn_dix.position.x + btn_dix.size.x * 0.5 - _cadeau.size.x * 0.5, Y_BOUTONS - 30.0 + 5.0 * sin(_t * 3.0))
		_cadeau.rotation = deg_to_rad(-3.0 + 1.5 * sin(_t * 1.7))


# ─────────────────────────────────────────────────────────────
# Les onglets : un par ciel ouvert ; seuls, pas d'onglet
# ─────────────────────────────────────────────────────────────

func _construire_onglets() -> void:
	_onglets = Control.new()
	_onglets.position = Vector2(40, 236)
	_onglets.size = Vector2(1000, 96)
	_onglets.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_onglets)
	var l := (1000.0 - 20.0) / 2.0
	for k in Portails.LISTE.size():
		var id: String = Portails.LISTE[k]["id"]
		var b := Style.bouton(_onglets, str(Portails.LISTE[k]["court"]), Rect2(k * (l + 20.0), 0, l, 96), false, 40)
		b.pressed.connect(func():
			if portail != id:
				_montrer(id, true))
		_boutons_onglets[id] = b
		# le point d'or : un cadeau attend dans ce ciel
		_points[id] = Dessin.ajouter(b, Rect2(0, 0, l, 96), func(ci: CanvasItem):
			if Portails.offerte_due(id) and portail != id:
				# comme celui de la barre (29/09) : plus gros, un anneau net qui s'élargit
				var c := Vector2(l - 34.0, 26.0)
				var ph := fmod(_t, 1.5) / 1.5
				ci.draw_arc(c, lerpf(18.0, 40.0, sqrt(ph)), 0.0, TAU, 40, Color(Style.OR_VIF, 0.9 * (1.0 - ph)), 3.0, true)
				ci.draw_circle(c, 21.0, Color("#1a1208"))
				ci.draw_circle(c, 17.0, Style.OR_VIF)
				ci.draw_circle(c + Vector2(-5, -5), 4.5, Color(1, 1, 1, 0.85)))


func _maj_onglets() -> void:
	var ouverts := Portails.ouverts()
	_onglets.visible = ouverts.size() > 1
	for id in _boutons_onglets:
		var b: Button = _boutons_onglets[id]
		b.visible = ouverts.has(id)
		Style.habiller(b, "jade" if id == portail else "sombre")
		(_points[id] as CanvasItem).queue_redraw()


# ─────────────────────────────────────────────────────────────
# La bannière d'un ciel
# ─────────────────────────────────────────────────────────────

func _montrer(id: String, anime: bool) -> void:
	portail = id
	_liberer_vitrine()
	if _banniere != null and is_instance_valid(_banniere):
		remove_child(_banniere)
		_banniere.queue_free()
	_astro = null
	_jauge = null
	_banniere = Control.new()
	_banniere.position = BANNIERE.position
	_banniere.size = BANNIERE.size
	_banniere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banniere)
	move_child(_banniere, 0)
	_fond(id)
	if id == "peintre":
		_construire_peintre()
	else:
		_construire_grand()
	_cadre()
	_maj_onglets()
	_rafraichir()
	if anime:
		_banniere.modulate.a = 0.0
		_banniere.position.y = BANNIERE.position.y + 36.0
		var tw := _banniere.create_tween().set_parallel(true)
		tw.tween_property(_banniere, "modulate:a", 1.0, 0.2)
		tw.tween_property(_banniere, "position:y", BANNIERE.position.y, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# Le fond rendu à sa taille, ses coins arrondis ; son ombre dessous.
func _fond(id: String) -> void:
	var ombre := Panel.new()
	ombre.size = BANNIERE.size
	ombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var so := Style.boite(Color(0.02, 0.03, 0.03, 1.0), RAYON, Color(0, 0, 0, 0), 0)
	so.shadow_color = Color(0, 0, 0, 0.5)
	so.shadow_size = 26
	so.shadow_offset = Vector2(0, 12)
	ombre.add_theme_stylebox_override("panel", so)
	_banniere.add_child(ombre)
	var fond := TextureRect.new()
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.texture = Style.texture("res://interface/banniere-%s.jpg" % id)
	fond.size = BANNIERE.size
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = SH_ARRONDI
	m.set_shader_parameter("taille", BANNIERE.size)
	m.set_shader_parameter("rayon", float(RAYON))
	m.set_shader_parameter("voile_bas", 0.5 if id == "peintre" else 0.3)
	m.set_shader_parameter("voile_haut", 0.3 if id == "peintre" else 0.15)
	fond.material = m
	_banniere.add_child(fond)


# Le double filet d'or des panneaux, par-dessus tout ce que porte la bannière.
func _cadre() -> void:
	var f := Panel.new()
	f.size = BANNIERE.size
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_theme_stylebox_override("panel", Style.boite(Color(0, 0, 0, 0), RAYON, Style.OR_FILET, 3))
	_banniere.add_child(f)
	var d := Panel.new()
	d.position = Vector2(12, 12)
	d.size = BANNIERE.size - Vector2(24, 24)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_theme_stylebox_override("panel", Style.boite(Color(0, 0, 0, 0), RAYON - 10, Style.OR_FILET_2, 2))
	_banniere.add_child(d)


# Les cartes du jour : la même journée pour tout le monde, un autre choix le lendemain.
static func _jour() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 400 + int(d["month"]) * 32 + int(d["day"])


static func _du_jour(rang: String, decalage: int) -> String:
	var ids := GS.ids_du_rang(rang)
	return str(ids[(_jour() + decalage) % ids.size()]) if not ids.is_empty() else str(GS.HEROS[0]["id"])


# Le Full art en vitrine aujourd'hui : une Légende, à son dernier stade.
static func vedette_du_jour() -> String:
	return _du_jour("legende", 0)


func _construire_grand() -> void:
	var b := _banniere
	Style.libelle(b, "TOUJOURS OUVERT", Rect2(0, 48, 1020, 40), "etiquette", 25, Style.OR_FILET, HORIZONTAL_ALIGNMENT_CENTER, 7)
	Style.libelle(b, "Le Grand Ciel", Rect2(0, 88, 1020, 120), "italique", 100, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	_astro = Dessin.ajouter(b, Rect2(0, 0, 1020, 1480), _dessiner_astrolabe)
	# l'éventail : un Mythe en Or, une Légende en Prismatique, un Héros Élémentaire
	var trio := [[_du_jour("mythe", 3), "or"], [_du_jour("legende", 5), "prisme"], [_du_jour("heros", 7), "elem"]]
	for k in [0, 2, 1]:
		var id := str(trio[k][0])
		var c := CarteView.new()
		b.add_child(c)
		var w := 372.0 if k == 1 else 292.0
		c.configurer(GS.heros(id), GS.stade_max(id), str(trio[k][1]), w, true)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.pivot_offset = c.size * 0.5
		var centre := Vector2(510.0 + (k - 1) * 268.0, 768.0 + (0.0 if k == 1 else 46.0))
		c.position = centre - c.size * 0.5
		c.rotation = deg_to_rad((k - 1) * 10.0)
	# les chances qui comptent, en trois pastilles
	var pc := GS.probas_cartes("grand")
	var pv := GS.probas("grand")
	_pastilles(b, 1142.0, [
		["Légende", _pct(_trouver(pc, "legende")), Style.couleur_rang("legende")],
		["Mythe", _pct(_trouver(pc, "mythe")), Style.couleur_rang("mythe")],
		["Full art", _pct(_trouver(pv, "full")), Style.IVOIRE]])
	# le premier pack (offert, guidé) : la place reste libre pour la consigne de l'accueil (accueil.gd) ; le pack ouvert,
	# la bannière se refait avec sa phrase et ses probabilités
	if GS.premier_pack_du():
		return
	Style.libelle(b, "Toutes les cartes, toutes les variantes.", Rect2(70, 1240, 880, 60), "italique", 34,
		Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)
	_lien_probas(b, 1358.0)


func _construire_peintre() -> void:
	var b := _banniere
	Style.libelle(b, "FULL ART  ×2", Rect2(0, 44, 1020, 48), "etiquette", 34, Style.OR_VIF, HORIZONTAL_ALIGNMENT_CENTER, 9)
	Style.libelle(b, "Le Ciel du Peintre", Rect2(0, 90, 1020, 110), "italique", 86, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	if is_visible_in_tree():
		_creer_vitrine()
	_jauge = Dessin.ajouter(b, Rect2(0, 0, 1020, 1480), _dessiner_jauge)
	_lbl_garanti = Style.libelle(b, "", Rect2(0, 1096, 1020, 40), "etiquette", 26, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 7)
	_lbl_nombre = Style.libelle(b, "", Rect2(0, 1132, 1020, 128), "fort", 118, Style.OR_VIF, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_nombre.pivot_offset = _lbl_nombre.size * 0.5
	_lbl_unite = Style.libelle(b, "", Rect2(0, 1258, 1020, 50), "italique", 36, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	Style.libelle(b, "Au premier Full art, ce ciel se referme.", Rect2(60, 1312, 900, 50), "italique", 30, Style.SOURD,
		HORIZONTAL_ALIGNMENT_CENTER)
	_lien_probas(b, 1376.0)


func _creer_vitrine() -> void:
	var id := vedette_du_jour()
	_vitrine = Carte3D.new()
	_banniere.add_child(_vitrine)
	_vitrine.configurer(GS.heros(id), GS.stade_max(id), "full", LARGEUR_VITRINE)
	_vitrine.position = Vector2((1020.0 - LARGEUR_VITRINE) * 0.5, Y_VITRINE)
	_vitrine.vitrine = true


func _liberer_vitrine() -> void:
	if _vitrine != null and is_instance_valid(_vitrine):
		_vitrine.get_parent().remove_child(_vitrine)
		_vitrine.queue_free()
	_vitrine = null


func _pastilles(b: Control, y: float, l: Array) -> void:
	var boite := HBoxContainer.new()
	boite.position = Vector2(40, y)
	boite.size = Vector2(940, 70)
	boite.alignment = BoxContainer.ALIGNMENT_CENTER
	boite.add_theme_constant_override("separation", 18)
	boite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(boite)
	for e in l:
		var lab := Label.new()
		lab.text = "%s  %s" % [e[0], e[1]]
		lab.add_theme_font_override("font", Style.police("normal"))
		lab.add_theme_font_size_override("font_size", 34)
		lab.add_theme_color_override("font_color", e[2])
		var sb := Style.boite(Color(0.02, 0.04, 0.04, 0.82), 30, Color(e[2], 0.55), 2)
		sb.content_margin_left = 24
		sb.content_margin_right = 24
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		lab.add_theme_stylebox_override("normal", sb)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boite.add_child(lab)


func _lien_probas(b: Control, y: float) -> void:
	var l := Button.new()
	l.text = "Les probabilités"
	l.position = Vector2(300, y)
	l.size = Vector2(420, 66)
	l.add_theme_font_override("font", Style.police("italique"))
	l.add_theme_font_size_override("font_size", 36)
	for etat in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		l.add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		l.add_theme_color_override(c, Style.OR)
	l.add_theme_color_override("font_pressed_color", Style.IVOIRE)
	b.add_child(l)
	var id := portail
	l.pressed.connect(func():
		if atlas != null:
			atlas.montrer_probas(id))


static func _trouver(l: Array, id: String) -> float:
	for e in l:
		if e["id"] == id:
			return float(e["pct"])
	return 0.0


static func _pct(p: float) -> String:
	var t := String.num(p, 1) if p < 1.0 or absf(p - roundf(p)) > 0.05 else str(int(roundf(p)))
	return t.replace(".", ",") + " %"


# ─────────────────────────────────────────────────────────────
# Ce qui bouge : l'astrolabe du Grand Ciel, le limbe du Peintre
# ─────────────────────────────────────────────────────────────

# Un astrolabe au repos : la platine, le cadran gradué qui tourne dans un sens, l'anneau de huit étoiles dans l'autre,
# l'octogramme qui les relie, les quatre étoiles cardinales. Tout en traits fins et étoiles nettes (rituel.gd, au repos).
func _dessiner_astrolabe(ci: CanvasItem) -> void:
	var c := Vector2(510, 768)
	var R := 392.0
	var a3 := _t * 0.05
	var a2 := -_t * 0.08
	var trait_or := Color(Style.OR, 0.5)
	for f in [0.24, 0.56, 0.853, 1.12]:
		ci.draw_arc(c, R * f, 0.0, TAU, 128, Color(Style.IVOIRE, 0.1), 1.5, true)
	for i in 24:
		var d := Vector2.from_angle(i * TAU / 24.0 + a3 * 0.3)
		ci.draw_line(c + d * R * 0.24, c + d * R * 1.12, Color(Style.IVOIRE, 0.05), 1.2, true)
	ci.draw_arc(c, R, 0.0, TAU, 160, Color(Style.OR, 0.55), 2.2, true)
	for i in 72:
		var d := Vector2.from_angle(i * TAU / 72.0 + a3)
		var L := R * (0.085 if i % 6 == 0 else 0.04)
		ci.draw_line(c + d * (R - L * 0.5), c + d * (R + L * 0.5), Color(Style.OR, 0.6), 2.6 if i % 6 == 0 else 1.6, true)
	var P: Array = []
	for k in 8:
		P.append(c + Vector2.from_angle(k * TAU / 8.0 - PI / 2.0 + a2) * R * 0.72)
	for k in 8:
		ci.draw_line(P[k], P[(k + 1) % 8], trait_or, 2.0, true)
		ci.draw_line(P[k], P[(k + 3) % 8], Color(Style.OR, 0.32), 1.8, true)
	for j in 4:
		var d := Vector2.from_angle(j * PI / 2.0 - PI / 2.0 + a3)
		ci.draw_line(c + d * R * 0.9, c + d * R * 1.08, Color(Style.OR, 0.7), 2.4, true)
		Effets.dessiner_etoile(ci, c + d * R, 26.0 * (0.9 + 0.1 * sin(_t * 2.1 + j)), 1.0, 0.0, Effets.OR_CLAIR)
	for k in 8:
		Effets.dessiner_etoile(ci, P[k], 18.0 * (0.85 + 0.15 * sin(_t * 1.7 + k * 0.9)), 0.95, 0.0, Effets.OR_CLAIR)


# Le limbe : 100 graduations sur un arc très ouvert ; celles qu'on a passées sont d'or, la centième est une étoile (le
# Full art garanti) ; une petite étoile marque où l'on en est.
func _dessiner_jauge(ci: CanvasItem) -> void:
	var n := Portails.compte("peintre")
	var g := Portails.garantie("peintre")
	var a0 := Vector2(-LIMBE_X, -sqrt(LIMBE_R * LIMBE_R - LIMBE_X * LIMBE_X)).angle()
	var a1 := Vector2(LIMBE_X, -sqrt(LIMBE_R * LIMBE_R - LIMBE_X * LIMBE_X)).angle()
	var proche := g - n <= Portails.ALERTE_GARANTIE
	ci.draw_arc(LIMBE_C, LIMBE_R - 18.0, a0, a1, 160, Color(Style.OR, 0.35), 2.0, true)
	ci.draw_arc(LIMBE_C, LIMBE_R + 18.0, a0, a1, 160, Color(Style.OR, 0.35), 2.0, true)
	for i in range(1, g):
		var a := lerpf(a0, a1, float(i - 1) / float(g - 1))
		var d := Vector2.from_angle(a)
		var L := 42.0 if i % 10 == 0 else 22.0
		var passe := i <= n
		var col := Color(Style.OR_VIF, 1.0) if passe else Color(Style.IVOIRE, 0.3)
		ci.draw_line(LIMBE_C + d * (LIMBE_R - L * 0.5), LIMBE_C + d * (LIMBE_R + L * 0.5), col, 3.2 if passe else 2.0, true)
	# la centième : l'étoile du Full art
	var pf := LIMBE_C + Vector2.from_angle(a1) * LIMBE_R
	var bat := 1.0 + (0.18 if proche else 0.08) * sin(_t * (5.0 if proche else 2.4))
	Effets.dessiner_etoile(ci, pf, 40.0 * bat, 1.0, 0.0, Effets.OR_CLAIR)
	# où l'on en est
	if n > 0:
		var a := lerpf(a0, a1, float(mini(n, g - 1) - 1) / float(g - 1))
		Effets.dessiner_etoile(ci, LIMBE_C + Vector2.from_angle(a) * (LIMBE_R + 46.0), 20.0 * (0.85 + 0.15 * sin(_t * 3.0)), 1.0, 0.0, Color.WHITE)


# ─────────────────────────────────────────────────────────────
# Les boutons
# ─────────────────────────────────────────────────────────────

func _rafraichir() -> void:
	if portail == "":
		return
	var pack := portail == "grand" and GS.premier_pack_du()
	btn_invoquer.disabled = not GS.peut_invoquer(1, portail)
	btn_dix.disabled = not (pack or GS.peut_invoquer(10, portail))
	btn_dix.text = "Premier pack" if pack else "Invoquer ×10"
	var offerte := Portails.offerte_due(portail)
	lbl_cout.text = "1 étoile" if GS.etoiles >= 1 else "1 étoile · tu en as 0"
	lbl_cout_dix.text = "offert" if pack else ("offerte" if offerte else ("10 étoiles" if GS.etoiles >= 10 else "10 étoiles · tu en as %d" % GS.etoiles))
	lbl_cout_dix.add_theme_color_override("font_color", Style.OR_VIF if pack or offerte else Style.SOURD)
	_cadeau.visible = offerte
	if _lbl_nombre != null and is_instance_valid(_lbl_nombre):
		var reste := Portails.restant("peintre")
		var proche := reste <= Portails.ALERTE_GARANTIE
		_lbl_garanti.text = "PLUS QUE" if proche else "FULL ART GARANTI DANS"
		_lbl_garanti.add_theme_color_override("font_color", Style.OR_VIF if proche else Style.SOURD)
		_lbl_nombre.text = str(reste)
		_lbl_unite.text = ("étoile" if reste == 1 else "étoiles") + (" avant ton Full art" if proche else "") + \
			(" · les 10 premières offertes" if Portails.offerte_due("peintre") else "")
		if not proche:
			_lbl_nombre.scale = Vector2.ONE
	for id in _points:
		(_points[id] as CanvasItem).queue_redraw()


# 🔴 Pendant la révélation, la bannière est dessous : elle ne se dessine plus (la vitrine et ses deux SubViewports, les
#    cartes prismatique et élémentaire) — l'animation a toutes les images pour elle. Elle revient à la fermeture.
func _invoquer(n: int) -> void:
	if atlas == null:
		return
	_liberer_vitrine()
	_banniere.visible = false
	atlas.invoquer_dans(portail, n)
	if not (atlas.rev.visible or atlas.multi.visible):
		_montrer(portail, false)          # rien ne s'est ouvert : la bannière revient tout de suite


# Le Ciel du Peintre s'est refermé : un mot, une seule fois, à la place des onglets.
func _adieu_si_besoin() -> void:
	if not Portails.adieu_a_montrer("peintre") or not is_visible_in_tree():
		return
	if _adieu != null and is_instance_valid(_adieu):
		_adieu.queue_free()
	_adieu = Style.libelle(self, "Le Ciel du Peintre s'est refermé : ton Full art t'attend dans l'Atlas.", Rect2(60, 232, 960, 104),
		"italique", 36, Style.OR_VIF, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	_adieu.modulate.a = 0.0
	_adieu.create_tween().tween_property(_adieu, "modulate:a", 1.0, 0.5)
	Portails.adieu_vu("peintre")


# ─────────────────────────────────────────────────────────────
# Les outils de test (D1 : un appui long sur l'onglet « Nébuleuse », réseau local seulement)
# ─────────────────────────────────────────────────────────────

func _construire_outils() -> void:
	var l := [
		["+10 étoiles", func(): GS.donner_etoiles(10)],
		["Prisma", func():
			if atlas != null:
				atlas.montrer_revelation(GS.donner_carte_test("prisme"))],
		["Full art", func():
			if atlas != null:
				atlas.montrer_revelation(GS.donner_carte_test("full"))],
		["Peintre +10", func():
			var d := Portails.donnees("peintre")
			d["n"] = mini(int(d["n"]) + 10, Portails.garantie("peintre") - 1)
			GS.save_game()
			GS.changed.emit()],
		["Rouvrir", func():
			(GS.voyage.get("portails", {}) as Dictionary).erase("peintre")
			GS.save_game()
			portail = ""
			montrer()],
	]
	for k in l.size():
		var b := Style.bouton(self, str(l[k][0]), Rect2(24.0 + k * 208.0, 2068, 200, 56), false, 24)
		b.pressed.connect(l[k][1])
		b.visible = false
		_outils.append(b)


func montrer_outils(v: bool) -> void:
	for b in _outils:
		(b as Control).visible = v
