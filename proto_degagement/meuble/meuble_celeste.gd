extends Node3D

# LE MEUBLE « BASE CÉLESTE » DE LA NÉBULEUSE (01/10/2026, PROTOTYPE — DECISIONS 01/10).
#
# Maxim : « actuellement le plateau, c'est un rectangle avec du texte, ça n'a pas le look d'une vraie
# machine ; faudrait faire une vraie machine qui a le look cosmique comme machine de base ». Sa maquette (la
# « Base céleste ») : une arche, des colonnes, une scène au fond, un cadre d'or. Et le 01/10 au soir : « le
# titre La Poussette peut dégager ; j'aime le jeu de profondeur (une impression de long plateau) ; des
# petites animations sur la machine ; la barre de la Supernova intégrée au décor, qui gère aussi
# l'animation de la Supernova ».
#
# Tout est construit ici en volumes simples — des cylindres, des tores, une bande d'arche, des étoiles à
# facettes, des perles — et éclairé comme les pièces (meuble/or.gdshader) : rien n'est une image plaquée,
# sauf le ciel sous l'arche et le dessus du bloc (le mauve étoilé choisi par Maxim).
#   · l'arche porte les NEUF LUNES de la jauge (de la nouvelle à la nouvelle) : elles s'allument une à une ;
#   · l'astrolabe, au centre : ses anneaux tournent doucement ; à la Supernova, ils s'emballent, puis se
#     VERROUILLENT (le geste que Maxim aime, 24/09), et l'étoile du centre s'allume ;
#   · deux sphères armillaires sur les colonnes, une étoile nette au cœur ;
#   · le ciel : des étoiles nettes qui scintillent, deux constellations d'un trait d'or, une étoile filante.
# Un THÈME changera ces matières, le ciel, la lumière, la musique — jamais les pièces ni les objets.
#
# Les mesures sont celles de la physique (pusher_screen.gd) : le plateau de x0 à x1, du mur au bord.

const SH_OR := preload("res://meuble/or.gdshader")
const SH_CIEL := preload("res://meuble/ciel_fond.gdshader")
const SH_LUNE := preload("res://meuble/lune.gdshader")
const SH_ETOILE := preload("res://meuble/etoile_sprite.gdshader")
const SH_PLATEAU := preload("res://meuble/plateau.gdshader")

const OR := Vector3(1.0, 0.74, 0.30)
const OR_PALE := Vector3(1.0, 0.84, 0.52)
const PHASES := [0.0, 0.25, 0.5, 0.75, 1.0, -0.75, -0.5, -0.25, 0.0]

const Y_NAISSANCE := 2.2       # où l'arche naît, sur les colonnes
const R_ARCHE := 5.4           # le rayon du milieu de sa bande
const LARGEUR_ARCHE := 0.62
const EP_ARCHE := 0.36
const Z_ARCHE := 5.55
const Y_ASTRO := 4.55
const H_COLONNE := 5.0

var x0 := 0.46
var x1 := 10.34
var mur := 6.0
var bord := 14.0
var h_bloc := 0.5
var fente := 0.7
var fente_z0 := 10.8
var fente_z1 := 13.3
var cx := 5.4

var face_z := 8.4
var bloc: Node3D
var mat_ciel: ShaderMaterial
var mat_etoile: ShaderMaterial
var _anneaux: Array = []        # [Node3D, vitesse en °/s]
var _armillaires: Array = []
var _lunes: Array = []
var _eclats: Array = []         # [matière, force, phase]
var _t := 0.0
var _sn := 0.0                  # la Supernova, de 0 à 1
var _sn_t := 0.0
var _en_sn := false
var _mat_perles: ShaderMaterial
var _etoile_mi: MeshInstance3D
var _eclat_centre: MeshInstance3D


func construire(p: Dictionary) -> void:
	x0 = float(p.get("x0", x0))
	x1 = float(p.get("x1", x1))
	mur = float(p.get("mur", mur))
	bord = float(p.get("bord", bord))
	h_bloc = float(p.get("h_bloc", h_bloc))
	fente = float(p.get("fente", fente))
	fente_z0 = float(p.get("fente_z0", fente_z0))
	fente_z1 = float(p.get("fente_z1", fente_z1))
	cx = (x0 + x1) * 0.5
	_plateau()
	_parois()
	_avant()
	_bloc()
	_fronton()
	_ciel()
	_arche()
	_lunes_arche()
	_astrolabe()
	for cote in [-1.0, 1.0]:
		_colonne(cx + cote * R_ARCHE, cote)


# La jauge (les lunes allumées) et la Supernova, à chaque image.
func regler_jauge(n: int, en_supernova: bool) -> void:
	if en_supernova and not _en_sn:
		_en_sn = true
		_sn_t = 0.0
	elif not en_supernova and _en_sn:
		_en_sn = false
	var pulse := 0.72 + 0.28 * sin(_t * 9.0) if _en_sn else 1.0
	for i in _lunes.size():
		var m: ShaderMaterial = _lunes[i]
		m.set_shader_parameter("allume", 1.0 if i < n else 0.0)
		m.set_shader_parameter("pulse", pulse)


func _process(delta: float) -> void:
	_t += delta
	if bloc != null:
		bloc.position.z = face_z
	var vite := 1.0
	if _en_sn:
		_sn_t += delta
		_sn = minf(1.0, _sn + delta * 3.0)
		# les 2,4 premières secondes, les anneaux s'emballent ; puis ils se verrouillent, cran par cran
		vite = 1.0 + 70.0 * sin(clampf(_sn_t / 2.4, 0.0, 1.0) * PI) if _sn_t < 2.4 else 0.0
	else:
		_sn = maxf(0.0, _sn - delta * 1.2)
	for a in _anneaux:
		var n: Node3D = a[0]
		if vite > 0.0:
			n.rotation.z += deg_to_rad(float(a[1])) * delta * vite
		else:
			var cran := PI * 0.25
			n.rotation.z = lerpf(n.rotation.z, roundf(n.rotation.z / cran) * cran, minf(1.0, delta * 9.0))
	for a in _armillaires:
		(a[0] as Node3D).rotation.y += deg_to_rad(float(a[1])) * delta * (1.0 + 5.0 * _sn)
	for e in _eclats:
		var f: float = float(e[1]) * (0.78 + 0.22 * sin(_t * 2.3 + float(e[2])))
		(e[0] as ShaderMaterial).set_shader_parameter("force", f * (1.0 + 1.3 * _sn))
	if mat_etoile != null:
		mat_etoile.set_shader_parameter("allume", _sn * (0.7 + 0.25 * sin(_t * 9.0)))
		_etoile_mi.scale = Vector3.ONE * (1.0 + 0.16 * _sn * (0.5 + 0.5 * sin(_t * 6.0)))
		_eclat_centre.scale = Vector3.ONE * (1.0 + 2.2 * _sn)
	if _mat_perles != null:
		_mat_perles.set_shader_parameter("chenillard", 1.0 if _en_sn else 0.0)
	if mat_ciel != null:
		mat_ciel.set_shader_parameter("supernova", _sn)
		mat_ciel.set_shader_parameter("t_supernova", _sn_t)


# ─────────────────────────────────────────────────────────────
# Les parties
# ─────────────────────────────────────────────────────────────

# Le plateau, miroir du ciel, en trois morceaux (comme la physique) : plein, plus étroit le long des fentes,
# plein devant. Les fentes : du noir, une lèvre d'or.
func _plateau() -> void:
	var m := ShaderMaterial.new()
	m.shader = SH_PLATEAU
	m.set_shader_parameter("etoiles", load("res://ciel/etoiles-fines.png"))
	m.set_shader_parameter("x_bords", Vector2(x0, x1))
	var w := x1 - x0
	_plan(Rect2(x0 - 0.02, mur - 0.8, w + 0.04, fente_z0 - mur + 0.8), 0.0, m)
	_plan(Rect2(x0 + fente, fente_z0, w - 2.0 * fente, fente_z1 - fente_z0), 0.0, m)
	_plan(Rect2(x0 - 0.02, fente_z1, w + 0.04, bord - fente_z1), 0.0, m)
	var noir: ShaderMaterial = m.duplicate()
	noir.set_shader_parameter("sombre", 1.0)
	var lev := _mat_or()
	for g in [true, false]:
		var fx: float = x0 - 0.02 if g else x1 - fente
		_plan(Rect2(fx, fente_z0, fente + 0.02, fente_z1 - fente_z0), -0.03, noir)
		var lx: float = x0 + fente if g else x1 - fente
		_cylindre(Vector3(lx, 0.0, (fente_z0 + fente_z1) * 0.5), 0.035, fente_z1 - fente_z0, lev, Basis(Vector3.RIGHT, PI * 0.5))
		for z in [fente_z0, fente_z1]:
			var mx: float = (x0 + lx) * 0.5 if g else (lx + x1) * 0.5
			_cylindre(Vector3(mx, 0.0, z), 0.035, fente, lev, Basis(Vector3(0, 0, 1), PI * 0.5))


# Les parois du plateau : de l'émail bleu nuit, une main courante d'or ; aux coins de devant, une borne et sa boule.
func _parois() -> void:
	var email := _mat_email()
	var orm := _mat_or()
	var z0 := mur - 0.5
	var z1 := bord + 0.25
	for g in [true, false]:
		var x: float = x0 - 0.17 if g else x1 + 0.17
		_boite(Vector3(x, 0.3, (z0 + z1) * 0.5), Vector3(0.3, 0.75, z1 - z0), email)
		_cylindre(Vector3(x, 0.7, (z0 + z1) * 0.5), 0.11, z1 - z0, orm, Basis(Vector3.RIGHT, PI * 0.5))
		var xi: float = x + (0.152 if g else -0.152)
		_boite(Vector3(xi, 0.3, (z0 + z1) * 0.5), Vector3(0.02, 0.045, z1 - z0), orm)
		_cylindre(Vector3(x, 0.5, z1 - 0.05), 0.15, 1.0, orm)
		_sphere(Vector3(x, 1.12, z1 - 0.05), 0.18, orm)


# Le bord : une lèvre d'or ; dessous, la gouttière (noire) et le panneau de devant.
func _avant() -> void:
	var orm := _mat_or()
	var w := x1 - x0 + 0.7
	_cylindre(Vector3(cx, -0.03, bord + 0.03), 0.06, w, orm, Basis(Vector3(0, 0, 1), PI * 0.5))
	var noir := StandardMaterial3D.new()
	noir.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	noir.albedo_color = Color(0.0, 0.0, 0.0)
	_boite(Vector3(cx, -0.7, bord + 0.16), Vector3(w, 1.1, 0.2), noir)
	_boite(Vector3(cx, -0.75, bord + 0.36), Vector3(w, 1.3, 0.18), _mat_email(Vector3(0.025, 0.05, 0.14)))
	_cylindre(Vector3(cx, -0.1, bord + 0.36), 0.08, w + 0.1, orm, Basis(Vector3(0, 0, 1), PI * 0.5))


# Le bloc qui pousse : son dessus mauve étoilé (le choix de Maxim), sa face d'or, un filet pâle.
func _bloc() -> void:
	bloc = Node3D.new()
	add_child(bloc)
	var w := x1 - x0
	var dessus := StandardMaterial3D.new()
	dessus.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dessus.albedo_texture = load("res://interface/bloc-nebuleuse.png")
	dessus.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, 4.0)
	_poser(pm, dessus, Transform3D(Basis(), Vector3(cx, h_bloc + 0.002, -2.0)), bloc)
	_boite(Vector3(cx, h_bloc * 0.5, -0.04), Vector3(w, h_bloc, 0.08), _mat_or(), bloc)
	_cylindre(Vector3(cx, h_bloc, -0.02), 0.035, w, _mat_or(OR_PALE), Basis(Vector3(0, 0, 1), PI * 0.5), bloc)


# Le fronton, sous l'arche (le bloc glisse dessous) : de l'émail, une lèvre d'or, une moulure, neuf étoiles.
func _fronton() -> void:
	var email := _mat_email()
	var orm := _mat_or()
	var w := x1 - x0 + 0.6
	var bas := h_bloc + 0.03
	var haut := 1.12
	_boite(Vector3(cx, (bas + haut) * 0.5, 5.75), Vector3(w, haut - bas, 0.5), email)
	_cylindre(Vector3(cx, bas + 0.04, 6.01), 0.055, w, orm, Basis(Vector3(0, 0, 1), PI * 0.5))
	_boite(Vector3(cx, haut + 0.04, 5.72), Vector3(w + 0.1, 0.1, 0.62), orm)
	var et := _etoile_relief(0.15, 0.10, 0.045, 0.05, 8)
	for i in 11:
		var x := lerpf(x0 + 0.45, x1 - 0.45, float(i) / 10.0)
		_poser(et, orm, Transform3D(Basis(), Vector3(x, (bas + haut) * 0.5 + 0.03, 6.003)))


# Le ciel sous l'arche (meuble/ciel_fond.gdshader), découpé à sa forme.
func _ciel() -> void:
	mat_ciel = ShaderMaterial.new()
	mat_ciel.shader = SH_CIEL
	mat_ciel.set_shader_parameter("etoiles", load("res://ciel/etoiles-fines.png"))
	var r_int := R_ARCHE - LARGEUR_ARCHE * 0.5 + 0.02
	var bas := 1.1
	var haut := Y_NAISSANCE + r_int
	mat_ciel.set_shader_parameter("centre_arche", Vector2(cx, Y_NAISSANCE))
	mat_ciel.set_shader_parameter("rayon_arche", r_int)
	mat_ciel.set_shader_parameter("coin_bas_gauche", Vector2(cx - r_int, bas))
	mat_ciel.set_shader_parameter("coin_haut_droit", Vector2(cx + r_int, haut))
	var q := QuadMesh.new()
	q.size = Vector2(2.0 * r_int, haut - bas)
	_poser(q, mat_ciel, Transform3D(Basis(), Vector3(cx, (bas + haut) * 0.5, Z_ARCHE - 0.2)))


# L'arche : une bande d'or bombée, perlée sur ses deux bords.
func _arche() -> void:
	var orm := _mat_or()
	var centre := Vector3(cx, Y_NAISSANCE, Z_ARCHE)
	_poser(_bande_arc(R_ARCHE, LARGEUR_ARCHE, EP_ARCHE, 0.0, PI, 120), orm, Transform3D(Basis(), centre))
	var perles: Array = []
	for k in 2:
		var r: float = R_ARCHE + (LARGEUR_ARCHE * 0.5 + 0.035) * (1.0 if k == 0 else -1.0)
		var n := 66 if k == 0 else 58
		for i in n + 1:
			var a := PI * float(i) / n
			perles.append(centre + Vector3(cos(a) * r, sin(a) * r, EP_ARCHE * 0.2))
	_mat_perles = _mat_or(OR_PALE)
	_mat_perles.set_shader_parameter("n_perles", float(perles.size()))
	_mat_perles.set_shader_parameter("couleur_allume", Vector3(1.0, 0.97, 0.86))
	_perles(perles, 0.05, _mat_perles, null, true)


# Les neuf lunes de la jauge, incrustées dans l'arche, de gauche à droite (la pleine au sommet).
func _lunes_arche() -> void:
	var d := _disque(0.25, 0.05)
	var centre := Vector3(cx, Y_NAISSANCE, Z_ARCHE)
	for i in 9:
		var a := deg_to_rad(162.0 - 18.0 * i)
		var m := ShaderMaterial.new()
		m.shader = SH_LUNE
		m.set_shader_parameter("phase", PHASES[i])
		_poser(d, m, Transform3D(Basis(), centre + Vector3(cos(a) * R_ARCHE, sin(a) * R_ARCHE, EP_ARCHE * 0.5 + 0.02)))
		_lunes.append(m)


# L'astrolabe : un anneau fixe gradué, deux anneaux qui tournent en sens contraire (des perles, une règle),
# un disque d'émail, la rose des vents à huit branches, une boule d'or, une étoile nette.
func _astrolabe() -> void:
	var orm := _mat_or()
	var pale := _mat_or(OR_PALE)
	var face := Basis(Vector3.RIGHT, PI * 0.5)
	var astro := Node3D.new()
	astro.position = Vector3(cx, Y_ASTRO, Z_ARCHE - 0.05)
	add_child(astro)
	_tore(Vector3.ZERO, 2.45, 0.085, orm, face, astro)
	_tore(Vector3.ZERO, 2.30, 0.03, orm, face, astro)
	var graduations: Array = []
	for i in 72:
		var a := TAU * float(i) / 72.0
		var longue := i % 6 == 0
		var l := 0.24 if longue else 0.12
		var b := Basis(Vector3(0, 0, 1), a).scaled(Vector3(l, 0.028 if not longue else 0.04, 0.035))
		graduations.append(Transform3D(b, Vector3(cos(a), sin(a), 0.0) * (2.56 + l * 0.5)))
	_boites(graduations, orm, astro)
	var b2 := Node3D.new()
	astro.add_child(b2)
	_tore(Vector3.ZERO, 2.02, 0.055, orm, face, b2)
	var pts: Array = []
	for i in 8:
		var a := TAU * float(i) / 8.0
		pts.append(Vector3(cos(a) * 2.02, sin(a) * 2.02, 0.0))
	_perles(pts, 0.09, pale, b2)
	_anneaux.append([b2, 7.0])
	var b3 := Node3D.new()
	astro.add_child(b3)
	_tore(Vector3.ZERO, 1.6, 0.05, orm, face, b3)
	_boite(Vector3.ZERO, Vector3(3.2, 0.07, 0.04), orm, b3)
	_anneaux.append([b3, -11.0])
	_cylindre(Vector3(0, 0, -0.03), 1.12, 0.06, _mat_email(Vector3(0.03, 0.07, 0.19)), face, astro)
	_tore(Vector3.ZERO, 1.12, 0.04, orm, face, astro)
	mat_etoile = _mat_or()
	_etoile_mi = _poser(_etoile_relief(1.05, 0.62, 0.30, 0.30, 8), mat_etoile, Transform3D(Basis(), Vector3(0, 0, 0.02)), astro)
	_sphere(Vector3(0, 0, 0.32), 0.09, pale, astro)
	_eclat_centre = _eclat(astro.position + Vector3(0, 0, 0.5), 1.0, 0.9)


# Une colonne : un fût d'émail, des bagues d'or, un chapiteau ; dessus, une sphère armillaire qui tourne.
func _colonne(x: float, cote: float) -> void:
	var orm := _mat_or()
	var z := Z_ARCHE
	var bas := -0.9
	var haut := H_COLONNE
	_cylindre(Vector3(x, (bas + haut) * 0.5, z), 0.3, haut - bas, _mat_email())
	# quatre filets d'or le long du fût
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * k
		_cylindre(Vector3(x + cos(a) * 0.3, (bas + haut) * 0.5, z + sin(a) * 0.3), 0.022, haut - bas - 0.4, orm)
	_cylindre(Vector3(x, bas + 0.2, z), 0.44, 0.4, orm)
	_tore(Vector3(x, bas + 0.45, z), 0.36, 0.06, orm)
	_tore(Vector3(x, Y_NAISSANCE - 0.28, z), 0.34, 0.06, orm)
	_cylindre(Vector3(x, Y_NAISSANCE - 0.06, z), 0.4, 0.24, orm)
	_tore(Vector3(x, haut - 0.32, z), 0.35, 0.06, orm)
	_cylindre(Vector3(x, haut - 0.1, z), 0.46, 0.2, orm)
	_cylindre(Vector3(x, haut + 0.05, z), 0.36, 0.1, orm)
	var arm := Node3D.new()
	arm.position = Vector3(x, haut + 0.86, z)
	add_child(arm)
	_cylindre(Vector3(0, -0.6, 0), 0.05, 0.4, orm, Basis(), arm)
	var rot := Node3D.new()
	arm.add_child(rot)
	_tore(Vector3.ZERO, 0.58, 0.035, orm, Basis(), rot)
	_tore(Vector3.ZERO, 0.58, 0.035, orm, Basis(Vector3.RIGHT, PI * 0.5), rot)
	_tore(Vector3.ZERO, 0.64, 0.028, _mat_or(OR_PALE), Basis(Vector3(0, 0, 1), deg_to_rad(23.5)), rot)
	var coeur := _mat_or(OR_PALE)
	coeur.set_shader_parameter("allume", 1.0)
	_sphere(Vector3.ZERO, 0.11, coeur, arm)
	_eclat(arm.position, 1.15, 1.0)
	_armillaires.append([rot, 14.0 * cote])


# ─────────────────────────────────────────────────────────────
# Les outils
# ─────────────────────────────────────────────────────────────

func _mat_or(teinte := OR) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_OR
	m.set_shader_parameter("teinte", teinte)
	return m


func _mat_email(c := Vector3(0.035, 0.075, 0.20)) -> ShaderMaterial:
	var m := _mat_or()
	m.set_shader_parameter("email", 1.0)
	m.set_shader_parameter("couleur_email", c)
	return m


func _poser(mesh: Mesh, mat: Material, t: Transform3D, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = t
	(parent if parent != null else self).add_child(mi)
	return mi


func _plan(r: Rect2, y: float, mat: Material) -> void:
	var pm := PlaneMesh.new()
	pm.size = r.size
	_poser(pm, mat, Transform3D(Basis(), Vector3(r.position.x + r.size.x * 0.5, y, r.position.y + r.size.y * 0.5)))


func _boite(c: Vector3, taille: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = taille
	return _poser(m, mat, Transform3D(Basis(), c), parent)


func _boites(ts: Array, mat: Material, parent: Node3D) -> void:
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bm
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	parent.add_child(mi)


func _cylindre(c: Vector3, r: float, h: float, mat: Material, b := Basis(), parent: Node3D = null) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 40
	m.rings = 1
	return _poser(m, mat, Transform3D(b, c), parent)


func _tore(c: Vector3, rayon: float, tube: float, mat: Material, b := Basis(), parent: Node3D = null) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = rayon - tube
	m.outer_radius = rayon + tube
	m.rings = 128
	m.ring_segments = 14
	return _poser(m, mat, Transform3D(b, c), parent)


func _sphere(c: Vector3, r: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = 2.0 * r
	m.radial_segments = 28
	m.rings = 14
	return _poser(m, mat, Transform3D(Basis(), c), parent)


func _perles(points: Array, r: float, mat: Material, parent: Node3D = null, rangs := false) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = 2.0 * r
	sm.radial_segments = 12
	sm.rings = 6
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = rangs
	mm.mesh = sm
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, Transform3D(Basis(), points[i]))
		if rangs:
			mm.set_instance_custom_data(i, Color(float(i) / points.size(), 0, 0, 0))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	(parent if parent != null else self).add_child(mi)


# Une étoile nette, toujours face à l'œil (meuble/etoile_sprite.gdshader) ; elle scintille.
func _eclat(c: Vector3, taille: float, force: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(taille, taille)
	var m := ShaderMaterial.new()
	m.shader = SH_ETOILE
	m.set_shader_parameter("force", force)
	var mi := _poser(q, m, Transform3D(Basis(), c))
	_eclats.append([m, force, randf() * TAU])
	return mi


# Une bande d'arche : un profil presque carré aux angles arrondis, balayé le long d'un arc (dans le plan XY).
func _bande_arc(rayon: float, largeur: float, ep: float, a0: float, a1: float, n: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var m := 24
	var e := 0.42
	var prof: Array = []
	for j in m:
		var t := TAU * float(j) / m
		var c := cos(t)
		var s := sin(t)
		var dr := signf(c) * pow(absf(c), e) * largeur * 0.5
		var dz := signf(s) * pow(absf(s), e) * ep * 0.5
		var nn := Vector2(signf(c) * pow(absf(c), 2.0 - e) / largeur, signf(s) * pow(absf(s), 2.0 - e) / ep).normalized()
		prof.append([dr, dz, nn.x, nn.y])
	for i in n:
		for j in m:
			for q in [[i, j], [i + 1, j], [i + 1, (j + 1) % m], [i, j], [i + 1, (j + 1) % m], [i, (j + 1) % m]]:
				var a := lerpf(a0, a1, float(q[0]) / n)
				var d := Vector3(cos(a), sin(a), 0.0)
				var pr: Array = prof[q[1]]
				st.set_normal((d * float(pr[2]) + Vector3(0, 0, float(pr[3]))).normalized())
				st.set_uv(Vector2(float(q[0]) / n, float(q[1]) / m))
				st.add_vertex(d * (rayon + float(pr[0])) + Vector3(0, 0, float(pr[1])))
	return st.commit()


# Une étoile à facettes (une rose des vents) : les pointes longues et courtes alternent, chaque branche a
# deux pans qui prennent la lumière différemment.
func _etoile_relief(r_long: float, r_court: float, r_creux: float, h: float, branches := 8) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sommet := Vector3(0, 0, h)
	for k in branches:
		var a := TAU * float(k) / branches + PI * 0.5
		var r := r_long if k % 2 == 0 else r_court
		var pointe := Vector3(cos(a) * r, sin(a) * r, 0.0)
		var cg := Vector3(cos(a - PI / branches) * r_creux, sin(a - PI / branches) * r_creux, 0.0)
		var cd := Vector3(cos(a + PI / branches) * r_creux, sin(a + PI / branches) * r_creux, 0.0)
		for tri in [[sommet, cg, pointe], [sommet, pointe, cd]]:
			var nrm: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			if nrm.z < 0.0:
				nrm = -nrm
			for v in tri:
				st.set_normal(nrm)
				st.set_uv(Vector2(0.5, 0.5))
				st.add_vertex(v)
	return st.commit()


# Un disque face à l'œil (les lunes) : UV = la face, (0,5 ; 0,5) au centre ; la tranche prend l'or de la bague.
func _disque(r: float, ep: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	for i in n:
		var a0 := TAU * float(i) / n
		var a1 := TAU * float(i + 1) / n
		for q in [Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1))]:
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(Vector2(q.x * 0.5 + 0.5, 0.5 - q.y * 0.5))
			st.add_vertex(Vector3(q.x * r, q.y * r, ep * 0.5))
		var p0 := Vector3(cos(a0), sin(a0), 0.0)
		var p1 := Vector3(cos(a1), sin(a1), 0.0)
		for c in [[p0, -1.0], [p1, -1.0], [p1, 1.0], [p0, -1.0], [p1, 1.0], [p0, 1.0]]:
			st.set_normal(c[0])
			st.set_uv(Vector2(0.5, 0.99))
			st.add_vertex((c[0] as Vector3) * r + Vector3(0, 0, float(c[1]) * ep * 0.5))
	return st.commit()
