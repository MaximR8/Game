extends Node

# LES DÉCORS PEINTS DE LA MACHINE, À L'ESSAI (02/10 — Maxim : « il y a des images dans Machine, je sais pas si ça peut bien
# aller, test »). Après le meuble en volumes simples (« ça fait vieille 3D »), la direction de Maxim : « un décor fixe
# derrière, bien HD, propre, et des petites animations dessus, un peu comme les cartes ». Ses décors sont générés dans
# ChatGPT (REPRISE.md, les prompts) et posés dans Machine/ ; design/machines/analyser.py en tire la caméra, les alvéoles
# (mesurées sur leur trou), le masque de l'or, les éclats, l'habit du bloc ; design/machines/lunes.py rend les lunes et le
# cadran.
#
# 🔄 02/10, sur le premier essai (Maxim : « en étirant ça a déformé les pièces ; les animations ne vont pas avec le décor ;
#    le compteur en Supernova est coupé à moitié ; les lunes sont mal alignées dans les trous ; ça fait très pauvre, fait en
#    CSS ») : les pièces gardent leur forme (seule leur place suit l'étirement) ; les lunes sont de vrais cabochons, posés
#    au centre mesuré de chaque trou, à sa taille ; le cadran du compte à rebours et les lunes passent AU-DESSUS de la vue
#    3D (le mur peint les coupait) ; plus d'anneaux plats : l'emblème s'allume de sa propre lumière ; le reflet ne court
#    que sur les arêtes claires de l'or ; les flammes ondulent à partir de leurs propres pixels.
#
# Un ESSAI, rien n'est changé dans le jeu : la vraie machine (sa physique, ses pièces, ses objets, son interface) posée dans
# le creux peint — la caméra du jeu calée sur le décor, la profondeur étirée à l'image (la physique ne change pas).
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_decor.tscn -- <dossier> [theme=BaseCeleste] [fov=80|90] [film] [glissiere]
#
# « glissiere » (02/10 — Maxim : « comment on fait pour lâcher les pièces ? ») : DECISIONS 02/10 montré. Un doigt (simulé)
# touche la machine n'importe où — ici tout en bas, près du pouce ; seule sa position gauche-droite compte : le chariot de la
# glissière (une goulotte d'or sur un rail perlé, en haut du bloc) le suit, et les pièces tombent de sa bouche sur le bloc ;
# glisser sème une pièce tous les ~0,75 de chemin, toucher en lâche une.

const SH_CORPS := preload("res://meuble/corps_vue.gdshader")
const SH_OMBRE := preload("res://meuble/ombre_vue.gdshader")
const SH_BILLE := preload("res://meuble/bille_vue.gdshader")
const SH_PEINT := preload("res://meuble/peint.gdshader")
const SH_REFLET := preload("res://meuble/reflet_or.gdshader")
const SH_FONDU := preload("res://meuble/decor_fondu.gdshader")
const SH_FLAMME := preload("res://meuble/flamme.gdshader")
const SH_OR := preload("res://meuble/or.gdshader")
const E := 1080.0 / 1024.0             # du pixel de l'image au pixel du jeu
const BORD := 14.0
const MUR := 6.0
const OR_TEXTE := Color(1.0, 0.86, 0.46)

var Y_DECOR := 40.0                    # où le décor commence (fondu dans le ciel du jeu) : assez bas pour que le haut
                                       # de l'arche (ses alvéoles) passe sous le bandeau du haut
var main: Node
var p: PusherScreen
var dossier := ""
var film := false
var glissiere := false                 # la démonstration de la glissière (le doigt simulé)
var tex_glissiere: ImageTexture
var tex_rail: ImageTexture
var lance := "croissant"               # (02/10, le soir) croissant | armillaire | lanterne
var tex_lance: ImageTexture
var tex_piece: Texture2D
var _chutes: Array = []                # les pièces qui tombent du lance-pièces : {de, x, t}
var _prochaine := 1.0                  # la pièce suivante apparaît dans le lance-pièces (de 0 à 1)
var _vx := 0.0                         # la vitesse du lance-pièces à l'écran (il penche un peu quand il glisse)
const Y_LANCE := 3.0                   # PLUS HAUT (Maxim) : le lance-pièces flotte au-dessus du bloc
const DUREE_CHUTE := 0.42
var chariot_x := 5.4                   # la place du chariot sur le rail (en x du monde)
var _x_dernier_lacher := -99.0
var doigt := {"la": false, "x": 540.0, "appui": 0.0}   # le doigt simulé : présent, sa position, l'onde d'un appui
const Y_RAIL := 1.5                    # le rail : au-dessus du bloc, près du mur du fond
const Z_RAIL := MUR + 0.35
const Z_LACHER := MUR + 0.6            # où tombent les pièces sur le bloc (toujours la même profondeur)
const Y_DOIGT := 1290.0                # le doigt touche en BAS de la machine (le pouce) : la hauteur n'y fait rien
var theme := "BaseCeleste"
var fov := "80"
var d: Dictionary
var k := 1.0
var racine := ""
var tex_decor: ImageTexture
var tex_eclat: Texture2D
var tex_bloc_dessus: ImageTexture
var tex_bloc_face: ImageTexture
var tex_lune_allumee: ImageTexture
var tex_cadran: ImageTexture
var tex_lunes: Array = []              # la lune éteinte de chaque alvéole (sa phase)
var couche_lunes: Control
var couche_eclats: Control
var mat_reflet: ShaderMaterial
var flammes: Array = []                # [ColorRect, ShaderMaterial]
var bloc: Node3D
var _t := 0.0
var _sn_t := -1.0
var _spheres := {}
var _scintille: Array = []
var _gerbe: Array = []
var _allumees := -1
var _allumee_t: Array = []             # depuis quand chaque lune est allumée (le « pop »)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dossier = args[0] if args.size() > 0 else OS.get_user_data_dir()
	film = args.has("film")
	glissiere = args.has("glissiere")
	for a2 in args:
		if a2.begins_with("lance="):
			lance = a2.trim_prefix("lance=")
	for a in args:
		if a.begins_with("theme="):
			theme = a.trim_prefix("theme=")
		elif a.begins_with("fov="):
			fov = a.trim_prefix("fov=")
	racine = ProjectSettings.globalize_path("res://").path_join("..")
	d = JSON.parse_string(FileAccess.get_file_as_string(racine.path_join("design/machines/%s.json" % theme)))
	var haut_alveoles := 9999.0
	for al in d["alveoles"]:
		haut_alveoles = minf(haut_alveoles, float(al[1]) - float(al[2]))
	Y_DECOR = clampf(168.0 - haut_alveoles * E, 40.0, 120.0)
	tex_decor = _texture(str(d["image"]))
	tex_bloc_dessus = _texture(str(d["bloc_dessus"]))
	tex_bloc_face = _texture(str(d["bloc_face"]))
	tex_lune_allumee = _texture("design/machines/lunes/lune-allumee.png")
	tex_cadran = _texture("design/machines/lunes/cadran.png")
	tex_glissiere = _texture("design/machines/lunes/glissiere.png")
	tex_rail = _texture("design/machines/lunes/rail.png")
	tex_lance = _texture("design/machines/lunes/lance-%s.png" % lance)
	tex_piece = Style.objet("piece-etoile")
	tex_eclat = load("res://ciel/eclat-etoile.png")
	var n_alv: int = (d["alveoles"] as Array).size()
	for i in n_alv:
		var t := float(i) / float(maxi(1, n_alv - 1))
		var cote := 1.0 if t < 0.5 else -1.0
		var ph := 0.0 if i == 0 or i == n_alv - 1 else cote * (1.0 - absf(2.0 * t - 1.0))
		tex_lunes.append(_texture("design/machines/lunes/lune%s.png" % _signe(ph)))
		_allumee_t.append(99.0)
	# les éclats : les plus vifs d'abord, plus grands
	var pts: Array = d["etoiles"]
	for i in mini(pts.size(), 18):
		var s: Array = pts[i]
		_scintille.append({"pos": _ecran(float(s[0]), float(s[1])), "w": randf_range(0.7, 1.8), "ph": randf() * TAU,
			"taille": lerpf(36.0, 18.0, float(i) / 17.0)})
	GS.sauvegarde_active = false
	if not film:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	GS.poussiere = 1240
	GS.etoiles = 12
	GS.pierres = {"lune": 3}
	GS.main_pieces = 148
	GS.jauge_supernova = int(ceil(float(PusherScreen.JAUGE_SUPERNOVA) * 4.0 / n_alv))     # 4 lunes allumées
	main = load("res://main.tscn").instantiate()
	add_child(main)
	p = main.ecran_pousse
	_convertir()
	if glissiere:
		p.lbl_hint.text = "Glisse le doigt pour lâcher tes pièces."
		if film:
			_film_glissiere()
		else:
			_scenario_glissiere()
	elif film:
		_film()
	else:
		_scenario()


func _signe(ph: float) -> String:
	# la pleine lune et la nouvelle n'ont qu'une image (pas de « -1,000 » ni de « -0,000 »)
	if absf(ph) > 0.999:
		return "+1.000"
	if absf(ph) < 0.001:
		return "+0.000"
	return "%+.3f" % ph


func _texture(chemin: String) -> ImageTexture:
	var img := Image.new()
	img.load_png_from_buffer(FileAccess.get_file_as_bytes(racine.path_join(chemin)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _ecran(x: float, y: float) -> Vector2:
	return Vector2(x * E, Y_DECOR + y * E)


func zs(z: float) -> float:
	return BORD - k * (BORD - z)


func _convertir() -> void:
	for c in [p.decor, p.bloc2d, p.fronton2d, p.jauge2d, p.lueur_bord, p.effets]:
		c.visible = false
	var rect := Rect2(0, Y_DECOR, 1080, 1536.0 * E)
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
	# 2. le reflet sur l'or (sous la vue 3D : il ne passe jamais sur une pièce)
	var or_tex := _texture("design/machines/%s-or.png" % theme)
	var reflet := ColorRect.new()
	reflet.position = rect.position
	reflet.size = rect.size
	reflet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat_reflet = ShaderMaterial.new()
	mat_reflet.shader = SH_REFLET
	mat_reflet.set_shader_parameter("masque", or_tex)
	mat_reflet.set_shader_parameter("decor", tex_decor)
	var em: Array = d["embleme"]
	mat_reflet.set_shader_parameter("embleme", Vector2(float(em[0]) / 1024.0, float(em[1]) / 1536.0))
	mat_reflet.set_shader_parameter("r_embleme", float(d["r_embleme"]) / 1024.0)
	reflet.material = mat_reflet
	p.add_child(reflet)
	p.move_child(reflet, 1)
	# 3. les flammes (sous la vue 3D) : chacune relit sa flamme peinte
	var i_fl := 2
	for fl in d["flammes"]:
		var fx := float(fl[0])
		var fy := float(fl[1])
		var fw := float(fl[2])
		var fh := float(fl[3])
		var cr := ColorRect.new()
		cr.position = _ecran(fx - fw * 0.5, fy - fh)
		cr.size = Vector2(fw, fh) * E
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mfl := ShaderMaterial.new()
		mfl.shader = SH_FLAMME
		mfl.set_shader_parameter("decor", tex_decor)
		mfl.set_shader_parameter("region", Vector4((fx - fw * 0.5) / 1024.0, (fy - fh) / 1536.0, fw / 1024.0, fh / 1536.0))
		cr.material = mfl
		p.add_child(cr)
		p.move_child(cr, i_fl)
		i_fl += 1
		flammes.append([cr, mfl])
	# 4. la vue 3D, calée sur le décor
	var r: MachineRendu = p.rendu
	r.zone = rect
	r.position = rect.position
	r.size = rect.size
	r.ecran.size = rect.size
	r._ajuster()
	# la vue 3D au plein du jeu (dans une fenêtre réduite, elle se calculait plus petite, puis agrandie : moins nette)
	r.vue.size = Vector2i(int(rect.size.x), int(rect.size.y))
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
	# 5. AU-DESSUS de la vue 3D : les lunes, le cadran (mélange normal), puis les éclats (additifs)
	var au_dessus := r.get_index() + 1
	couche_lunes = Control.new()
	couche_lunes.size = Vector2(1080, 2400)
	couche_lunes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche_lunes.draw.connect(_dessiner_lunes)
	p.add_child(couche_lunes)
	p.move_child(couche_lunes, au_dessus + 1)
	couche_eclats = Control.new()
	couche_eclats.size = Vector2(1080, 2400)
	couche_eclats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	couche_eclats.material = add
	couche_eclats.draw.connect(_dessiner_eclats)
	p.add_child(couche_eclats)
	p.move_child(couche_eclats, au_dessus)


func _regler(m: ShaderMaterial) -> void:
	m.set_shader_parameter("k_h", 0.0)
	m.set_shader_parameter("etirement", k)
	m.set_shader_parameter("bord_plateau", BORD)


# Ce que le décor ne peut pas peindre : le bloc qui pousse (il bouge ; il porte l'habit de la marche peinte), les fentes
# (où les pièces se perdent), et deux caches peints — un mur BAS au fond (le bloc glisse dessous ; haut, il coupait le
# cadran de la Supernova) et la lèvre de l'avant (les pièces tombent derrière elle).
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
	var habit := StandardMaterial3D.new()
	habit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	habit.albedo_texture = tex_bloc_face
	var face := QuadMesh.new()
	face.size = Vector2(w, float(p.H_BLOC))
	_mi(bloc, face, habit, Vector3(cx, float(p.H_BLOC) * 0.5, 0.0))
	var mur := BoxMesh.new()
	mur.size = Vector3(w + 3.0, 1.2, 0.3)
	_mi(vue, mur, peint, Vector3(cx, 0.6, zs(MUR) - 0.15))
	var levre := BoxMesh.new()
	levre.size = Vector3(w + 4.0, 3.0, 0.8)
	_mi(vue, levre, peint, Vector3(cx, -1.5, BORD + 0.4))
	var orm := ShaderMaterial.new()
	orm.shader = SH_OR
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
	# les objets : la place étirée, la forme gardée ; les billes, de vraies sphères
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
	# la jauge : une lune qui s'allume « pope » et lâche quelques étoiles
	var n := (d["alveoles"] as Array).size()
	var en_sn := p.supernova_t > 0.0
	var allumees := n if en_sn else clampi(int(GS.jauge_supernova * n / PusherScreen.JAUGE_SUPERNOVA), 0, n)
	for i in n:
		_allumee_t[i] = float(_allumee_t[i]) + delta
		if _allumees >= 0 and i >= _allumees and i < allumees:
			_allumee_t[i] = 0.0
			_eclats_lune(i)
	_allumees = allumees
	# la Supernova : son temps ; le mot rangé laisse la place au compte à rebours, dans l'emblème
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
		g["vel"] = g["vel"] * 0.982 + Vector2(0, 160.0) * delta
		g["vie"] -= delta
	_gerbe = _gerbe.filter(func(g): return g["vie"] > 0.0)
	# le reflet : un passage lent toutes les 7 s ; à la Supernova, toutes les 1,8 s, et l'emblème flambe
	var periode := 1.8 if en_sn else 7.0
	var u := fmod(_t, periode) / 1.6
	mat_reflet.set_shader_parameter("phase", -0.6 + 2.4 * clampf(u, 0.0, 1.0))
	mat_reflet.set_shader_parameter("eclat_embleme", (0.95 + 0.35 * sin(_t * 8.0)) * clampf(_sn_t / 0.3, 0.0, 1.0) if en_sn else 0.0)
	for fl in flammes:
		(fl[1] as ShaderMaterial).set_shader_parameter("temps", _t)
	if glissiere:
		_suivre_doigt(delta)
		_avancer_chutes(delta)
		p.lbl_hint.text = "Glisse le doigt pour lâcher tes pièces."
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
	return _ecran(float(em[0]), float(em[1]))


# Les lunes de la jauge : de vrais cabochons (design/machines/lunes.py), au centre mesuré de chaque trou, à sa taille ;
# éteintes, la phase se devine dans le verre ; allumées, la pierre de lune pleine. Puis le cadran du compte à rebours.
func _dessiner_lunes() -> void:
	var v := couche_lunes
	var alv: Array = d["alveoles"]
	var en_sn := p.supernova_t > 0.0
	for i in alv.size():
		var c := _ecran(float(alv[i][0]), float(alv[i][1]))
		var r := float(alv[i][2]) * E * 1.04
		var allumee := i < _allumees
		var pop := 1.0 + 0.22 * exp(-float(_allumee_t[i]) / 0.10) * (1.0 if allumee else 0.0)
		if en_sn:
			pop *= 1.0 + 0.04 * sin(_t * 9.0 + i)
		var rr := r * pop
		v.draw_texture_rect(tex_lune_allumee if allumee else tex_lunes[i], Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false)
	if glissiere:
		_dessiner_glissiere(v)
	if en_sn and p.supernova_fx._range:
		var ce := _centre_embleme()
		var rc := clampf(float(d["r_embleme"]) * 0.38, 50.0, 78.0) * E
		v.draw_texture_rect(tex_cadran, Rect2(ce - Vector2(rc, rc), Vector2(rc, rc) * 2.0), false)
		var f := Style.police("etiquette")
		var txt := str(int(ceil(p.supernova_t)))
		var taille := int(rc * 1.05)
		var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, taille)
		var bas := ce + Vector2(-ts.x * 0.5, taille * 0.36)
		v.draw_string_outline(f, bas, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, 7, Color(0.08, 0.05, 0.0))
		v.draw_string(f, bas, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, OR_TEXTE)


# Les éclats (additifs) : les étoiles du ciel peint qui scintillent (nettes, à leur taille) ; une lune qui s'allume lâche
# quelques étoiles ; à la Supernova, l'emblème s'allume de sa propre lumière et une gerbe d'étoiles en jaillit.
func _dessiner_eclats() -> void:
	var v := couche_eclats
	var en_sn := p.supernova_t > 0.0
	for s in _scintille:
		var b := pow(maxf(0.0, sin(_t * float(s["w"]) + float(s["ph"]))), 4.0)
		var a := (0.10 + 0.80 * b) * (1.4 if en_sn else 1.0)
		var t := float(s["taille"]) * (0.5 + 0.5 * b)
		v.draw_texture_rect(tex_eclat, Rect2(s["pos"] - Vector2(t, t) * 0.5, Vector2(t, t)), false, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	for g in _gerbe:
		var a3 := clampf(float(g["vie"]) / float(g["vie0"]), 0.0, 1.0)
		var t2 := float(g["taille"]) * (0.6 + 0.4 * a3)
		v.draw_texture_rect(tex_eclat, Rect2(g["pos"] - Vector2(t2, t2) * 0.5, Vector2(t2, t2)), false, Color(1, 0.93, 0.74, a3))


func _eclats_lune(i: int) -> void:
	var al: Array = d["alveoles"][i]
	var c := _ecran(float(al[0]), float(al[1]))
	for j in 7:
		var a := TAU * float(j) / 7.0 + randf_range(-0.2, 0.2)
		var vie := randf_range(0.45, 0.8)
		_gerbe.append({"pos": c, "vel": Vector2.from_angle(a) * randf_range(90.0, 190.0), "vie": vie, "vie0": vie,
			"taille": randf_range(16.0, 30.0)})


func _lancer_gerbe() -> void:
	var ce := _centre_embleme()
	for i in 34:
		var a := TAU * float(i) / 34.0 + randf_range(-0.08, 0.08)
		var vie := randf_range(0.9, 1.7)
		_gerbe.append({"pos": ce + Vector2.from_angle(a) * 30.0, "vel": Vector2.from_angle(a) * randf_range(240.0, 640.0),
			"vie": vie, "vie0": vie, "taille": randf_range(26.0, 54.0)})


# ── La glissière (DECISIONS 02/10) ──────────────────────────────────────────────────────────────────────────────

# Un point du monde, à l'écran (la vue 3D couvre le décor, décalée de Y_DECOR).
func _a_l_ecran(x: float, y: float, z: float) -> Vector2:
	var vue: SubViewport = p.rendu.vue
	var k_vue := p.rendu.size.x / float(vue.size.x)
	return p.rendu.camera.unproject_position(Vector3(x, y, zs(z))) * k_vue + Vector2(0, Y_DECOR)


# Le x du monde sous le doigt, à la profondeur du rail : le chariot reste exactement au-dessus du doigt.
func _x_sous(ecran_x: float) -> float:
	var a := _a_l_ecran(float(p.X0), Y_RAIL, Z_RAIL)
	var b := _a_l_ecran(float(p.X1), Y_RAIL, Z_RAIL)
	var x := float(p.X0) + (ecran_x - a.x) / (b.x - a.x) * (float(p.X1) - float(p.X0))
	return clampf(x, float(p.X0) + float(p.R_PIECE), float(p.X1) - float(p.R_PIECE))


func _suivre_doigt(delta: float) -> void:
	doigt["appui"] = maxf(0.0, float(doigt["appui"]) - delta * 2.5)
	if not bool(doigt["la"]):
		return
	var avant := chariot_x
	chariot_x = lerpf(chariot_x, _x_sous(float(doigt["x"])), minf(1.0, delta * 12.0))
	_vx = lerpf(_vx, (chariot_x - avant) / maxf(delta, 1e-3), minf(1.0, delta * 8.0))
	if absf(chariot_x - _x_dernier_lacher) >= 0.75:
		_lacher_ici()


func _lacher_ici() -> void:
	_x_dernier_lacher = chariot_x
	_chutes.append({"de": _bouche(), "x": chariot_x, "t": 0.0})
	_prochaine = -1.3                  # la suivante attend que celle-ci soit partie (~0,23 s), puis grandit
	doigt["appui"] = 1.0


# La chute finie : la vraie pièce naît là où l'animation l'a posée (et sonne à son premier contact).
func _atterrir(x: float) -> void:
	var b: RigidBody3D = p._lacher(x, Z_LACHER)
	if b == null:
		return
	p._sonner_a_la_pose(b)
	GS.main_pieces -= 1
	p._maj_main()


func _avancer_chutes(delta: float) -> void:
	_prochaine = minf(1.0, _prochaine + delta / 0.18)
	for c in _chutes:
		c["t"] = float(c["t"]) + delta
		if float(c["t"]) >= DUREE_CHUTE and not c.has("pose"):
			c["pose"] = true
			_atterrir(float(c["x"]))
	_chutes = _chutes.filter(func(c): return float(c["t"]) < DUREE_CHUTE + 0.02)


# Le lance-pièces à l'écran : au-dessus du doigt, flottant (il respire), et sa bouche, d'où part la pièce.
func _lance_pos() -> Vector2:
	return _a_l_ecran(chariot_x, Y_LANCE, Z_RAIL) + Vector2(0, 3.0 * sin(_t * 2.1))


func _taille_lance() -> float:
	return 150.0 if lance != "croissant" else 140.0


func _bouche() -> Vector2:
	var t := _taille_lance()
	var dy := {"croissant": 0.08, "armillaire": 0.0, "lanterne": 0.12}.get(lance, 0.0) as float
	return _lance_pos() + Vector2(0, t * dy)


func _toucher(ecran_x: float) -> void:
	doigt["la"] = true
	doigt["x"] = ecran_x
	chariot_x = _x_sous(ecran_x)
	_lacher_ici()


func _dessiner_glissiere(v: Control) -> void:
	var c0 := _lance_pos()
	var tl := _taille_lance()
	var penche := clampf(-_vx * 0.035, -0.22, 0.22)
	# la pièce qui attend, derrière l'avant du lance-pièces (elle apparaît en grandissant après chaque lâcher)
	var vue_p := clampf(_prochaine, 0.0, 1.0)
	var tp := tl * 0.30 * (0.4 + 0.6 * vue_p)
	var b := _bouche()
	v.draw_set_transform(c0, penche, Vector2.ONE)
	if lance == "armillaire":
		v.draw_texture_rect(tex_piece, Rect2(b - c0 - Vector2(tp, tp) * 0.5, Vector2(tp, tp)), false, Color(1, 1, 1, vue_p))
		v.draw_texture_rect(tex_lance, Rect2(-Vector2(tl, tl) * 0.5, Vector2(tl, tl)), false)
	else:
		v.draw_texture_rect(tex_lance, Rect2(-Vector2(tl, tl) * 0.5, Vector2(tl, tl)), false)
		v.draw_texture_rect(tex_piece, Rect2(b - c0 - Vector2(tp, tp) * 0.5 - Vector2(0, tp * 0.25), Vector2(tp, tp)), false, Color(1, 1, 1, vue_p))
	v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# les pièces qui tombent : elles tournoient (la tranche, puis la face), grandissent un peu en approchant
	for ch in _chutes:
		var u := clampf(float(ch["t"]) / DUREE_CHUTE, 0.0, 1.0)
		var arrivee := _a_l_ecran(float(ch["x"]), float(p.H_BLOC) + 0.12, Z_LACHER)
		var pos: Vector2 = (ch["de"] as Vector2).lerp(arrivee, u * u)
		var taille := lerpf(tl * 0.30, 58.0, u)
		var tour := absf(cos(u * 9.0)) * 0.75 + 0.25
		v.draw_set_transform(pos, 0.0, Vector2(1.0, tour))
		v.draw_texture_rect(tex_piece, Rect2(-Vector2(taille, taille) * 0.5, Vector2(taille, taille)), false)
		v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# le doigt (simulé) : un rond clair, une onde à chaque pièce lâchée
	if bool(doigt["la"]):
		var c := Vector2(float(doigt["x"]), Y_DOIGT)
		v.draw_circle(c, 44.0, Color(1.0, 0.97, 0.88, 0.30))
		v.draw_arc(c, 44.0, 0.0, TAU, 64, Color(1.0, 0.95, 0.80, 0.85), 3.0, true)
		var o := 1.0 - float(doigt["appui"])
		if float(doigt["appui"]) > 0.0:
			v.draw_arc(c, 44.0 + o * 40.0, 0.0, TAU, 64, Color(1.0, 0.9, 0.6, float(doigt["appui"]) * 0.8), 2.5, true)


func _scenario_glissiere() -> void:
	await _attendre(0.3)
	_sans_cadeau()
	await _attendre(4.0)
	_toucher(250.0)
	await _attendre(0.18)
	_capture("lance_%s_chute" % lance)
	for i in 60:
		doigt["x"] = 540.0 + 300.0 * sin(-1.0 + float(i) / 60.0 * 3.0)
		await _attendre(1.0 / 30.0)
	_capture("lance_%s_glisse" % lance)
	await _attendre(0.8)
	_capture("lance_%s_pieces" % lance)
	get_tree().quit(0)


func _film_glissiere() -> void:
	await _images(10)
	_sans_cadeau()
	await _images(70)
	_toucher(250.0)
	await _images(30)
	for i in 330:
		doigt["x"] = 540.0 + 330.0 * sin(-0.9 + float(i) / 330.0 * TAU * 1.5)
		await _images(1)
	doigt["la"] = false
	await _images(45)
	_toucher(780.0)
	await _images(12)
	doigt["la"] = false
	await _images(30)
	_toucher(330.0)
	await _images(12)
	doigt["la"] = false
	await _images(70)
	get_tree().quit(0)


func _scenario() -> void:
	await _attendre(0.3)
	_sans_cadeau()
	await _attendre(5.5)
	_capture("repos")
	GS.jauge_supernova += int(ceil(float(PusherScreen.JAUGE_SUPERNOVA) / float((d["alveoles"] as Array).size())))
	await _attendre(0.06)
	_capture("lune_pop")
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
	await _images(120)
	GS.jauge_supernova += int(ceil(float(PusherScreen.JAUGE_SUPERNOVA) / float((d["alveoles"] as Array).size())))
	await _images(60)
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
