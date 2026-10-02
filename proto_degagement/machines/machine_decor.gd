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
#     l'or, les étoiles qui scintillent, les flammes qui ondulent ;
#   · la SUPERNOVA (refaite le 02/10 — Maxim : « pas assez spectaculaire », « il n'y a pas de récompense sur le plateau » ;
#     puis, le soir : plus de mode de 30 s, un gros lot d'un coup) : la salle s'assombrit, les lunes versent leur lumière
#     dans l'astrolabe, il explose (une couronne de rais, l'étoile, deux ondes ; l'onde court dans tout l'or du décor ; la
#     machine tremble), le mot SUPERNOVA en lettres d'or ; une PLUIE D'OR en jaillit — de vraies pièces qui volent jusqu'au
#     plateau, devant le bloc —, des POUSSIÈRES D'ÉTOILE offertes, et le CŒUR D'ÉTOILE, en dernier, qui brille sur le
#     plateau ; les lunes en chenillard ; à la fin, elles s'éteignent du centre vers les bords ;
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
const SH_MOT := preload("res://machines/mot_or.gdshader")
const E := 1080.0 / 1024.0             # du pixel de l'image au pixel du jeu
const OR_TEXTE := Color(1.0, 0.86, 0.46)
const Y_LANCE := 3.0                   # le lance-pièces flotte au-dessus du bloc (« plus haut », Maxim)
const DZ_LANCE := 0.35                 # sa profondeur : juste devant le mur du fond
const DZ_LACHER := 0.6                 # où tombent les pièces sur le bloc (toujours la même profondeur)
const DUREE_CHUTE := 0.42
const PAS_SEMIS := 0.75                # glisser : une pièce tous les ~0,75 de chemin du lance-pièces
const HAUT_TOUCHER := 200.0            # au-dessus : le bandeau du haut (ses compteurs)
const BAS_TOUCHER := 1470.0            # au-dessous : le panneau Réserve
# La Supernova : ses instants, depuis son départ (le son les suit : Son.supernova(true)) ; elle dure
# PusherScreen.SUPERNOVA_S (~6 s : le cœur est posé), puis les lunes s'éteignent
const SN_ECLAT := 0.6                  # l'explosion (avant : l'aspiration)
const SN_MOT := 2.6                    # le mot reste, puis rentre dans l'astrolabe…
const SN_RANGE := SN_ECLAT + SN_MOT
const SN_PLUIE := SN_ECLAT + 0.3       # la pluie d'or jaillit de l'astrolabe…
const SN_PAS_PLUIE := 0.065            # …une pièce tous les 65 ms
const SN_POUSSIERE := SN_PLUIE + 0.6   # les poussières d'étoile, au milieu de la pluie…
const SN_PAS_POUSSIERE := 0.7          # …une tous les 0,7 s
const SN_COEUR := SN_RANGE + 0.3       # …et le cœur d'étoile en sort, en dernier
const SN_FIN := 0.7                    # la fin : les lunes s'éteignent
const VOL_PIECE := 0.85
const VOL_POUSSIERE := 1.15
const VOL_COEUR := 1.4
const Z_ASTRE := 5.6                   # d'où partent les vols : juste derrière le mur bas, au cœur de l'astrolabe

static var theme := "BaseCeleste"      # le décor de la machine — Base céleste par défaut (DECISIONS 02/10)
# leurs noms, pour les outils de test (02/10 — Maxim : « faudrait que je teste les skins : mets-moi un bouton caché ») ;
# l'ordre : celui de machines/decors.gd
const NOMS := {"BaseCeleste": "Base céleste", "Grec": "Olympe", "Vahlalla": "Valhalla", "egypte": "Égypte",
	"Atlantis": "Atlantide", "Persian": "Perse", "Aztec": "Aztèque"}
static var champ := "80"               # la caméra relevée pour un champ de 80° (90° : moins d'étirement, plus grand-angle)

var p: PusherScreen
var d: Dictionary
var k := 1.0
var y_decor := 40.0
var rect := Rect2()
var tex_decor: Texture2D
var tex_eclat: Texture2D
var tex_lune_allumee: Texture2D
var tex_lance: Texture2D
var tex_piece: Texture2D
var tex_lunes: Array = []
var couche_lunes: Control
var couche_eclats: Control
var mat_reflet: ShaderMaterial
var mat_fond: ShaderMaterial
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
# la Supernova
var tex_rai: Texture2D
var tex_nova: Texture2D
var mot: TextureRect
var mat_mot: ShaderMaterial
var couches_machine: Array = []        # [nœud, sa place] : ce qui tremble à l'explosion (pas le panneau Réserve)
var _sn_fin := -1.0                    # le temps depuis la fin (-1 : pas de fin en cours)
var _aspires: Array = []               # la lumière que l'astrolabe aspire
var _t_lune: Array = []                # l'instant où chaque lune verse la sienne
var _flash_lune: Array = []            # depuis quand chaque lune s'est avivée
var _vols: Array = []                  # les pièces et le cœur qui volent de l'astrolabe au plateau
var _pluie_reste := 0
var _pluie_t := 0.0
var _poussieres_reste := 0
var _poussiere_t := 0.0
var _posees := 0
var _coeur_du := false
var _depart := Vector3.ZERO
var _secousse := 0.0
var _rechauffe := 4                    # les premières images : le mot et une onde, dessinés invisibles (leurs shaders se
                                       # compilent là, pas à l'explosion — sinon la machine se fige au plus beau moment)


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
	tex_lance = load("res://machines/lunes/lance-armillaire.png")
	tex_eclat = load("res://ciel/eclat-etoile.png")
	tex_piece = Style.objet("piece-etoile")
	tex_rai = load("res://machines/lunes/rai.png")
	tex_nova = load("res://machines/lunes/eclat-nova.png")
	var n_alv: int = (d["alveoles"] as Array).size()
	for i in n_alv:
		var t := float(i) / float(maxi(1, n_alv - 1))
		var cote := 1.0 if t < 0.5 else -1.0
		var ph := 0.0 if i == 0 or i == n_alv - 1 else cote * (1.0 - absf(2.0 * t - 1.0))
		tex_lunes.append(load("res://machines/lunes/lune%s.png" % _signe(ph)))
		_allumee_t.append(99.0)
		_flash_lune.append(99.0)
	# les étoiles du ciel peint qui scintillent : les 18 plus vives ; toutes pendant la Supernova
	var pts: Array = d["etoiles"]
	for i in pts.size():
		var s: Array = pts[i]
		_scintille.append({"pos": _ecran_image(float(s[0]), float(s[1])), "w": randf_range(0.7, 1.8), "ph": randf() * TAU,
			"taille": lerpf(36.0, 18.0, clampf(float(i) / 17.0, 0.0, 1.0)), "sn": i >= 18})
	_couches()
	_vue_3d()
	_le_mot()
	couches_machine.append([p.rendu, p.rendu.position])
	p.supernova_fx.visible = false         # le décor a sa Supernova (supernova_fx sert à la vue d'avant)
	# ses sons, chargés d'avance (au premier son, le téléphone lit le fichier : un à-coup) — après l'ouverture
	p.get_tree().create_timer(2.0).timeout.connect(_prechauffer_sons)


static func nom_du(cle: String) -> String:
	return str(NOMS.get(cle, cle))


static func suivant(cle: String) -> String:
	var l: Array = DONNEES.DECORS.keys()
	return str(l[(l.find(cle) + 1) % l.size()])


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
	var em0: Array = d["embleme"]
	mf.set_shader_parameter("embleme", Vector2(float(em0[0]) / 1024.0, float(em0[1]) / 1536.0))
	mf.set_shader_parameter("r_embleme", float(d["r_embleme"]) / 1024.0)
	fond.material = mf
	mat_fond = mf
	p.add_child(fond)
	p.move_child(fond, 0)
	couches_machine.append([fond, fond.position])
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
	couches_machine.append([reflet, reflet.position])
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
		couches_machine.append([cr, cr.position])
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
	couches_machine.append([couche_eclats, Vector2.ZERO])
	couche_lunes = Control.new()
	couche_lunes.size = Vector2(1080, 2400)
	couche_lunes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche_lunes.draw.connect(_dessiner_lunes)
	p.add_child(couche_lunes)
	p.move_child(couche_lunes, au_dessus + 1)
	couches_machine.append([couche_lunes, Vector2.ZERO])


# Le mot SUPERNOVA (design/machines/supernova.py), au-dessus de tout, centré sur l'emblème.
func _le_mot() -> void:
	mot = TextureRect.new()
	mot.texture = load("res://machines/lunes/mot-supernova.png")
	mot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mot.stretch_mode = TextureRect.STRETCH_SCALE
	mot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mot.size = Vector2(880.0, 880.0 * 300.0 / 1400.0)
	mot.pivot_offset = mot.size * 0.5
	mot.position = _centre_embleme() - mot.size * 0.5
	mot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat_mot = ShaderMaterial.new()
	mat_mot.shader = SH_MOT
	mot.material = mat_mot
	mot.visible = false
	p.add_child(mot)
	p.move_child(mot, couche_lunes.get_index() + 1)
	couches_machine.append([mot, mot.position])


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
	# (02/10) le dessus, d'un seul niveau (analyser.py : sans les filets d'or de la marche peinte, sans couture) : il se
	# répète à l'échelle de la marche peinte (420 lignes de l'image redressée pour ~1,6 de bloc)
	dessus.uv1_scale = Vector3(1.0, 2.5 * 420.0 / float(maxi(1, dessus.albedo_texture.get_height())), 1.0)
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
	_front_de_marche(vue, cx, w, habit.albedo_texture)
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


# Le front de la marche fixe (02/10 — Maxim, sur les six autres décors : « la plaque mobile, on dirait qu'elle passe sous un
# jpeg du décor ; sur la Base céleste, on dirait une barre qui pousse les pièces »). Le bloc disparaît sous le mur du fond
# (zs(MUR), la physique) ; mais la marche peinte commence plus haut à l'écran : entre les deux, le décor montrait le dessus de
# la marche, immobile, au-dessus du bloc qui bouge (20 px sur la Base céleste, 35 à 75 sur les autres). Un front de marche
# (l'habit de la face du bloc) couvre cette bande : le bloc sort de dessous une marche fixe, comme dans une vraie machine, et
# les pièces du bloc butent contre lui ; une ombre en bas : la fente.
func _front_de_marche(vue: Node, cx: float, w: float, tex: Texture2D) -> void:
	if not d.has("dessus"):
		return
	var des: Array = d["dessus"]
	var y_dos := _ecran_image(0.0, (float(des[0][1]) + float(des[1][1])) * 0.5).y
	var bas := float(p.H_BLOC)
	if ecran(Vector3(cx, bas, float(p.MUR))).y <= y_dos + 1.0:
		return
	var lo := 0.0
	var hi := 4.0
	for i in 30:
		var m := (lo + hi) * 0.5
		if ecran(Vector3(cx, bas + m, float(p.MUR))).y > y_dos:
			lo = m
		else:
			hi = m
	var h := (lo + hi) * 0.5
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D habit : filter_linear_mipmap, repeat_disable;
void fragment() {
	vec3 c = texture(habit, UV).rgb;
	float fente = smoothstep(0.0, 0.22, 1.0 - UV.y);
	ALBEDO = c * mix(0.35, 1.0, fente);
}
"""
	mat.shader = sh
	mat.set_shader_parameter("habit", tex)
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	_mi(vue, q, mat, Vector3(cx, bas + h * 0.5, zs(float(p.MUR)) + 0.003))


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
# La Supernova (refaite le 02/10)
# ─────────────────────────────────────────────────────────────

# Elle part (PusherScreen.declencher_supernova) : la pluie d'or (n pièces offertes), les poussières d'étoile et le cœur
# sortiront de l'astrolabe. La machine cachée (personne ne regarde) : tout se pose tout de suite sur le plateau.
func supernova(n_pieces: int, n_poussieres: int, anime: bool) -> void:
	_sn_t = 0.0
	_sn_fin = -1.0
	_pluie_reste = n_pieces
	_pluie_t = SN_PLUIE
	_poussieres_reste = n_poussieres
	_poussiere_t = SN_POUSSIERE
	_posees = 0
	_coeur_du = n_pieces > 0
	_depart = _point_astre()
	_aspires.clear()
	_t_lune.clear()
	if anime:
		_preparer_aspiration()
	else:
		achever_pluie()


# Elle finit (PusherScreen._fin_supernova) : ce qui n'est pas encore tombé tombe ; les lunes s'éteignent.
func fin_supernova() -> void:
	achever_pluie()
	_sn_t = -1.0
	_sn_fin = 0.0
	var ce := _centre_embleme()
	for i in 14:
		var vie := randf_range(0.4, 0.7)
		_gerbe.append({"pos": ce, "vel": Vector2.from_angle(TAU * float(i) / 14.0) * randf_range(140.0, 300.0), "vie": vie,
			"vie0": vie, "taille": randf_range(16.0, 30.0)})


# Tout ce qui reste de la pluie tombe d'un coup (la machine se cache, l'app passe en arrière-plan, la Supernova finit) :
# la sauvegarde ne perd rien — pas une pièce, surtout pas le cœur.
func achever_pluie() -> void:
	for v in _vols:
		if not v.has("pose"):
			var b: RigidBody3D = v["b"]
			if is_instance_valid(b):
				b.global_position = v["a"]
			_poser_vol(v, false)
	_vols.clear()
	while _pluie_reste > 0:
		_pluie_reste -= 1
		p._piece(_cible_pluie())
	while _poussieres_reste > 0:
		_poussieres_reste -= 1
		var xz := _cible_bille(float(p.lot_def("poussiere")["r"]))
		p._lot("poussiere", Vector3.INF, Vector2(xz.x, xz.z)).set_meta("bonus", true)
	if _coeur_du:
		_donner_coeur(false)


# D'où partent les vols : au cœur de l'astrolabe peint, juste derrière le mur bas — la hauteur cherchée pour que le point
# tombe pile sur l'emblème, à l'écran.
func _point_astre() -> Vector3:
	var x := (float(p.X0) + float(p.X1)) * 0.5
	var cible := _centre_embleme().y
	var bas := 0.0
	var haut := 14.0
	for i in 24:
		var m := (bas + haut) * 0.5
		if ecran(Vector3(x, m, Z_ASTRE)).y > cible:
			bas = m
		else:
			haut = m
	return Vector3(x, (bas + haut) * 0.5, Z_ASTRE)


# Où tombe une pièce de la pluie : sur le plateau, devant le bloc (il la poussera), pas tout près du bord.
func _cible_pluie() -> Vector3:
	var r := float(p.R_PIECE)
	var x := randf_range(float(p.X0) + r + 0.3, float(p.X1) - r - 0.3)
	var z := randf_range(float(p.MILIEU) + float(p.COURSE) + 0.7, float(p.BORD) - 2.2)
	return Vector3(x, float(p._hauteur_libre(x, z, r, float(p.EP_PIECE) * 0.5)) + 0.22, z)


func _lancer_piece() -> void:
	_envoler(p._piece(_depart), _cible_pluie(), VOL_PIECE * randf_range(0.9, 1.15), randf_range(0.5, 1.2), "piece")
	# elle naît d'un éclat, au cœur de l'astrolabe
	var ce := _centre_embleme()
	for j in 3:
		var vie := randf_range(0.3, 0.55)
		_gerbe.append({"pos": ce, "vel": Vector2.from_angle(randf() * TAU) * randf_range(120.0, 280.0), "vie": vie,
			"vie0": vie, "taille": randf_range(14.0, 26.0)})


# Une place pour une bille offerte, sur le plateau devant le bloc : x, la hauteur où elle tient, z.
func _cible_bille(r: float, x0 := 1.2, z0 := 9.9, z1 := 11.8) -> Vector3:
	var x := randf_range(float(p.X0) + r + x0, float(p.X1) - r - x0)
	var z := randf_range(z0, z1)
	var ep := 2.0 * r * Volumes.APLATI
	return Vector3(x, float(p._hauteur_libre(x, z, r, ep * 0.5 + 0.01)) + 0.25, z)


func _donner_coeur(anime: bool) -> void:
	_coeur_du = false
	var a := _cible_bille(float(p.lot_def("coeur-etoile")["r"]), 2.0, 10.4, 11.2)
	if not anime:
		p._lot("coeur-etoile", Vector3.INF, Vector2(a.x, a.z))
		return
	_envoler(p._lot("coeur-etoile", _depart), a, VOL_COEUR, 1.6, "coeur")
	Son.inv("etoile", 0.0, 0.0)


func _lancer_poussiere() -> void:
	var b: RigidBody3D = p._lot("poussiere", _depart)
	b.set_meta("bonus", true)
	_envoler(b, _cible_bille(float(p.lot_def("poussiere")["r"])), VOL_POUSSIERE, 1.3, "poussiere")


# Un corps qui vole : figé (rien ne le touche, il ne touche rien ; PusherScreen ne le compte pas pour faire de la
# place), mené à la main de l'astrolabe jusqu'à sa place ; arrivé, il redevient un corps comme les autres.
func _envoler(b: RigidBody3D, a: Vector3, duree: float, bosse: float, sorte: String) -> void:
	b.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	b.freeze = true
	b.collision_layer = 0
	b.collision_mask = 0
	b.set_meta("vol", true)
	var de := _depart + Vector3(randf_range(-0.25, 0.25), randf_range(-0.15, 0.15), 0.0)
	b.global_transform = Transform3D(Basis(), de)
	_vols.append({"b": b, "de": de, "a": a, "t": 0.0, "duree": duree, "bosse": bosse, "sorte": sorte,
		"axe": Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU),
		"tours": randf_range(2.0, 3.5) * TAU * (1.0 if randf() < 0.5 else -1.0), "lacet": randf() * TAU})


func _voler(delta: float) -> void:
	for v in _vols:
		var b: RigidBody3D = v["b"]
		if v.has("pose") or not is_instance_valid(b):
			v["pose"] = true
			continue
		v["t"] = float(v["t"]) + delta
		var u := clampf(float(v["t"]) / float(v["duree"]), 0.0, 1.0)
		var e := 1.0 - (1.0 - u) * (1.0 - u)          # elle file, puis ralentit en arrivant
		var de: Vector3 = v["de"]
		var a: Vector3 = v["a"]
		var pos := Vector3(lerpf(de.x, a.x, e), lerpf(de.y, a.y, u) + float(v["bosse"]) * 4.0 * u * (1.0 - u),
			lerpf(de.z, a.z, e))
		var bs := Basis()
		if str(v["sorte"]) != "piece":
			# une bille laisse un sillage d'étoiles (d'or : le cœur ; bleu pâle : la poussière)
			var sp := ecran(pos)
			var coeur := str(v["sorte"]) == "coeur"
			for j in (2 if coeur else 1):
				var vie := randf_range(0.35, 0.7)
				_gerbe.append({"pos": sp + Vector2(randf_range(-22.0, 22.0), randf_range(-22.0, 22.0)),
					"vel": Vector2(randf_range(-40.0, 40.0), randf_range(-70.0, 0.0)), "vie": vie, "vie0": vie,
					"taille": randf_range(12.0, 26.0), "col": Color(1, 0.93, 0.74) if coeur else Color(0.78, 0.88, 1.0)})
		else:
			# elle tournoie, et arrive à plat
			bs = Basis(Vector3.UP, float(v["lacet"])) * Basis(v["axe"] as Vector3, float(v["tours"]) * (1.0 - e))
		b.global_transform = Transform3D(bs, pos)
		if u >= 1.0:
			_poser_vol(v, true)
	_vols = _vols.filter(func(v): return not v.has("pose"))


func _poser_vol(v: Dictionary, sonore: bool) -> void:
	v["pose"] = true
	var b: RigidBody3D = v["b"]
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	var ici := b.global_position
	# la place a pu se prendre pendant le vol : jamais dans un autre corps (lui vole encore : il ne se compte pas)
	var libre := float(p._hauteur_libre(ici.x, ici.z, float(b.get_meta("r")), float(b.get_meta("ep")) * 0.5 + 0.01)) + 0.04
	ici.y = maxf(ici.y, libre)
	var sorte := str(v["sorte"])
	b.global_transform = Transform3D(Basis() if sorte != "piece" else Basis(Vector3.UP, float(v["lacet"])), ici)
	b.remove_meta("vol")
	b.collision_layer = 1
	b.collision_mask = 1
	b.freeze = false
	b.linear_velocity = Vector3(0.0, -2.0, 0.0)
	b.angular_velocity = Vector3.ZERO
	if not sonore:
		return
	if sorte != "piece":
		var coeur := sorte == "coeur"
		Son.sonner("recevoir", 0.0 if coeur else -5.0, 0.0 if coeur else 4.0)
		var c := ecran(ici)
		var n := 12 if coeur else 7
		for i in n:
			var vie := randf_range(0.5, 0.8)
			_gerbe.append({"pos": c, "vel": Vector2.from_angle(TAU * float(i) / float(n)) * randf_range(150.0, 260.0),
				"vie": vie, "vie0": vie, "taille": randf_range(18.0, 32.0) * (1.0 if coeur else 0.8),
				"col": Color(1, 0.93, 0.74) if coeur else Color(0.78, 0.88, 1.0)})
	else:
		_posees += 1
		p._sonner_a_la_pose(b)
		if _posees % 6 == 1:
			Son.objet_tombe()


# L'aspiration : chaque lune verse sa lumière dans l'astrolabe (des bords vers le centre), les flammes et les étoiles du
# ciel aussi ; tout arrive au cœur de l'emblème à l'instant de l'explosion.
func _preparer_aspiration() -> void:
	var alv: Array = d["alveoles"]
	var n := alv.size()
	for i in n:
		var c := _ecran_image(float(alv[i][0]), float(alv[i][1]))
		var t0 := 0.04 + 0.09 * float(mini(i, n - 1 - i))
		_t_lune.append(t0)
		for j in 4:
			_aspires.append({"de": c + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)), "t0": t0 + 0.05 * j,
				"t1": SN_ECLAT - randf_range(0.0, 0.03), "taille": randf_range(30.0, 46.0), "courbe": randf_range(-0.45, 0.45)})
	for fl in d["flammes"]:
		var cf := _ecran_image(float(fl[0]), float(fl[1]) - float(fl[3]) * 0.6)
		for j in 4:
			_aspires.append({"de": cf, "t0": 0.02 + 0.07 * j, "t1": SN_ECLAT - randf_range(0.0, 0.03),
				"taille": randf_range(26.0, 40.0), "courbe": randf_range(-0.35, 0.35)})
	var pts: Array = d["etoiles"]
	for i in mini(pts.size(), 16):
		var s: Array = pts[i]
		_aspires.append({"de": _ecran_image(float(s[0]), float(s[1])), "t0": randf_range(0.0, 0.22),
			"t1": SN_ECLAT - randf_range(0.0, 0.03), "taille": randf_range(22.0, 34.0), "courbe": randf_range(-0.6, 0.6)})


# L'explosion : l'astrolabe éclate (les rais, l'étoile, les ondes : _dessiner_eclats ; l'onde dans l'or : reflet_or), une
# gerbe d'étoiles, toutes les lunes s'avivent, la machine tremble.
func _eclater() -> void:
	_secousse = 1.0
	Reglages.vibrer(140)
	var ce := _centre_embleme()
	for i in 72:
		var a := TAU * float(i) / 72.0 + randf_range(-0.05, 0.05)
		var vie := randf_range(0.9, 1.9)
		_gerbe.append({"pos": ce + Vector2.from_angle(a) * 24.0, "vel": Vector2.from_angle(a) * randf_range(260.0, 900.0),
			"vie": vie, "vie0": vie, "taille": randf_range(22.0, 56.0)})
	for i in _flash_lune.size():
		_flash_lune[i] = 0.0
		_allumee_t[i] = 0.0


# Chaque image de la Supernova : le temps, l'explosion, la pluie, les vols, le mot, la lumière de l'or et des flammes,
# la secousse ; la fin.
func _supernova_image(delta: float, en_sn: bool, n: int) -> void:
	if en_sn and _sn_t < 0.0:
		supernova(0, 0, true)           # (partie sans PusherScreen.declencher_supernova : le spectacle seul)
	if _sn_t >= 0.0:
		var avant := _sn_t
		_sn_t += delta
		for i in mini(n, _t_lune.size()):
			if avant < float(_t_lune[i]) and _sn_t >= float(_t_lune[i]):
				_flash_lune[i] = 0.0
				_allumee_t[i] = 0.0
		if avant < SN_ECLAT and _sn_t >= SN_ECLAT:
			_eclater()
		while _pluie_reste > 0 and _sn_t >= _pluie_t:
			_pluie_reste -= 1
			_pluie_t += SN_PAS_PLUIE
			_lancer_piece()
		while _poussieres_reste > 0 and _sn_t >= _poussiere_t:
			_poussieres_reste -= 1
			_poussiere_t += SN_PAS_POUSSIERE
			_lancer_poussiere()
		if _coeur_du and _sn_t >= SN_COEUR:
			_donner_coeur(true)
	_voler(delta)
	# la fin : les lunes s'éteignent du centre vers les bords, chacune lâche quelques étoiles
	if _sn_fin >= 0.0:
		var av := _sn_fin
		_sn_fin += delta
		for i in n:
			var te := _t_eteinte(i, n)
			if av < te and _sn_fin >= te:
				_eclats_lune(i)
		if _sn_fin > SN_FIN:
			_sn_fin = -1.0
	# le mot : il jaillit, deux reflets le traversent, puis il rentre dans l'astrolabe (le cœur va en sortir)
	var tm := _sn_t - SN_ECLAT if _sn_t >= 0.0 else -1.0
	mot.visible = tm >= 0.0 and tm < SN_MOT + 0.35
	if _rechauffe > 0:
		_rechauffe -= 1
		mot.visible = true
		mot.modulate.a = 0.004
	elif mot.visible:
		var ech := 1.0
		var al := 1.0
		if tm < 0.24:
			ech = lerpf(1.55, 1.0, _retour(tm / 0.24))
			al = clampf(tm / 0.07, 0.0, 1.0)
		elif tm > SN_MOT:
			var kk := (tm - SN_MOT) / 0.35
			ech = lerpf(1.0, 0.14, kk * kk)
			al = 1.0 - kk * kk * kk
		mot.scale = Vector2(ech, ech)
		mot.modulate.a = al
		mat_mot.set_shader_parameter("eclat", clampf(1.0 - tm / 0.3, 0.0, 1.0))
		var bal := -1.0
		if tm > 0.12 and tm < 0.8:
			bal = lerpf(-0.3, 1.3, (tm - 0.12) / 0.68)
		elif tm > 1.0 and tm < 1.68:
			bal = lerpf(-0.3, 1.3, (tm - 1.0) / 0.68)
		mat_mot.set_shader_parameter("balai", bal)
	# la lumière : l'emblème se charge, puis flambe ; l'onde et l'éclair de l'explosion ; les flammes s'emballent
	var tb := _sn_t - SN_ECLAT if _sn_t >= SN_ECLAT else -1.0
	var em := 0.0
	if _sn_t >= 0.0:
		em = 1.4 * pow(clampf(_sn_t / SN_ECLAT, 0.0, 1.0), 2.0) if _sn_t < SN_ECLAT else 0.95 + 0.35 * sin(_t * 8.0)
	elif _sn_fin >= 0.0:
		em = 0.95 * (1.0 - clampf(_sn_fin / 0.4, 0.0, 1.0))
	mat_reflet.set_shader_parameter("eclat_embleme", em)
	var salle := 1.0
	if _sn_t >= 0.0 and _sn_t < SN_ECLAT:
		salle = 1.0 - 0.32 * smoothstep(0.0, SN_ECLAT * 0.85, _sn_t)
	mat_fond.set_shader_parameter("lumiere", salle)
	if tb >= 0.0 and tb < 0.95:
		var q := 1.0 - pow(1.0 - tb / 0.95, 3.0)
		mat_reflet.set_shader_parameter("onde_r", (50.0 + 1050.0 * q) / 1080.0)
		mat_reflet.set_shader_parameter("onde_force", 1.0 - q * q)
	else:
		mat_reflet.set_shader_parameter("onde_r", -1.0)
	mat_reflet.set_shader_parameter("flash_or", 0.9 * exp(-tb / 0.2) if tb >= 0.0 else 0.0)
	var force_fl := 0.55
	if en_sn:
		force_fl = 0.9 + (0.9 * exp(-tb / 0.3) if tb >= 0.0 else 0.0)
	for mfl in flammes:
		(mfl as ShaderMaterial).set_shader_parameter("force", force_fl)
	# la secousse : le décor, la vue, les couches (pas le panneau Réserve)
	if _secousse > 0.0:
		_secousse *= exp(-delta / 0.13)
		var off := Vector2.ZERO
		if _secousse > 0.01:
			off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 13.0 * _secousse
		else:
			_secousse = 0.0
		for c in couches_machine:
			(c[0] as Control).position = (c[1] as Vector2) + off


func _prechauffer_sons() -> void:
	if Son.global == null:
		return
	var a := str(Son.ambiance_invocation)
	for nom in ["inv-%s-tension" % a, "inv-%s-aspiration" % a, "inv-%s-revelation" % a, "inv-%s-etoile" % a, "rarete-5",
			"recevoir", "paquet-2"]:
		Son.global._charger(nom)


# Une courbe qui dépasse un peu puis revient (le mot qui jaillit, le cadran qui s'ouvre).
func _retour(x: float) -> float:
	var y := x - 1.0
	return 1.0 + 2.70158 * y * y * y + 1.70158 * y * y


# La fin : l'instant où la lune i s'éteint (le centre d'abord).
func _t_eteinte(i: int, n: int) -> float:
	return 0.05 + 0.09 * absf(float(i) - float(n - 1) * 0.5)


func _lune_allumee(i: int, n: int) -> bool:
	if _sn_t >= 0.0:
		return true
	if _sn_fin >= 0.0:
		return _sn_fin < _t_eteinte(i, n)
	return i < _allumees


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
	for i in n:
		_flash_lune[i] = float(_flash_lune[i]) + delta
	_supernova_image(delta, en_sn, n)
	for g in _gerbe:
		g["pos"] += g["vel"] * delta
		g["vel"] = g["vel"] * 0.982 + Vector2(0, 160.0) * delta
		g["vie"] -= delta
	_gerbe = _gerbe.filter(func(g): return g["vie"] > 0.0)
	# le reflet : un passage lent toutes les 7 s ; à la Supernova, toutes les 1,8 s
	var periode := 1.8 if en_sn else 7.0
	mat_reflet.set_shader_parameter("phase", -0.6 + 2.4 * clampf(fmod(_t, periode) / 1.6, 0.0, 1.0))
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


# Les lunes (des cabochons : design/machines/lunes.py), au centre mesuré de chaque trou, à sa taille ; le lance-pièces,
# la pièce qui l'attend, les pièces qui tombent.
func _dessiner_lunes() -> void:
	var v := couche_lunes
	var alv: Array = d["alveoles"]
	var en_sn := p.supernova_t > 0.0
	for i in alv.size():
		var c := _ecran_image(float(alv[i][0]), float(alv[i][1]))
		var r := float(alv[i][2]) * E * 1.04
		var allumee := _lune_allumee(i, alv.size())
		var pop := 1.0 + 0.22 * exp(-float(_allumee_t[i]) / 0.10) * (1.0 if allumee else 0.0)
		if en_sn:
			pop *= 1.0 + 0.04 * sin(_t * 9.0 + i)
		var rr := r * pop
		v.draw_texture_rect(tex_lune_allumee if allumee else tex_lunes[i], Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false)
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


# Les éclats (additifs) : les étoiles du ciel peint qui scintillent ; les lunes qui s'avivent ; à la Supernova, la lumière
# aspirée, l'explosion (les rais, l'étoile, les ondes), les gerbes ; le
# cœur d'étoile qui scintille sur le plateau.
func _dessiner_eclats() -> void:
	var v := couche_eclats
	var en_sn := p.supernova_t > 0.0
	var tb := _sn_t - SN_ECLAT if _sn_t >= SN_ECLAT else -1.0
	var flash_ciel := exp(-tb / 0.35) if tb >= 0.0 else 0.0
	if _rechauffe > 0:
		v.draw_arc(_centre_embleme(), 60.0, 0.0, TAU, 32, Color(1, 1, 1, 0.004), 2.0, true)
	for s in _scintille:
		if bool(s["sn"]) and not en_sn:
			continue
		var b := pow(maxf(0.0, sin(_t * float(s["w"]) + float(s["ph"]))), 4.0)
		var a := (0.10 + 0.80 * b) * (1.4 if en_sn else 1.0) + flash_ciel
		var t := float(s["taille"]) * (0.5 + 0.5 * maxf(b, flash_ciel))
		v.draw_texture_rect(tex_eclat, Rect2(s["pos"] - Vector2(t, t) * 0.5, Vector2(t, t)), false, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	# les lunes qui s'avivent : leur éclair (l'aspiration, l'explosion) ; le chenillard pendant la Supernova
	var alv: Array = d["alveoles"]
	for i in alv.size():
		var fl := exp(-float(_flash_lune[i]) / 0.22)
		var chenille := 0.0
		if en_sn and _sn_t > SN_ECLAT + 0.5:
			chenille = pow(maxf(0.0, cos(_sn_t * 4.2 - float(i) * 0.8)), 10.0) * 0.55
		var al := clampf(fl + chenille, 0.0, 1.0)
		if al > 0.01 and _lune_allumee(i, alv.size()):
			var c := _ecran_image(float(alv[i][0]), float(alv[i][1]))
			var rr := float(alv[i][2]) * E * 1.04 * (1.0 + 0.12 * fl)
			v.draw_texture_rect(tex_lune_allumee, Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false, Color(1, 1, 1, al))
	# la lumière aspirée par l'astrolabe : des comètes d'or qui accélèrent vers son cœur, leur traînée derrière elles
	if _sn_t >= 0.0 and _sn_t < SN_ECLAT + 0.05:
		var ce := _centre_embleme()
		for asp in _aspires:
			var t0 := float(asp["t0"])
			var t1 := float(asp["t1"])
			if _sn_t < t0 or _sn_t > t1:
				continue
			var u := (_sn_t - t0) / maxf(t1 - t0, 0.01)
			var de: Vector2 = asp["de"]
			var ctrl := (de + ce) * 0.5 + (ce - de).orthogonal() * float(asp["courbe"])
			for k5 in range(6, -1, -1):
				var uk := u - 0.045 * float(k5)
				if uk <= 0.0:
					continue
				var e := uk * uk
				var pos := de * (1.0 - e) * (1.0 - e) + ctrl * 2.0 * (1.0 - e) * e + ce * e * e
				var ta := float(asp["taille"]) * (1.0 - 0.35 * e) * (1.0 - 0.11 * float(k5))
				var ak := clampf(u * 5.0, 0.0, 1.0) * (1.0 - float(k5) / 7.0) * (1.0 if k5 == 0 else 0.7)
				v.draw_texture_rect(tex_nova, Rect2(pos - Vector2(ta, ta) * 0.5, Vector2(ta, ta)), false,
					Color(1.0, 0.88, 0.58, ak))
	# l'explosion : une couronne de rais, l'étoile du cœur, deux ondes nettes
	if tb >= 0.0 and tb < 1.2:
		var ce2 := _centre_embleme()
		var pousse := 1.0 - pow(1.0 - clampf(tb / 0.16, 0.0, 1.0), 3.0)
		var fondu := 1.0 - smoothstep(0.18, 1.1, tb)
		for i in 12:
			var ang := TAU * float(i) / 12.0 + 0.26 + tb * 0.35
			var lg := (600.0 if i % 2 == 0 else 360.0) * pousse * (1.0 + 0.15 * tb)
			var w := 22.0 if i % 2 == 0 else 14.0
			v.draw_set_transform(ce2, ang, Vector2.ONE)
			v.draw_texture_rect(tex_rai, Rect2(-w * 0.5, -lg - 34.0, w, lg), false,
				Color(1.0, 0.86, 0.56, fondu) if i % 2 == 0 else Color(1.0, 0.95, 0.82, fondu * 0.8))
		var tn := (0.25 + 0.75 * pousse) * (1.0 - 0.55 * smoothstep(0.1, 0.9, tb)) * 470.0
		v.draw_set_transform(ce2, tb * 0.6, Vector2.ONE)
		v.draw_texture_rect(tex_nova, Rect2(-Vector2(tn, tn) * 0.5, Vector2(tn, tn)), false,
			Color(1, 1, 1, 1.0 - smoothstep(0.3, 1.0, tb)))
		v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for k2 in 2:
			var tk := tb - 0.1 * float(k2)
			if tk > 0.0 and tk < 0.95:
				var q := 1.0 - pow(1.0 - tk / 0.95, 3.0)
				var a2 := (1.0 - q) * (0.85 if k2 == 0 else 0.55)
				v.draw_arc(ce2, 50.0 + 1050.0 * q, 0.0, TAU, 160, Color(1.0, 0.92, 0.70, a2),
					lerpf(7.0, 1.5, q) * (1.0 if k2 == 0 else 0.6), true)
	for g in _gerbe:
		var a3 := clampf(float(g["vie"]) / float(g["vie0"]), 0.0, 1.0)
		var t2 := float(g["taille"]) * (0.6 + 0.4 * a3)
		var cg: Color = g.get("col", Color(1, 0.93, 0.74))
		v.draw_texture_rect(tex_nova, Rect2(g["pos"] - Vector2(t2, t2) * 0.5, Vector2(t2, t2)), false, Color(cg, a3))
	# le cœur d'étoile, posé sur le plateau : deux éclats tournent sur son verre (on le reconnaît de loin)
	for l in p.lots:
		if str(l.get_meta("lot")) != "coeur-etoile" or l.has_meta("vol"):
			continue
		var r4 := float(l.get_meta("r"))
		var cp := ecran(l.position + Vector3(0.0, r4 * 0.48, 0.0))
		var rp := absf(ecran(l.position + Vector3(r4, r4 * 0.48, 0.0)).x - cp.x) * 0.9
		for k4 in 2:
			var b4 := pow(maxf(0.0, sin(_t * 2.6 + float(k4) * 2.4)), 3.0)
			if b4 < 0.02:
				continue
			var pos4 := cp + Vector2.from_angle(_t * 0.9 + float(k4) * PI + 0.8) * rp * 0.75 + Vector2(0.0, -rp * 0.2)
			var t4 := 30.0 * (0.4 + 0.6 * b4)
			v.draw_texture_rect(tex_nova, Rect2(pos4 - Vector2(t4, t4) * 0.5, Vector2(t4, t4)), false, Color(1.0, 0.92, 0.72, b4))


func _eclats_lune(i: int) -> void:
	var al: Array = d["alveoles"][i]
	var c := _ecran_image(float(al[0]), float(al[1]))
	for j in 7:
		var a := TAU * float(j) / 7.0 + randf_range(-0.2, 0.2)
		var vie := randf_range(0.45, 0.8)
		_gerbe.append({"pos": c, "vel": Vector2.from_angle(a) * randf_range(90.0, 190.0), "vie": vie, "vie0": vie,
			"taille": randf_range(16.0, 30.0)})
