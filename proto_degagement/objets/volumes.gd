class_name Volumes
extends RefCounted

# LES OBJETS DE L'UNIVERS EN VOLUME (FEATURES ⑭, 26/09).
#
# Chaque objet (l'étoile d'invocation, la poussière d'étoile, les pierres) est rendu par
# design/objets/render_objets.py --univers --taille 256 --3d … : son relief (normales,
# occlusion, matière), la couleur de son corps, et sa silhouette (objets/3d/). Ici, la
# silhouette devient un volume — dessus, dessous, tranche —, éclairé EN DIRECT par
# objets/corps.gdshader (mode_objet) : ses reflets bougent quand il penche, comme les pièces.
# Sert à la poussette, et à la pierre qui se pose sur la carte quand elle évolue.

const DOSSIER := "res://objets/3d/"
const OR := Color(1.0, 0.74, 0.30)
const ARGENT := Color(0.86, 0.885, 0.93)

static var _defs := {}


# Tout ce qu'il faut pour dessiner l'objet `nom` (le nom de son image : « pierre-feu ») :
# {"relief", "corps", "contour", "disque", "tranche"} — vide s'il n'existe pas.
static func objet(nom: String) -> Dictionary:
	if _defs.is_empty():
		_charger()
	return _defs.get(nom, {})


static func _charger() -> void:
	var f := FileAccess.open(DOSSIER + "contours.json", FileAccess.READ)
	if f == null:
		push_error("Volumes : objets/3d/contours.json manque")
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	for nom in d:
		var e: Dictionary = d[nom]
		var pts := PackedVector2Array()
		for q in e["contour"]:
			pts.append(Vector2(float(q[0]), float(q[1])))
		var sphere := bool(e.get("sphere", false))
		var o := {"contour": pts, "disque": bool(e.get("dessus_disque", false)), "sphere": sphere, "tranche": _tranche(str(nom))}
		if sphere:
			# une bille : son voile et l'objet du centre (objets/bille.gdshader)
			o["voile"] = load(DOSSIER + str(nom) + "-voile.png")
			o["coeur"] = load(DOSSIER + str(nom) + "-coeur.png")
			var t: Array = e.get("teinte", [0.8, 0.7, 1.0])
			o["teinte"] = Vector3(float(t[0]), float(t[1]), float(t[2]))
		else:
			o["relief"] = load(DOSSIER + str(nom) + "-relief.png")
			o["corps"] = load(DOSSIER + str(nom) + "-corps.png")
		_defs[str(nom)] = o


# La matière du bord : argent pour la lune et le globe, verre violet pour la bille, or sinon.
static func _tranche(nom: String) -> Color:
	if nom in ["poussiere-etoile", "pierre-lune"]:
		return ARGENT
	if nom == "etoile-invocation":
		return Color(0.45, 0.38, 0.70)
	return OR


# Le volume : la silhouette (unités de l'image, de −1 à 1) à l'échelle r, épaisse de ep.
# Dessus : COLOR.r = 1 ; dessous : 0 ; tranche : 0,5 — comme le disque des pièces.
# « disque » : le dessus est un disque (l'étoile : ses astéroïdes débordent de sa silhouette ;
# le shader ne garde que ce que l'image couvre).
static func volume(contour: PackedVector2Array, disque: bool, r: float, ep: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := ep * 0.5
	var dessus := contour
	if disque:
		dessus = PackedVector2Array()
		for i in 48:
			dessus.append(Vector2(cos(TAU * i / 48.0), sin(TAU * i / 48.0)) * 0.99)
	var n := dessus.size()
	for face in [1.0, -1.0]:
		for i in n:
			for q in [Vector2.ZERO, dessus[i], dessus[(i + 1) % n]]:
				st.set_color(Color(1.0 if face > 0.0 else 0.0, 0, 0))
				st.set_normal(Vector3(0, face, 0))
				st.set_uv(q * 0.5 + Vector2(0.5, 0.5))
				st.add_vertex(Vector3(q.x * r, h * face, q.y * r))
	var m := contour.size()
	var tour := 0.0
	for i in m:
		tour += contour[i].distance_to(contour[(i + 1) % m])
	var fait := 0.0
	for i in m:
		var a := contour[i]
		var b := contour[(i + 1) % m]
		var e := b - a
		var nrm := Vector3(e.y, 0, -e.x).normalized()
		var milieu := (a + b) * 0.5
		if nrm.x * milieu.x + nrm.z * milieu.y < 0.0:
			nrm = -nrm
		var u0 := fait / tour
		fait += e.length()
		var u1 := fait / tour
		for c in [[a, -h, u0], [b, -h, u1], [b, h, u1], [a, -h, u0], [b, h, u1], [a, h, u0]]:
			var pp: Vector2 = c[0]
			st.set_color(Color(0.5, 0, 0))
			st.set_normal(nrm)
			st.set_uv(Vector2(float(c[2]), 0.5 + float(c[1]) / ep))
			st.add_vertex(Vector3(pp.x * r, float(c[1]), pp.y * r))
	return st.commit()


# 🔴 Les billes (26/09 — Maxim : « des sphères, transparentes ») : la poussière d'étoile et l'étoile
#    d'invocation sont de vraies sphères de verre, un peu aplaties, et non des volumes extrudés (« des
#    boîtes à médicaments »). Leur corps physique reste le même disque : le jeu ne change pas.
# 🔴 0,42 (26/09) : la vue est oblique ; aplatie ainsi, la bille a un contour presque rond à l'écran
#    (une vraie boule s'y affichait en œuf) — son éclairage, lui, est celui d'une sphère (bille.gdshader).
const APLATI := 0.42            # la hauteur d'une bille, en part de son diamètre
const TAILLE_BILLE := 1.0       # son rayon, en part du rayon du corps


static func bille_mesh(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r * TAILLE_BILLE
	m.height = 2.0 * r * TAILLE_BILLE * APLATI
	m.radial_segments = 48
	m.rings = 24
	return m


static func matiere_bille(nom: String, k_h: float, r: float) -> ShaderMaterial:
	var d := objet(nom)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://objets/bille.gdshader")
	mat.set_shader_parameter("k_h", k_h)
	mat.set_shader_parameter("rayon", r * TAILLE_BILLE)
	mat.set_shader_parameter("aplati", APLATI)
	if not d.is_empty():
		mat.set_shader_parameter("voile", d["voile"])
		mat.set_shader_parameter("coeur", d["coeur"])
		mat.set_shader_parameter("teinte", d["teinte"])
	return mat


# La matière d'un objet, prête à poser sur un MeshInstance3D.
static func matiere(nom: String, k_h: float) -> ShaderMaterial:
	var d := objet(nom)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://objets/corps.gdshader")
	mat.set_shader_parameter("k_h", k_h)
	if not d.is_empty():
		mat.set_shader_parameter("relief_objet", d["relief"])
		mat.set_shader_parameter("corps_objet", d["corps"])
		mat.set_shader_parameter("mode_objet", 1.0)
		var c: Color = d["tranche"]
		mat.set_shader_parameter("metal_tranche", Vector3(c.r, c.g, c.b))
	return mat
