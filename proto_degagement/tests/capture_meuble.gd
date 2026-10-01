extends Node

# LA MACHINE « BASE CÉLESTE », EN APERÇU (01/10 — Maxim : « tu peux me faire un artifact pour déjà voir la
# nouvelle machine, on partirait sur la Base Céleste »). Un PROTOTYPE, rien n'est changé dans le jeu : la
# vraie machine (sa physique, ses pièces, ses objets, son interface) est regardée par une caméra en
# perspective, dans le meuble 3D (meuble/meuble_celeste.gd) ; le dessin 2D d'avant (le cadre, le titre, la
# frise des lunes, le bloc) est caché. Lancé en fenêtre ; les images vont dans le dossier donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_meuble.tscn -- <dossier> [film]
#
# « film » : pas de photos, une séquence pour --write-movie (à lancer avec --fixed-fps 30).

const MEUBLE := preload("res://meuble/meuble_celeste.gd")
const SH_BILLE := preload("res://meuble/bille_vue.gdshader")
const ZONE := Rect2(0, 228, 1080, 1236)

var main: Node
var p: PusherScreen
var meuble: Node3D
var dossier := ""
var film := false
var avant := false
var camera := {"pos": Vector3(5.4, 12.2, 22.5), "vise": Vector3(5.4, 3.7, 10.2), "fov": 47.0}
var _spheres := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	film = args.has("film")
	for a in args:
		if a.begins_with("cam="):
			var v := a.trim_prefix("cam=").split(",")
			camera["pos"] = Vector3(float(v[0]), float(v[1]), float(v[2]))
			camera["vise"] = Vector3(float(v[3]), float(v[4]), float(v[5]))
			camera["fov"] = float(v[6])
	# « avant » : la machine d'aujourd'hui, photographiée aux mêmes moments (la comparaison)
	avant = args.has("avant")
	GS.sauvegarde_active = false
	if not film:
		# les photos au plein du jeu (1080 × 2400), quelle que soit la fenêtre
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.poussiere = 1240
	GS.etoiles = 12
	GS.pierres = {"lune": 3}
	GS.main_pieces = 148
	GS.jauge_supernova = 84          # 5 lunes sur 9
	main = load("res://main.tscn").instantiate()
	add_child(main)
	p = main.ecran_pousse
	if not avant:
		_convertir()
	if film:
		_film()
	else:
		_scenario()


# La machine d'aujourd'hui, vue autrement : la caméra en perspective, le meuble, les matières des pièces
# sans l'oblique (k_h = 0), les billes en vraies sphères.
func _convertir() -> void:
	for c in [p.decor, p.bloc2d, p.fronton2d, p.jauge2d, p.lueur_bord, p.effets]:
		c.visible = false
	var r: MachineRendu = p.rendu
	r.zone = ZONE
	r.position = ZONE.position
	r.size = ZONE.size
	r.ecran.size = ZONE.size
	r._ajuster()
	var cam: Camera3D = r.camera
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.fov = camera["fov"]
	cam.near = 0.5
	cam.far = 200.0
	cam.position = camera["pos"]
	cam.look_at(camera["vise"])
	for c in r.vue.get_children():
		if c is MultiMeshInstance3D:
			((c as MultiMeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("k_h", 0.0)
	meuble = MEUBLE.new()
	r.vue.add_child(meuble)
	meuble.construire({"x0": p.X0, "x1": p.X1, "mur": p.MUR, "bord": p.BORD, "h_bloc": p.H_BLOC,
		"fente": PusherScreen.fente, "fente_z0": PusherScreen.fente_z0, "fente_z1": PusherScreen.fente_z1})


func _process(_d: float) -> void:
	if meuble == null:
		return
	meuble.face_z = p.face_z
	meuble.regler_jauge(p._lunes_allumees(), p.supernova_t > 0.0)
	for b in p.rendu._objets:
		var e: Array = p.rendu._objets[b]
		var mi: MeshInstance3D = e[0]
		if mi.has_meta("vue"):
			continue
		mi.set_meta("vue", true)
		(e[3] as ShaderMaterial).set_shader_parameter("k_h", 0.0)
		if bool(e[4]):
			var ancien: ShaderMaterial = e[2]
			var m := ShaderMaterial.new()
			m.shader = SH_BILLE
			for k in ["voile", "coeur", "teinte"]:
				m.set_shader_parameter(k, ancien.get_shader_parameter(k))
			e[2] = m
			mi.material_override = m
			mi.mesh = _sphere_posee(float(b.get_meta("r")), float(b.get_meta("ep")))
		else:
			(e[2] as ShaderMaterial).set_shader_parameter("k_h", 0.0)


# Une vraie sphère, posée sur le corps (un disque) : son bas au bas du disque.
func _sphere_posee(r: float, ep: float) -> ArrayMesh:
	var cle := "%.3f" % r
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


func _scenario() -> void:
	await _attendre(0.3)
	_sans_cadeau()
	await _attendre(5.5)
	_capture("meuble_repos")
	_semer()
	await _attendre(1.1)
	_capture("meuble_seme")
	p.declencher_supernova()
	await _attendre(0.45)
	_capture("meuble_supernova_eclat")
	await _attendre(1.0)
	_capture("meuble_supernova_mot")
	await _attendre(2.4)
	_capture("meuble_supernova_verrou")
	await _attendre(3.0)
	_capture("meuble_supernova_pluie")
	get_tree().quit(0)


# Pour --write-movie (--fixed-fps 30) : le temps du film est celui du jeu.
func _film() -> void:
	await _images(10)
	_sans_cadeau()
	await _images(150)
	_semer()
	await _images(150)
	_semer()
	await _images(90)
	p.declencher_supernova()
	await _images(330)
	get_tree().quit(0)


func _images(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _attendre(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _capture(nom: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var chemin := dossier.path_join("godot_%s%s.png" % ["avant_" if avant else "", nom])
	var err := img.save_png(chemin)
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _sans_cadeau() -> void:
	var d = main.get("daily")
	if d != null and is_instance_valid(d):
		d.queue_free()


func _semer() -> void:
	for x in [1.6, 2.9, 4.2, 5.5, 6.8, 8.1, 9.2]:
		for z in [6.5, 7.2]:
			p._lacher(x, z)
