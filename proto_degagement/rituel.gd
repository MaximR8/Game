class_name Rituel
extends Control

# LE RITUEL DES CONSTELLATIONS (FEATURES § ⑬, ligne D du canevas, validé le 24/09).
#
# Un astrolabe — l'anneau de huit étoiles et le cadran — tourne en sens contraires,
# ralentit et se verrouille ; au verrou se dessine l'étoile à huit branches. Des
# constellations s'allument ÉPARPILLÉES sur tout l'écran : 🔴 leur NOMBRE dit la rareté
# (Base 2 · Or 3 · Ombre 4 · Élémentaire 5 · Prisma 7 · Full art 9). Puis leurs étoiles
# filent se poser sur le cadran, et l'astrolabe se resserre en l'embleme du dos de la
# carte, qui se retourne. En ×10 : une constellation par carte, de la couleur de SA
# rareté, et ses étoiles filent vers la place de la carte.
#
# ⛔ Tout est dessiné net — branches fines, cœur blanc, traits à la plume. Ni halo, ni
#    pilier, ni fissure, ni éclair : Maxim les a refusés (24/09). Aucune image.
#
# Tout se calcule à partir de l'âge de la scène : dessiner, c'est évaluer le temps.

const NB_CONSTELLATIONS := [2, 3, 4, 5, 7, 9]        # par rang de variante (base → full art)
const IVOIRE := Color("#efe9dc")

# Les figures du ciel : les étoiles (en unités de la maquette) et les chaînes du tracé.
const MODELES := {
	"W": [[[0, 0], [18, 15], [35, 3], [52, 18], [70, 6]], [[0, 1, 2, 3, 4]]],
	"tri": [[[0, 0], [32, -10], [20, 22]], [[0, 1, 2, 0]]],
	"ourse": [[[0, 0], [20, 7], [38, 5], [56, 14], [54, 36], [76, 42], [80, 22]], [[0, 1, 2, 3, 4, 5, 6, 3]]],
	"cerf": [[[0, 0], [17, -22], [36, -4], [19, 24], [24, 48]], [[0, 1, 2, 3, 0], [3, 4]]],
	"croix": [[[-28, -4], [0, 0], [30, 5], [2, -32], [-3, 34]], [[0, 1, 2], [3, 1, 4]]],
	"arc": [[[0, 0], [15, -15], [36, -21], [57, -15], [70, 0]], [[0, 1, 2, 3, 4]]],
	"lyre": [[[0, 0], [10, 15], [27, 17], [23, 1], [-7, -16]], [[4, 0, 1, 2, 3, 0]]],
}
const FORMES := ["W", "croix", "arc", "cerf", "tri", "lyre", "ourse"]
const ECHELLE_FIGURE := 2.6          # maquette (390 px) → écran du jeu (1080 px)
const SEG := 0.07                    # durée d'un trait de constellation

var _t := 0.0
var _s: Dictionary = {}              # la scène en cours (vide : rien)
var _coins: Array = []               # les éclats posés sur les coins d'une carte dévoilée
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add
	_rng.randomize()
	set_process(false)


# La teinte d'un effet : fixe, ou irisée (une seule teinte pâle qui dérive).
static func teinte(couleur: Color, mode: String, phase: float) -> Color:
	match mode:
		"irise":
			return Color.from_hsv(fposmod(phase, 1.0), 0.3, 1.0)
		"arc":
			return Color.from_hsv(fposmod(phase, 1.0), 0.55, 1.0)
	return couleur


static func nb_constellations(rang: int) -> int:
	return NB_CONSTELLATIONS[clampi(rang, 0, NB_CONSTELLATIONS.size() - 1)]


# ─────────────────────────────────────────────────────────────
# Les deux invocations
# ─────────────────────────────────────────────────────────────

# L'invocation simple. Renvoie les instants utiles à l'écran : « t_carte » (le dos
# apparaît sous l'astrolabe qui se resserre) et « t_flip » (la carte se retourne).
# embleme : le rayon du cercle de l'embleme du dos, là où finit le cadran.
func simple(centre: Vector2, rayon: float, embleme: float, col: Color, mode: String, n: int) -> Dictionary:
	_nouvelle_scene(centre, rayon, col, mode)
	var ecart: float = {2: 0.22, 3: 0.2, 4: 0.17, 5: 0.15, 7: 0.13}.get(n, 0.11)
	var fin := _semer(n, 0.2, ecart, [], [], true)
	var t_lock := maxf(1.2, fin + 0.15)
	var t_conv := t_lock + 0.3
	var t_con := t_conv + 0.6
	_s["t_lock"] = t_lock
	_s["fin"] = {"type": "resserre", "t": t_con, "s": embleme / rayon}
	# les étoiles des constellations se posent sur le cadran, également réparties
	var etoiles: Array = _s["etoiles"]
	var ordre := range(etoiles.size())
	ordre.sort_custom(func(a, b): return (etoiles[a]["p0"] - centre).angle() < (etoiles[b]["p0"] - centre).angle())
	var a0: float = (etoiles[ordre[0]]["p0"] - centre).angle()
	for rang in ordre.size():
		var e: Dictionary = etoiles[ordre[rang]]
		var a := a0 + TAU * rang / ordre.size()
		e["cible"] = centre + Vector2(cos(a), sin(a)) * rayon
		e["t_m0"] = t_conv + rang * 0.005
		e["dm"] = 0.45
		e["flares"] = [e["t_m0"] + 0.45]
		e["suit"] = true
	for tr in _s["traits"]:
		tr["t_off"] = t_conv
	_s["duree"] = t_con + 0.6
	set_process(true)
	return {"t_carte": t_con + 0.1, "t_flip": t_con + 0.75}


# L'invocation ×10. cibles : le centre de chaque carte ; teintes : [couleur, mode] de
# chaque carte. Renvoie « arrivees » (l'instant où les étoiles d'une carte arrivent à
# sa place : son dos y apparaît) et « t_retour » (les retournements peuvent commencer).
func multiple(centre: Vector2, rayon: float, col: Color, mode: String, cibles: Array, teintes: Array) -> Dictionary:
	_nouvelle_scene(centre, rayon, col, mode)
	var fin := _semer(cibles.size(), 0.2, 0.1, cibles, teintes, true)
	var t_lock := fin + 0.15
	var t_go := t_lock + 0.35
	_s["t_lock"] = t_lock
	_s["fin"] = {"type": "s_efface", "t": t_go, "s": 0.3}
	var arrivees: Array = []
	for i in cibles.size():
		arrivees.append(t_go + i * 0.03 + 0.5)
	for e in _s["etoiles"]:
		var i: int = e["carte"]
		e["t_m0"] = t_go + i * 0.03
		e["dm"] = 0.5
		e["t_off"] = arrivees[i] + 0.05
	for tr in _s["traits"]:
		tr["t_off"] = t_go
	_s["duree"] = t_go + 0.03 * cibles.size() + 1.0
	set_process(true)
	return {"arrivees": arrivees, "t_retour": arrivees[arrivees.size() - 1] + 0.3}


# Quatre éclats nets qui s'allument sur les coins d'une carte dévoilée (Or et plus).
func coins(rect: Rect2, col: Color, mode: String, R := 22.0) -> void:
	var pts := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		_coins.append({"p": pts[i], "age": -i * 0.08, "vie": 1.8, "R": R, "col": col, "mode": mode,
			"ph": _rng.randf() * TAU})
	set_process(true)


func effacer() -> void:
	_s = {}
	_coins.clear()
	set_process(false)
	queue_redraw()


# ─────────────────────────────────────────────────────────────
# Préparer la scène
# ─────────────────────────────────────────────────────────────

func _nouvelle_scene(centre: Vector2, rayon: float, col: Color, mode: String) -> void:
	_s = {"age": 0.0, "c": centre, "R": rayon, "col": col, "mode": mode, "etoiles": [], "traits": [],
		"t_lock": 1.2, "fin": {}, "duree": 3.0}


# Éparpille n constellations sur tout l'écran (loin de l'astrolabe, loin les unes des
# autres), tracées l'une après l'autre. Renvoie l'instant où la dernière est finie.
# Avec des cibles (×10), la constellation i va à la carte i, dans sa teinte.
func _semer(n: int, t0: float, ecart: float, cibles: Array, teintes: Array, loin_du_centre: bool) -> float:
	var c: Vector2 = _s["c"]
	var R: float = _s["R"]
	var places: Array = []
	var zone := Rect2(110, 250, 860, 1900)
	for k in n:
		var meilleur := Vector2.ZERO
		var meilleure_d := -1.0
		for essai in 80:
			var p := Vector2(_rng.randf_range(zone.position.x, zone.end.x), _rng.randf_range(zone.position.y, zone.end.y))
			if loin_du_centre and p.distance_to(c) < R * 1.15:
				continue
			var d := 1e9
			for q in places:
				d = minf(d, p.distance_to(q))
			if d > meilleure_d:
				meilleure_d = d
				meilleur = p
			if d > 330.0:
				break
		places.append(meilleur)
	var fin := t0
	var formes := FORMES.duplicate()
	formes.shuffle()
	for k in n:
		var modele: Array = MODELES[formes[k % formes.size()]]
		var angle := _rng.randf_range(-0.7, 0.7)
		var brut: Array = modele[0]
		var centre_f := Vector2.ZERO
		for q in brut:
			centre_f += Vector2(q[0], q[1])
		centre_f /= brut.size()
		var pts: Array = []
		for q in brut:
			pts.append(places[k] + ((Vector2(q[0], q[1]) - centre_f) * ECHELLE_FIGURE).rotated(angle))
		var tg := t0 + k * ecart
		var t_on := {}
		var col: Color = _s["col"] if teintes.is_empty() else teintes[k][0]
		var mode: String = _s["mode"] if teintes.is_empty() else teintes[k][1]
		for ch in modele[1]:
			if not t_on.has(ch[0]):
				t_on[ch[0]] = tg
			for j in ch.size() - 1:
				var a: int = ch[j]
				var b: int = ch[j + 1]
				var ta: float = tg + j * SEG
				_s["traits"].append({"a": pts[a], "b": pts[b], "t0": ta, "t1": ta + SEG, "t_off": 99.0,
					"col": col, "mode": mode})
				if not t_on.has(b) or t_on[b] > ta + SEG:
					t_on[b] = ta + SEG
				fin = maxf(fin, ta + SEG)
		for i in pts.size():
			_s["etoiles"].append({"p0": pts[i], "cible": pts[i], "t_on": t_on.get(i, tg), "t_m0": 99.0, "dm": 0.5,
				"t_off": 99.0, "R": 18.0 if i == 0 else _rng.randf_range(11.0, 14.0), "col": col, "mode": mode,
				"flares": [], "suit": false, "carte": k, "ph": _rng.randf() * TAU, "w": _rng.randf_range(3.0, 6.0)})
	return fin


# ─────────────────────────────────────────────────────────────
# Le temps
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	if not _s.is_empty():
		_s["age"] += delta
		if _s["age"] > _s["duree"]:
			_s = {}
	for i in range(_coins.size() - 1, -1, -1):
		_coins[i]["age"] += delta
		if _coins[i]["age"] > _coins[i]["vie"]:
			_coins.remove_at(i)
	queue_redraw()
	if _s.is_empty() and _coins.is_empty():
		set_process(false)


static func _lisse(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


# L'échelle d'une étoile qui s'allume (elle jaillit, puis se pose), avec ses éclats.
static func _allumage(t: float, t_on: float, flares: Array) -> float:
	var d := t - t_on
	if d < 0.0:
		return 0.0
	var s := 1.0
	if d < 0.12:
		s = lerpf(0.3, 1.8, d / 0.12)
	elif d < 0.4:
		s = lerpf(1.8, 1.0, _lisse((d - 0.12) / 0.28))
	for tf in flares:
		var df := t - float(tf)
		if df >= 0.0 and df < 0.45:
			s *= 1.0 + 0.7 * sin(PI * df / 0.45)
	return s


# L'angle d'un cercle de l'astrolabe : il tourne vite, ralentit, se verrouille à zéro
# avec un petit clic.
static func _rotation(t: float, a0: float, t_lock: float) -> float:
	if t < t_lock:
		return deg_to_rad(a0) * pow(1.0 - t / t_lock, 3.0)
	var d := t - t_lock
	if d < 0.25:
		return deg_to_rad(-1.5 * signf(a0)) * sin(PI * d / 0.25)
	return 0.0


# ─────────────────────────────────────────────────────────────
# Le dessin
# ─────────────────────────────────────────────────────────────

func _draw() -> void:
	if not _s.is_empty():
		_dessiner_scene()
	for co in _coins:
		var age: float = co["age"]
		if age < 0.0:
			continue
		var a := 1.0 - _lisse((age - co["vie"] + 0.5) / 0.5)
		var s := _allumage(age, 0.0, []) * (0.85 + 0.2 * sin(_t * 5.0 + co["ph"]))
		_etoile(co["p"], co["R"] * s, teinte(co["col"], co["mode"], _t * 0.12), a, true)


func _dessiner_scene() -> void:
	var t: float = _s["age"]
	var c: Vector2 = _s["c"]
	var R: float = _s["R"]
	var t_lock: float = _s["t_lock"]
	var fin: Dictionary = _s["fin"]
	# la fin de l'astrolabe : il se resserre en l'embleme, ou il s'efface (×10)
	var s := 1.0
	var a_astro := 1.0
	if fin.get("type", "") == "resserre":
		s = lerpf(1.0, fin["s"], _lisse((t - fin["t"]) / 0.4))
		a_astro = 1.0 - _lisse((t - fin["t"] - 0.3) / 0.2)
	elif fin.get("type", "") == "s_efface":
		s = lerpf(1.0, fin["s"], _lisse((t - fin["t"]) / 0.45))
		a_astro = 1.0 - _lisse((t - fin["t"]) / 0.45)
	var col := teinte(_s["col"], _s["mode"], _t * 0.12)
	if a_astro > 0.0:
		_dessiner_astrolabe(t, c, R, s, t_lock, col, a_astro)
	# les traits des constellations
	for tr in _s["traits"]:
		var k := clampf((t - tr["t0"]) / (tr["t1"] - tr["t0"]), 0.0, 1.0)
		if k <= 0.0:
			continue
		var a := 0.85 * (1.0 - _lisse((t - tr["t_off"]) / 0.2))
		if a <= 0.0:
			continue
		var tc := teinte(tr["col"], tr["mode"], _t * 0.12)
		var b: Vector2 = tr["a"].lerp(tr["b"], _lisse(k))
		draw_line(tr["a"], b, Color(tc, a), 3.0, true)
		if k < 1.0:
			draw_circle(b, 5.5, Color(1, 1, 1, a))
	# les étoiles des constellations
	for e in _s["etoiles"]:
		var sc := _allumage(t, e["t_on"], e["flares"])
		if sc <= 0.0:
			continue
		var k := _lisse((t - e["t_m0"]) / e["dm"])
		var p: Vector2 = e["p0"].lerp(e["cible"], k)
		var a := 1.0 - _lisse((t - e["t_off"]) / 0.15)
		if e["suit"]:
			p = c + (p - c) * s
			a *= a_astro
			sc *= lerpf(1.0, 0.6, 1.0 - s)
		if a <= 0.0:
			continue
		var tw := 0.82 + 0.18 * sin(_t * e["w"] + e["ph"])
		var R_e: float = e["R"] * sc * tw
		_etoile(p, R_e, teinte(e["col"], e["mode"], _t * 0.12), a, e["R"] >= 16.0)
		_ping(p, t, [e["t_on"]] + e["flares"], e["R"], teinte(e["col"], e["mode"], _t * 0.12), a)


func _dessiner_astrolabe(t: float, c: Vector2, R: float, s: float, t_lock: float, col: Color, a: float) -> void:
	var r2 := _rotation(t, -300.0, t_lock)
	var r3 := _rotation(t, 200.0, t_lock)
	var k_in := _lisse(t / 0.6)
	# la platine, très discrète
	for f in [0.24, 0.56, 0.853, 1.12]:
		draw_arc(c, R * f * s, 0.0, TAU, 96, Color(IVOIRE, 0.12 * a * k_in), 1.5, true)
	for i in 24:
		var d := Vector2.from_angle(i * TAU / 24.0)
		draw_line(c + d * R * 0.24 * s, c + d * R * 1.12 * s, Color(IVOIRE, 0.06 * a * k_in), 1.2, true)
	# le cadran : son cercle se trace, ses graduations, ses quatre étoiles cardinales
	var k3 := _lisse((t - 0.15) / 0.45)
	if k3 > 0.0:
		draw_arc(c, R * s, -PI / 2 + r3, -PI / 2 + r3 + TAU * k3, 128, Color(col, 0.55 * a), 2.2, true)
	var kg := _lisse((t - 0.3) / 0.4)
	if kg > 0.0:
		for i in 48:
			var d := Vector2.from_angle(i * TAU / 48.0 - PI / 2 + r3)
			var L := R * (0.09 if i % 4 == 0 else 0.045)
			draw_line(c + d * (R - L * 0.5) * s, c + d * (R + L * 0.5) * s, Color(col, 0.55 * a * kg),
				2.6 if i % 4 == 0 else 1.8, true)
	# l'anneau de huit : sa chaîne, puis au verrou l'octogramme et la rose
	var P2: Array = []
	for k in 8:
		P2.append(c + Vector2.from_angle(k * TAU / 8.0 - PI / 2 + r2) * R * 0.72 * s)
	for k in 8:
		_trait(P2[k], P2[(k + 1) % 8], t, 0.1 + k * 0.05, 0.15 + k * 0.05, Color(col, 0.45 * a), 2.0)
	for k in 8:
		_trait(P2[k], P2[(k + 3) % 8], t, t_lock + 0.05, t_lock + 0.4, Color(col, 0.7 * a), 2.2)
		_trait(c, P2[k], t, t_lock + 0.1, t_lock + 0.35, Color(col, 0.85 * a), 2.4)
	for j in 4:
		var d := Vector2.from_angle(j * PI / 2 - PI / 2)
		_trait(c + d * R * 0.72 * s, c + d * R * s, t, t_lock + 0.15, t_lock + 0.4, Color(col, 0.85 * a), 2.4)
	for k in 8:
		var sc := _allumage(t, 0.1 + k * 0.05, [t_lock + 0.06])
		_etoile(P2[k], 17.0 * sc * s, col, a, true)
		_ping(P2[k], t, [0.1 + k * 0.05, t_lock + 0.06], 17.0, col, a)
	for j in 4:
		var p := c + Vector2.from_angle(j * PI / 2 - PI / 2 + r3) * R * s
		var sc := _allumage(t, 0.35 + j * 0.07, [t_lock + 0.12])
		_etoile(p, 20.0 * sc * s, col, a, true)
	var sc_c := _allumage(t, t_lock + 0.1, [])
	_etoile(c, 22.0 * sc_c * s, col, a, true)
	_ping(c, t, [t_lock + 0.1], 22.0, col, a)


# Un trait qui se trace de a vers b entre t0 et t1.
func _trait(a: Vector2, b: Vector2, t: float, t0: float, t1: float, col: Color, l: float) -> void:
	var k := _lisse((t - t0) / (t1 - t0))
	if k <= 0.0 or col.a <= 0.0:
		return
	draw_line(a, a.lerp(b, k), col, l, true)


# Une étoile nette : quatre branches fines (huit, avec des diagonales courtes), un cœur blanc.
func _etoile(p: Vector2, R: float, col: Color, a: float, diag: bool) -> void:
	if a <= 0.01 or R <= 0.5:
		return
	var pts := PackedVector2Array()
	var n := 8 if diag else 4
	for i in n:
		var ang := i * TAU / n - PI / 2
		var L := R if (not diag or i % 2 == 0) else R * 0.45
		pts.append(p + Vector2(cos(ang), sin(ang)) * L)
		pts.append(p + Vector2.from_angle(ang + PI / n) * R * 0.16)
	draw_colored_polygon(pts, Color(col, a))
	draw_circle(p, maxf(2.0, R * 0.19), Color(1, 1, 1, a))


# Un anneau fin qui s'élargit et s'efface quand une étoile s'allume ou brille.
func _ping(p: Vector2, t: float, temps: Array, R: float, col: Color, a: float) -> void:
	for tp in temps:
		var d := t - float(tp)
		if d >= 0.0 and d < 0.6:
			var k := d / 0.6
			draw_arc(p, R * lerpf(0.4, 2.3, sqrt(k)), 0.0, TAU, 32, Color(col, 0.8 * a * (1.0 - k)), 2.0, true)
