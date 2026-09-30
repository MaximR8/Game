class_name Effets
extends Control

# LES EFFETS DE L'INTERFACE (FEATURES ⑮, 26/09) : des étoiles nettes qui s'allument, des grains
# de poussière qui filent le long d'une courbe, des constellations tracées à la plume, des étoiles
# filantes. Tout est DESSINÉ (pas d'image) : net à toutes les tailles.
# ⛔ Ni halo, ni flou, ni éclair (les goûts de Maxim : des étoiles nettes).
#
# Une couche au-dessus de tout le jeu (main.gd) : Effets.global. Un écran peut aussi avoir la sienne.

static var global: Effets

const OR_CLAIR := Color("#f6e2b0")
const OR_GRAIN := Color("#e9bf62")
const IVOIRE := Color("#efe9dc")

enum { ETOILE, GRAIN, TRAIT, FILANTE }

var _items: Array = []
var _vide_dessine := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


# La couche d'effets du calque où vit `noeud` (le jeu, ou une surimpression de la collection) :
# créée au besoin, toujours au-dessus du reste de son calque.
static func pour(noeud: Node) -> Effets:
	var p := noeud
	while p != null and not (p is CanvasLayer):
		p = p.get_parent()
	if p == null:
		if global != null and global.get_parent() != null:
			global.get_parent().move_child(global, -1)
		return global
	var fx := p.get_node_or_null("Effets") as Effets
	if fx == null:
		fx = Effets.new()
		fx.name = "Effets"
		fx.size = Vector2(1080, 2400)
		p.add_child(fx)
	p.move_child(fx, -1)
	return fx


# Un objet qui s'envole : il bondit hors de son point de départ, file vers sa cible en semant des
# étoiles, et rapetisse jusqu'à la taille de l'icône qui l'attend. fin : appelé à l'arrivée.
func envoler(tex: Texture2D, depart: Vector2, cible: Vector2, taille: float, duree: float, fin := Callable(),
		echelle_fin := 0.7, trainee := true, montee := 570.0, approche := 510.0) -> void:
	var im := TextureRect.new()
	im.texture = tex
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	im.size = Vector2(taille, taille)
	im.pivot_offset = im.size * 0.5
	im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(im)
	var b := depart + Vector2(-90.0 if depart.x < 540.0 else 90.0, -montee)
	var c := cible + Vector2(0, approche)
	var dernier := [0.0]
	var suivre := func(t: float):
		var e := lisse(t)
		var u := 1.0 - e
		var p := depart * (u * u * u) + b * (3.0 * u * u * e) + c * (3.0 * u * e * e) + cible * (e * e * e)
		var ech := lerpf(0.75, 1.3, t / 0.2) if t < 0.2 else lerpf(1.3, echelle_fin, (t - 0.2) / 0.8)
		im.position = p - im.size * 0.5
		im.scale = Vector2(ech, ech)
		im.rotation = sin(t * 9.0) * 0.2 * (1.0 - t)
		if trainee and t > 0.15 and t < 0.9 and maintenant() - float(dernier[0]) > 0.055:
			dernier[0] = maintenant()
			etoile(p + Vector2(randf_range(-15, 15), randf_range(-15, 15)), randf_range(9.0, 16.0), 0.38)
	var tw := create_tween()
	tw.tween_method(suivre, 0.0, 1.0, duree)
	tw.tween_callback(func():
		im.queue_free()
		if fin.is_valid():
			fin.call())


static func maintenant() -> float:
	return Time.get_ticks_msec() / 1000.0


func _ajouter(it: Dictionary) -> void:
	it["t0"] = maintenant() + float(it.get("retard", 0.0))
	_items.append(it)
	set_process(true)


# Une étoile qui s'allume puis s'éteint (en tournant un peu).
func etoile(p: Vector2, r: float, duree := 0.45, retard := 0.0, couleur := OR_CLAIR) -> void:
	_ajouter({"type": ETOILE, "p": p, "r": r, "duree": duree, "retard": retard, "c": couleur, "rot": randf() * 0.6})


# Des étincelles sur le pourtour d'un rectangle (un bouton lâché, un compteur qui reçoit).
func etincelles(rect: Rect2, n := 3, r := 16.0) -> void:
	for i in n:
		var p: Vector2
		if randf() < 0.5:
			p = Vector2(rect.position.x + randf() * rect.size.x, rect.position.y if randf() < 0.5 else rect.end.y)
		else:
			p = Vector2(rect.position.x if randf() < 0.5 else rect.end.x, rect.position.y + randf() * rect.size.y)
		etoile(p, r * randf_range(0.8, 1.2), 0.5, i * 0.05)


# Un grain de poussière qui file de a vers c en passant près de b (une courbe), avec sa traîne.
# fin : appelé à l'arrivée.
func grain(a: Vector2, b: Vector2, c: Vector2, duree: float, retard := 0.0, couleur := OR_GRAIN, gros := 1.0,
		fin := Callable(), sortie := false, fondu := false) -> void:
	_ajouter({"type": GRAIN, "a": a, "b": b, "c": c, "duree": duree, "retard": retard, "c_": couleur, "gros": gros,
		"fin": fin, "sortie": sortie, "fondu": fondu})


# Une constellation tracée à la plume : ses traits se dessinent, ses étoiles s'allument, puis tout s'efface.
func constellation(pts: PackedVector2Array, duree: float, retard := 0.0, couleur := IVOIRE, epais := 2.0, etoiles := OR_CLAIR) -> void:
	_ajouter({"type": TRAIT, "pts": pts, "duree": duree, "retard": retard, "c": couleur, "epais": epais, "ce": etoiles})


# Une étoile filante d'or, de a vers b.
func filante(a: Vector2, b: Vector2, queue: float, duree: float, retard := 0.0) -> void:
	_ajouter({"type": FILANTE, "a": a, "b": b, "queue": queue, "duree": duree, "retard": retard})


func vider() -> void:
	_items.clear()
	queue_redraw()


func _process(_d: float) -> void:
	var t := maintenant()
	var garde: Array = []
	var finis: Array = []
	for it in _items:
		if (t - float(it["t0"])) / float(it["duree"]) >= 1.0:
			finis.append(it)
		else:
			garde.append(it)
	_items = garde
	for it in finis:
		var f = it.get("fin")
		if f is Callable and (f as Callable).is_valid():
			(f as Callable).call()
	queue_redraw()
	if _items.is_empty():
		set_process(false)


static func lisse(t: float) -> float:
	return 4.0 * t * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0


static func sortie_cubique(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


static func bez(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return a * (u * u) + b * (2.0 * u * t) + c * (t * t)


# Une étoile nette : quatre branches fines, quatre courtes, un cœur blanc. Le contour est repassé
# en trait lissé : les branches fines ne crénèlent pas.
static func dessiner_etoile(ci: CanvasItem, p: Vector2, R: float, a: float, rot := 0.0, col := OR_CLAIR) -> void:
	if a <= 0.01 or R <= 0.5:
		return
	for k in 2:
		var r := R if k == 0 else R * 0.48
		var w := R * (0.1 if k == 0 else 0.08)
		var base := rot + k * PI / 4.0
		var pts := PackedVector2Array()
		for i in 4:
			var ang := base + i * PI / 2.0
			pts.append(p + Vector2.from_angle(ang - PI / 2.0) * r)
			pts.append(p + Vector2.from_angle(ang - PI / 4.0) * w * 1.41)
		ci.draw_colored_polygon(pts, Color(col, a))
		pts.append(pts[0])
		ci.draw_polyline(pts, Color(col, a * 0.8), 1.0, true)
	ci.draw_circle(p, maxf(1.6, R * 0.13), Color(1, 1, 1, a))


func _draw() -> void:
	var t := maintenant()
	for it in _items:
		var k := (t - float(it["t0"])) / float(it["duree"])
		if k < 0.0 or k >= 1.0:
			continue
		match int(it["type"]):
			ETOILE:
				var s := sin(PI * k)
				dessiner_etoile(self, it["p"], float(it["r"]) * (0.3 + 0.7 * s), s, float(it["rot"]) + k * 0.7, it["c"])
			GRAIN:
				var e := sortie_cubique(k) if bool(it["sortie"]) else lisse(k)
				var fond := 1.0 - maxf(0.0, (k - 0.8) / 0.2) if bool(it["fondu"]) else 1.0
				var gros := float(it["gros"])
				for q in 4:
					var p := bez(it["a"], it["b"], it["c"], maxf(0.0, e - q * 0.035))
					var al := (1.0 - q * 0.24) * minf(1.0, k * 5.0) * fond
					var col: Color = Color(1.0, 0.98, 0.92) if q == 0 else it["c_"]
					draw_circle(p, (5.0 if q == 0 else 4.0 - q * 0.6) * gros, Color(col, al))
			TRAIT:
				var pts: PackedVector2Array = it["pts"]
				var n := pts.size()
				var fait := minf(1.0, k / 0.5) * (n - 1)
				var fond2 := 1.0 - (k - 0.72) / 0.28 if k > 0.72 else 1.0
				var ligne := PackedVector2Array()
				for j in int(floor(fait)) + 1:
					ligne.append(pts[j])
				var jj := int(floor(fait))
				if jj < n - 1:
					ligne.append(pts[jj].lerp(pts[jj + 1], fait - jj))
				if ligne.size() >= 2:
					draw_polyline(ligne, Color(it["c"], 0.85 * fond2), float(it["epais"]), true)
				for m in mini(n - 1, int(ceil(fait))) + 1:
					dessiner_etoile(self, pts[m], 16.0 if m == 0 else 12.0, fond2, 0.0, it["ce"])
			FILANTE:
				var e3 := sortie_cubique(k)
				var a: Vector2 = it["a"]
				var b: Vector2 = it["b"]
				var tete := a.lerp(b, e3)
				var dirr := (b - a).normalized()
				var q2 := float(it["queue"]) * minf(1.0, k * 3.0)
				var n2 := 8
				for i in n2:
					var p0 := tete - dirr * q2 * float(i) / n2
					var p1 := tete - dirr * q2 * float(i + 1) / n2
					draw_line(p0, p1, Color(OR_CLAIR, (1.0 - k) * (1.0 - float(i) / n2)), 3.0, true)
				dessiner_etoile(self, tete, 16.0, 1.0 - k * 0.6, k * 2.0)
