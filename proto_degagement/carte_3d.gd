class_name Carte3D
extends Control

# ─────────────────────────────────────────────────────────────
# LA CARTE EN 3D (27/09) — la carte en grand de l'Atlas se tourne au doigt, comme une carte
# qu'on tient : glisser l'incline et la fait jouer dans la lumière ; glisser plus loin, ou d'un
# geste vif, la retourne, et son dos (dos_info.gd) raconte sa légende et son pouvoir. Maxim :
# « pas toucher la carte : on peut la faire bouger avec son doigt, donc une carte en 3D ».
#
# La carte (CarteView) et son dos sont dessinés à plat, chacun dans son SubViewport ; le shader
# carte_3d les pose sur un plan qui tourne, en perspective. Le rectangle de ce nœud est celui de
# la carte à plat ; le dessin déborde autour (la perspective agrandit le côté qui s'approche).
# ─────────────────────────────────────────────────────────────

signal touchee

const SH := preload("res://cartes/shaders/carte_3d.gdshader")
const BASCULE_MAX := 0.36     # la bascule haut / bas, au plus (radians, ~20°)
const FOCALE := 2.4           # l'œil, à 2,4 largeurs de carte : assez de perspective, sans déformer
const DEBORD := 0.3           # le dessin déborde de la carte de 30 % de chaque côté
const ELAN := 5.0             # rad/s : au-delà, un geste vif retourne la carte

var h: Dictionary = {}
var stade := 1
var variante := "base"
var largeur := 820.0
var carte: CarteView
var dos: DosInfo
var ry := 0.0                 # le tour, autour de la verticale (0 : recto, PI : verso)
var rx := 0.0                 # la bascule, autour de l'horizontale

var _vp_recto: SubViewport
var _vp_verso: SubViewport
var _mat: ShaderMaterial
var _cible := 0.0
var _vit := 0.0
var _tient := false
var _appui := Vector2.ZERO
var _ry0 := 0.0
var _glisse := 0.0
var _dernier := Vector2.ZERO
var _t_dernier := 0
var _t := 0.0
var _lumiere_libre := true
# La vitrine (l'Astrolabe, 28/09) : au repos, la carte se balance plus large, et sa matière joue dans la lumière.
var vitrine := false


func configurer(p_h: Dictionary, p_stade: int, p_variante: String, p_largeur: float) -> void:
	h = p_h
	stade = p_stade
	variante = p_variante
	largeur = p_largeur
	size = Vector2(largeur, largeur * 1.4)
	custom_minimum_size = size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	for c in get_children():
		remove_child(c)
		c.queue_free()
	# chaque face à plat, avec la marge où tombent son ombre et sa lueur (CarteView : 8 u)
	var marge := ceilf(9.0 * largeur / 100.0)
	var face := Vector2i(ceili(largeur + 2.0 * marge), ceili(largeur * 1.4 + 2.0 * marge))
	_vp_recto = _viewport(face)
	carte = CarteView.new()
	_vp_recto.add_child(carte)
	carte.configurer(h, stade, variante, largeur, true)
	carte.position = Vector2(marge, marge)
	_vp_verso = _viewport(face)
	_vp_verso.render_target_update_mode = SubViewport.UPDATE_ONCE
	dos = DosInfo.new()
	_vp_verso.add_child(dos)
	dos.configurer(h, stade, variante, largeur)
	dos.position = Vector2(marge, marge)
	var ecran := ColorRect.new()
	var zone := Vector2(face) * (1.0 + 2.0 * DEBORD)
	ecran.size = zone
	ecran.position = size * 0.5 - zone * 0.5
	ecran.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SH
	_mat.set_shader_parameter("recto", _vp_recto.get_texture())
	_mat.set_shader_parameter("verso", _vp_verso.get_texture())
	_mat.set_shader_parameter("zone", zone)
	_mat.set_shader_parameter("plan", Vector2(face))
	_mat.set_shader_parameter("focale", FOCALE * largeur)
	ecran.material = _mat
	add_child(ecran)
	ry = 0.0
	rx = 0.0
	_cible = 0.0
	_vit = 0.0
	_tient = false
	_lumiere_libre = true
	_appliquer()


func _viewport(taille: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.size = taille
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	return vp


# Poser la carte à un angle, sans animation (0 : recto, PI : verso). « tenir » la garde à cet
# angle comme sous un doigt (les captures) ; sinon elle retombe sur la face la plus proche.
func poser(r_y: float, r_x := 0.0, tenir := false) -> void:
	ry = r_y
	rx = r_x
	_cible = round(r_y / PI) * PI
	_vit = 0.0
	_tient = tenir
	_appliquer()


func _gui_input(ev: InputEvent) -> void:
	var b := ev as InputEventMouseButton
	var m := ev as InputEventMouseMotion
	if b != null and b.button_index == MOUSE_BUTTON_LEFT:
		if b.pressed:
			_tient = true
			_appui = b.position
			_ry0 = ry
			_glisse = 0.0
			_vit = 0.0
			_dernier = b.position
			_t_dernier = Time.get_ticks_msec()
		elif _tient:
			_tient = false
			if _glisse < 24.0:
				touchee.emit()
			_lacher()
		accept_event()
	elif m != null and _tient:
		var d := m.position - _appui
		_glisse = maxf(_glisse, d.length())
		# la surface suit le doigt : glisser vers la droite fait fuir le bord droit ; toute la
		# largeur de la carte, c'est un demi-tour
		ry = _ry0 - d.x / largeur * PI
		rx = clampf(d.y / (largeur * 1.4) * 1.2, -BASCULE_MAX, BASCULE_MAX)
		var maintenant := Time.get_ticks_msec()
		var dt := maxf(0.001, float(maintenant - _t_dernier) / 1000.0)
		_vit = lerpf(_vit, -(m.position.x - _dernier.x) / largeur * PI / dt, 0.5)
		_dernier = m.position
		_t_dernier = maintenant
		accept_event()


# Le doigt se lève : la carte retombe sur la face la plus proche — ou, lancée d'un geste vif,
# sur la face suivante dans le sens du geste.
func _lacher() -> void:
	if absf(_vit) > ELAN:
		_cible = (floorf(ry / PI) + (1.0 if _vit > 0.0 else 0.0)) * PI
	else:
		_cible = round(ry / PI) * PI


func _process(delta: float) -> void:
	if _mat == null:
		return
	_t += delta
	if not _tient:
		# un ressort amorti vers la face visée ; la bascule revient à plat
		var k := 70.0
		var a := (_cible - ry) * k - _vit * 2.0 * sqrt(k)
		_vit += a * delta
		ry += _vit * delta
		rx = lerpf(rx, 0.0, 1.0 - exp(-delta * 9.0))
	_appliquer()


func _appliquer() -> void:
	# au repos, la carte respire à peine : elle a l'air tenue
	var calme := not _tient and absf(_vit) < 0.05 and absf(_cible - ry) < 0.01
	var bal_y := 0.03 * sin(_t * 1.1) if calme else 0.0
	var bal_x := 0.02 * sin(_t * 0.8) if calme else 0.0
	if calme and vitrine:
		bal_y = 0.3 * sin(_t * 0.55)
		bal_x = 0.07 * sin(_t * 0.4)
	var y := ry + bal_y
	var x := rx + bal_x
	_mat.set_shader_parameter("ry", y)
	_mat.set_shader_parameter("rx", x)
	# la lumière suit l'inclinaison : le holo, le reflet, le chrome jouent quand la carte tourne ;
	# au repos, la carte reprend sa propre lumière (en vitrine, elle la suit toujours)
	if calme and not vitrine:
		if not _lumiere_libre:
			carte.relacher_lumiere()
			_lumiere_libre = true
	else:
		_lumiere_libre = false
		var s := sin(y)
		carte.eclairer(Vector2(0.5 + 0.55 * s, 0.5 + 1.1 * x), 0.3 + 0.9 * absf(s) + absf(x))
	# ne dessiner que la face qu'on voit (la carte de dos ne coûte pas son recto, et l'inverse)
	var vers_nous := cos(y) * cos(x)
	_mode(_vp_recto, vers_nous > -0.08)
	_mode(_vp_verso, vers_nous < 0.08)


func _mode(vp: SubViewport, actif: bool) -> void:
	var m := SubViewport.UPDATE_ALWAYS if actif else SubViewport.UPDATE_DISABLED
	if vp.render_target_update_mode != m and not (not actif and vp.render_target_update_mode == SubViewport.UPDATE_ONCE):
		vp.render_target_update_mode = m
