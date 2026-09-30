class_name Style
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LE LOOK « CONTE MYSTIQUE » — la seule source des couleurs, des
# polices et des panneaux de l'interface. D'après la planche des
# personnages (image.png) et le canevas « Directions du look », page 5.
#
# ⛔ Pas de thème de pays : encre, jade, ivoire, or — la lumière vient
#    de la magie et de la lune.
# ─────────────────────────────────────────────────────────────

const ENCRE := Color("#0c0f0e")
const IVOIRE := Color("#efe9dc")
const SOURD := Color("#a9b4ae")
const JADE := Color("#7fd0b0")
const JADE_F := Color("#3f9c7d")
const OR := Color("#caa968")
const OR_FILET := Color(0.81, 0.68, 0.43, 0.78)
const OR_FILET_2 := Color(0.81, 0.68, 0.43, 0.30)
const ALERTE := Color("#e6c67f")
const TEXTE_SUR_IVOIRE := Color("#1c2320")

static var _polices := {}
# 🔴 La police de secours (27/09) : Castoro n'a pas l'étoile « ★ ». Sur le web, il n'y a pas de police du
#    système pour la remplacer — elle sortait en boîte (Maxim : « un symbole bizarre »). Une police d'un
#    seul glyphe, dessinée pour le jeu (polices/Etoile.ttf).
const SECOURS := preload("res://polices/Etoile.ttf")

static var _textures := {}


# « normal » et « fort » : Castoro · « italique » · « etiquette » : Castoro Titling,
# toujours en capitales, avec un espacement.
static func police(role: String, espacement: int = 0) -> Font:
	var cle := "%s_%d" % [role, espacement]
	if _polices.has(cle):
		return _polices[cle]
	var fv := FontVariation.new()
	match role:
		"italique":
			fv.base_font = load("res://polices/Castoro-Italic.ttf")
		"etiquette":
			fv.base_font = load("res://polices/CastoroTitling-Regular.ttf")
		"fort":
			fv.base_font = load("res://polices/Castoro.ttf")
			var ts := TextServerManager.get_primary_interface()
			fv.variation_opentype = {ts.name_to_tag("wght"): 600}
		_:
			fv.base_font = load("res://polices/Castoro.ttf")
	fv.spacing_glyph = espacement
	fv.fallbacks = [SECOURS]
	_polices[cle] = fv
	return fv


static func texture(chemin: String) -> Texture2D:
	if not _textures.has(chemin):
		_textures[chemin] = load(chemin)
	return _textures[chemin]


# Les objets rendus en relief (design/objets/) : « piece-etoile », « piece-lune »,
# « xp », « ticket », « eclat ». Le disque occupe 92 % de l'image : dessiner un objet
# de rayon r, c'est dessiner l'image en 2·r / 0,92 de côté.
const DISQUE := 0.92


static func objet(nom: String) -> Texture2D:
	return texture("res://objets/%s.png" % nom)


static func cote_objet(rayon: float) -> float:
	return 2.0 * rayon / DISQUE


# 1 240 : les milliers séparés par une espace fine insécable.
static func nombre(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = " " + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


# ─────────────────────────────────────────────────────────────
# Panneaux : un fond, un filet d'or franc au bord, un filet pâle à 12 px
# ─────────────────────────────────────────────────────────────

static func boite(fond: Color, rayon: int, filet := OR_FILET, epaisseur := 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fond
	sb.border_color = filet
	sb.set_border_width_all(epaisseur)
	sb.set_corner_radius_all(rayon)
	sb.anti_aliasing = true
	return sb


static func panneau(parent: Node, rect: Rect2, fond: Color, rayon := 34) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := boite(fond, rayon)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 24
	sb.shadow_offset = Vector2(0, 10)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	var dedans := Panel.new()
	dedans.position = Vector2(12, 12)
	dedans.size = rect.size - Vector2(24, 24)
	dedans.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dedans.add_theme_stylebox_override("panel", boite(Color(0, 0, 0, 0), maxi(rayon - 10, 4), OR_FILET_2, 2))
	p.add_child(dedans)
	return p


# retour : le texte revient à la ligne dans la largeur donnée.
static func libelle(parent: Node, texte: String, rect: Rect2, role: String, taille: int, couleur: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, espacement := 0, retour := false) -> Label:
	var l := Label.new()
	# 🔴 Le retour à la ligne AVANT la taille : sans lui, la largeur minimale d'un
	#    Label est celle de tout son texte sur une ligne, et la taille s'y cale —
	#    le texte déborde ensuite du panneau, même une fois le retour activé.
	if retour:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = texte
	l.position = rect.position
	l.size = rect.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", police(role, espacement))
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


static func icone(parent: Node, tex: Texture2D, rect: Rect2, teinte := Color.WHITE) -> TextureRect:
	var t := TextureRect.new()
	# 🔴 Le mode d'étirement AVANT la taille : sinon la taille de l'image fait
	#    plancher, et une icône de 70 px s'affiche à 128.
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture = tex
	t.position = rect.position
	t.custom_minimum_size = rect.size
	t.size = rect.size
	t.modulate = teinte
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


# Le bouton principal est ivoire, cerclé d'or, avec une lueur jade ;
# le secondaire est sombre, à filet d'or.
# 🔴 DES BOUTONS DE JEU (Maxim, 26/09 : « ça doit faire jeu vidéo, les boutons doivent être
#    marquants ») : épais, avec leur tranche (interface/bouton-*.png, rendus par
#    design/objets/render_objets.py --interface). Sous le doigt, la face descend dans sa tranche
#    et s'éclaire ; en revenant, le bouton rebondit et lâche des étincelles ; le téléphone vibre.
#    Le principal est en émail d'or, l'autre en émail sombre bordé d'or ; éteint, il est gris.
#    Un bouton éteint qu'on touche tremble, et dit pourquoi si on le lui a appris (meta « pourquoi »).
const OR_VIF := Color("#f1d28a")
const TEXTE_SUR_OR := Color("#2b1b06")


static func _boite_bouton(style: String, enfonce: bool, petit: bool) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = texture("res://interface/bouton-%s%s%s.png" % [style, "-petit" if petit else "", "-enfonce" if enfonce else ""])
	var r := 20 if petit else 34
	var tranche := 9 if petit else 16
	var decal := (tranche - 3) if enfonce else 0
	sb.texture_margin_left = r + 4
	sb.texture_margin_right = r + 4
	sb.texture_margin_top = r + 4
	sb.texture_margin_bottom = r + tranche + 4
	sb.content_margin_left = 14 if petit else 26
	sb.content_margin_right = 14 if petit else 26
	sb.content_margin_top = 3 + decal
	sb.content_margin_bottom = 3 + tranche - decal
	return sb


static func bouton(parent: Node, texte: String, rect: Rect2, principal := true, taille := 50) -> Button:
	var b := Button.new()
	b.text = texte
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_override("font", police("normal"))
	b.add_theme_font_size_override("font_size", taille)
	var petit := rect.size.y < 100.0
	var st := "or" if principal else "sombre"
	var n := _boite_bouton(st, false, petit)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", _boite_bouton(st, true, petit))
	b.add_theme_stylebox_override("hover_pressed", _boite_bouton(st, true, petit))
	b.add_theme_stylebox_override("disabled", _boite_bouton("eteint", false, petit))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var texte_c := TEXTE_SUR_OR if principal else IVOIRE
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, texte_c)
	b.add_theme_color_override("font_disabled_color", Color("#2f2e2b"))
	parent.add_child(b)
	jeu(b)
	return b


# 🔴 LE RANG D'UNE CARTE SE VOIT (28/09 — Maxim : « on sait pas quand on a une carte mythe, légende, héros ? ») : son nom
#    et sa couleur, partout pareils (la carte, la révélation, la ×10, l'Atlas).
const COULEURS_RANG := {"legende": Color("#f1d28a"), "mythe": Color("#cda8ff"), "heros": Color("#e8e2d4"), "sbire": Color("#a9b4ae")}
const NOMS_RANG := {"legende": "LÉGENDE", "mythe": "MYTHE", "heros": "HÉROS", "sbire": "SBIRE"}


static func couleur_rang(r: String) -> Color:
	return COULEURS_RANG.get(r, IVOIRE)


static func nom_rang(r: String) -> String:
	return str(NOMS_RANG.get(r, "HÉROS"))


# Change l'habit d'un bouton : « or », « sombre » ou « jade » (l'onglet choisi du Voyage, 28/09).
static func habiller(b: Button, style: String) -> void:
	var petit := b.size.y < 100.0
	var n := _boite_bouton(style, false, petit)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", _boite_bouton(style, true, petit))
	b.add_theme_stylebox_override("hover_pressed", _boite_bouton(style, true, petit))
	var texte_c := TEXTE_SUR_OR if style == "or" else IVOIRE
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, texte_c)


# Ce que fait un bouton de jeu sous le doigt (les onglets et les boutons faits à la main l'ont aussi).
static func jeu(b: BaseButton, cible: Control = null) -> void:
	if cible == null:
		cible = b
	b.button_down.connect(func():
		if b.disabled:
			return
		Reglages.vibrer(12))
	b.button_up.connect(func():
		cible.pivot_offset = cible.size * 0.5
		var tw := cible.create_tween()
		tw.tween_property(cible, "scale", Vector2(1.05, 1.05), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(cible, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if b.is_inside_tree() and b.is_visible_in_tree():
			Effets.pour(b).etincelles(cible.get_global_rect(), 3, 18.0)
		if not b.disabled:
			Son.bouton())                  # (29/09) chaque bouton du jeu a son petit clic
	b.gui_input.connect(func(ev: InputEvent):
		var mb := ev as InputEventMouseButton
		if b.disabled and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			trembler(cible)
			Son.sonner("refus")
			var pourquoi = b.get_meta("pourquoi", "")
			if pourquoi is Callable:
				pourquoi = (pourquoi as Callable).call()
			if str(pourquoi) != "":
				bulle(b, str(pourquoi)))


static func trembler(c: Control) -> void:
	var x0 := c.position.x
	var tw := c.create_tween()
	for dx in [-10.0, 10.0, -6.0, 0.0]:
		tw.tween_property(c, "position:x", x0 + dx, 0.06)


# Une petite bulle au-dessus d'un élément, qui s'efface d'elle-même (un bouton éteint dit pourquoi,
# un menu scellé dit quand il s'ouvre).
static func bulle(pres_de: Control, texte: String) -> void:
	var fx := Effets.pour(pres_de)
	for v in fx.get_children():
		if v.has_meta("bulle"):
			v.queue_free()
	var r := pres_de.get_global_rect()
	var l := Label.new()
	l.set_meta("bulle", true)
	l.text = texte
	l.add_theme_font_override("font", police("italique"))
	l.add_theme_font_size_override("font_size", 38)
	l.add_theme_color_override("font_color", IVOIRE)
	var sb := boite(Color(0.05, 0.07, 0.06, 0.98), 26, OR_FILET, 3)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(l)
	var taille := l.get_minimum_size()
	l.size = taille
	# au-dessus de ce qu'elle désigne ; sous lui s'il est trop près du haut de l'écran (le « Quitter » du combat, 28/09)
	var y := r.position.y - taille.y - 18.0
	if y < 20.0:
		y = r.end.y + 18.0
	l.position = Vector2(clampf(r.get_center().x - taille.x * 0.5, 20.0, 1060.0 - taille.x), y)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.18)
	tw.tween_interval(1.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


# 🔴 UN JEU RÉPOND AU DOIGT (Maxim, 25/09 : « c'est un jeu, pas un site HTML ») : le
#    bouton s'enfonce quand on appuie et rebondit quand on lâche. « cible » : ce qui
#    bouge (le bouton lui-même, ou seulement son contenu pour un onglet très large).
static func rebond(b: BaseButton, cible: Control) -> void:
	b.button_down.connect(func():
		if b.disabled:
			return
		cible.pivot_offset = cible.size * 0.5
		var tw := cible.create_tween()
		tw.tween_property(cible, "scale", Vector2(0.93, 0.93), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	b.button_up.connect(func():
		cible.pivot_offset = cible.size * 0.5
		var tw := cible.create_tween()
		tw.tween_property(cible, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


# Un dégradé vertical, pour les barres dorées et les lueurs.
static func degrade(couleurs: PackedColorArray, positions: PackedFloat32Array, vertical := true) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = positions
	g.colors = couleurs
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 4 if vertical else 256
	t.height = 256 if vertical else 4
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1) if vertical else Vector2(1, 0)
	return t
