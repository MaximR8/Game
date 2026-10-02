extends Node

# LA MACHINE DANS SON DÉCOR PEINT (02/10/2026 — DECISIONS 02/10).
#
# Maxim, sur le meuble en volumes simples : « ça fait vieille 3D » — il veut « un décor fixe derrière, bien HD, propre, et
# des petites animations dessus, un peu comme les cartes ». Ses décors sont générés dans ChatGPT (REPRISE.md, les prompts) ;
# « on garde tous les décors, mais le céleste est celui par défaut » ; le lance-pièces : « on part sur la B » (la sphère
# armillaire) ; « tu peux mettre en ligne ».
#
# Posé par PusherScreen sur la Nébuleuse (il remplace le cadre dessiné d'avant, son titre, sa frise) :
#   · le DÉCOR peint (res://machines/<décor>/decor.jpg), fondu en haut et en bas, du haut de l'écran au panneau Réserve ;
#   · la vue 3D (MachineRendu) calée dessus : la caméra en perspective relevée par design/machines/analyser.py ; le creux
#     peint est plus profond que le plateau : la profondeur est étirée à l'image autour du bord — la PLACE des pièces
#     seulement, leur forme reste (« en étirant, ça a déformé les pièces ») ; la physique ne change pas ;
#   · ce que le décor ne peut pas peindre : le bloc qui pousse (il porte l'habit de la marche peinte), les fentes, et deux
#     caches peints (un mur bas au fond, sous lequel le bloc glisse ; la lèvre de l'avant, derrière laquelle les pièces
#     tombent) ;
#   · par-dessus : les lunes de la jauge (des cabochons, au centre mesuré de chaque alvéole), le reflet sur les arêtes de
#     l'or, les étoiles qui scintillent, les flammes qui ondulent ; à la Supernova, l'or de l'emblème s'allume, une gerbe
#     d'étoiles en jaillit, et le compte à rebours s'inscrit dans un cadran d'émail (le mot SUPERNOVA rangé laisse la place) ;
#   · le LANCE-PIÈCES (DECISIONS 02/10) : le doigt touche la machine n'importe où, seule sa position gauche-droite compte ;
#     la sphère armillaire se place au-dessus de lui, la pièce suivante en son cœur ; chaque pièce lâchée tombe en
#     tournoyant, puis devient la vraie pièce sur le bloc (le son à son premier contact).

const DONNEES := preload("res://machines/decors.gd")
const SH_CORPS := preload("res://machines/corps_vue.gdshader")
const SH_OMBRE := preload("res://machines/ombre_vue.gdshader")
const SH_PEINT := preload("res://machines/peint.gdshader")
const SH_REFLET := preload("res://machines/reflet_or.gdshader")
const SH_FONDU := preload("res://machines/decor_fondu.gdshader")
const SH_FLAMME := preload("res://machines/flamme.gdshader")
const E := 1080.0 / 1024.0             # du pixel de l'image au pixel du jeu
const OR_TEXTE := Color(1.0, 0.86, 0.46)
const Y_LANCE := 3.0                   # le lance-pièces flotte au-dessus du bloc (« plus haut », Maxim)
const DZ_LANCE := 0.35                 # sa profondeur : juste devant le mur du fond
const DZ_LACHER := 0.6                 # où tombent les pièces sur le bloc (toujours la même profondeur)
const DUREE_CHUTE := 0.42
const PAS_SEMIS := 0.75                # glisser : une pièce tous les ~0,75 de chemin du lance-pièces
const HAUT_TOUCHER := 200.0            # au-dessus : le bandeau du haut (ses compteurs)
const BAS_TOUCHER := 1470.0            # au-dessous : le panneau Réserve

static var theme := "BaseCeleste"      # le décor de la machine — Base céleste par défaut (DECISIONS 02/10)
static var champ := "80"               # la caméra relevée pour un champ de 80° (90° : moins d'étirement, plus grand-angle)

var p: PusherScreen
var d: Dictionary
var k := 1.0
var y_decor := 40.0
var rect := Rect2()
var tex_decor: Texture2D
var tex_eclat: Texture2D
var tex_lune_allumee: Texture2D
var tex_cadran: Texture2D
var tex_lance: Texture2D
var tex_piece: Texture2D
var tex_lunes: Array = []
var couche_lunes: Control
var couche_eclats: Control
var mat_reflet: ShaderMaterial
var flammes: Array = []
var bloc3d: Node3D
var lance_x := 5.4
var _t := 0.0
var _sn_t := -1.0
var _scintille: Array = []
var _gerbe: Array = []
var _allumees := -1
var _allumee_t: Array = []
var _vx := 0.0
var _x_dernier := -99.0
var _doigt := false
var _doigt_x := 540.0
var _chutes: Array = []
var _prochaine := 1.0


func installer(pusher: PusherScreen) -> void:
	p = pusher
	d = DONNEES.DECORS.get(theme, DONNEES.DECORS["BaseCeleste"])
	var haut_alveoles := 9999.0
	for al in d["alveoles"]:
		haut_alveoles = minf(haut_alveoles, float(al[1]) - float(al[2]))
	# assez bas pour que le haut de l'arche (ses alvéoles) passe sous le bandeau du haut
	y_decor = clampf(168.0 - haut_alveoles * E, 40.0, 120.0)
	rect = Rect2(0, y_decor, 1080, 1536.0 * E)
	tex_decor = load(str(d["image"]))
	tex_lune_allumee = load("res://machines/lunes/lune-allumee.png")
	tex_cadran = load("res://machines/lunes/cadran.png")
	tex_lance = load("res://machines/lunes/lance-armillaire.png")
	tex_eclat = load("res://ciel/eclat-etoile.png")
	tex_piece = Style.objet("piece-etoile")
	var n_alv: int = (d["alveoles"] as Array).size()
	for i in n_alv:
		var t := float(i) / float(maxi(1, n_alv - 1))
		var cote := 1.0 if t < 0.5 else -1.0
		var ph := 0.0 if i == 0 or i == n_alv - 1 else cote * (1.0 - absf(2.0 * t - 1.0))
		tex_lunes.append(load("res://machines/lunes/lune%s.png" % _signe(ph)))
		_allumee_t.append(99.0)
	var pts: Array = d["etoiles"]
	for i in mini(pts.size(), 18):
		var s: Array = pts[i]
		_scintille.append({"pos": _ecran_image(float(s[0]), float(s[1])), "w": randf_range(0.7, 1.8), "ph": randf() * TAU,
			"taille": lerpf(36.0, 18.0, float(i) / 17.0)})
	_couches()
	_vue_3d()


func _signe(ph: float) -> String:
	# la pleine lune et la nouvelle n'ont qu'une image
	if absf(ph) > 0.999:
		return "+1.000"
	if absf(ph) < 0.001:
		return "+0.000"
	return "%+.3f" % ph


func _ecran_image(x: float, y: float) -> Vector2:
	return Vector2(x * E, y_decor + y * E)


func zs(z: float) -> float:
	return p.BORD - k * (p.BORD - z)


# Un point du monde de la machine (en coordonnées de la physique) à l'écran : les gains, les effets, le lance-pièces.
func ecran(pos: Vector3) -> Vector2:
	var vue: SubViewport = p.rendu.vue
	var k_vue := p.rendu.size.x / float(vue.size.x)
	return p.rendu.camera.unproject_position(Vector3(pos.x, pos.y, zs(pos.z))) * k_vue + Vector2(0, y_decor)


# ─────────────────────────────────────────────────────────────
# La pose : les couches 2D, la vue 3D
# ─────────────────────────────────────────────────────────────

func _couches() -> void:
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
	# le reflet sur l'or (sous la vue 3D : il ne passe jamais sur une pièce)
	var reflet := ColorRect.new()
	reflet.position = rect.position
	reflet.size = rect.size
	reflet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat_reflet = ShaderMaterial.new()
	mat_reflet.shader = SH_REFLET
	mat_reflet.set_shader_parameter("masque", load(str(d["or"])))
	mat_reflet.set_shader_parameter("decor", tex_decor)
	var em: Array = d["embleme"]
	mat_reflet.set_shader_parameter("embleme", Vector2(float(em[0]) / 1024.0, float(em[1]) / 1536.0))
	mat_reflet.set_shader_parameter("r_embleme", float(d["r_embleme"]) / 1024.0)
	reflet.material = mat_reflet
	p.add_child(reflet)
	p.move_child(reflet, 1)
	# les flammes (sous la vue 3D) : chacune relit sa flamme peinte
	var i_fl := 2
	for fl in d["flammes"]:
		var fx := float(fl[0])
		var fy := float(fl[1])
		var fw := float(fl[2])
		var fh := float(fl[3])
		var cr := ColorRect.new()
		cr.position = _ecran_image(fx - fw * 0.5, fy - fh)
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
		flammes.append(mfl)
	# AU-DESSUS de la vue 3D : les éclats (additifs), puis les lunes, le cadran, le lance-pièces (mélange normal)
	var au_dessus := p.rendu.get_index() + 1
	couche_eclats = Control.new()
	couche_eclats.size = Vector2(1080, 2400)
	couche_eclats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	couche_eclats.material = add
	couche_eclats.draw.connect(_dessiner_eclats)
	p.add_child(couche_eclats)
	p.move_child(couche_eclats, au_dessus)
	couche_lunes = Control.new()
	couche_lunes.size = Vector2(1080, 2400)
	couche_lunes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche_lunes.draw.connect(_dessiner_lunes)
	p.add_child(couche_lunes)
	p.move_child(couche_lunes, au_dessus + 1)


func _vue_3d() -> void:
	var r: MachineRendu = p.rendu
	r.zone = rect
	r.position = rect.position
	r.size = rect.size
	r.ecran.size = rect.size
	r._ajuster()
	var cam_d: Dictionary = d["cameras"][champ]
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
	r.perspective(k)
	for c in r.vue.get_children():
		if c is MultiMeshInstance3D:
			var m: ShaderMaterial = (c as MultiMeshInstance3D).material_override
			m.shader = SH_CORPS if m.shader.resource_path.ends_with("corps.gdshader") else SH_OMBRE
			r.regler_vue(m)
	_plateau(r.vue)


# Ce que le décor ne peut pas peindre : le bloc qui pousse (il bouge ; l'habit de la marche peinte, découpé dans l'image),
# les fentes (où les pièces se perdent), et deux caches peints — un mur BAS au fond (le bloc glisse dessous ; haut, il
# coupait le cadran de la Supernova) et la lèvre de l'avant (les pièces tombent derrière elle).
func _plateau(vue: Node) -> void:
	var x0 := float(p.X0)
	var x1 := float(p.X1)
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	var peint := ShaderMaterial.new()
	peint.shader = SH_PEINT
	peint.set_shader_parameter("decor", tex_decor)
	bloc3d = Node3D.new()
	vue.add_child(bloc3d)
	var dessus := StandardMaterial3D.new()
	dessus.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dessus.albedo_texture = load(str(d["bloc_dessus"]))
	dessus.texture_repeat = true
	dessus.uv1_scale = Vector3(1.0, 2.5, 1.0)       # le dessus se répète tous les 1,6 : ce qui sort de sous le mur
	dessus.uv1_offset = Vector3(0.0, -1.5, 0.0)     # continue le motif
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, 4.0 * k)
	_mi(bloc3d, pm, dessus, Vector3(cx, float(p.H_BLOC) + 0.002, -2.0 * k))
	var habit := StandardMaterial3D.new()
	habit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	habit.albedo_texture = load(str(d["bloc_face"]))
	var face := QuadMesh.new()
	face.size = Vector2(w, float(p.H_BLOC))
	_mi(bloc3d, face, habit, Vector3(cx, float(p.H_BLOC) * 0.5, 0.0))
	var mur := BoxMesh.new()
	mur.size = Vector3(w + 3.0, 1.2, 0.3)
	_mi(vue, mur, peint, Vector3(cx, 0.6, zs(p.MUR) - 0.15))
	var levre := BoxMesh.new()
	levre.size = Vector3(w + 4.0, 3.0, 0.8)
	_mi(vue, levre, peint, Vector3(cx, -1.5, p.BORD + 0.4))
	var or_ := StandardMaterial3D.new()
	or_.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	or_.albedo_color = Color(0.93, 0.74, 0.38)
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
		_mi(vue, lev, or_, Vector3(lx, 0.0, (z0 + z1) * 0.5), Basis(Vector3.RIGHT, PI * 0.5))
		for z in [z0, z1]:
			var bout := CylinderMesh.new()
			bout.top_radius = 0.035
			bout.bottom_radius = 0.035
			bout.height = f
			_mi(vue, bout, or_, Vector3(fx, 0.0, z), Basis(Vector3(0, 0, 1), PI * 0.5))


func _mi(parent: Node, mesh: Mesh, mat: Material, pos: Vector3, b := Basis()) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(b, pos)
	parent.add_child(mi)
	return mi


# ─────────────────────────────────────────────────────────────
# Le doigt : le lance-pièces
# ─────────────────────────────────────────────────────────────

func dans_la_machine(pos: Vector2) -> bool:
	return pos.y > HAUT_TOUCHER and pos.y < BAS_TOUCHER


func toucher(pos: Vector2, appui: bool) -> void:
	if not appui:
		_doigt = false
		return
	if not dans_la_machine(pos):
		return
	_doigt = true
	_doigt_x = pos.x
	lance_x = _x_sous(pos.x)
	_lacher_ici()


func glisser(pos: Vector2) -> void:
	if _doigt:
		_doigt_x = pos.x


# Le x du monde sous le doigt, à la profondeur du lance-pièces : il reste exactement au-dessus du doigt.
func _x_sous(ecran_x: float) -> float:
	var z := float(p.MUR) + DZ_LANCE
	var a := ecran(Vector3(float(p.X0), Y_LANCE, z))
	var b := ecran(Vector3(float(p.X1), Y_LANCE, z))
	var x := float(p.X0) + (ecran_x - a.x) / (b.x - a.x) * (float(p.X1) - float(p.X0))
	return clampf(x, float(p.X0) + float(p.R_PIECE), float(p.X1) - float(p.R_PIECE))


# Une pièce part : elle est prise dans la réserve au départ (deux pièces en l'air ne se paient pas deux fois), et rendue
# si elle ne trouve pas de place en arrivant.
func _lacher_ici() -> void:
	_x_dernier = lance_x
	var refus := p.refus_lacher()
	if refus != "":
		p._indice(refus, Style.ALERTE)
		return
	GS.main_pieces -= 1
	p._maj_main()
	_chutes.append({"de": _bouche(), "x": lance_x, "t": 0.0})
	_prochaine = -1.3                  # la suivante attend que celle-ci soit partie (~0,23 s), puis grandit


func _atterrir(x: float) -> void:
	var b: RigidBody3D = p._lacher(x, float(p.MUR) + DZ_LACHER)
	if b == null:
		GS.main_pieces += 1
		p._maj_main()
		p._indice("Trop de pièces ici : vise un endroit plus dégagé.", Style.ALERTE)
		return
	p._sonner_a_la_pose(b)
	Presages.evenement("piece")
	GS.demander_sauvegarde()


func _lance_pos() -> Vector2:
	return ecran(Vector3(lance_x, Y_LANCE, float(p.MUR) + DZ_LANCE)) + Vector2(0, 3.0 * sin(_t * 2.1))


func _bouche() -> Vector2:
	return _lance_pos()


# ─────────────────────────────────────────────────────────────
# À chaque image
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if p == null or not p.visible:
		return
	_t += delta
	bloc3d.position.z = zs(p.face_z)
	# le lance-pièces suit le doigt (un peu de retard : il a du poids), et sème en glissant
	if _doigt:
		var avant := lance_x
		lance_x = lerpf(lance_x, _x_sous(_doigt_x), minf(1.0, delta * 12.0))
		_vx = lerpf(_vx, (lance_x - avant) / maxf(delta, 1e-3), minf(1.0, delta * 8.0))
		if absf(lance_x - _x_dernier) >= PAS_SEMIS:
			_lacher_ici()
	else:
		_vx = lerpf(_vx, 0.0, minf(1.0, delta * 6.0))
	_prochaine = minf(1.0, _prochaine + delta / 0.18)
	for c in _chutes:
		c["t"] = float(c["t"]) + delta
		if float(c["t"]) >= DUREE_CHUTE and not c.has("pose"):
			c["pose"] = true
			_atterrir(float(c["x"]))
	_chutes = _chutes.filter(func(c): return float(c["t"]) < DUREE_CHUTE + 0.02)
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
	# la Supernova : le mot rangé laisse la place au compte à rebours, dans l'emblème
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
	# le reflet : un passage lent toutes les 7 s ; à la Supernova, toutes les 1,8 s, et l'or de l'emblème flambe
	var periode := 1.8 if en_sn else 7.0
	mat_reflet.set_shader_parameter("phase", -0.6 + 2.4 * clampf(fmod(_t, periode) / 1.6, 0.0, 1.0))
	mat_reflet.set_shader_parameter("eclat_embleme", (0.95 + 0.35 * sin(_t * 8.0)) * clampf(_sn_t / 0.3, 0.0, 1.0) if en_sn else 0.0)
	for mfl in flammes:
		(mfl as ShaderMaterial).set_shader_parameter("temps", _t)
	couche_lunes.queue_redraw()
	couche_eclats.queue_redraw()


# ─────────────────────────────────────────────────────────────
# Le dessin
# ─────────────────────────────────────────────────────────────

func _centre_embleme() -> Vector2:
	var em: Array = d["embleme"]
	return _ecran_image(float(em[0]), float(em[1]))


# Les lunes (des cabochons : design/machines/lunes.py), au centre mesuré de chaque trou, à sa taille ; le cadran du compte
# à rebours ; le lance-pièces, la pièce qui l'attend, les pièces qui tombent.
func _dessiner_lunes() -> void:
	var v := couche_lunes
	var alv: Array = d["alveoles"]
	var en_sn := p.supernova_t > 0.0
	for i in alv.size():
		var c := _ecran_image(float(alv[i][0]), float(alv[i][1]))
		var r := float(alv[i][2]) * E * 1.04
		var allumee := i < _allumees
		var pop := 1.0 + 0.22 * exp(-float(_allumee_t[i]) / 0.10) * (1.0 if allumee else 0.0)
		if en_sn:
			pop *= 1.0 + 0.04 * sin(_t * 9.0 + i)
		var rr := r * pop
		v.draw_texture_rect(tex_lune_allumee if allumee else tex_lunes[i], Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false)
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
	# le lance-pièces (la sphère armillaire) : la pièce suivante en son cœur, il penche un peu quand il glisse
	var c0 := _lance_pos()
	var tl := 150.0
	var vue_p := clampf(_prochaine, 0.0, 1.0)
	var tp := tl * 0.30 * (0.4 + 0.6 * vue_p)
	v.draw_set_transform(c0, clampf(-_vx * 0.035, -0.22, 0.22), Vector2.ONE)
	v.draw_texture_rect(tex_piece, Rect2(-Vector2(tp, tp) * 0.5, Vector2(tp, tp)), false, Color(1, 1, 1, vue_p))
	v.draw_texture_rect(tex_lance, Rect2(-Vector2(tl, tl) * 0.5, Vector2(tl, tl)), false)
	v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# les pièces qui tombent : elles tournoient, grandissent un peu en approchant
	for ch in _chutes:
		var u := clampf(float(ch["t"]) / DUREE_CHUTE, 0.0, 1.0)
		var arrivee := ecran(Vector3(float(ch["x"]), float(p.H_BLOC) + 0.12, float(p.MUR) + DZ_LACHER))
		var pos: Vector2 = (ch["de"] as Vector2).lerp(arrivee, u * u)
		var taille2 := lerpf(tl * 0.30, 58.0, u)
		var tour := absf(cos(u * 9.0)) * 0.75 + 0.25
		v.draw_set_transform(pos, 0.0, Vector2(1.0, tour))
		v.draw_texture_rect(tex_piece, Rect2(-Vector2(taille2, taille2) * 0.5, Vector2(taille2, taille2)), false)
		v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Les éclats (additifs) : les étoiles du ciel peint qui scintillent ; une lune qui s'allume lâche quelques étoiles ; la
# gerbe de la Supernova.
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
	var c := _ecran_image(float(al[0]), float(al[1]))
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
