extends Control

# ⑦ — L'ESSAI 3D DE LA POUSSETTE : la même machine, la physique en 3D (Jolt)
# pour que les pièces et les objets se SUPERPOSENT, sur le bloc comme sur le
# plateau. Le dessin reste en 2D, en perspective oblique : la hauteur se lit
# (une pièce plus haute se dessine plus haut), on voit la tranche des pièces et
# la face du bloc, et chaque pièce jette son ombre sur celles du dessous.
#
# 🔴 BUT : MESURER. Combien de pièces tient-on à 60 images/s sur le téléphone ?
#    On ne continue (FEATURES ⑦) que si ≥ 55 images/s à 150 pièces.
#    Ce n'est pas le jeu : ni sauvegarde, ni gains, ni réserve.
#
# Exporté à part (préréglage « Web essai 3D », drapeau « essai3d ») :
#   https://192.168.0.17:18443/essai/
# Les tests (sans écran) — empilement, glissement, objets enfouis, une minute de
# jeu, et le temps par image à 100, 150, 200 pièces :
#   Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path ./proto_degagement res://essais/essai_3d.tscn -- tests
#
# Unités : 1 unité = 100 px. x → x à l'écran, z → la profondeur (y à l'écran),
# y → la hauteur au-dessus du plateau.

const U := 100.0
const X0 := 0.46
const X1 := 10.34
const MUR := 6.0              # la face du fronton : les pièces du bloc y butent
const MILIEU := 8.4           # la face du bloc va de 7,6 à 9,2…
const COURSE := 0.8
const PERIODE := 2.71         # … en un aller-retour, comme la machine 2D
const BORD := 14.0            # le bord du plateau : au-delà, ça tombe
const H_BLOC := 0.5           # le dessus du bloc, au-dessus du plateau (plus haut qu'une pièce debout)
const R_PIECE := 0.4
const EP_PIECE := 0.12
# 🔴 À cette échelle (une pièce de 80 px = 0,8 unité), la gravité réelle rend
#    tout flottant et glissant : une vraie pièce tombe 30 fois sa taille plus vite.
const GRAVITE := 5.0
# 🔴 Le métal glisse sur le métal : trop de frottement entre les pièces, et le tas
#    poussé se redresse (des pièces debout, sur la tranche) au lieu d'avancer.
const FROTTEMENT := 0.35      # entre les pièces
const FROTTEMENT_PLATEAU := 0.15   # le plateau est poli : le tas glisse au lieu de grimper sur lui-même
const FROTTEMENT_BLOC := 0.8  # le dessus du bloc accroche : il porte ses pièces
const K_H := 0.9              # 1 px de hauteur = 0,9 px vers le haut de l'écran
const MAX_PIECES := 260
const CADRE := Rect2(20, 238, 1040, 1214)
const LOTS := {"xp": [0.44, 12.7], "ticket": [0.54, 11.2], "eclat": [0.66, 9.75]}
# 🔴 Les objets restent AU-DESSUS du tas, pour qu'on les voie (Maxim, 23/09) : plus épais
#    qu'une pile de pièces, posés sur le tas, et ils secouent les pièces posées sur eux
#    (_physics_process). ⛔ Pas glissants : un objet glissant dévale le tas tout seul.
const EP_LOT := 0.28

var monde: Node3D
var bloc: AnimatableBody3D
var bloc_fige := false
var face_z := MILIEU - COURSE
var pieces: Array[RigidBody3D] = []
var lots: Array[RigidBody3D] = []
var tombees := 0

var tex_pieces: Array[Texture2D] = []
var tex_lot := {}
var tex_lueur: Texture2D
var tex_face: Texture2D
var sb_cadre: StyleBoxFlat
var lbl: Label
var lbl_mesure: Label
var _mesure_en_cours := false
var dessin: Control

var _t_bloc := 0.0
var _image_physique := 0
var _ms := 0.0
var _n := 0
var _acc := 0.0
var _doigt := false
var _dernier := Vector2(-9999, -9999)


func _ready() -> void:
	GS.sauvegarde_active = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Ciel.new())
	tex_pieces = [Style.objet("piece-etoile"), Style.objet("piece-lune")]
	for k in LOTS.keys():
		tex_lot[k] = Style.objet(k)
	tex_lueur = Style.texture("res://ciel/lueur.png")
	tex_face = Style.degrade(PackedColorArray([Color("#fff2c6"), Color("#e6c275"), Color("#b58d40"), Color("#6c5021")]),
		PackedFloat32Array([0.0, 0.3, 0.62, 1.0]))
	sb_cadre = Style.boite(Color("#121715"), 44, Style.OR_FILET, 3)
	dessin = Control.new()
	dessin.size = Vector2(1080, 2400)
	dessin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dessin.draw.connect(_dessiner)
	add_child(dessin)
	monde = Node3D.new()
	add_child(monde)
	_decor()
	_interface()
	_garnir(150)
	var args := OS.get_cmdline_user_args()
	if args.has("tests"):
		_lancer_tests()
	elif not _a_capture(args):
		_mesure_auto()
	for a in args:
		if a.begins_with("capture="):
			_photographier(a.trim_prefix("capture="))


# ─────────────────────────────────────────────────────────────
# La machine en 3D
# ─────────────────────────────────────────────────────────────

func _boite(corps: CollisionObject3D, pos: Vector3, taille: Vector3, frottement := FROTTEMENT) -> void:
	var mat := PhysicsMaterial.new()
	mat.friction = frottement
	mat.bounce = 0.0
	if corps is StaticBody3D:
		(corps as StaticBody3D).physics_material_override = mat
	elif corps is AnimatableBody3D:
		(corps as AnimatableBody3D).physics_material_override = mat
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = taille
	cs.shape = sh
	corps.add_child(cs)
	corps.position = pos
	monde.add_child(corps)


func _decor() -> void:
	var cx := (X0 + X1) * 0.5
	var w := X1 - X0
	# le plateau : sa surface à y = 0, du pied du fronton jusqu'au bord
	_boite(StaticBody3D.new(), Vector3(cx, -0.1, (MUR + BORD) * 0.5), Vector3(w + 0.64, 0.2, BORD - MUR), FROTTEMENT_PLATEAU)
	# les côtés, qui dépassent le bord : ce qui tombe tombe droit
	for x in [X0 - 0.16, X1 + 0.16]:
		_boite(StaticBody3D.new(), Vector3(x, 1.5, (MUR + BORD) * 0.5 + 1.0), Vector3(0.32, 3.0, BORD - MUR + 4.0), 0.1)
	# le fronton : il commence juste au-dessus du bloc, qui glisse dessous
	_boite(StaticBody3D.new(), Vector3(cx, H_BLOC + 0.02 + 1.5, MUR - 0.5), Vector3(w + 0.64, 3.0, 1.0), 0.1)
	# le bloc : un pavé posé sur le plateau, sa face avant en face_z, qui s'enfonce sous le fronton
	bloc = AnimatableBody3D.new()
	bloc.sync_to_physics = true
	_boite(bloc, Vector3(cx, H_BLOC * 0.5, face_z - 2.0), Vector3(w, H_BLOC, 4.0), FROTTEMENT_BLOC)


func _corps(pos: Vector3, r: float, ep: float, masse: float) -> RigidBody3D:
	var b := RigidBody3D.new()
	b.mass = masse
	b.gravity_scale = GRAVITE
	var mat := PhysicsMaterial.new()
	mat.friction = FROTTEMENT
	mat.bounce = 0.0
	b.physics_material_override = mat
	b.linear_damp = 0.3
	b.angular_damp = 1.0
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = ep
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	b.rotation.y = randf() * TAU
	b.set_meta("r", r)
	b.set_meta("ep", ep)
	monde.add_child(b)
	return b


func _piece(pos: Vector3) -> RigidBody3D:
	var b := _corps(pos, R_PIECE, EP_PIECE, 1.0)
	b.set_meta("face", randi() % 2)
	pieces.append(b)
	return b


# La hauteur où poser un disque en (x, z) sans le faire naître dans un autre.
func _hauteur_libre(x: float, z: float, r: float, sol: float) -> float:
	var h := sol
	for arr in [pieces, lots]:
		for q in arr:
			if Vector2(q.position.x - x, q.position.z - z).length() < r + float(q.get_meta("r")):
				h = maxf(h, q.position.y + float(q.get_meta("ep")) + 0.01)
	return h


func _vider() -> void:
	for arr in [pieces, lots]:
		for b in arr:
			monde.remove_child(b)
			b.queue_free()
	pieces.clear()
	lots.clear()
	tombees = 0


func _garnir(n: int) -> void:
	_vider()
	var sur_bloc := int(n * 0.3)
	for i in n:
		var sb := i < sur_bloc
		var x := randf_range(X0 + R_PIECE, X1 - R_PIECE)
		var z := randf_range(MUR + R_PIECE + 0.05, face_z - R_PIECE) if sb else randf_range(MILIEU + COURSE + R_PIECE - 0.05, BORD - R_PIECE - 0.1)
		var sol := (H_BLOC if sb else 0.0) + EP_PIECE * 0.5 + 0.01
		_piece(Vector3(x, _hauteur_libre(x, z, R_PIECE, sol), z))
	# les objets ensuite, à leur profondeur, posés SUR le tas
	for k in LOTS.keys():
		_lot(k)


func _lot(k: String) -> void:
	var r: float = LOTS[k][0]
	var x := randf_range(X0 + 1.8, X1 - 1.8)
	var z := float(LOTS[k][1])
	var b := _corps(Vector3(x, _hauteur_libre(x, z, r, EP_LOT * 0.5 + 0.01), z), r, EP_LOT, 4.0)
	b.set_meta("lot", k)
	lots.append(b)


func _physics_process(delta: float) -> void:
	# le bloc va et vient comme une bielle : il ralentit en bout de course au lieu
	# de repartir d'un coup — sinon les pièces glissent sur lui à chaque retour
	if not bloc_fige:
		_t_bloc += delta
	face_z = MILIEU - COURSE * cos(TAU * _t_bloc / PERIODE)
	bloc.position.z = face_z - 2.0
	# un objet secoue les pièces posées sur lui : elles glissent et tombent à côté
	_image_physique += 1
	if _image_physique % 6 == 0:
		for l in lots:
			var rl: float = l.get_meta("r")
			var haut: float = l.position.y + float(l.get_meta("ep")) * 0.3
			for q in pieces:
				var d := Vector2(q.position.x - l.position.x, q.position.z - l.position.z)
				if d.length() < rl + 0.1 and q.position.y > haut:
					var dirr := d.normalized() if d.length() > 0.01 else Vector2.RIGHT.rotated(randf() * TAU)
					q.apply_central_impulse(Vector3(dirr.x, 0.0, dirr.y) * 0.45)
	# ce qui passe le bord tombe : on le compte, on l'enlève
	for arr in [pieces, lots]:
		for i in range(arr.size() - 1, -1, -1):
			var b: RigidBody3D = arr[i]
			if b.position.y < -0.5 or b.position.z > BORD + 1.5:
				arr.remove_at(i)
				monde.remove_child(b)
				b.queue_free()
				tombees += 1
				# l'essai garde toujours ses trois objets : un objet tombé revient sur le tas
				if b.has_meta("lot"):
					_lot.call_deferred(str(b.get_meta("lot")))
	_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_n += 1


func _process(delta: float) -> void:
	_acc += delta
	if _acc >= 1.0:
		var fps := Engine.get_frames_per_second()
		lbl.text = "%d images/s · %d pièces · %d tombées · physique ≤ %.1f ms" % [fps, pieces.size(), tombees, _ms / maxf(1.0, _n)]
		# vert : ça tient ; orange : limite ; rouge : ça ne tient pas
		lbl.add_theme_color_override("font_color", Style.JADE if fps >= 55 else (Style.ALERTE if fps >= 40 else Color("#e5554e")))
		_acc = 0.0
		_ms = 0.0
		_n = 0
	dessin.queue_redraw()


# ─────────────────────────────────────────────────────────────
# Le geste : on lâche la pièce AU-DESSUS du doigt, n'importe où dans la
# machine ; elle tombe sur ce qui est dessous
# ─────────────────────────────────────────────────────────────

func _input(ev: InputEvent) -> void:
	var p := Vector2(-1, -1)
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_doigt = ev.pressed
		_dernier = Vector2(-9999, -9999)
		if ev.pressed:
			p = ev.position
	elif ev is InputEventMouseMotion and _doigt:
		p = ev.position
	if p.x < X0 * U or p.x > X1 * U or p.y < CADRE.position.y or p.y > BORD * U:
		return
	if _mesure_en_cours:
		_mesure_en_cours = false
		lbl_mesure.text = "Mesure arrêtée : tu joues. Rouvre la page pour la relancer."
	if p.distance_to(_dernier) < 60.0 or pieces.size() >= MAX_PIECES:
		return
	_dernier = p
	# le dessus du bloc est dessiné plus haut que sa place : un doigt posé sur le
	# bloc dessiné vise la profondeur de dessous
	var z := p.y / U
	if z + H_BLOC * K_H < face_z:
		z += H_BLOC * K_H
	_lacher(clampf(p.x / U, X0 + R_PIECE, X1 - R_PIECE), clampf(z, MUR + R_PIECE + 0.02, BORD - R_PIECE))


func _lacher(x: float, z: float) -> RigidBody3D:
	var sol := (H_BLOC if z < face_z else 0.0) + EP_PIECE * 0.5
	# lâchée d'assez bas pour ne jamais traverser une pièce en un pas de physique
	return _piece(Vector3(x, _hauteur_libre(x, z, R_PIECE, sol) + 0.25, z))


func _semer(n: int) -> void:
	for i in n:
		_lacher(randf_range(X0 + R_PIECE, X1 - R_PIECE), randf_range(MUR + R_PIECE + 0.02, face_z - R_PIECE))


# ─────────────────────────────────────────────────────────────
# Le dessin, en perspective oblique : la hauteur remonte à l'écran
# ─────────────────────────────────────────────────────────────

func _ecran(x: float, z: float, h: float) -> Vector2:
	return Vector2(x * U, z * U - h * U * K_H)


func _dessiner() -> void:
	var v := dessin
	var ci := v.get_canvas_item()
	sb_cadre.draw(ci, CADRE)
	var gauche := X0 * U - 8.0
	var large := (X1 - X0) * U + 16.0
	# le plateau
	var haut_plateau := _ecran(0.0, MILIEU - COURSE - 0.6, 0.0).y
	v.draw_rect(Rect2(gauche, haut_plateau, large, BORD * U - haut_plateau), Color("#08110f"))
	# le dessus du bloc, puis sa face avant dorée : la marche qu'on voit
	var haut_bloc := _ecran(0.0, MUR - 0.4, H_BLOC).y
	var face_haut := _ecran(0.0, face_z, H_BLOC).y
	var face_bas := _ecran(0.0, face_z, 0.0).y
	v.draw_rect(Rect2(X0 * U, haut_bloc, (X1 - X0) * U, face_haut - haut_bloc), Color("#f1ebdf"))
	v.draw_texture_rect(tex_face, Rect2(X0 * U, face_haut, (X1 - X0) * U, face_bas - face_haut), false)
	for i in 8:
		var t := float(i) / 7.0
		v.draw_rect(Rect2(X0 * U, face_bas + t * 40.0, (X1 - X0) * U, 7.0), Color(0, 0, 0, 0.3 * (1.0 - t)))
	# le fronton, jusqu'au-dessus du bloc
	var bas_fronton := _ecran(0.0, MUR, H_BLOC + 0.02).y
	v.draw_rect(Rect2(gauche, CADRE.position.y + 18.0, large, bas_fronton - CADRE.position.y - 18.0), Color("#0a0f0d"))
	v.draw_rect(Rect2(gauche, bas_fronton - 3.0, large, 3.0), Style.OR)
	v.draw_string(Style.police("italique"), Vector2(200, 400), "La Poussette — essai 3D", HORIZONTAL_ALIGNMENT_CENTER, 680, 60,
		Color(Style.IVOIRE, 0.9))
	# le bord gagnant
	v.draw_rect(Rect2(gauche, BORD * U - 3.0, large, 5.0), Style.JADE)
	# les corps, étage par étage : d'abord les ombres de l'étage (elles tombent sur
	# les pièces du dessous), puis ses pièces
	var etages: Array = []
	etages.resize(32)
	for i in 32:
		etages[i] = []
	for b in pieces:
		(etages[clampi(int(b.position.y / (EP_PIECE * 0.9)), 0, 31)] as Array).append(b)
	for e in etages:
		for b in e:
			_ombre(v, b)
		for b in e:
			_dessiner_corps(v, b)
	# les objets en dernier : toujours visibles, au-dessus du tas
	for b in lots:
		_ombre(v, b)
	for b in lots:
		_dessiner_corps(v, b)


func _ombre(v: Control, b: RigidBody3D) -> void:
	var p := b.position
	var r: float = b.get_meta("r")
	var base := H_BLOC if (p.z < face_z and p.z > MUR - 0.5) else 0.0
	var dh := maxf(0.0, p.y - base) * U
	var s := Vector2(r, r) * U * (2.3 + dh / 200.0)
	var c := _ecran(p.x, p.z, base) + Vector2(5.0 + dh * 0.15, 9.0 + dh * 0.2)
	v.draw_texture_rect(tex_lueur, Rect2(c - s * 0.5, s), false, Color(0, 0, 0, clampf(0.55 - dh / 400.0, 0.15, 0.55)))


func _dessiner_corps(v: Control, b: RigidBody3D) -> void:
	var p := b.position
	var r: float = b.get_meta("r")
	var c := _ecran(p.x, p.z, p.y)
	var ech := 1.0 + maxf(0.0, p.y) * U / 700.0
	# penchée : le disque se voit en ellipse, écrasé dans le sens où il penche
	var bas := b.global_transform.basis
	var axe := bas.y.normalized()
	var penche := clampf(absf(axe.y), 0.3, 1.0)
	var dir := atan2(axe.z, axe.x)
	var tour := atan2(bas.x.z, bas.x.x)
	var cote := Style.cote_objet(r * U) * ech
	var rect := Rect2(Vector2(-cote, -cote) * 0.5, Vector2(cote, cote))
	var forme := Transform2D.IDENTITY.scaled(Vector2(penche, 1.0)) * Transform2D(tour - dir, Vector2.ZERO)
	var tex: Texture2D = tex_lot[b.get_meta("lot")] if b.has_meta("lot") else tex_pieces[int(b.get_meta("face", 0))]
	# la tranche : la même image, sombre, un peu plus bas — l'épaisseur vue de biais
	var tranche := float(b.get_meta("ep")) * U * K_H
	v.draw_set_transform_matrix(Transform2D(dir, c + Vector2(0.0, tranche * 0.5)) * forme)
	v.draw_texture_rect(tex, rect, false, Color(0.36, 0.3, 0.18) if not b.has_meta("lot") else Color(0.32, 0.32, 0.32))
	v.draw_set_transform_matrix(Transform2D(dir, c - Vector2(0.0, tranche * 0.5)) * forme)
	v.draw_texture_rect(tex, rect, false)
	v.draw_set_transform_matrix(Transform2D.IDENTITY)


# ─────────────────────────────────────────────────────────────
# Le panneau de mesure
# ─────────────────────────────────────────────────────────────

func _interface() -> void:
	var p := Style.panneau(self, Rect2(30, 1478, 1020, 330), Color(0.035, 0.05, 0.045, 0.7), 34)
	Style.libelle(p, "ESSAI 3D · VERT = ÇA TIENT (≥ 55 IMAGES/S)", Rect2(48, 30, 900, 36), "etiquette", 23, Style.OR_FILET,
		HORIZONTAL_ALIGNMENT_LEFT, 5)
	lbl = Style.libelle(p, "…", Rect2(48, 76, 930, 60), "normal", 36, Style.IVOIRE)
	var i := 0
	for n in [100, 150, 200]:
		var b := Style.bouton(p, "%d pièces" % n, Rect2(48 + i * 236, 156, 220, 110), false, 36)
		b.pressed.connect(_garnir.bind(n))
		i += 1
	var s := Style.bouton(p, "Semer ×10", Rect2(756, 156, 220, 110), true, 36)
	s.pressed.connect(_semer.bind(10))
	lbl_mesure = Style.libelle(p, "", Rect2(48, 276, 930, 44), "italique", 30, Style.SOURD)
	Style.libelle(self, "Glisse le doigt n'importe où : la pièce tombe sur ce qui est dessous.", Rect2(40, 1830, 1000, 50),
		"italique", 34, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER)


# ─────────────────────────────────────────────────────────────
# Les tests, sans écran (--fixed-fps 60 : chaque image vaut 1/60 s de jeu)
# ─────────────────────────────────────────────────────────────

func _secondes(s: float) -> void:
	for i in int(s * 60.0):
		await get_tree().physics_frame


func _lancer_tests() -> void:
	var ok := true
	seed(20260924)

	# T1 — une pièce lâchée sur une autre y reste (bloc arrêté)
	bloc_fige = true
	_vider()
	var couche: Array = []
	for rang in 2:
		var x := X0 + R_PIECE + 0.02 + (0.41 if rang == 1 else 0.0)
		while x <= X1 - R_PIECE:
			couche.append(_piece(Vector3(x, H_BLOC + EP_PIECE * 0.5 + 0.005, MUR + R_PIECE + 0.03 + rang * 0.72)))
			x += 0.82
	await _secondes(1.0)
	var lachees: Array = []
	for i in range(0, couche.size(), 2):
		var q: RigidBody3D = couche[i]
		lachees.append(_piece(Vector3(q.position.x + randf_range(-0.12, 0.12), q.position.y + 0.5, q.position.z + randf_range(-0.12, 0.12))))
	await _secondes(2.0)
	var dessus := 0
	for b in lachees:
		if b.position.y > H_BLOC + EP_PIECE * 1.3:
			dessus += 1
	print("T1 · lâchées sur une pièce : %d sur %d y restent" % [dessus, lachees.size()])
	if dessus < lachees.size() * 0.8:
		ok = false

	# T2 — sur le bloc qui va et vient, une pièce seule ne glisse pas
	bloc_fige = false
	_vider()
	var seules: Array = []
	for i in 8:
		seules.append(_piece(Vector3(X0 + 0.9 + i * 1.2, H_BLOC + EP_PIECE * 0.5 + 0.005, face_z - 0.6)))
	await _secondes(0.5)
	var d0: Array = []
	for b in seules:
		d0.append(face_z - b.position.z)
	var glisse := 0.0
	for k in 330:
		await get_tree().physics_frame
		for j in seules.size():
			var b: RigidBody3D = seules[j]
			if pieces.has(b):
				glisse = maxf(glisse, absf((face_z - b.position.z) - float(d0[j])))
	var restees := 0
	for b in seules:
		if pieces.has(b):
			restees += 1
	print("T2 · deux allers-retours du bloc : %.1f px de glissement au pire, %d pièces sur 8 toujours dessus" % [glisse * U, restees])
	if glisse * U > 6.0 or restees < 8:
		ok = false

	# T3 — les objets restent au-dessus du tas : aucune pièce posée sur un objet
	_garnir(150)
	await _secondes(2.5)
	var couverts := _objets_couverts()
	print("T3 · objets avec une pièce posée dessus : %d sur %d (attendu : aucun)" % [couverts, lots.size()])
	for l in lots:
		for q in pieces:
			var d := Vector2(q.position.x - l.position.x, q.position.z - l.position.z).length()
			if d < float(l.get_meta("r")) and q.position.y > l.position.y + float(l.get_meta("ep")) * 0.4:
				print("  diag · %s en (%.2f, %.2f, %.2f), penché %.2f · pièce en (%.2f, %.2f, %.2f) à %.2f du centre, penchée %.2f" % [
					l.get_meta("lot"), l.position.x, l.position.y, l.position.z, l.global_transform.basis.y.y,
					q.position.x, q.position.y, q.position.z, d, q.global_transform.basis.y.y])
	if couverts > 0:
		ok = false

	# T4 — trois minutes de jeu, deux pièces par seconde : rien ne s'envole, rien ne se
	# traverse, et une fois la machine pleine, elle rend ce qu'on lui donne
	var max_corps := 0
	var hors := 0
	var lachees_min := 0
	var tombees_avant := tombees
	var rendement := 0.0
	for k in 10800:
		await get_tree().physics_frame
		if k % 30 == 0 and pieces.size() < MAX_PIECES:
			_lacher(randf_range(X0 + R_PIECE, X1 - R_PIECE), randf_range(MUR + R_PIECE + 0.02, face_z - R_PIECE))
			lachees_min += 1
		if k % 3600 == 3599:
			rendement = float(tombees - tombees_avant) / maxf(1.0, lachees_min)
			print("  minute %d : %d lâchées, %d tombées au bord (%d %%), %d pièces sur la machine" % [
				(k + 1) / 3600, lachees_min, tombees - tombees_avant, roundi(rendement * 100.0), pieces.size()])
			lachees_min = 0
			tombees_avant = tombees
		max_corps = maxi(max_corps, pieces.size() + lots.size())
		if k % 60 == 0:
			for arr in [pieces, lots]:
				for b in arr:
					var q: Vector3 = b.position
					if is_nan(q.x) or is_nan(q.y) or q.x < X0 - 0.3 or q.x > X1 + 0.3 or q.y > 3.0:
						hors += 1
	# l'une dans l'autre : deux pièces À PLAT, à la même hauteur, trop proches
	var traversees := 0
	var debout := 0
	for i in pieces.size():
		var a: RigidBody3D = pieces[i]
		var ay := absf(a.global_transform.basis.y.normalized().y)
		if ay < 0.5:
			debout += 1
			continue
		if ay < 0.985:
			continue
		for j in range(i + 1, pieces.size()):
			var b: RigidBody3D = pieces[j]
			if absf(b.global_transform.basis.y.normalized().y) < 0.985:
				continue
			if Vector2(a.position.x - b.position.x, a.position.z - b.position.z).length() < 2.0 * R_PIECE - 0.1 \
					and absf(a.position.y - b.position.y) < 0.03:
				traversees += 1
	var couverts_fin := _objets_couverts()
	print("T3 · après trois minutes de jeu : %d objet(s) avec une pièce posée dessus" % couverts_fin)
	if couverts_fin > 1:
		ok = false
	var empilees := 0
	for b in pieces:
		var sol := H_BLOC if (b.position.z < face_z and b.position.z > MUR - 0.5) else 0.0
		if b.position.y > sol + EP_PIECE * 1.3:
			empilees += 1
	print("T4 · trois minutes de jeu : %d tombées au bord, %d corps au plus, %d hors jeu, %d l'une dans l'autre, %d debout sur la tranche, %d pièces sur d'autres (sur %d)" % [
		tombees, max_corps, hors, traversees, debout, empilees, pieces.size()])
	_diagnostic()
	# pleine, la machine doit rendre au moins la moitié de ce qu'on lui donne
	if rendement < 0.5 or hors > 0 or traversees > 2 or debout > pieces.size() / 20 or empilees == 0:
		ok = false

	# T5 — le temps par image, chronométré (le moniteur de Godot rend le pire par seconde RÉELLE)
	for n in [100, 150, 200]:
		_garnir(n)
		await _secondes(3.0)
		var somme := 0.0
		var pire := 0.0
		var avant := Time.get_ticks_usec()
		for k in 300:
			await get_tree().physics_frame
			var maintenant := Time.get_ticks_usec()
			var ms := (maintenant - avant) / 1000.0
			avant = maintenant
			somme += ms
			pire = maxf(pire, ms)
		print("T5 · %3d pièces : %.2f ms par image en moyenne (pire %.2f) sur le PC" % [pieces.size(), somme / 300.0, pire])
	print("RESULTAT: " + ("OK" if ok else "ECHEC"))
	get_tree().quit(0 if ok else 1)


# La photo (en fenêtre, rendu réel) : le tas posé, des pièces lâchées sur les tas.
func _photographier(dossier: String) -> void:
	await get_tree().create_timer(2.5).timeout
	for i in 6:
		var q: RigidBody3D = pieces[i * 7]
		_lacher(q.position.x, q.position.z)
	await get_tree().create_timer(0.18).timeout
	get_viewport().get_texture().get_image().save_png(dossier.path_join("godot_essai3d_chute.png"))
	await get_tree().create_timer(2.5).timeout
	get_viewport().get_texture().get_image().save_png(dossier.path_join("godot_essai3d.png"))
	print("capture essai 3D : ok")
	get_tree().quit(0)


# Où sont les pièces : sur le bloc ou le plateau, à quelle hauteur, et où se traversent-elles.
func _diagnostic() -> void:
	var sur_bloc := 0
	var h_max := 0.0
	var hauteurs := {}
	for b in pieces:
		if b.position.z < face_z:
			sur_bloc += 1
		h_max = maxf(h_max, b.position.y)
		var e := int(b.position.y / EP_PIECE)
		hauteurs[e] = int(hauteurs.get(e, 0)) + 1
	var cles := hauteurs.keys()
	cles.sort()
	var t := ""
	for k in cles:
		t += "%d:%d " % [k, hauteurs[k]]
	print("  diag · %d sur le bloc, %d sur le plateau · hauteur max %.2f · étages %s" % [sur_bloc, pieces.size() - sur_bloc, h_max, t])
	var n := 0
	for i in pieces.size():
		for j in range(i + 1, pieces.size()):
			var a: RigidBody3D = pieces[i]
			var b: RigidBody3D = pieces[j]
			var dxz := Vector2(a.position.x - b.position.x, a.position.z - b.position.z).length()
			if dxz < 2.0 * R_PIECE - 0.1 and absf(a.position.y - b.position.y) < EP_PIECE * 0.6 and n < 6:
				n += 1
				print("  diag · l'une dans l'autre : (%.2f, %.2f, %.2f) et (%.2f, %.2f, %.2f), %.2f d'écart" % [
					a.position.x, a.position.y, a.position.z, b.position.x, b.position.y, b.position.z, dxz])


func _a_capture(args: PackedStringArray) -> bool:
	for a in args:
		if a.begins_with("capture="):
			return true
	return false


# La mesure automatique, dès l'ouverture : 100, 150, 200 et 260 pièces, 10 s
# chacune (les 6 dernières comptent, en images réellement affichées), puis le
# verdict. Un toucher dans la machine l'arrête, pour jouer.
func _mesure_auto() -> void:
	_mesure_en_cours = true
	var morceaux: Array = []
	for n in [100, 150, 200, 260]:
		if not _mesure_en_cours:
			return
		_garnir(n)
		lbl_mesure.text = "Mesure automatique : %d pièces… (touche la machine pour jouer)" % n
		await get_tree().create_timer(4.0).timeout
		if not _mesure_en_cours:
			return
		var images := Engine.get_frames_drawn()
		var t0 := Time.get_ticks_msec()
		await get_tree().create_timer(6.0).timeout
		if not _mesure_en_cours:
			return
		var fps := (Engine.get_frames_drawn() - images) * 1000.0 / maxf(1.0, Time.get_ticks_msec() - t0)
		morceaux.append("%d → %d" % [n, roundi(fps)])
		lbl_mesure.text = "Mesure : " + " · ".join(morceaux) + " images/s"
	_mesure_en_cours = false
	lbl_mesure.add_theme_color_override("font_color", Style.IVOIRE)
	lbl_mesure.text = "Mesure : " + " · ".join(morceaux) + " images/s — envoie-moi cette ligne"


# Un objet est couvert quand une pièce REPOSE dessus : au-dessus de son centre, à
# une ou deux pièces de sa face — pas une pièce du bloc qui le surplombe.
func _objets_couverts() -> int:
	var n := 0
	for l in lots:
		var ep: float = l.get_meta("ep")
		for q in pieces:
			var dy := q.position.y - l.position.y
			if Vector2(q.position.x - l.position.x, q.position.z - l.position.z).length() < float(l.get_meta("r")) \
					and dy > ep * 0.4 and dy < ep * 0.5 + EP_PIECE * 2.0:
				n += 1
				break
	return n
