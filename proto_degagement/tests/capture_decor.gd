extends Node

# LES DÉCORS PEINTS DE LA MACHINE, À L'ESSAI (02/10 — Maxim : « il y a des images dans Machine, je sais pas si ça peut bien
# aller, test »). Après le meuble en volumes simples (« ça fait vieille 3D »), la direction de Maxim : « un décor fixe
# derrière, bien HD, propre, et des petites animations dessus, un peu comme les cartes ». Ses décors sont générés dans
# ChatGPT (REPRISE.md, les prompts) et posés dans Machine/ ; design/machines/analyser.py en tire la caméra, les alvéoles,
# le masque de l'or, les étoiles.
#
# Un ESSAI, rien n'est changé dans le jeu : la vraie machine (sa physique, ses pièces, ses objets, son interface) est
# posée dans le creux peint — la caméra du jeu calée sur le décor, la profondeur étirée à l'image (la physique ne change
# pas) ; le décor peint en fond, et par-dessus : les lunes de la jauge dans les alvéoles de l'arche, un reflet qui glisse
# sur l'or, des étoiles qui scintillent, les flammes qui vacillent ; à la Supernova, l'emblème s'allume, des anneaux nets
# s'en échappent, et le compte à rebours s'y inscrit.
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_decor.tscn -- <dossier> [theme=BaseCeleste] [fov=80|90] [film]

const SH_CORPS := preload("res://meuble/corps_vue.gdshader")
const SH_OMBRE := preload("res://meuble/ombre_vue.gdshader")
const SH_BILLE := preload("res://meuble/bille_vue.gdshader")
const SH_PEINT := preload("res://meuble/peint.gdshader")
const SH_REFLET := preload("res://meuble/reflet_or.gdshader")
const SH_FONDU := preload("res://meuble/decor_fondu.gdshader")
const SH_OR := preload("res://meuble/or.gdshader")
var Y_DECOR := 40.0                    # où le décor commence (fondu dans le ciel du jeu) : assez bas pour que le
                                       # haut de l'arche (ses alvéoles) passe sous le bandeau du haut
const E := 1080.0 / 1024.0             # du pixel de l'image au pixel du jeu
const BORD := 14.0
const MUR := 6.0

var main: Node
var p: PusherScreen
var dossier := ""
var film := false
var theme := "BaseCeleste"
var fov := "80"
var d: Dictionary
var k := 1.0
var tex_decor: ImageTexture
var tex_eclat: Texture2D
var tex_bloc_dessus: ImageTexture
var tex_bloc_face: ImageTexture
var couche_lunes: Control
var couche_eclats: Control
var mat_reflet: ShaderMaterial
var bloc: Node3D
var _t := 0.0
var _sn_t := -1.0
var _spheres := {}
var _phases: Array = []
var _scintille: Array = []
var _gerbe: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	film = args.has("film")
	for a in args:
		if a.begins_with("theme="):
			theme = a.trim_prefix("theme=")
		elif a.begins_with("fov="):
			fov = a.trim_prefix("fov=")
	var racine := ProjectSettings.globalize_path("res://").path_join("..")
	d = JSON.parse_string(FileAccess.get_file_as_string(racine.path_join("design/machines/%s.json" % theme)))
	var haut_alveoles := 9999.0
	for al in d["alveoles"]:
		haut_alveoles = minf(haut_alveoles, float(al[1]) - float(d["r_alveole"]))
	Y_DECOR = clampf(168.0 - haut_alveoles * E, 40.0, 120.0)
	tex_decor = _texture(racine.path_join(str(d["image"])))
	var tex_or := _texture(racine.path_join("design/machines/%s-or.png" % theme))
	tex_bloc_dessus = _texture(racine.path_join(str(d["bloc_dessus"])))
	tex_bloc_face = _texture(racine.path_join(str(d["bloc_face"])))
	tex_eclat = load("res://ciel/eclat-etoile.png")
	GS.sauvegarde_active = false
	if not film:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var n_alv: int = (d["alveoles"] as Array).size()
	GS.poussiere = 1240
	GS.etoiles = 12
	GS.pierres = {"lune": 3}
	GS.main_pieces = 148
	GS.jauge_supernova = int(ceil(p_jauge_max() * 4.0 / n_alv))     # 4 lunes allumées
	for i in n_alv:
		var t := float(i) / float(maxi(1, n_alv - 1))
		var cote := 1.0 if t < 0.5 else -1.0
		_phases.append(0.0 if i == 0 or i == n_alv - 1 else cote * (1.0 - absf(2.0 * t - 1.0)))
	for s in d["etoiles"]:
		_scintille.append({"pos": Vector2(float(s[0]) * E, Y_DECOR + float(s[1]) * E), "w": randf_range(0.9, 2.4),
			"ph": randf() * TAU, "taille": randf_range(26.0, 46.0)})
	main = load("res://main.tscn").instantiate()
	add_child(main)
	p = main.ecran_pousse
	_convertir(tex_or)
	if film:
		_film()
	else:
		_scenario()


func _texture(chemin: String) -> ImageTexture:
	var img := Image.new()
	img.load_png_from_buffer(FileAccess.get_file_as_bytes(chemin))
	return ImageTexture.create_from_image(img)


func p_jauge_max() -> float:
	return float(PusherScreen.JAUGE_SUPERNOVA)


func zs(z: float) -> float:
	return BORD - k * (BORD - z)


func _convertir(tex_or: Texture2D) -> void:
	for c in [p.decor, p.bloc2d, p.fronton2d, p.jauge2d, p.lueur_bord, p.effets]:
		c.visible = false
	var rect := Rect2(0, Y_DECOR, 1080, 1024.0 * 1.5 * E)
	# 1. le décor peint, fondu en haut et en bas
	var fond := TextureRect.new()
	fond.texture = tex_decor
	fond.position = rect.position
	fond.size = rect.size
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mf := ShaderMaterial.new()
	mf.shader = SH_FONDU
	fond.material = mf
	p.add_child(fond)
	p.move_child(fond, 0)
	# 2. le reflet qui glisse sur l'or
	var reflet := TextureRect.new()
	reflet.texture = tex_or
	reflet.position = rect.position
	reflet.size = rect.size
	reflet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reflet.stretch_mode = TextureRect.STRETCH_SCALE
	reflet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat_reflet = ShaderMaterial.new()
	mat_reflet.shader = SH_REFLET
	mat_reflet.set_shader_parameter("masque", tex_or)
	var em: Array = d["embleme"]
	mat_reflet.set_shader_parameter("embleme", Vector2(float(em[0]) / 1024.0, float(em[1]) / 1536.0))
	mat_reflet.set_shader_parameter("r_embleme", float(d["r_embleme"]) / 1024.0)
	reflet.material = mat_reflet
	p.add_child(reflet)
	p.move_child(reflet, 1)
	# 3. les lunes (mélange normal), puis les éclats (additif : étoiles, flammes, gerbes)
	couche_lunes = Control.new()
	couche_lunes.size = Vector2(1080, 2400)
	couche_lunes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche_lunes.draw.connect(_dessiner_lunes)
	p.add_child(couche_lunes)
	p.move_child(couche_lunes, 2)
	couche_eclats = Control.new()
	couche_eclats.size = Vector2(1080, 2400)
	couche_eclats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	couche_eclats.material = add
	couche_eclats.draw.connect(_dessiner_eclats)
	p.add_child(couche_eclats)
	p.move_child(couche_eclats, 3)
	# 4. la vue 3D, calée sur le décor
	var r: MachineRendu = p.rendu
	r.zone = rect
	r.position = rect.position
	r.size = rect.size
	r.ecran.size = rect.size
	r._ajuster()
	var cam_d: Dictionary = d["cameras"][fov]
	k = float(cam_d["etirement"])
	var cam: Camera3D = r.camera
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.fov = float(cam_d["fov_deg"])
	cam.near = 0.3
	cam.far = 200.0
	var pos: Array = cam_d["position"]
	cam.position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	cam.rotation = Vector3(deg_to_rad(-float(cam_d["plongee_deg"])), 0.0, 0.0)
	for c in r.vue.get_children():
		if c is MultiMeshInstance3D:
			var m: ShaderMaterial = (c as MultiMeshInstance3D).material_override
			m.shader = SH_CORPS if m.shader.resource_path.ends_with("corps.gdshader") else SH_OMBRE
			_regler(m)
	_plateau(r.vue)


func _regler(m: ShaderMaterial) -> void:
	m.set_shader_parameter("k_h", 0.0)
	m.set_shader_parameter("etirement", k)
	m.set_shader_parameter("bord_plateau", BORD)


# Ce que le décor ne peut pas peindre : le bloc qui pousse (il bouge), les fentes (où les pièces se perdent), et deux
# caches peints — le mur du fond (le bloc glisse dessous) et la lèvre de l'avant (les pièces tombent derrière elle).
func _plateau(vue: Node) -> void:
	var x0 := float(p.X0)
	var x1 := float(p.X1)
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	var peint := ShaderMaterial.new()
	peint.shader = SH_PEINT
	peint.set_shader_parameter("decor", tex_decor)
	bloc = Node3D.new()
	vue.add_child(bloc)
	var dessus := StandardMaterial3D.new()
	dessus.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dessus.albedo_texture = tex_bloc_dessus
	dessus.texture_repeat = true
	dessus.uv1_scale = Vector3(1.0, 2.5, 1.0)
	dessus.uv1_offset = Vector3(0.0, -1.5, 0.0)
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, 4.0 * k)
	_mi(bloc, pm, dessus, Vector3(cx, float(p.H_BLOC) + 0.002, -2.0 * k))
	var orm := ShaderMaterial.new()
	orm.shader = SH_OR
	var habit := StandardMaterial3D.new()
	habit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	habit.albedo_texture = tex_bloc_face
	var face := QuadMesh.new()
	face.size = Vector2(w, float(p.H_BLOC))
	_mi(bloc, face, habit, Vector3(cx, float(p.H_BLOC) * 0.5, 0.0))
	var mur := BoxMesh.new()
	mur.size = Vector3(w + 3.0, 4.0, 0.3)
	_mi(vue, mur, peint, Vector3(cx, 2.0, zs(MUR) - 0.15))
	var levre := BoxMesh.new()
	levre.size = Vector3(w + 4.0, 3.0, 0.8)
	_mi(vue, levre, peint, Vector3(cx, -1.5, BORD + 0.4))
	var noir := StandardMaterial3D.new()
	noir.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	noir.albedo_color = Color(0.0, 0.0, 0.0)
	var f := float(PusherScreen.fente)
	var z0 := zs(PusherScreen.fente_z0)
	var z1 := zs(PusherScreen.fente_z1)
	for g in [true, false]:
		var fx: float = x0 + f * 0.5 if g else x1 - f * 0.5
		var trou := PlaneMesh.new()
		trou.size = Vector2(f, z1 - z0)
		_mi(vue, trou, noir, Vector3(fx, -0.01, (z0 + z1) * 0.5))
		var lx: float = x0 + f if g else x1 - f
		var lev := CylinderMesh.new()
		lev.top_radius = 0.035
		lev.bottom_radius = 0.035
		lev.height = z1 - z0
		_mi(vue, lev, orm, Vector3(lx, 0.0, (z0 + z1) * 0.5), Basis(Vector3.RIGHT, PI * 0.5))
		for z in [z0, z1]:
			var bout := CylinderMesh.new()
			bout.top_radius = 0.035
			bout.bottom_radius = 0.035
			bout.height = f
			_mi(vue, bout, orm, Vector3(fx, 0.0, z), Basis(Vector3(0, 0, 1), PI * 0.5))


func _mi(parent: Node, mesh: Mesh, mat: Material, pos: Vector3, b := Basis()) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(b, pos)
	parent.add_child(mi)
	return mi


func _process(delta: float) -> void:
	if bloc == null:
		return
	_t += delta
	bloc.position.z = zs(p.face_z)
	# les objets : la profondeur étirée ; les billes, de vraies sphères
	for b in p.rendu._objets:
		var e: Array = p.rendu._objets[b]
		var mi: MeshInstance3D = e[0]
		if mi.has_meta("vue"):
			continue
		mi.set_meta("vue", true)
		var mo: ShaderMaterial = e[3]
		mo.shader = SH_OMBRE
		_regler(mo)
		var ancien: ShaderMaterial = e[2]
		if bool(e[4]):
			var m := ShaderMaterial.new()
			m.shader = SH_BILLE
			for cle in ["voile", "coeur", "teinte"]:
				m.set_shader_parameter(cle, ancien.get_shader_parameter(cle))
			m.set_shader_parameter("etirement", k)
			m.set_shader_parameter("bord_plateau", BORD)
			e[2] = m
			mi.material_override = m
			mi.mesh = _sphere_posee(float(b.get_meta("r")), float(b.get_meta("ep")))
		else:
			ancien.shader = SH_CORPS
			_regler(ancien)
	# la Supernova : son temps ; le mot rangé laisse la place au compte à rebours, dans l'emblème
	var en_sn := p.supernova_t > 0.0
	if en_sn and _sn_t < 0.0:
		_sn_t = 0.0
		_lancer_gerbe()
	elif not en_sn:
		_sn_t = -1.0
		p.supernova_fx.visible = true
	if _sn_t >= 0.0:
		_sn_t += delta
		if p.supernova_fx._range:
			p.supernova_fx.visible = false
	for g in _gerbe:
		g["pos"] += g["vel"] * delta
		g["vel"] *= 0.985
		g["vie"] -= delta
	_gerbe = _gerbe.filter(func(g): return g["vie"] > 0.0)
	# le reflet : un passage toutes les 6,5 s ; à la Supernova, toutes les 1,6 s, et l'emblème flambe
	var periode := 1.6 if en_sn else 6.5
	var u := fmod(_t, periode) / 1.3
	mat_reflet.set_shader_parameter("phase", -0.6 + 2.4 * clampf(u, 0.0, 1.0))
	mat_reflet.set_shader_parameter("eclat_embleme", (0.75 + 0.3 * sin(_t * 9.0)) if en_sn else 0.0)
	couche_lunes.queue_redraw()
	couche_eclats.queue_redraw()


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


func _centre_embleme() -> Vector2:
	var em: Array = d["embleme"]
	return Vector2(float(em[0]) * E, Y_DECOR + float(em[1]) * E)


# Les lunes de la jauge, dans les alvéoles : éteintes, leur phase gravée d'or ; allumées, pleines et vives, cerclées net.
func _dessiner_lunes() -> void:
	var v := couche_lunes
	var alv: Array = d["alveoles"]
	var n := alv.size()
	var en_sn := p.supernova_t > 0.0
	var allumees := n if en_sn else clampi(int(GS.jauge_supernova * n / PusherScreen.JAUGE_SUPERNOVA), 0, n)
	var pulse := 0.72 + 0.28 * sin(_t * 9.0) if en_sn else 1.0
	var r := float(d["r_alveole"]) * E * 0.9
	for i in n:
		var c := Vector2(float(alv[i][0]) * E, Y_DECOR + float(alv[i][1]) * E)
		if i < allumees:
			v.draw_circle(c, r, Color(1.0, 0.93, 0.66, pulse))
			v.draw_arc(c, r, 0.0, TAU, 48, Color(1.0, 0.98, 0.88, pulse), 2.5, true)
		else:
			_lune(v, c, r * 0.86, float(_phases[i]), Color(0.86, 0.66, 0.32, 0.62))
	# le compte à rebours, au cœur de l'emblème (le mot SUPERNOVA rangé laisse la place)
	if en_sn and p.supernova_fx._range:
		var ce := _centre_embleme()
		v.draw_circle(ce, 68.0, Color(0.02, 0.04, 0.12, 0.92))
		v.draw_arc(ce, 68.0, 0.0, TAU, 64, Color(1.0, 0.84, 0.46), 4.0, true)
		var f := Style.police("fort")
		var txt := str(int(ceil(p.supernova_t)))
		var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 80)
		v.draw_string_outline(f, ce + Vector2(-ts.x * 0.5, 28.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 80, 8, Color(0.1, 0.06, 0.0))
		v.draw_string(f, ce + Vector2(-ts.x * 0.5, 28.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 80, Color(1.0, 0.86, 0.46))


# k : la part éclairée, de 0 (nouvelle) à 1 (pleine) ; négatif : la lune décroît (comme la frise d'avant).
func _lune(v: Control, c: Vector2, r: float, ph: float, col: Color) -> void:
	v.draw_arc(c, r, 0.0, TAU, 40, col, 1.8, true)
	var fk := absf(ph)
	if fk < 0.001:
		return
	if fk > 0.999:
		v.draw_circle(c, r, col)
		return
	var cote := 1.0 if ph > 0.0 else -1.0
	var rx := (1.0 - 2.0 * fk) * r
	var pts := PackedVector2Array()
	for j in 21:
		var a := -PI * 0.5 + PI * float(j) / 20.0
		pts.append(c + Vector2(cos(a) * r * cote, sin(a) * r))
	for j in range(1, 20):
		var a2 := PI * 0.5 - PI * float(j) / 20.0
		pts.append(c + Vector2(cos(a2) * rx * cote, sin(a2) * r))
	v.draw_colored_polygon(pts, col)


# Les éclats (additifs) : les étoiles du ciel peint qui scintillent, les flammes qui vacillent ; à la Supernova, des
# anneaux nets qui s'échappent de l'emblème et une gerbe d'étoiles.
func _dessiner_eclats() -> void:
	var v := couche_eclats
	var en_sn := p.supernova_t > 0.0
	for s in _scintille:
		var b := pow(maxf(0.0, sin(_t * float(s["w"]) + float(s["ph"]))), 3.0)
		var a := (0.25 + 0.75 * b) * (1.6 if en_sn else 1.0)
		var t := float(s["taille"]) * (0.55 + 0.45 * b)
		v.draw_texture_rect(tex_eclat, Rect2(s["pos"] - Vector2(t, t) * 0.5, Vector2(t, t)), false, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	for fl in d["flammes"]:
		var fx := float(fl[0])
		var fy := float(fl[1])
		var fw := float(fl[2]) if fl.size() > 2 else 26.0
		var fh := float(fl[3]) if fl.size() > 3 else 46.0
		var src := Rect2(fx - fw * 0.5, fy - fh, fw, fh)
		var etire := 1.0 + 0.07 * sin(_t * 13.0 + fx) + 0.04 * sin(_t * 23.0)
		var h := src.size.y * E * etire
		var dst := Rect2(fx * E - src.size.x * E * 0.5, Y_DECOR + fy * E - h, src.size.x * E, h)
		var a2 := 0.16 + 0.12 * (0.5 + 0.5 * sin(_t * 17.0 + fy))
		v.draw_texture_rect_region(tex_decor, dst, src, Color(1, 1, 1, a2))
	if _sn_t >= 0.0:
		var ce := _centre_embleme()
		for kk in 2:
			var u := fmod(_sn_t + kk * 0.6, 1.2) / 1.2
			v.draw_arc(ce, 70.0 + u * 560.0, 0.0, TAU, 160, Color(1.0, 0.86, 0.55, 1.0 - u), 5.0, true)
	for g in _gerbe:
		var a3 := clampf(float(g["vie"]) / float(g["vie0"]), 0.0, 1.0)
		var t2 := float(g["taille"])
		v.draw_texture_rect(tex_eclat, Rect2(g["pos"] - Vector2(t2, t2) * 0.5, Vector2(t2, t2)), false, Color(1, 0.92, 0.7, a3))


func _lancer_gerbe() -> void:
	var ce := _centre_embleme()
	for i in 30:
		var a := TAU * float(i) / 30.0 + randf_range(-0.1, 0.1)
		var vie := randf_range(0.9, 1.6)
		_gerbe.append({"pos": ce + Vector2.from_angle(a) * 40.0, "vel": Vector2.from_angle(a) * randf_range(260.0, 620.0),
			"vie": vie, "vie0": vie, "taille": randf_range(30.0, 58.0)})


func _scenario() -> void:
	await _attendre(0.3)
	_sans_cadeau()
	await _attendre(5.5)
	_capture("repos")
	_semer()
	await _attendre(1.1)
	_capture("seme")
	p.declencher_supernova()
	await _attendre(0.45)
	_capture("sn_eclat")
	await _attendre(1.0)
	_capture("sn_mot")
	await _attendre(2.4)
	_capture("sn_compte")
	await _attendre(3.0)
	_capture("sn_pluie")
	get_tree().quit(0)


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
	var chemin := dossier.path_join("decor_%s_%s_%s.png" % [theme, fov, nom])
	var err := img.save_png(chemin)
	print("capture %s : %s" % [nom, "ok" if err == OK else "erreur %d" % err])


func _sans_cadeau() -> void:
	var dd = main.get("daily")
	if dd != null and is_instance_valid(dd):
		dd.queue_free()


func _semer() -> void:
	for x in [1.6, 2.9, 4.2, 5.5, 6.8, 8.1, 9.2]:
		for z in [6.5, 7.2]:
			p._lacher(x, z)
