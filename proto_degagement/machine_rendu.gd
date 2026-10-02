class_name MachineRendu
extends Control

# LE RENDU DE LA POUSSETTE, EN 3D (FEATURES ⑦, 25/09).
#
# Les pièces et les objets sont de vrais disques 3D, dessinés d'un seul coup (un
# MultiMesh : un appel de dessin pour toutes les pièces, un pour leurs ombres) dans une
# vue à part (SubViewport), au plein de la résolution de l'écran, lissée (MSAA ×4).
# Leur métal est calculé en temps réel (objets/corps.gdshader) : le relief et les
# reflets bougent quand une pièce penche. La projection est celle du dessin d'avant.
#
# 🔴 Chaque pièce a SA case dans le MultiMesh. Quand la poussette retire une pièce, elle
#    doit l'OUBLIER ici d'abord (oublier()), sinon sa case reste dessinée.
# 🔴 UN SEUL ENVOI PAR IMAGE (25/09) : toutes les cases sont écrites dans un tableau, puis
#    envoyées d'un coup (multimesh_set_buffer). Case par case, c'était ~1 000 appels au
#    serveur de rendu par image — jusqu'à 9 ms sur le PC : les à-coups de la poussette.
#    (Et on ne peut pas compter sur le sommeil des pièces : le tas touche le bloc qui
#    bouge, le moteur les garde TOUTES éveillées — mesuré : 318 sur 318.)
# 🔴 Avant (le 2D) : 900 dessins par image depuis GDScript, ~6 ms sur le PC — le premier
#    poste de la poussette, et ce qui faisait « JPEG » (des images de 128 px agrandies).

const SH_CORPS := preload("res://objets/corps.gdshader")
const SH_OMBRE := preload("res://objets/ombre.gdshader")
# (02/10) la machine dans son décor peint (machines/machine_decor.gd) : la vue en perspective, la profondeur étirée à
# l'image (la place des corps, pas leur forme) ; les billes, de vraies sphères posées sur leur corps
const SH_CORPS_VUE := preload("res://machines/corps_vue.gdshader")
const SH_OMBRE_VUE := preload("res://machines/ombre_vue.gdshader")
const SH_BILLE_VUE := preload("res://machines/bille_vue.gdshader")
const TEX_RELIEF := preload("res://objets/piece-relief.png")
const SEGMENTS := 36
const CASES := 420

var zone: Rect2
var u := 100.0
var k_h := 0.9
var bord := 14.0
var h_bloc := 0.5
var mur := 6.0
var vue: SubViewport
var ecran: TextureRect
var camera: Camera3D
var mm_pieces: MultiMesh
var mm_ombres: MultiMesh
var _cases := {}                 # corps -> sa case
var _libres: Array[int] = []
var _haut := 0                   # la plus haute case utilisée + 1
var _objets := {}                # corps (objet) -> [MeshInstance3D, ombre MeshInstance3D, matière, matière d'ombre]
var _meshes_objets := {}         # « type|rayon » -> ArrayMesh
var _images := {}                # type d'objet -> le nom de son image (« pierre-feu ») : Volumes.objet()
var face_z := 8.4
var r_p := 0.4
var ep_p := 0.12
var us_maj := 0.0                # le temps de maj() (µs, lissé) : le compteur des outils
var _buf_p := PackedFloat32Array()     # les cases des pièces : 12 (transformée) + 4 (données) par case
var _buf_o := PackedFloat32Array()     # les cases des ombres
const PAS_BUF := 16
var _zero := Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -50, 0))
var _vue_perspective := false
var _etirement := 1.0
var _spheres := {}


func preparer(p_zone: Rect2, r_piece: float, ep_piece: float, p: Dictionary) -> void:
	zone = p_zone
	r_p = r_piece
	ep_p = ep_piece
	u = p["u"]
	k_h = p["k_h"]
	bord = p["bord"]
	h_bloc = p["h_bloc"]
	mur = p["mur"]
	_images = p["objets"]
	position = zone.position
	size = zone.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vue = SubViewport.new()
	vue.own_world_3d = true
	vue.transparent_bg = true
	vue.msaa_3d = Viewport.MSAA_4X
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vue)
	ecran = TextureRect.new()
	ecran.texture = vue.get_texture()
	ecran.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ecran.stretch_mode = TextureRect.STRETCH_SCALE
	ecran.size = zone.size
	ecran.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ecran)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = zone.size.y / u
	camera.near = 1.0
	camera.far = 200.0
	camera.rotation_degrees = Vector3(-90, 0, 0)
	camera.position = Vector3((zone.position.x + zone.size.x * 0.5) / u, 100.0, (zone.position.y + zone.size.y * 0.5) / u)
	vue.add_child(camera)
	# les pièces : une matière, un disque, CASES cases
	var mat := ShaderMaterial.new()
	mat.shader = SH_CORPS
	mat.set_shader_parameter("relief", TEX_RELIEF)
	mat.set_shader_parameter("k_h", k_h)
	mm_pieces = _multimesh(_disque(r_piece, ep_piece), mat)
	var mat_o := ShaderMaterial.new()
	mat_o.shader = SH_OMBRE
	mat_o.set_shader_parameter("k_h", k_h)
	var plan := PlaneMesh.new()
	plan.size = Vector2(1, 1)
	mm_ombres = _multimesh(plan, mat_o)
	_buf_p.resize(CASES * PAS_BUF)
	_buf_o.resize(CASES * PAS_BUF)
	_buf_p.fill(0.0)
	_buf_o.fill(0.0)
	for i in CASES:
		_libres.append(CASES - 1 - i)
	mm_pieces.custom_aabb = AABB(Vector3(-50, -50, -50), Vector3(100, 200, 100))
	mm_ombres.custom_aabb = AABB(Vector3(-50, -50, -50), Vector3(100, 200, 100))
	_ajuster()
	get_tree().root.size_changed.connect(_ajuster)


# (02/10) La machine dans son décor peint : machine_decor.gd règle la caméra ; ici, les matières des objets à venir.
func perspective(etirement: float) -> void:
	_vue_perspective = true
	_etirement = etirement
	k_h = 0.0


func regler_vue(m: ShaderMaterial) -> void:
	m.set_shader_parameter("k_h", 0.0)
	m.set_shader_parameter("etirement", _etirement)
	m.set_shader_parameter("bord_plateau", bord)


# Une vraie sphère, posée sur le corps (un disque) : son bas au bas du disque.
func _sphere_posee(r: float, ep: float) -> ArrayMesh:
	var cle := "%.3f|%.3f" % [r, ep]
	if _spheres.has(cle):
		return _spheres[cle]
	var rs := r * 0.9
	var sm := SphereMesh.new()
	sm.radius = rs
	sm.height = 2.0 * rs
	sm.radial_segments = 48
	sm.rings = 24
	var arr := sm.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in v.size():
		v[i] += Vector3(0, rs - ep * 0.5, 0)
	arr[Mesh.ARRAY_VERTEX] = v
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_spheres[cle] = am
	return am


# La vue au plein de la résolution réelle : sur le téléphone, 1 px de la vue = 1 px de l'écran.
func _ajuster() -> void:
	var ech := get_viewport().get_final_transform().get_scale().x
	vue.size = Vector2i(maxi(64, int(round(zone.size.x * ech))), maxi(64, int(round(zone.size.y * ech))))


func _multimesh(mesh: Mesh, mat: Material) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = CASES
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	# le MultiMesh couvre tout : jamais écarté par la caméra
	mi.custom_aabb = AABB(Vector3(-50, -50, -50), Vector3(100, 200, 100))
	vue.add_child(mi)
	return mm


# Un disque : le dessus (COLOR.r = 1), le dessous (0), la tranche (0,5).
func _disque(r: float, ep: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := ep * 0.5
	for face in [1.0, -1.0]:
		for i in SEGMENTS:
			var a0 := TAU * i / SEGMENTS
			var a1 := TAU * (i + 1) / SEGMENTS
			for q in [Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1))]:
				st.set_color(Color(1.0 if face > 0.0 else 0.0, 0, 0))
				st.set_normal(Vector3(0, face, 0))
				st.set_uv(Vector2(q.x * 0.5 + 0.5, q.y * 0.5 + 0.5))
				st.add_vertex(Vector3(q.x * r, h * face, q.y * r))
	for i in SEGMENTS:
		var a0 := TAU * i / SEGMENTS
		var a1 := TAU * (i + 1) / SEGMENTS
		var p0 := Vector3(cos(a0), 0, sin(a0))
		var p1 := Vector3(cos(a1), 0, sin(a1))
		for c in [[p0, -h, 0.0], [p1, -h, 1.0], [p1, h, 1.0], [p0, -h, 0.0], [p1, h, 1.0], [p0, h, 0.0]]:
			var pp: Vector3 = c[0]
			st.set_color(Color(0.5, 0, 0))
			st.set_normal(pp)
			st.set_uv(Vector2((float(i) + float(c[2])) / SEGMENTS, 0.5 + float(c[1]) / ep))
			st.add_vertex(pp * r + Vector3(0, float(c[1]), 0))
	return st.commit()


# ─────────────────────────────────────────────────────────────
# À chaque image
# ─────────────────────────────────────────────────────────────

func maj(pieces: Array, lots: Array, p_face_z: float) -> void:
	var t0 := Time.get_ticks_usec()
	face_z = p_face_z
	for b in pieces:
		var i: int = _cases.get(b, -1)
		if i < 0:
			i = _prendre(b)
			b.set_meta("case_face", float(b.get_meta("face", 0)))
		_placer(i, b)
	RenderingServer.multimesh_set_buffer(mm_pieces.get_rid(), _buf_p)
	RenderingServer.multimesh_set_buffer(mm_ombres.get_rid(), _buf_o)
	for b in lots:
		_objet(b)
	us_maj = lerpf(us_maj, float(Time.get_ticks_usec() - t0), 0.05)


func _prendre(b: RigidBody3D) -> int:
	var i: int = _libres.pop_back()
	_cases[b] = i
	_haut = maxi(_haut, i + 1)
	return i


func _placer(i: int, b: RigidBody3D) -> void:
	var t := b.global_transform
	var p := t.origin
	var bs := t.basis
	var o := i * PAS_BUF
	# la transformée, ligne par ligne (3 × 4), puis les données : la face, le fondu
	_buf_p[o] = bs.x.x
	_buf_p[o + 1] = bs.y.x
	_buf_p[o + 2] = bs.z.x
	_buf_p[o + 3] = p.x
	_buf_p[o + 4] = bs.x.y
	_buf_p[o + 5] = bs.y.y
	_buf_p[o + 6] = bs.z.y
	_buf_p[o + 7] = p.y
	_buf_p[o + 8] = bs.x.z
	_buf_p[o + 9] = bs.y.z
	_buf_p[o + 10] = bs.z.z
	_buf_p[o + 11] = p.z
	var fondu := 0.0
	if p.z > bord - 0.5 or p.y < 0.0:
		fondu = _fondu(p, r_p)
	_buf_p[o + 12] = b.get_meta("case_face")
	_buf_p[o + 13] = fondu
	# l'ombre : sous la pièce, décalée à droite et vers le bas, plus grande et plus pâle
	# quand la pièce est haut au-dessus de ce qui la porte
	var base := h_bloc if (p.z < face_z and p.z > mur - 0.5) else 0.0
	var dh := maxf(0.0, p.y - ep_p * 0.5 - base)
	var sc := r_p * (2.3 + dh * 0.5)
	_buf_o[o] = sc
	_buf_o[o + 1] = 0.0
	_buf_o[o + 2] = 0.0
	_buf_o[o + 3] = p.x + 0.05 + dh * 0.15
	_buf_o[o + 4] = 0.0
	_buf_o[o + 5] = 1.0
	_buf_o[o + 6] = 0.0
	_buf_o[o + 7] = p.y - ep_p * 0.5 - 0.004
	_buf_o[o + 8] = 0.0
	_buf_o[o + 9] = 0.0
	_buf_o[o + 10] = sc
	_buf_o[o + 11] = p.z + 0.09 + dh * 0.2
	_buf_o[o + 14] = clampf(0.55 - dh / 4.0, 0.15, 0.55) * (1.0 - fondu)


# Ce qui passe le bord s'efface en tombant.
func _fondu(p: Vector3, r: float) -> float:
	return clampf(maxf((p.z - bord) / (r * 2.0), -p.y * 2.0), 0.0, 1.0)


# L'ombre : sous le corps, décalée à droite et vers le bas, plus grande et plus pâle
# quand il est haut au-dessus de ce qui le porte.
func _ombre(p: Vector3, r: float, ep: float) -> Array:
	var base := h_bloc if (p.z < face_z and p.z > mur - 0.5) else 0.0
	var dh := maxf(0.0, p.y - ep * 0.5 - base)
	var s := r * (2.3 + dh * 0.5)
	var bas := p.y - ep * 0.5 - 0.004
	var t := Transform3D(Basis().scaled(Vector3(s, 1.0, s)), Vector3(p.x + 0.05 + dh * 0.15, bas, p.z + 0.09 + dh * 0.2))
	return [t, clampf(0.55 - dh / 4.0, 0.15, 0.55)]


func oublier(b: RigidBody3D) -> void:
	if _cases.has(b):
		var i: int = _cases[b]
		_cases.erase(b)
		# une case libre : transformée nulle (rien n'est dessiné)
		for k in PAS_BUF:
			_buf_p[i * PAS_BUF + k] = 0.0
			_buf_o[i * PAS_BUF + k] = 0.0
		_libres.append(i)
	if _objets.has(b):
		for n in [_objets[b][0], _objets[b][1]]:
			vue.remove_child(n)
			n.queue_free()
		_objets.erase(b)


# Un objet : son volume (sa silhouette extrudée), éclairé en direct (Volumes), et son ombre.
func _objet(b: RigidBody3D) -> void:
	if not _objets.has(b):
		var r: float = b.get_meta("r")
		var ep: float = b.get_meta("ep_vu", b.get_meta("ep"))
		var nom := str(_images.get(str(b.get_meta("lot")), ""))
		var d := Volumes.objet(nom)
		var bille := not d.is_empty() and bool(d.get("sphere", false))
		var cle := "%s|%.3f" % [nom, r]
		if not _meshes_objets.has(cle):
			if d.is_empty():
				_meshes_objets[cle] = _disque(r, ep)
			elif bille:
				_meshes_objets[cle] = _sphere_posee(r, float(b.get_meta("ep"))) if _vue_perspective else Volumes.bille_mesh(r)
			else:
				_meshes_objets[cle] = Volumes.volume(d["contour"], d["disque"], r, ep)
		var mat := Volumes.matiere_bille(nom, k_h, r) if bille else Volumes.matiere(nom, k_h)
		if _vue_perspective:
			if bille:
				var mb := ShaderMaterial.new()
				mb.shader = SH_BILLE_VUE
				for cle_b in ["voile", "coeur", "teinte"]:
					mb.set_shader_parameter(cle_b, mat.get_shader_parameter(cle_b))
				mat = mb
			else:
				mat.shader = SH_CORPS_VUE
			regler_vue(mat)
		var mi := MeshInstance3D.new()
		mi.mesh = _meshes_objets[cle]
		mi.material_override = mat
		mi.custom_aabb = AABB(Vector3(-50, -50, -50), Vector3(100, 200, 100))
		var mat_o := ShaderMaterial.new()
		mat_o.shader = SH_OMBRE_VUE if _vue_perspective else SH_OMBRE
		mat_o.set_shader_parameter("k_h", k_h)
		if _vue_perspective:
			regler_vue(mat_o)
		var plan := PlaneMesh.new()
		plan.size = Vector2(1, 1)
		var mo := MeshInstance3D.new()
		mo.mesh = plan
		mo.material_override = mat_o
		mo.custom_aabb = AABB(Vector3(-50, -50, -50), Vector3(100, 200, 100))
		vue.add_child(mo)
		vue.add_child(mi)
		_objets[b] = [mi, mo, mat, mat_o, bille]
	var e: Array = _objets[b]
	var t := b.global_transform
	var r2: float = b.get_meta("r")
	var fondu := _fondu(t.origin, r2)
	# une bille reste droite, posée sur son corps : ronde, elle se voit pareille de tous les côtés
	#    (penchée avec lui, son étoile glissait vers le bord)
	(e[0] as MeshInstance3D).transform = Transform3D(Basis(), t.origin) if bool(e[4]) else t
	(e[2] as ShaderMaterial).set_shader_parameter("fondu_objet", fondu)
	var o := _ombre(t.origin, r2, float(b.get_meta("ep")))
	(e[1] as MeshInstance3D).transform = o[0]
	(e[3] as ShaderMaterial).set_shader_parameter("force_objet", o[1] * (1.0 - fondu))


# Arrêter la vue quand la poussette est cachée : le téléphone ne dessine pas pour rien.
func actif(v: bool) -> void:
	if vue != null:
		vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS if v else SubViewport.UPDATE_DISABLED
