class_name Ciel
extends Control

# ─────────────────────────────────────────────────────────────
# LE CIEL — le fond commun des écrans : nébuleuses qui dérivent,
# étoiles qui scintillent, constellations qui se tracent, étoiles
# filantes, lucioles.
#
# 🔴 Pas de shader plein écran : des textures calculées une fois
#    (design/ciel/render_ciel.py) et quelques propriétés animées.
#    Le téléphone paie une quarantaine de mises à jour par image.
# ─────────────────────────────────────────────────────────────

const LARGEUR := 1080.0
const HAUTEUR := 2400.0

# Les étoiles brillantes (x, y, teinte) : la Grande Ourse et Cassiopée dans le bas de
# l'écran du poussoir, le Cygne en haut à droite de la collection, et quelques isolées.
const ASTRES := [
	[83, 2032, "b"], [161, 1999, "o"], [238, 2013, "b"], [305, 2041, "b"], [321, 2096, "j"], [421, 2102, "b"], [421, 2041, "o"],
	[681, 2077, "r"], [737, 2021, "b"], [797, 2063, "o"], [858, 2005, "b"], [925, 2049, "b"],
	[835, 221, "b"], [825, 294, "o"], [809, 393, "b"], [725, 305, "b"], [930, 271, "j"],
	[626, 244, "b"], [540, 214, "b"], [980, 1860, "o"], [128, 1840, "j"], [1000, 2150, "b"], [60, 2170, "r"],
]
const LIENS := [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3],
	[7, 8], [8, 9], [9, 10], [10, 11],
	[12, 13], [13, 14], [15, 13], [13, 16]]
const TEINTES := {
	"b": Color(1.0, 1.0, 1.0), "o": Color(1.0, 0.93, 0.78),
	"j": Color(0.78, 1.0, 0.92), "r": Color(1.0, 0.88, 0.92),
}
const LUCIOLES := [[18, 500, "j"], [1060, 690, "o"], [60, 1860, "j"], [590, 1940, "r"],
	[1000, 1910, "o"], [980, 2120, "j"], [200, 2140, "o"]]
const PERIODE_TRAIT := 16.0

var t := 0.0
var _couches: Array = []      # [TextureRect, période, alpha min, alpha max, phase]
var _nebuleuses: Array = []   # [TextureRect, position de départ, période, phase]
var _astres: Array = []       # [TextureRect, phase, période]
var _traits: Array = []       # [Line2D, a, b, décalage]
var _lucioles: Array = []     # [TextureRect, position de départ, phase, période]
var _filante: TextureRect
var _filante_active := false
var _filante_p := 0.0
var _filante_depart := Vector2.ZERO
var _filante_dans := 3.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(LARGEUR, HAUTEUR)

	var fond := _sprite(Style.degrade(PackedColorArray([Color("#0d1716"), Color("#070c0b"), Color("#050707")]),
		PackedFloat32Array([0.0, 0.55, 1.0])), Vector2.ZERO, size, Color.WHITE)
	fond.stretch_mode = TextureRect.STRETCH_SCALE

	var lueur := Style.texture("res://ciel/lueur.png")
	for n in [[Color(0.31, 0.70, 0.57, 0.38), Vector2(-250, 1440), Vector2(900, 900), 34.0],
			[Color(0.91, 0.69, 0.75, 0.24), Vector2(580, -200), Vector2(830, 720), 41.0],
			[Color(0.89, 0.76, 0.49, 0.17), Vector2(420, 1770), Vector2(780, 640), 47.0]]:
		_nebuleuses.append([_sprite(lueur, n[1], n[2], n[0]), n[1], n[3], randf() * TAU])

	for c in [["res://ciel/etoiles-fines.png", 5.0, 0.55, 1.0], ["res://ciel/etoiles-moyennes.png", 7.0, 0.4, 1.0]]:
		var couche := _sprite(Style.texture(c[0]), Vector2(-60, -60), Vector2(LARGEUR + 120, HAUTEUR + 120), Color.WHITE)
		couche.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		couche.stretch_mode = TextureRect.STRETCH_TILE
		_couches.append([couche, c[1], c[2], c[3], randf() * TAU])

	for i in range(LIENS.size()):
		var a := Vector2(ASTRES[LIENS[i][0]][0], ASTRES[LIENS[i][0]][1])
		var b := Vector2(ASTRES[LIENS[i][1]][0], ASTRES[LIENS[i][1]][1])
		var ln := Line2D.new()
		ln.width = 2.4
		ln.default_color = Color(0.80, 0.96, 0.90, 0.0)
		ln.antialiased = true
		ln.points = PackedVector2Array([a, a])
		add_child(ln)
		_traits.append([ln, a, b, float(i) * 1.3])

	var eclat := Style.texture("res://ciel/eclat-etoile.png")
	for i in range(ASTRES.size()):
		var s: Array = ASTRES[i]
		var cote := 64.0 if i % 3 == 0 else 46.0
		var r := _sprite(eclat, Vector2(s[0], s[1]) - Vector2(cote, cote) * 0.5, Vector2(cote, cote), TEINTES[s[2]])
		r.pivot_offset = Vector2(cote, cote) * 0.5
		_astres.append([r, randf() * TAU, randf_range(3.5, 6.5)])

	for p in LUCIOLES:
		var base := Vector2(p[0], p[1]) - Vector2(14, 14)
		_lucioles.append([_sprite(lueur, base, Vector2(28, 28), TEINTES[p[2]]), base, randf() * TAU, randf_range(6.0, 11.0)])

	_filante = _sprite(Style.texture("res://ciel/filante.png"), Vector2.ZERO, Vector2(330, 12), Color(1, 1, 1, 0))
	_filante.pivot_offset = Vector2(0, 6)
	_filante.rotation = deg_to_rad(-26.0)


func _sprite(tex: Texture2D, pos: Vector2, cote: Vector2, teinte: Color) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = pos
	r.size = cote
	r.modulate = teinte
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _process(delta: float) -> void:
	t += delta
	var derive := Vector2(-14, -20) * (sin(t * TAU / 160.0) * 0.5 + 0.5)
	for c in _couches:
		var couche: TextureRect = c[0]
		couche.modulate.a = lerpf(c[2], c[3], sin(t * TAU / c[1] + c[4]) * 0.5 + 0.5)
		couche.position = Vector2(-60, -60) + derive
	for n in _nebuleuses:
		var neb: TextureRect = n[0]
		neb.position = n[1] + Vector2(44, -30) * sin(t * TAU / n[2] + n[3])
	for a in _astres:
		var astre: TextureRect = a[0]
		var k := sin(t * TAU / a[2] + a[1]) * 0.5 + 0.5
		astre.modulate.a = lerpf(0.65, 1.0, k)
		astre.scale = Vector2.ONE * lerpf(0.8, 1.15, k)
	for d in _traits:
		_tracer(d)
	for l in _lucioles:
		var luc: TextureRect = l[0]
		var k2 := sin(t * TAU / l[3] + l[2])
		luc.position = l[1] + Vector2(8, -14) * k2
		luc.modulate.a = lerpf(0.5, 1.0, k2 * 0.5 + 0.5)
	_etoile_filante(delta)


# Chaque trait se dessine, reste, puis s'efface — cycle de 16 s, décalé d'un trait à l'autre.
func _tracer(d: Array) -> void:
	var ln: Line2D = d[0]
	var u := fposmod(t + float(d[3]), PERIODE_TRAIT) / PERIODE_TRAIT
	var p := clampf((u - 0.02) / 0.26, 0.0, 1.0)
	var a := 1.0
	if u < 0.06:
		a = u / 0.06
	elif u > 0.82:
		a = clampf((1.0 - u) / 0.18, 0.0, 1.0)
	var depart: Vector2 = d[1]
	ln.set_point_position(1, depart.lerp(d[2], p))
	ln.default_color.a = 0.42 * a


func _etoile_filante(delta: float) -> void:
	if not _filante_active:
		_filante_dans -= delta
		if _filante_dans <= 0.0:
			_filante_active = true
			_filante_p = 0.0
			_filante_depart = Vector2(randf_range(760.0, 1060.0), randf_range(1760.0, 1900.0))
		return
	_filante_p += delta / 1.1
	if _filante_p >= 1.0:
		_filante_active = false
		_filante.modulate.a = 0.0
		_filante_dans = randf_range(7.0, 13.0)
		return
	_filante.position = _filante_depart + Vector2(-660.0, 325.0) * _filante_p
	_filante.modulate.a = sin(_filante_p * PI)
