class_name CarteView
extends Control

# ─────────────────────────────────────────────────────────────
# UNE CARTE — la même que la maquette « Six Variantes » (v5).
#
# 🔴 Le CADRE est du CODE, l'illustration est générée : le cadre
# porte l'identité du jeu, la variante n'est qu'une matière.
# Tout se mesure en « u » = 1 % de la largeur (les cqw de la
# maquette) : la carte est la même en miniature et en grand.
# ─────────────────────────────────────────────────────────────

signal touchee

const SH_CADRE := preload("res://cartes/shaders/cadre.gdshader")
const SH_ART := preload("res://cartes/shaders/art.gdshader")
const SH_REFLET := preload("res://cartes/shaders/reflet.gdshader")
const SH_NOM := preload("res://cartes/shaders/nom_arc.gdshader")   # le nom du full art
const SH_NOM_IRISE := preload("res://cartes/shaders/nom_irise.gdshader")   # le nom du prismatique
const SH_BORD_ARC := preload("res://cartes/shaders/bord_arc.gdshader")
const TEX_COIN := preload("res://cartes/svg/coin.svg")
const TEX_EMBLEME := preload("res://cartes/svg/embleme.svg")
const TEX_PAILLETTES := preload("res://cartes/paillettes.png")

const LAITON := Color(0.769, 0.627, 0.384)

# ─────────────────────────────────────────────────────────────
# LA CARTE DU CARRÉ (v6, 27/09) — la même partout : l'Atlas, la main, le plateau.
# 🔴 Une carte normale montre son illustration dans une FENÊTRE, entourée du cadre ;
#    les quatre chiffres sont posés SUR LE CADRE, au milieu du côté qu'ils défendent.
#    Le full art casse la fenêtre : l'image couvre toute la carte, le reste flotte
#    dessus. Sans cette différence, le full art ne se voit plus en combat.
# Haut, droite, bas, gauche (en u) : deux cartes voisines montrent leurs chiffres face
# à face, de part et d'autre de la frontière qu'ils se disputent.
# ─────────────────────────────────────────────────────────────
const PIERRES := [Vector2(50.0, 9.0), Vector2(91.0, 59.0), Vector2(50.0, 131.0), Vector2(9.0, 59.0)]
const PIERRE_U := 18.0
const POUVOIR_POS := Vector2(76.0, 131.0)
const POUVOIR_U := 14.0
const IVOIRE := Color("#efe9dc")

# La lumière au repos parcourt ces quatre points en dix secondes
# (x, y de la lumière, et sa force) — la même boucle que la maquette.
const REPOS := [
	Vector3(0.30, 0.28, 0.55), Vector3(0.82, 0.18, 0.95),
	Vector3(0.70, 0.66, 0.60), Vector3(0.18, 0.80, 0.95),
]

var h: Dictionary = {}
var stade := 1
var variante := "base"
var largeur := 486.0
var recto := true
var interactif := false   # vue en grand : la lumière suit le doigt
var lumiere := Vector2(0.3, 0.28)
var force := 0.55

var _u := 4.86
var _pal: Dictionary = {}
var _R: Dictionary = {}
var _cadre: ColorRect
var _art: TextureRect
var _reflet: ColorRect
var _nom: Label
var _recto: Array = []
var _verso: Array = []
var _t := 0.0
var _suivi := false
var _dos: Dictionary = {}
var _fx_sous: Node2D     # sous le contenu de la carte : ce que seule la bande du cadre montre
var _fx: CarteFx         # par-dessus tout : particules, éclairs, brume
# Les chiffres et le pouvoir : le Carré (carre/carte_carre.gd) les colore, les anime.
var pierres: Array = []   # TextureRect, haut, droite, bas, gauche
var nombres: Array = []   # Label, dans chaque pierre
var pouvoir: Control      # null : la carte n'a pas de pouvoir
var _verif := 0.0
var _appui := Vector2.ZERO
var _glisse := 0.0

static var _polices := {}

# 🔴 LES ILLUSTRATIONS RESTENT EN MÉMOIRE (28/09 — Maxim : « l'animation d'ouverture de carte lag au début ») : décoder
#    une illustration coûte ~18 ms sur le PC (la vignette ~11), plusieurs fois plus sur le téléphone ; et elle sortait de
#    la mémoire dès que la carte suivante la remplaçait. On garde les dernières (les sbires tombent 6 fois sur 10 : la
#    plupart des révélations n'ont plus rien à décoder). Banc : tests/banc_invocation, tests/banc_image.
const CACHE_PLEINES := 12        # 800 × 1000 : ~3 Mo chacune
const CACHE_VIGNETTES := 30      # 480 × 600 : ~1 Mo chacune
static var _cache_art := {}      # chemin -> Texture2D
static var _ordre_art: Array = []   # du plus ancien au plus récent


static func texture_art(chemin: String) -> Texture2D:
	if _cache_art.has(chemin):
		_ordre_art.erase(chemin)
		_ordre_art.append(chemin)
		return _cache_art[chemin]
	var tex: Texture2D = load(chemin)
	if tex == null:
		return null
	_cache_art[chemin] = tex
	_ordre_art.append(chemin)
	# on oublie les plus anciennes de la même sorte (vignettes, ou illustrations pleines)
	var mini := chemin.contains("/min/")
	var limite := CACHE_VIGNETTES if mini else CACHE_PLEINES
	var n := 0
	for c in _ordre_art:
		if str(c).contains("/min/") == mini:
			n += 1
	var i := 0
	while n > limite and i < _ordre_art.size():
		var c: String = _ordre_art[i]
		if c.contains("/min/") == mini:
			_ordre_art.remove_at(i)
			_cache_art.erase(c)
			n -= 1
		else:
			i += 1
	return tex
static var _degrades := {}


# ─────────────────────────────────────────────────────────────
# Les polices : Castoro, comme tout le jeu (le look « Conte mystique ») —
# le romain pour les noms et les chiffres, l'italique pour les ultimes, le
# Titling (des capitales dessinées pour ça) pour les petites mentions.
# ─────────────────────────────────────────────────────────────

static func police(role: String, espacement: int = 0) -> Font:
	var cle := "%s_%d" % [role, espacement]
	if _polices.has(cle):
		return _polices[cle]
	var fv := FontVariation.new()
	var graisse := 0
	match role:
		"titre":
			fv.base_font = load("res://polices/Castoro.ttf")
			graisse = 600
		"italique":
			fv.base_font = load("res://polices/Castoro-Italic.ttf")
			graisse = 500
		"gras":
			fv.base_font = load("res://polices/CastoroTitling-Regular.ttf")
		"fort":
			fv.base_font = load("res://polices/Castoro.ttf")
			graisse = 700
		_:
			fv.base_font = load("res://polices/Castoro.ttf")
	if graisse > 0:
		var ts := TextServerManager.get_primary_interface()
		fv.variation_opentype = {ts.name_to_tag("wght"): graisse}
	fv.spacing_glyph = espacement
	fv.fallbacks = [Style.SECOURS]
	_polices[cle] = fv
	return fv


# ─────────────────────────────────────────────────────────────
# Les matières : une palette par variante (et par type, pour l'élémentaire)
# ─────────────────────────────────────────────────────────────

static func palette(v: String, type_id: String) -> Dictionary:
	var ty: Dictionary = GS.TYPES[type_id]
	var e: Color = ty["elt"]
	var ec: Color = ty["clair"]
	var es: Color = ty["sombre"]
	var p := {
		"angle": 160.0, "radial": false, "echelle": 1.0, "spectre": 0.0, "brume": 0.0,
		"brume_col": Color(0.72, 0.74, 0.78),
		"cadre": [[0.0, Color("#2c2931")], [1.0, Color("#1c1a20")]],
		"gravure": Color(LAITON, 0.10),
		"fond": Color("#16141a"), "plaque": Color("#24222a"), "keyline": Color(LAITON, 0.42),
		"coin": Color(LAITON, 0.85), "encre": Color("#ece6dc"), "sourd": Color("#9c94a0"),
		"lueur": Color(0, 0, 0, 0), "lueur_u": 5.0, "balayage": Color(0, 0, 0, 0), "eclat": 0.06,
		"art": {}, "holo": 0.0, "nom": "",
		"arc": 0.0, "plein": false, "bord_u": 3.8,
	}
	match v:
		"or":
			p["angle"] = 125.0
			p["cadre"] = [[0.0, Color("#6f5220")], [0.20, Color("#d7b86e")], [0.38, Color("#8c6a2d")],
				[0.55, Color("#f2dd9f")], [0.72, Color("#9a7634")], [0.88, Color("#cfa95f")], [1.0, Color("#7a5a24")]]
			p["gravure"] = Color(1.0, 0.933, 0.745, 0.20)
			p["fond"] = Color("#1b1710")
			p["plaque"] = Color("#372b13")
			p["keyline"] = Color(0.949, 0.867, 0.624, 0.72)
			p["coin"] = Color("#fff0c2")
			p["encre"] = Color("#f6e8c2")
			p["sourd"] = Color("#c9b384")
			p["balayage"] = Color(1.0, 0.95, 0.80, 0.30)
			p["art"] = {"sepia": 0.22, "saturation": 1.08}
		"ombre":
			# Graphite et fumée : une ombre n'a pas de couleur. (Violette jusqu'au 23/09 :
			# elle se confondait avec l'élémentaire esprit.)
			p["radial"] = true
			p["cadre"] = [[0.0, Color("#2b2d33")], [0.62, Color("#0a0a0c")], [1.0, Color("#0a0a0c")]]
			p["gravure"] = Color(0.78, 0.8, 0.85, 0.09)
			p["fond"] = Color("#0c0c0e")
			p["plaque"] = Color("#18191c")
			p["keyline"] = Color(0.75, 0.77, 0.82, 0.5)
			p["coin"] = Color("#b9bec8")
			p["encre"] = Color("#e6e7ea")
			p["sourd"] = Color("#8d9099")
			p["lueur"] = Color(0.62, 0.64, 0.7, 0.18)
			p["lueur_u"] = 6.0
			p["brume"] = 0.7
			p["art"] = {"gris": 0.72, "luminosite": 0.74, "contraste": 1.2, "vignette": 0.85}
		"elem":
			p["angle"] = 150.0
			p["cadre"] = [[0.0, es], [0.42, e], [0.72, es], [1.0, ec]]
			p["gravure"] = Color(1, 1, 1, 0.10)
			var noir := Color("#0d0c10")
			p["fond"] = es.lerp(noir, 0.45)
			p["plaque"] = e.lerp(Color("#1a1820"), 0.62).lerp(es.lerp(noir, 0.30), 0.5)
			p["keyline"] = Color(ec, 0.7)
			p["coin"] = ec
			p["encre"] = Color("#f4f1ea")
			p["sourd"] = ec.lerp(Color("#8a8490"), 0.35)
			p["lueur"] = Color(e, 0.4)
		"prisme":
			p["angle"] = 125.0
			p["echelle"] = 2.6
			# 🔴 Plus discret que le full art (27/09, remarque rapportée par Maxim : « la prisma tape
			#    plus à l'œil que la full art ») : un bord plus fin, un spectre qui ne fait que
			#    teinter le chrome, moins de lueur. Sa signature reste le holo sur l'illustration.
			# 🔄 28/09 — trop sobre (Maxim : « le côté noir et le nom en blanc, on dirait la carte de
			#    base avec un contour arc-en-ciel ») : le cadre entier est du chrome irisé (le fond
			#    laisse passer la matière), et le nom a un reflet irisé qui glisse avec la lumière —
			#    plus pâle que l'arc-en-ciel franc du full art, qui reste au-dessus.
			p["spectre"] = 0.45
			p["bord_u"] = 2.2
			p["cadre"] = [[0.0, Color("#8a929e")], [0.14, Color("#d9dde3")], [0.30, Color("#727a86")],
				[0.46, Color("#d2d7de")], [0.62, Color("#7b8390")], [0.78, Color("#dde1e6")], [1.0, Color("#858d9a")]]
			p["gravure"] = Color(1, 1, 1, 0.16)
			p["fond"] = Color(0.055, 0.06, 0.075, 0.6)
			p["plaque"] = Color(0.07, 0.078, 0.098, 0.84)
			p["nom"] = "irise"
			p["keyline"] = Color(0.941, 0.957, 1.0, 0.8)
			p["coin"] = Color.WHITE
			p["encre"] = Color("#f5f7fb")
			p["sourd"] = Color("#b9bfcb")
			p["lueur"] = Color(0.745, 0.824, 1.0, 0.16)
			p["eclat"] = 0.10
			p["holo"] = 1.0
		"full":
			# Le full art : l'illustration peinte couvre toute la carte, les textes
			# sont posés sur du verre sombre, un arc-en-ciel tourne sur le bord
			# (la maquette v2, « géniaux » — Maxim).
			p["plein"] = true
			p["arc"] = 1.0
			# le nom en arc-en-ciel qui défile : la signature de la plus rare (27/09)
			p["nom"] = "arc"
			p["gravure"] = Color(0, 0, 0, 0)
			p["fond"] = Color(0, 0, 0, 0)
			p["plaque"] = Color(0.04, 0.03, 0.055, 0.5)
			p["keyline"] = Color(1, 1, 1, 0.28)
			p["coin"] = Color(1, 1, 1, 0.9)
			p["encre"] = Color.WHITE
			p["sourd"] = Color(1, 1, 1, 0.82)
			p["lueur"] = Color(1, 1, 1, 0.28)
			p["lueur_u"] = 6.0
			p["eclat"] = 0.10
		"dos":
			p["cadre"] = [[0.0, Color("#15131a")], [1.0, Color("#15131a")]]
			p["gravure"] = Color(0, 0, 0, 0)
	return p


# Le dos trahit un peu la variante : on devine ce qu'on a tiré avant de retourner
# la carte. La base garde le dos de la maquette ; les autres y ajoutent une touche.
static func dos(v: String, type_id: String) -> Dictionary:
	var d := {"laiton": LAITON, "embleme": LAITON, "lueur": Color(0, 0, 0, 0), "lueur_u": 5.0,
		"brume": 0.0, "brume_col": Color(0.72, 0.74, 0.78), "balayage": Color(0, 0, 0, 0), "irise": false}
	match v:
		"or":
			d["laiton"] = Color("#e8c877")
			d["embleme"] = Color("#ffe39a")
			d["lueur"] = Color(1.0, 0.8, 0.4, 0.22)
			d["balayage"] = Color(1.0, 0.92, 0.7, 0.35)
		"ombre":
			d["laiton"] = Color("#9ea3ad")
			d["embleme"] = Color("#c9cdd5")
			d["lueur"] = Color(0.62, 0.64, 0.7, 0.22)
			d["lueur_u"] = 6.0
			d["brume"] = 0.8
		"elem":
			# le halo de l'élémentaire, qui déborde un peu sur les côtés, à la couleur du type
			var ty: Dictionary = GS.TYPES[type_id]
			d["lueur"] = Color(ty["elt"], 0.5)
			d["embleme"] = LAITON.lerp(ty["clair"], 0.35)
		"prisme":
			d["laiton"] = Color("#e8ecf2")
			d["embleme"] = Color("#f5f7fb")
			d["lueur"] = Color(0.745, 0.824, 1.0, 0.4)
			d["irise"] = true
		"full":
			# le plus rare : un dos blanc, irisé, qui rayonne
			d["laiton"] = Color("#f5f7fb")
			d["embleme"] = Color.WHITE
			d["lueur"] = Color(1, 1, 1, 0.5)
			d["lueur_u"] = 7.0
			d["balayage"] = Color(1, 1, 1, 0.4)
			d["irise"] = true
	return d


static func _degrade(cle: String, arrets: Array) -> GradientTexture1D:
	if _degrades.has(cle):
		return _degrades[cle]
	var g := Gradient.new()
	var o := PackedFloat32Array()
	var c := PackedColorArray()
	for a in arrets:
		o.append(float(a[0]))
		c.append(a[1])
	g.offsets = o
	g.colors = c
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	_degrades[cle] = tex
	return tex


# ─────────────────────────────────────────────────────────────
# Construction
# ─────────────────────────────────────────────────────────────

func configurer(p_h: Dictionary, p_stade: int, p_variante: String, p_largeur: float, p_recto: bool = true) -> void:
	h = p_h
	stade = p_stade
	variante = p_variante
	largeur = p_largeur
	recto = p_recto
	_u = largeur / 100.0
	size = Vector2(largeur, largeur * 1.4)
	custom_minimum_size = size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP if interactif else Control.MOUSE_FILTER_PASS
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_recto.clear()
	_verso.clear()
	pierres.clear()
	nombres.clear()
	pouvoir = null
	_pal = palette(variante, str(h["type"]))
	_dos = dos(variante, str(h["type"]))
	_mise_en_page()
	_construire_cadre()
	_fx_sous = Node2D.new()
	add_child(_fx_sous)
	_construire_recto()
	_construire_verso()
	_fx = CarteFx.new()
	add_child(_fx)
	_fx.configurer(_nature_fx(), size, _R["image"], 3.8 * _u, _fx_sous)
	_reflet = ColorRect.new()
	_reflet.size = size
	_reflet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mr := ShaderMaterial.new()
	mr.shader = SH_REFLET
	mr.set_shader_parameter("taille", size)
	mr.set_shader_parameter("rayon", 4.6 * _u)
	mr.set_shader_parameter("eclat", _pal["eclat"])
	mr.set_shader_parameter("balayage", _pal["balayage"])
	_reflet.material = mr
	add_child(_reflet)
	montrer_recto(recto)
	_appliquer_lumiere()


func montrer_recto(v: bool) -> void:
	recto = v
	for n in _recto:
		n.visible = v
	for n in _verso:
		n.visible = not v
	var mc := _cadre.material as ShaderMaterial
	var pal: Dictionary = _pal if v else palette("dos", "aucun")
	mc.set_shader_parameter("degrade", _degrade((variante + str(h["type"])) if v else "dos", pal["cadre"]))
	mc.set_shader_parameter("angle_deg", pal["angle"])
	mc.set_shader_parameter("radial", pal["radial"])
	mc.set_shader_parameter("echelle", pal["echelle"])
	mc.set_shader_parameter("gravure_col", pal["gravure"])
	mc.set_shader_parameter("lueur_col", pal["lueur"] if v else _dos["lueur"])
	mc.set_shader_parameter("lueur_taille", float(pal["lueur_u"] if v else _dos["lueur_u"]) * _u)
	mc.set_shader_parameter("brume", pal["brume"] if v else _dos["brume"])
	mc.set_shader_parameter("brume_col", pal["brume_col"] if v else _dos["brume_col"])
	mc.set_shader_parameter("spectre", pal["spectre"] if v else 0.0)
	if _reflet != null:
		(_reflet.material as ShaderMaterial).set_shader_parameter("balayage", pal["balayage"] if v else _dos["balayage"])
	if _fx != null:
		_fx.set_face(v)


# Quels effets vivent sur cette carte.
func _nature_fx() -> String:
	match variante:
		"ombre":
			return "ombre"
		"prisme":
			return "prisme"
		"full":
			return "full"
		"elem":
			return "" if str(h["type"]) == "aucun" else str(h["type"])
	return ""


func _mise_en_page() -> void:
	var u := _u
	var hh := 140.0 * u
	# le bord dans la matière de la variante (plus fin pour le prismatique)
	var b := float(_pal["bord_u"]) * u
	_R["contenu"] = Rect2(b, b, 100.0 * u - 2.0 * b, hh - 2.0 * b)
	# la fenêtre : entre les pierres de gauche et de droite, sous celle du haut
	_R["art"] = Rect2(12.0 * u, 14.0 * u, 76.0 * u, 90.0 * u)
	# en haut, de part et d'autre de la pierre : le rôle, et le pays
	_R["bandeau"] = Rect2(17.5 * u, 4.4 * u, 65.0 * u, 8.6 * u)
	# en bas, la plaque du nom ; sous elle, le type, la pierre du bas, le pouvoir
	_R["plaque"] = Rect2(12.0 * u, 106.4 * u, 76.0 * u, 15.0 * u)
	_R["medaillon"] = Vector2(24.0 * u, 131.0 * u)
	# l'image : dans sa fenêtre, ou sur toute la carte (full art)
	_R["image"] = Rect2(Vector2.ZERO, Vector2(100.0 * u, hh)) if bool(_pal["plein"]) else _R["art"]


func _construire_cadre() -> void:
	var m := 8.0 * _u
	_cadre = ColorRect.new()
	_cadre.position = Vector2(-m, -m)
	_cadre.size = size + Vector2(2 * m, 2 * m)
	_cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mc := ShaderMaterial.new()
	mc.shader = SH_CADRE
	mc.set_shader_parameter("taille", size)
	mc.set_shader_parameter("marge", m)
	mc.set_shader_parameter("rayon", 4.6 * _u)
	mc.set_shader_parameter("centre_degrade", size * 0.5)
	mc.set_shader_parameter("gravure_pas", 1.1 * _u)
	mc.set_shader_parameter("gravure_trait", 0.28 * _u)
	mc.set_shader_parameter("lueur_taille", float(_pal["lueur_u"]) * _u)
	mc.set_shader_parameter("ombre_dy", 3.0 * _u)
	mc.set_shader_parameter("ombre_flou", 7.0 * _u)
	_cadre.material = mc
	add_child(_cadre)


func _noeud_dessin(f: Callable, pour_recto: bool) -> Control:
	var c := Control.new()
	c.size = size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(f.bind(c))
	add_child(c)
	(_recto if pour_recto else _verso).append(c)
	return c


func _label(texte: String, role: String, taille_u: float, col: Color, rect: Rect2,
		align := HORIZONTAL_ALIGNMENT_LEFT, espacement_em := 0.0) -> Label:
	var s := maxi(6, int(round(taille_u * _u)))
	var l := Label.new()
	l.text = texte
	l.add_theme_font_override("font", police(role, int(round(espacement_em * s))))
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", col)
	l.position = rect.position
	l.size = rect.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	_recto.append(l)
	return l


func _largeur_texte(texte: String, role: String, taille_u: float, espacement_em := 0.0) -> float:
	var s := maxi(6, int(round(taille_u * _u)))
	return police(role, int(round(espacement_em * s))).get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x


# La taille (en u) qui fait tenir le texte dans la largeur donnée, sans jamais
# dépasser la taille voulue : un nom long rapetisse au lieu d'être coupé.
func _taille_pour(texte: String, role: String, taille_u: float, largeur: float, espacement_em := 0.0) -> float:
	var w := _largeur_texte(texte, role, taille_u, espacement_em)
	return taille_u if w <= largeur else taille_u * largeur / w * 0.98


func _construire_recto() -> void:
	var pal := _pal
	# 🔴 Le full art peint l'image SOUS tout le reste (verre, textes, médaillons) :
	#    posée après le fond, elle les recouvrait.
	if pal["plein"]:
		_ajouter_image()
	_noeud_dessin(_dessiner_fond, true)
	if not pal["plein"]:
		_ajouter_image()
	_construire_textes()


# L'illustration, recadrée : l'image couvre sa fenêtre (ou la carte entière, en
# full art), et « cadrage » dit quelle hauteur on garde (la tête est haut dans
# ces peintures).
func _ajouter_image() -> void:
	var u := _u
	var pal := _pal
	var ar: Rect2 = _R["image"]
	var plein: bool = pal["plein"]
	_art = TextureRect.new()
	_art.position = ar.position
	_art.size = ar.size
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# un sbire sans illustration montre sa pierre
	if h.get("sbire", false) and not ResourceLoader.exists("res://cartes/%s-1.jpg" % h["id"]):
		_art.free()
		_art = null
		_image_sbire(ar)
		return
	var chemin := "res://cartes/%s-%d.jpg" % [h["id"], stade]
	# 🔴 Une petite carte (la grille, le ×10) prend la vignette (480 × 600) : l'illustration
	#    pleine (800 × 1000) coûtait 25 à 85 ms à charger par carte, et 4 Mo de mémoire.
	var vignette := "res://cartes/min/%s-%d.jpg" % [h["id"], stade]
	if largeur <= 520.0 and ResourceLoader.exists(vignette):
		chemin = vignette
	if ResourceLoader.exists(chemin):
		_art.texture = texture_art(chemin)
	else:
		push_error("Illustration manquante : %s" % chemin)
	var ma := ShaderMaterial.new()
	ma.shader = SH_ART
	ma.set_shader_parameter("taille", ar.size)
	ma.set_shader_parameter("rayon", (4.6 if plein else 1.6) * u)
	ma.set_shader_parameter("region", _region(ar.size))
	for k in (pal["art"] as Dictionary).keys():
		ma.set_shader_parameter(k, pal["art"][k])
	ma.set_shader_parameter("holo", pal["holo"])
	ma.set_shader_parameter("paillettes", TEX_PAILLETTES)
	ma.set_shader_parameter("arc", pal["arc"])
	ma.set_shader_parameter("pas_raies", 1.6 * u)
	_art.material = ma
	add_child(_art)
	_recto.append(_art)
	if plein:
		# l'arc-en-ciel qui tourne sur le bord
		var bord := ColorRect.new()
		bord.size = size
		bord.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mb := ShaderMaterial.new()
		mb.shader = SH_BORD_ARC
		mb.set_shader_parameter("taille", size)
		mb.set_shader_parameter("rayon", 4.6 * u)
		mb.set_shader_parameter("largeur", 2.4 * u)
		bord.material = mb
		add_child(bord)
		_recto.append(bord)


func _construire_textes() -> void:
	var u := _u
	var pal := _pal
	# Par-dessus l'illustration : son liseré et ses rivets.
	_noeud_dessin(_dessiner_dessus, true)

	# La plaque : le nom, puis la forme et les pastilles du stade — centrés, au-dessus de la
	# pierre du bas.
	var pl: Rect2 = _R["plaque"]
	var place := pl.size.x - 5.0 * u
	var nom_txt := str(h["nom"])
	_nom = _label(nom_txt, "titre", _taille_pour(nom_txt, "titre", 6.4, place), pal["encre"],
		Rect2(pl.position.x + 2.5 * u, pl.position.y + 0.5 * u, place, 8.2 * u), HORIZONTAL_ALIGNMENT_CENTER)
	if pal["nom"] == "arc":
		var mn := ShaderMaterial.new()
		mn.shader = SH_NOM
		mn.set_shader_parameter("largeur", _largeur_texte(nom_txt, "titre", _taille_pour(nom_txt, "titre", 6.4, place)))
		_nom.material = mn
	elif pal["nom"] == "irise":
		var mi := ShaderMaterial.new()
		mi.shader = SH_NOM_IRISE
		mi.set_shader_parameter("teinte", 0.6)
		_nom.material = mi
	var formes: Array = h["formes"]
	var forme_txt := str(formes[stade - 1]).to_upper()
	var pips_w := formes.size() * 2.6 * u
	var t_forme := _taille_pour(forme_txt, "gras", 3.0, place - pips_w - 1.6 * u, 0.1)
	var forme_w := _largeur_texte(forme_txt, "gras", t_forme, 0.1)
	var x := pl.position.x + pl.size.x * 0.5 - (forme_w + 1.6 * u + pips_w) * 0.5
	_R["pips"] = Vector2(x + forme_w + 1.6 * u, pl.position.y + 10.6 * u)
	_label(forme_txt, "gras", t_forme, pal["sourd"],
		Rect2(x, pl.position.y + 8.1 * u, forme_w + 2.0, 5.0 * u), HORIZONTAL_ALIGNMENT_LEFT, 0.1)

	# Le bandeau du haut : le rôle à gauche de la pierre, le pays à droite. Le full art n'en a
	# pas : sur son image, rien que ce qui sert au jeu.
	if not pal["plein"]:
		var bd: Rect2 = _R["bandeau"]
		var cote := (bd.size.x - (PIERRE_U + 3.0) * u) * 0.5
		# 🔴 Le rang de la carte, pour toutes (28/09 — Maxim : « on sait pas quand on a une carte mythe, légende, héros ? ») :
		#    à la place du rôle (il ne sert plus au Carré), plus grand, dans la couleur de son rang (Style.couleur_rang).
		var r := MoteurCarre.rang(str(h["id"]))
		var role := Style.nom_rang(r)
		var col_role: Color = Style.couleur_rang(r)
		var pays := str(h.get("pays", "")).to_upper()
		_label(role, "gras", _taille_pour(role, "gras", 2.9, cote, 0.16), col_role,
			Rect2(bd.position, Vector2(cote, bd.size.y)), HORIZONTAL_ALIGNMENT_CENTER, 0.16)
		_label(pays, "gras", _taille_pour(pays, "gras", 2.4, cote, 0.16), pal["sourd"],
			Rect2(bd.end.x - cote, bd.position.y, cote, bd.size.y), HORIZONTAL_ALIGNMENT_CENTER, 0.16)

	# L'icône du type, dans son médaillon
	var ic := TextureRect.new()
	ic.texture = load("res://cartes/svg/type-%s.svg" % h["type"])
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_SCALE
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ic.size = Vector2(5.4 * u, 5.4 * u)
	ic.position = (_R["medaillon"] as Vector2) - ic.size * 0.5
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ic)
	_recto.append(ic)

	_coins(pal["coin"], true)
	_construire_chiffres()


# Les quatre chiffres du Carré, sertis dans des pierres d'émail (jade : les tiennes), et
# l'emblème d'or de son pouvoir. Tout vient de la fabrique (design/objets/render_carre.py).
# Au combat, carre/carte_carre.gd en change la couleur (le camp) et les valeurs (les bonus).
func _construire_chiffres() -> void:
	var u := _u
	var id := str(h["id"])
	var vals := MoteurCarre.chiffres_de(id, stade)
	var tex := Style.texture("res://carre/chiffre-jade.png")
	var police_ch := police("fort")
	for k in 4:
		var t := _image(self, tex, Rect2((PIERRES[k] as Vector2) * u - Vector2(PIERRE_U, PIERRE_U) * u * 0.5,
			Vector2(PIERRE_U, PIERRE_U) * u))
		t.pivot_offset = t.size * 0.5
		_recto.append(t)
		pierres.append(t)
		var l := Label.new()
		l.text = str(vals[k])
		l.add_theme_font_override("font", police_ch)
		l.add_theme_font_size_override("font_size", maxi(6, int(round(11.4 * u))))
		l.add_theme_color_override("font_color", IVOIRE)
		l.add_theme_color_override("font_outline_color", Color("#0b0a10"))
		l.add_theme_constant_override("outline_size", maxi(1, int(round(2.0 * u))))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = t.size
		l.position = Vector2(0, -0.55 * u)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(l)
		nombres.append(l)
	if MoteurCarre.POUVOIRS.has(id):
		pouvoir = Control.new()
		pouvoir.size = Vector2(POUVOIR_U, POUVOIR_U) * u
		pouvoir.position = POUVOIR_POS * u - pouvoir.size * 0.5
		pouvoir.pivot_offset = pouvoir.size * 0.5
		pouvoir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pouvoir)
		_recto.append(pouvoir)
		_image(pouvoir, Style.texture("res://interface/medaillon-sombre.png"), Rect2(Vector2.ZERO, pouvoir.size))
		var e := pouvoir.size.x * 0.62
		_image(pouvoir, Style.texture("res://carre/pouvoir-%s.png" % MoteurCarre.POUVOIRS[id]["g"]),
			Rect2((pouvoir.size - Vector2(e, e)) * 0.5, Vector2(e, e)))


func _image(parent: Control, tex: Texture2D, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _coins(col: Color, pour_recto: bool) -> void:
	var u := _u
	# le full art a des coins plus fins, plus près du bord
	var plein: bool = pour_recto and bool(_pal["plein"])
	var t := (11.0 if plein else 15.0) * u
	var marge := (1.0 if plein else 1.3) * u
	var places := [
		[Vector2(marge, marge), false, false],
		[Vector2(size.x - marge - t, marge), true, false],
		[Vector2(marge, size.y - marge - t), false, true],
		[Vector2(size.x - marge - t, size.y - marge - t), true, true],
	]
	for pl in places:
		var c := TextureRect.new()
		c.texture = TEX_COIN
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_SCALE
		c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		c.size = Vector2(t, t)
		c.position = pl[0]
		c.flip_h = pl[1]
		c.flip_v = pl[2]
		c.modulate = col
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
		(_recto if pour_recto else _verso).append(c)


func _construire_verso() -> void:
	_noeud_dessin(_dessiner_dos, false)
	var ros := Control.new()
	var ins := 4.1 * _u
	ros.position = Vector2(ins, ins)
	ros.size = size - Vector2(2 * ins, 2 * ins)
	ros.clip_contents = true
	ros.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ros.draw.connect(_dessiner_rosace.bind(ros))
	add_child(ros)
	_verso.append(ros)
	var em := TextureRect.new()
	em.texture = TEX_EMBLEME
	em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	em.stretch_mode = TextureRect.STRETCH_SCALE
	em.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	em.size = Vector2(46.0 * _u, 46.0 * _u)
	em.position = size * 0.5 - em.size * 0.5
	em.modulate = _dos["embleme"]
	em.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(em)
	_verso.append(em)
	_coins(Color(_dos["laiton"], 0.85), false)


# Un sbire sans illustration (ceux de l'Aventure, 27/09) : sa fenêtre montre sa pierre
# élémentaire (rendue par la fabrique), posée sur le fond sombre de son type.
func _image_sbire(ar: Rect2) -> void:
	var ty: Dictionary = GS.TYPES[h["type"]]
	var fond := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([(ty["elt"] as Color).darkened(0.35), (ty["sombre"] as Color), Color("#09090d")])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.42)
	gt.fill_to = Vector2(1.05, 0.95)
	gt.width = 128
	gt.height = 128
	fond.texture = gt
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.position = ar.position
	fond.size = ar.size
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	_recto.append(fond)
	var gem := TextureRect.new()
	gem.texture = load("res://objets/pierre-%s.png" % h["type"])
	gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var cote := minf(ar.size.x, ar.size.y) * 0.62
	gem.size = Vector2(cote, cote)
	gem.position = ar.position + ar.size * 0.5 - gem.size * 0.5
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gem)
	_recto.append(gem)


# La région de l'image montrée dans la fenêtre : « couvrir », puis le cadrage.
func _region(fenetre: Vector2) -> Vector4:
	if _art.texture == null:
		return Vector4(0, 0, 1, 1)
	var img := Vector2(_art.texture.get_size())
	var echelle := maxf(fenetre.x / img.x, fenetre.y / img.y)
	var vis := fenetre / echelle
	var cad: Array = h.get("cadrage", [])
	var pos := float(cad[stade - 1]) if stade - 1 < cad.size() else 0.4
	var x0 := (img.x - vis.x) * 0.5
	var y0 := (img.y - vis.y) * pos
	return Vector4(x0 / img.x, y0 / img.y, vis.x / img.x, vis.y / img.y)


# ─────────────────────────────────────────────────────────────
# Le dessin
# ─────────────────────────────────────────────────────────────

func _boite(fond: Color, rayon: float, bord: float = 0.0, col_bord := Color(0, 0, 0, 0), centre := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fond
	s.draw_center = centre
	s.set_corner_radius_all(int(round(rayon)))
	s.set_border_width_all(int(round(bord)))
	s.border_color = col_bord
	s.anti_aliasing = true
	return s


func _dessiner_fond(c: Control) -> void:
	var u := _u
	var pal := _pal
	var ct: Rect2 = _R["contenu"]
	var plein: bool = pal["plein"]
	if not plein:
		c.draw_style_box(_boite(pal["fond"], 3.0 * u, 0.3 * u, pal["keyline"]), ct)
		c.draw_style_box(_boite(Color(0, 0, 0, 0), 2.7 * u, 0.6 * u, Color(0, 0, 0, 0.25), false), ct.grow(-0.3 * u))

	var pl: Rect2 = _R["plaque"]
	if plein:
		# du verre : un fond sombre translucide, cerclé d'un filet blanc
		c.draw_style_box(_boite(pal["plaque"], 1.8 * u, 0.25 * u, pal["keyline"]), pl)
	else:
		c.draw_style_box(_boite(pal["keyline"], 2.1 * u), pl.grow(0.3 * u))
		c.draw_style_box(_boite(pal["plaque"], 1.8 * u), pl)
	c.draw_line(pl.position + Vector2(1.8 * u, 0.25 * u), Vector2(pl.end.x - 1.8 * u, pl.position.y + 0.25 * u), Color(1, 1, 1, 0.10), 0.3 * u)

	# Les pips du stade, derrière le nom de la forme
	var formes: Array = h["formes"]
	var p0: Vector2 = _R.get("pips", pl.get_center())
	for i in formes.size():
		var centre := p0 + Vector2(0.9 * u + i * 2.6 * u, 0.0)
		if i < stade:
			c.draw_circle(centre, 0.9 * u, pal["sourd"], true, -1.0, true)
		else:
			c.draw_circle(centre, 0.75 * u, pal["sourd"], false, 0.3 * u, true)

	# Le médaillon du type : un dégradé rond, deux anneaux, un halo
	var ty: Dictionary = GS.TYPES[h["type"]]
	var mc: Vector2 = _R["medaillon"]
	var r := 4.7 * u
	for i in 5:
		c.draw_circle(mc, r + 3.0 * u - i * 0.6 * u, Color(ty["elt"], 0.05), true, -1.0, true)
	c.draw_circle(mc, r + 0.85 * u, pal["keyline"], true, -1.0, true)
	c.draw_circle(mc, r + 0.45 * u, Color(0, 0, 0, 0.45), true, -1.0, true)
	var reflet := mc + Vector2(-0.3 * r, -0.4 * r)
	for i in 12:
		var t := i / 11.0
		var col: Color = (ty["sombre"] as Color).lerp(ty["elt"], minf(1.0, t / 0.45)) if t < 0.45 else (ty["elt"] as Color).lerp(ty["clair"], (t - 0.45) / 0.55)
		c.draw_circle(mc.lerp(reflet, t), r * (1.0 - t * 0.82), col, true, -1.0, true)


func _dessiner_dessus(c: Control) -> void:
	var u := _u
	var pal := _pal
	if pal["plein"]:
		c.draw_style_box(_boite(Color(0, 0, 0, 0), 4.3 * u, 0.55 * u, Color(1, 1, 1, 0.38), false),
			Rect2(Vector2.ZERO, size).grow(-0.3 * u))
		return
	var ar: Rect2 = _R["art"]
	c.draw_style_box(_boite(Color(0, 0, 0, 0), 1.6 * u, 0.35 * u, pal["keyline"], false), ar)
	c.draw_style_box(_boite(Color(0, 0, 0, 0), 1.3 * u, 0.65 * u, Color(0, 0, 0, 0.22), false), ar.grow(-0.35 * u))
	for coin in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var p := ar.position + Vector2(2.3 * u + coin.x * (ar.size.x - 4.6 * u), 2.3 * u + coin.y * (ar.size.y - 4.6 * u))
		c.draw_circle(p, 0.9 * u, Color(0, 0, 0, 0.5), true, -1.0, true)
		c.draw_circle(p, 0.75 * u, pal["coin"], true, -1.0, true)
		c.draw_circle(p + Vector2(-0.25, -0.3) * u, 0.3 * u, Color(1, 1, 1, 0.55), true, -1.0, true)


func _dessiner_dos(c: Control) -> void:
	var u := _u
	var r := Rect2(Vector2.ZERO, size)
	var l: Color = _dos["laiton"]
	c.draw_style_box(_boite(Color("#15131a"), 4.6 * u, 0.3 * u, Color(l, 0.5)), r)
	c.draw_style_box(_boite(Color(0, 0, 0, 0), 4.3 * u, 3.5 * u, Color("#1d1a22"), false), r.grow(-0.3 * u))
	c.draw_style_box(_boite(Color(0, 0, 0, 0), 3.0 * u, 0.3 * u, Color(l, 0.45), false), r.grow(-3.8 * u))
	if _dos["irise"]:
		# le prismatique : un liseré irisé tout autour
		var chemin := _chemin_arrondi(r.grow(-3.95 * u), 3.0 * u)
		var cols := PackedColorArray()
		for i in chemin.size():
			cols.append(Color.from_hsv(float(i) / chemin.size(), 0.5, 1.0, 0.9))
		c.draw_polyline_colors(chemin, cols, 0.45 * u, true)


func _chemin_arrondi(r: Rect2, rayon: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var centres := [Vector2(r.end.x - rayon, r.position.y + rayon), Vector2(r.end.x - rayon, r.end.y - rayon),
		Vector2(r.position.x + rayon, r.end.y - rayon), Vector2(r.position.x + rayon, r.position.y + rayon)]
	for i in 4:
		for j in 9:
			var a := -PI * 0.5 + i * PI * 0.5 + j * PI / 16.0
			pts.append((centres[i] as Vector2) + Vector2(cos(a), sin(a)) * rayon)
	pts.append(pts[0])
	return pts


func _dessiner_rosace(c: Control) -> void:
	var u := _u
	var s := c.size
	var centre := s * 0.5
	c.draw_style_box(_boite(Color("#121016"), 3.0 * u), Rect2(Vector2.ZERO, s))
	# le fond : plus clair au centre, qui s'assombrit vers les bords (anneaux superposés)
	var rmax := s.length() * 0.5
	for i in 16:
		var t := i / 15.0
		c.draw_circle(centre, rmax * 0.72 * (1.0 - t), Color("#121016").lerp(Color("#221e28"), t), true, -1.0, true)
	var rayon := 2.6 * u
	while rayon < rmax:
		c.draw_arc(centre, rayon, 0.0, TAU, 96, Color(_dos["laiton"], 0.13), 0.3 * u, true)
		rayon += 2.6 * u
	for i in 72:
		var a := i * TAU / 72.0
		c.draw_line(centre, centre + Vector2(cos(a), sin(a)) * rmax, Color(_dos["laiton"], 0.14), 0.25 * u, true)


# ─────────────────────────────────────────────────────────────
# La lumière : au repos elle tourne, en grand elle suit le doigt
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_verif -= delta
	if _verif <= 0.0:
		_verif = 0.25
		_maj_effets_visibles()
	if not is_visible_in_tree() or _suivi:
		return
	_t = fmod(_t + delta, 10.0)
	var ph := _t / 2.5
	var i := int(ph) % 4
	var f := ph - floorf(ph)
	f = f * f * (3.0 - 2.0 * f)
	var a: Vector3 = REPOS[i]
	var b: Vector3 = REPOS[(i + 1) % 4]
	var v := a.lerp(b, f)
	lumiere = Vector2(v.x, v.y)
	force = v.z
	_appliquer_lumiere()


func _appliquer_lumiere() -> void:
	if _cadre == null:
		return
	var mc := _cadre.material as ShaderMaterial
	mc.set_shader_parameter("lumiere", lumiere)
	if float(_pal["echelle"]) != 1.0 and recto:
		# le chrome du prismatique : ses reflets glissent à l'opposé de la lumière
		mc.set_shader_parameter("centre_degrade", Vector2(size.x * (-0.3 + 1.6 * lumiere.x), size.y * (-0.3 + 1.6 * lumiere.y)))
		# le spectre respire avec la lumière, autour de celui de la variante (0,8 → 0,6 à 1,0)
		mc.set_shader_parameter("spectre", float(_pal["spectre"]) * (0.75 + 0.5 * force))
	if _art != null:
		var ma := _art.material as ShaderMaterial
		ma.set_shader_parameter("lumiere", lumiere)
		ma.set_shader_parameter("force", force)
	if _reflet != null:
		(_reflet.material as ShaderMaterial).set_shader_parameter("lumiere", lumiere)
	if _nom != null and _nom.material != null:
		(_nom.material as ShaderMaterial).set_shader_parameter("lumiere", lumiere)


func _gui_input(ev: InputEvent) -> void:
	var appui := false
	var relache := false
	var pos := Vector2.ZERO
	var bouton := ev as InputEventMouseButton
	var mouvement := ev as InputEventMouseMotion
	if bouton != null and bouton.button_index == MOUSE_BUTTON_LEFT:
		appui = bouton.pressed
		relache = not bouton.pressed
		pos = bouton.position
	elif mouvement != null and (mouvement.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pos = mouvement.position
		_glisse = maxf(_glisse, pos.distance_to(_appui))
		if interactif:
			_suivre(pos)
		return
	else:
		return
	if appui:
		_appui = pos
		_glisse = 0.0
		if interactif:
			_suivre(pos)
	elif relache:
		_suivi = false
		if _glisse < 24.0:
			touchee.emit()


# La lumière vient d'ailleurs (la carte en 3D la règle selon son inclinaison) : la boucle au
# repos s'arrête jusqu'à relacher_lumiere().
func eclairer(l: Vector2, f: float) -> void:
	_suivi = true
	lumiere = Vector2(clampf(l.x, 0.0, 1.0), clampf(l.y, 0.0, 1.0))
	force = clampf(f, 0.0, 1.0)
	_appliquer_lumiere()


func relacher_lumiere() -> void:
	_suivi = false


func _suivre(pos: Vector2) -> void:
	_suivi = true
	lumiere = Vector2(clampf(pos.x / size.x, 0.0, 1.0), clampf(pos.y / size.y, 0.0, 1.0))
	force = clampf(lumiere.distance_to(Vector2(0.5, 0.5)) / 0.62, 0.0, 1.0)
	_appliquer_lumiere()


# Les effets ne tournent que sur une carte à l'écran : une grille pleine de cartes
# animées, défilée ou cachée, ne coûte rien au téléphone.
func _maj_effets_visibles() -> void:
	if _fx == null:
		return
	var vu := is_visible_in_tree() and _zone_visible().intersects(get_global_rect().grow(8.0 * _u))
	var mode := Node.PROCESS_MODE_INHERIT if vu else Node.PROCESS_MODE_DISABLED
	if _fx.process_mode != mode:
		_fx.process_mode = mode


func _zone_visible() -> Rect2:
	var n := get_parent()
	while n != null:
		if n is ScrollContainer:
			return (n as Control).get_global_rect()
		n = n.get_parent()
	return get_viewport_rect()
