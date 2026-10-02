class_name PusherScreen
extends Control

signal tombe(genre: String)     # un corps vient d'être gagné : "piece" ou "lot"

# ─────────────────────────────────────────────────────────────
# LA POUSSETTE — la vraie machine, en 3D (FEATURES § ⑦, adoptée le 24/09).
#
# La physique est en 3D (Jolt) pour que les pièces et les objets se
# SUPERPOSENT, sur le bloc comme sur le plateau ; le dessin reste le nôtre,
# en perspective oblique : une pièce plus haute se dessine plus haut, on voit
# sa tranche, et chacune jette son ombre sur celles du dessous.
#
#   · on lâche une pièce AU-DESSUS du doigt, sur le bloc (ou au pied du
#     fronton) : elle tombe sur ce qui est dessous ;
#   · le bloc va et vient comme une bielle ; il porte ses pièces (son dessus
#     accroche), le fronton les retient, sa face avant pousse le tas ;
#   · ce qui passe le bord tombe ; c'est gagné une fois la ligne ENTIÈREMENT
#     passée.
#
# 🔴 LES OBJETS RESTENT AU-DESSUS DU TAS (Maxim, 23/09) : plus épais qu'une pile
#    de pièces, posés sur le tas, et ils secouent les pièces posées sur eux.
# 🔴 LES OBJETS SONT PLACÉS PAR RARETÉ, EN PROFONDEUR : banal près du bord,
#    rare tout au fond. La distance EST le prix.
#
# Unités : 1 unité = 100 px. x → x à l'écran, z → la profondeur (y à
# l'écran), y → la hauteur au-dessus du plateau. Les cotes sont celles de la
# poussette 2D : le mur à 600 px, la face du bloc de 760 à 920, le bord à 1400.
# ─────────────────────────────────────────────────────────────

const U := 100.0
const X0 := 0.46
const X1 := 10.34
const MUR := 6.0              # la face du fronton : les pièces du bloc y butent
const MILIEU := 8.4           # la face du bloc va de 7,6 à 9,2…
const COURSE := 0.8
const PERIODE := 2.71         # … en un aller-retour
const BORD := 14.0            # le bord du plateau : au-delà, ça tombe
const H_BLOC := 0.5           # le dessus du bloc, au-dessus du plateau
# 🔴 27/09 : 0,40 → 0,46. Mesuré au compteur sur le téléphone : 33-35 images/s, physique 16-18 ms à
#    ~340 pièces — la machine ne tenait pas 60 pas de physique par seconde (elle tournait au ralenti).
#    Ce qui coûte, c'est le nombre de pièces qui se touchent (un solveur allégé, une physique à 30 Hz :
#    écartés au banc). Des pièces 15 % plus larges : ~215 pièces au lieu de ~322, −32 % de physique,
#    et le plateau reste fourni (Maxim : « légèrement plus grosses… faut juste que le plateau soit fourni »).
const R_PIECE := 0.46
const EP_PIECE := 0.12
const EP_LOT := 0.28            # l'épaisseur PHYSIQUE d'un objet (à 0,18, un objet large et lourd passait sous le sol)
const EP_LOT_VU := 0.18         # 26/09 : l'épaisseur DESSINÉE (à 0,28 : « une boîte de conserve »)
# 🔴 À cette échelle, la gravité réelle rend tout flottant et glissant.
const GRAVITE := 5.0
# 🔴 Le métal glisse sur le métal : trop de frottement entre les pièces, et le
#    tas poussé se redresse sur la tranche au lieu d'avancer.
const FROTTEMENT := 0.35
const FROTTEMENT_PLATEAU := 0.15
const FROTTEMENT_BLOC := 0.8
static var frottement_plateau := FROTTEMENT_PLATEAU     # le banc (sim_poussoir plateau=…) l'essaie sans toucher au code
# LES FENTES (29/09 — Maxim : « rendre le plateau moins facile à faire tomber les pièces » ; « l'idée, c'est que les gens
# achètent des pièces pour jouer plus à la machine ») : comme les vraies machines, deux fentes le long des côtés, à l'avant.
# Une pièce qui dérive sur un côté y tombe : PERDUE. (Un objet qui y tomberait revient sur le tas : on ne perd jamais une
# récompense.) Leur largeur et leur longueur sont le prix du plateau : réglées au banc (sim_poussoir).
# 🔴 29/09, soir — Maxim : « j'ai pas l'impression que des pièces tombent sur les côtés » : à 0,4, AUCUNE ne tombait (une
#    pièce fait 0,46 de rayon : collée au mur, son centre restait sur le plancher) ; ce que le banc comptait comme « perdu
#    dans les fentes » était des pièces tombées DEVANT et pas comptées (le bord, corrigé). Désormais plus larges qu'une
#    demi-pièce, et elles S'ARRÊTENT AVANT LE BORD : un coin plein devant — une pièce perdue tombe sur le côté, au milieu du
#    plateau, jamais là où l'on gagne.
static var fente := 0.7                # la largeur de chaque fente (le banc l'essaie : sim_poussoir fente=…)
static var fente_z0 := 10.8            # où elles commencent…
static var fente_z1 := 13.3            # … et où elles s'arrêtent (le coin plein, jusqu'au bord)
var perdues := 0                  # les pièces tombées dans les fentes (le banc les compte)
var entrechocs := 0               # les pièces arrivées sur le tas en tombant (le banc les compte)
var ratees_au_bord := 0           # les pièces tombées devant sans être comptées (le banc les compte)
const K_H := 0.9              # 1 px de hauteur = 0,9 px vers le haut de l'écran

# 🔴 Plus de recharge (28/09, ⑧ — Maxim : « arrêter de donner des pièces à la minute ») : les pièces viennent
#    du cadeau du jour, des défis des Présages, et de ce que la machine rend. Plus de plafond non plus.
const SEMIS_DIST := 60.0
# 🔴 Le plafond. Mesuré au banc (sim_poussoir) : nourrie sans arrêt, la machine se
#    stabilise à son équilibre et rend alors ~60-75 % de ce qu'on lui donne. ⛔ Un plafond
#    SOUS cet équilibre la bloque : le joueur ne peut plus lâcher, et sans pièces lâchées
#    rien ne pousse (vu à 260 avec les pièces de 0,40 : 2 gains par minute).
#    Pièces de 0,46 (27/09) : équilibre vers 255 → plafond 270 (360 ÷ 1,32, l'aire d'une pièce).
const MAX_PIECES := 270
const GARNI := 225            # une machine neuve part près de l'équilibre : elle rend tout de suite

# À INCRÉMENTER dès qu'une cote ci-dessous bouge : le tas sauvegardé repart à zéro.
const GEO_VERSION := 12          # 11 (27/09) : les pièces passent de 0,40 à 0,46 · 12 (29/09) : les fentes

const CADRE := Rect2(20, 238, 1040, 1214)

# rang : 0 banal (près du bord) · 1 normal · 2 rare (au fond) ; r et z en unités
# 🔴 Les objets de l'univers (FEATURES ⑭, 26/09) : un objet de chaque rang sur le plateau. Le rare est
#    une pierre, tirée à chaque fois qu'elle revient : un des six types, ou — plus rarement — la lune.
#    « image » : le nom de l'objet dans objets/ (l'icône) et objets/3d/ (le volume, Volumes).
const LOTS := {
	"poussiere": {"rang": 0, "r": 0.50, "z": 12.7, "col": Color("#9fb4ff"), "titre": "Poussière d'étoile",
		"detail": "60 poussières d'étoile, pour faire monter tes cartes.", "etiq": "banal", "image": "poussiere-etoile"},
	"etoile": {"rang": 1, "r": 0.64, "z": 11.2, "col": Color("#c9a4ff"), "titre": "Étoile d'invocation",
		"detail": "Une invocation dans la collection.", "etiq": "normal", "image": "etoile-invocation"},
	# (30/09) ce que laisse la Supernova : il ne fait pas partie du plateau du jour (Plateau l'ignore)
	"coeur-etoile": {"rang": 1, "r": 0.64, "z": 11.2, "col": Color("#f2b440"), "titre": "Cœur d'étoile",
		"detail": "Trois cœurs allument une Nouvelle machine.", "etiq": "rare", "image": "coeur-etoile"},
}
const PIERRES_LOT := Plateau.PIERRES        # (la chance de la lune : Plateau.CHANCE_LUNE)
const R_PIERRE := 0.70
const Z_PIERRE := 9.75
# le tas d'une version d'avant : ses objets deviennent ceux d'aujourd'hui
const ANCIENS_LOTS := {"xp": "poussiere", "ticket": "etoile", "eclat": "pierre-lune"}
const COL_PIECE := Color("#e2b75c")


# Ce qu'est un objet (sa profondeur, sa taille, son nom) : les deux fixes, ou une pierre.
static func lot_def(k: String) -> Dictionary:
	if LOTS.has(k):
		return LOTS[k]
	var t := k.trim_prefix("pierre-")
	if t == "lune":
		return {"rang": 2, "r": R_PIERRE, "z": Z_PIERRE, "col": Color("#b8ccff"), "titre": "Pierre de lune",
			"detail": "Rare : fait évoluer n'importe quelle carte.", "etiq": "rare", "image": k}
	var ty: Dictionary = GS.TYPES.get(t, GS.TYPES["aucun"])
	var nom: String = GS.NOMS_PIERRES.get(t, "pierre")
	return {"rang": 2, "r": R_PIERRE, "z": Z_PIERRE, "col": ty["elt"], "titre": nom[0].to_upper() + nom.substr(1),
		"detail": "Fait évoluer une carte de type %s." % str(ty["nom"]).to_lower(), "etiq": "rare", "image": k}


static func types_de_lots() -> Array:
	var ks: Array = LOTS.keys()
	for t in PIERRES_LOT + ["lune"]:
		ks.append("pierre-" + t)
	return ks


# (L'objet qui arrive à un rang : le plateau du jour le dit, Plateau.prochain — 28/09. Avant, il était
#  tiré au hasard, sans fin.)

var monde: Node3D
var bloc: AnimatableBody3D
var face_z := MILIEU - COURSE
var t_bloc := 0.0
var _en_chute := {}            # (29/09) les pièces en train de tomber sur le tas : leur arrivée sonne (Son.entrechoc)
var pieces: Array[RigidBody3D] = []
var lots: Array[RigidBody3D] = []
var _image_physique := 0
var us_script := 0.0             # le temps du script de physique (µs, lissé) : le compteur des outils

var particules: Array = []
var textes: Array = []
var sauve_t := 0.0
var horloge := 0.0

var doigt := false
var dernier_semis := Vector2.ZERO
var gel := false
var a_rendre: Array = []        # les objets qui reviennent sur le tas (1,4 s après un gain)

var decor: Control         # le fond fixe (cadre, plateau, repères, gouttière) : dessiné une fois
var bloc2d: Control        # le bloc qui va et vient : redessiné à chaque image (quelques rectangles)
var fronton2d: Control     # le fronton, par-dessus le bloc : dessiné une fois
var rendu: MachineRendu    # les pièces et les objets, en 3D (machine_rendu.gd)
var effets: Control        # les étincelles, les « +3 »
var lueur_bord: ColorRect  # la ligne du bord qui respire
var tex_pieces: Array[Texture2D] = []
var tex_lot := {}
var tex_lueur: Texture2D
var tex_etoiles: Texture2D
var tex_face: Texture2D
# Le dessus du bloc (Maxim, 26/09 : « le poussoir en blanc, je trouve ça pas ouf » ; il a choisi
# « le mauve ») : « nebuleuse ». Les autres restent pour comparer : « ivoire » (avant), « nuit »,
# « jade » (interface/bloc-*.png, rendus par render_objets.py --blocs).
var style_bloc := "nebuleuse"
var tex_blocs := {}
var tex_jade_monte: Texture2D
var sb_cadre: StyleBoxFlat
var sb_filet: StyleBoxFlat
var sb_fronton: StyleBoxFlat
var etincelle_t := 0.0

var lbl_main: Label
var anneau: Control             # l'anneau de la réserve : il se remplit jusqu'à la prochaine pièce
var ico_reserve: TextureRect
var icones_pj: Array = []       # le plateau du jour : ses 12 objets (TextureRect)
var lbl_pj_fin: Label           # « Revient demain » une fois tout gagné
var _jour_vu := ""              # le jour que la machine affiche (minuit en pleine partie : elle se regarnit)
var lbl_hint: Label
var lbl_perf: Label
var outils: Control
var bandeau: Bandeau            # le bandeau du haut (main.gd) : les objets gagnés s'y envolent
# (02/10, DECISIONS 02/10) la machine dans son décor peint — Base céleste par défaut — et le lance-pièces : il remplace le
# cadre dessiné d'avant (son titre, sa frise, le bloc en 2D) ; la vue 3D y passe en perspective
const MACHINE_DECOR := preload("res://machines/machine_decor.gd")
var decor_peint: Node
static var rouvrir_outils := false    # (02/10) le décor change : la machine se recharge, les outils restent ouverts
var bouton_decor: Button
var _reserve_retenue := 0       # les pièces en vol vers la réserve


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# 🔴 Les pièces arrivent aussi d'ailleurs depuis le 28/09 (les défis des Présages, le cadeau du jour) : la
	#    réserve se relit à chaque changement, sinon elle montrait l'ancien nombre (vu à la capture : 130 pour 0).
	GS.changed.connect(func():
		if lbl_main != null:
			_maj_main())
	# Pas de fond : le ciel commun (Ciel, dans main) se voit autour de la machine.
	monde = Node3D.new()
	add_child(monde)
	_cuire()
	decor = _couche(_dessiner_decor)
	bloc2d = _couche(_dessiner_bloc)
	fronton2d = _couche(_dessiner_fronton)
	jauge2d = _couche(_dessiner_jauge)            # (30/09) la jauge de la Supernova, sur la frise de lunes
	rendu = MachineRendu.new()
	add_child(rendu)
	rendu.preparer(Rect2(X0 * U - 12.0, 440.0, (X1 - X0) * U + 24.0, CADRE.end.y - 12.0 - 440.0), R_PIECE, EP_PIECE,
		{"u": U, "k_h": K_H, "bord": BORD, "h_bloc": H_BLOC, "mur": MUR, "objets": _images_lots()})
	effets = _couche(_dessiner_effets)
	lueur_bord = ColorRect.new()
	lueur_bord.position = Vector2(X0 * U - 8.0, BORD * U - 3.0)
	lueur_bord.size = Vector2((X1 - X0) * U + 16.0, 5.0)
	lueur_bord.color = Color(0.80, 0.98, 0.90)
	lueur_bord.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lueur_bord)
	supernova_fx = SupernovaFx.new()
	add_child(supernova_fx)
	visibility_changed.connect(_visibilite)
	_ui()
	_installer_decor()
	_decor()
	_charger()


func _installer_decor() -> void:
	if MACHINE_DECOR.DONNEES.DECORS.has(Reglages.decor_machine):
		MACHINE_DECOR.theme = Reglages.decor_machine
	decor_peint = MACHINE_DECOR.new()
	add_child(decor_peint)
	decor_peint.installer(self)
	if bouton_decor != null:
		bouton_decor.text = "Décor : %s  ›" % MACHINE_DECOR.nom_du(MACHINE_DECOR.theme)
	for c in [decor, bloc2d, fronton2d, jauge2d, lueur_bord]:
		c.visible = false


func _exit_tree() -> void:
	PhysicsServer3D.set_active(true)


func _couche(f: Callable) -> Control:
	var c := Control.new()
	c.size = Vector2(1080, 2400)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	c.draw.connect(f)
	add_child(c)
	return c


# Cachée (on passe à la collection) : on sauve le tas et on arrête de dessiner la machine.
func _visibilite() -> void:
	if rendu != null:
		rendu.actif(visible)
	# 🔴 Cachée, la machine se met EN PAUSE (25/09) : avant, sa physique tournait pendant
	#    qu'on regardait la collection — la machine jouait seule, et la collection ramait.
	if not gel:
		PhysicsServer3D.set_active(visible)
	set_physics_process(visible)
	if not visible and decor_peint != null:
		decor_peint.achever_pluie()
	if not visible and pieces.size() > 0:
		# le tas est figé : on le sauve une fois la transition finie, pas pendant
		get_tree().create_timer(0.6).timeout.connect(func():
			if not visible:
				_sauver())


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if decor_peint != null:
			decor_peint.achever_pluie()
		if pieces.size() > 0:
			_sauver()


func _cuire() -> void:
	tex_pieces = [Style.objet("piece-etoile"), Style.objet("piece-lune")]
	for k in types_de_lots():
		tex_lot[k] = Style.objet(str(lot_def(k)["image"]))
	tex_lueur = Style.texture("res://ciel/lueur.png")
	tex_etoiles = Style.texture("res://ciel/etoiles-fines.png")
	for st in ["nuit", "nebuleuse", "jade"]:
		tex_blocs[st] = Style.texture("res://interface/bloc-%s.png" % st)
	tex_face = Style.degrade(PackedColorArray([Color("#fff2c6"), Color("#e6c275"), Color("#b58d40"), Color("#6c5021")]),
		PackedFloat32Array([0.0, 0.3, 0.62, 1.0]))
	tex_jade_monte = Style.degrade(PackedColorArray([Color(Style.JADE, 0.0), Color(Style.JADE, 0.6)]),
		PackedFloat32Array([0.0, 1.0]))
	sb_cadre = Style.boite(Color("#121715"), 44, Style.OR_FILET, 3)
	sb_filet = Style.boite(Color(0, 0, 0, 0), 34, Style.OR_FILET_2, 2)
	sb_fronton = Style.boite(Color("#0a0f0d"), 30, Color(0, 0, 0, 0), 0)
	sb_fronton.corner_radius_bottom_left = 0
	sb_fronton.corner_radius_bottom_right = 0


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
	# le plateau : sa surface à y = 0, du pied du fronton jusqu'au bord — plein, plus étroit le long des fentes, plein devant
	_boite(StaticBody3D.new(), Vector3(cx, -0.1, (MUR + fente_z0) * 0.5), Vector3(w + 0.64, 0.2, fente_z0 - MUR), frottement_plateau)
	_boite(StaticBody3D.new(), Vector3(cx, -0.1, (fente_z1 + BORD) * 0.5), Vector3(w + 0.64, 0.2, BORD - fente_z1), frottement_plateau)
	_boite(StaticBody3D.new(), Vector3(cx, -0.1, (fente_z0 + fente_z1) * 0.5), Vector3(w - 2.0 * fente, 0.2, fente_z1 - fente_z0),
		frottement_plateau)
	# les côtés, qui dépassent le bord : ce qui tombe tombe droit
	for x in [X0 - 0.16, X1 + 0.16]:
		_boite(StaticBody3D.new(), Vector3(x, 1.5, (MUR + BORD) * 0.5 + 1.0), Vector3(0.32, 3.0, BORD - MUR + 4.0), 0.1)
	# le fronton : il commence juste au-dessus du bloc, qui glisse dessous
	_boite(StaticBody3D.new(), Vector3(cx, H_BLOC + 0.02 + 1.5, MUR - 0.5), Vector3(w + 0.64, 3.0, 1.0), 0.1)
	# le bloc : un pavé posé sur le plateau, sa face avant en face_z
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


func _images_lots() -> Dictionary:
	var d := {}
	for k in types_de_lots():
		d[k] = lot_def(k)["image"]
	return d


func _lot(k: String, pos := Vector3.INF, xz := Vector2.INF) -> RigidBody3D:
	k = str(ANCIENS_LOTS.get(k, k))
	if not types_de_lots().has(k):
		k = "etoile"
	var r: float = lot_def(k)["r"]
	# 🔴 Une bille (la poussière, l'étoile) a un corps À SA TAILLE : aussi épais qu'elle est dessinée, et
	#    qui ne penche pas (26/09 — Maxim : « bug, les deux se sont chevauchées » : leurs corps étaient
	#    les disques plats d'avant, qui glissaient l'un sur l'autre sous les boules dessinées).
	var bille := bool(Volumes.objet(str(lot_def(k)["image"])).get("sphere", false))
	var ep := 2.0 * r * Volumes.APLATI if bille else EP_LOT
	if pos == Vector3.INF:
		if xz == Vector2.INF:
			xz = Vector2(randf_range(X0 + 1.8, X1 - 1.8), float(lot_def(k)["z"]))
		pos = Vector3(xz.x, _hauteur_libre(xz.x, xz.y, r, ep * 0.5 + 0.01), xz.y)
	var b := _corps(pos, r, ep, 4.0)
	if bille:
		b.axis_lock_angular_x = true
		b.axis_lock_angular_z = true
		b.rotation = Vector3.ZERO
	b.set_meta("ep_vu", ep if bille else EP_LOT_VU)
	b.set_meta("lot", k)
	lots.append(b)
	return b


# La hauteur où poser un disque en (x, z) sans le faire naître dans un autre.
# « parmi » : les corps à regarder (par défaut tous) — le lâcher ne passe que les voisines.
func _hauteur_libre(x: float, z: float, r: float, sol: float, parmi: Array = []) -> float:
	var h := sol
	for arr in ([pieces, lots] if parmi.is_empty() else [parmi]):
		for q in arr:
			if q.has_meta("vol"):
				continue          # (02/10) il vole de l'astrolabe au plateau : il n'occupe aucune place
			if Vector2(q.position.x - x, q.position.z - z).length() < r + float(q.get_meta("r")):
				h = maxf(h, q.position.y + float(q.get_meta("ep")) + 0.01)
	return h


# Les corps assez près de (x, z) pour compter dans une recherche de place (une passe).
func _voisines(x: float, z: float, portee: float) -> Array:
	var res: Array = []
	for arr in [pieces, lots]:
		for q in arr:
			if absf(q.position.x - x) < portee and absf(q.position.z - z) < portee and not q.has_meta("vol"):
				res.append(q)
	return res


func _vider() -> void:
	for arr in [pieces, lots]:
		for b in arr:
			if rendu != null:
				rendu.oublier(b)
			# 🔴 remove_child AVANT queue_free : sinon l'ancien corps reste une image de
			#    plus dans le monde physique, et le nouveau tas naît dedans.
			monde.remove_child(b)
			b.queue_free()
	pieces.clear()
	lots.clear()


func _garnir(n := GARNI) -> void:
	_vider()
	n = maxi(0, n - AMAS * Plateau.a_poser().size())        # les tas des objets font partie de la machine neuve
	# le bloc du haut n'en garde que SUR_BLOC ; le plateau du bas, autant qu'avant (85 %) : le reste n'est pas posé
	var sur_bloc := mini(SUR_BLOC, n)
	n = sur_bloc + int(n * 0.85)
	for i in n:
		var sb := i < sur_bloc
		var x := randf_range(X0 + R_PIECE, X1 - R_PIECE)
		var z := randf_range(MUR + R_PIECE + 0.05, face_z - R_PIECE) if sb else randf_range(MILIEU + COURSE + R_PIECE - 0.05, BORD - R_PIECE - 0.1)
		var sol := (H_BLOC if sb else 0.0) + EP_PIECE * 0.5 + 0.01
		_piece(Vector3(x, _hauteur_libre(x, z, R_PIECE, sol), z))
	# les objets ensuite, TOUS ceux qu'il reste aujourd'hui, chacun sur son amas (créé : la machine est neuve)
	_garnissage = true
	_completer_plateau()
	_garnissage = false


func _physics_process(delta: float) -> void:
	if gel or delta <= 0.0:
		return
	# le bloc va et vient comme une bielle : il ralentit en bout de course au lieu
	# de repartir d'un coup — sinon les pièces glissent sur lui à chaque retour
	t_bloc = fmod(t_bloc + delta, PERIODE)
	if supernova_t > 0.0:
		_tic_supernova(delta)
	face_z = MILIEU - COURSE * cos(TAU * t_bloc / PERIODE)
	bloc.position.z = face_z - 2.0
	# L'ENTRECHOC (29/09) : le poussoir ne sonne plus ; une pièce qui TOMBE sur le tas sonne quand elle y arrive. Toutes les
	# 3 images, et seulement près de la face du bloc (c'est de là qu'elles tombent) : lire la vitesse d'un corps coûte, et la
	# physique tient à peine ses images (D13). Une pièce lâchée par le joueur a déjà son son (pose) : elle n'entre pas ici.
	if _image_physique % 3 == 0 and is_visible_in_tree():
		for q in pieces:
			var qp := q.position
			if absf(qp.z - face_z) > 1.2 or qp.y < -0.05 or q.has_meta("lachee"):     # (sous le plateau : une fente, le bord)
				continue
			var vy := q.linear_velocity.y
			if vy < -2.0:
				_en_chute[q] = true
			elif _en_chute.has(q) and vy > -0.6:
				_en_chute.erase(q)
				entrechocs += 1
				Son.entrechoc()
	if _image_physique % 180 == 0:
		for q in _en_chute.keys():
			if not is_instance_valid(q) or not pieces.has(q):
				_en_chute.erase(q)
	var t0 := Time.get_ticks_usec()
	# un objet secoue les pièces posées sur lui : elles glissent et tombent à côté
	_image_physique += 1
	if _image_physique % 6 == 0:
		for l in lots:
			var lp := l.position
			var rl: float = float(l.get_meta("r")) + 0.1
			var haut: float = lp.y + float(l.get_meta("ep")) * 0.3
			for q in pieces:
				var qp := q.position
				if qp.y <= haut:
					continue
				var d := Vector2(qp.x - lp.x, qp.z - lp.z)
				if d.length_squared() < rl * rl:
					var dirr := d.normalized() if d.length() > 0.01 else Vector2.RIGHT.rotated(randf() * TAU)
					q.apply_central_impulse(Vector3(dirr.x, 0.0, dirr.y) * 0.45)
	# 🔴 LE BORD : gagné une fois la ligne ENTIÈREMENT passée — OU dès qu'il bascule par-dessus (son centre au-delà du bord,
	#    et déjà sous la surface) ; puis le corps tombe et disparaît. (Une seule lecture de position par corps : cette boucle
	#    tourne à chaque pas de physique, sur 300 corps.)
	# 🔴 29/09 — Maxim : « des fois on a 4-5 pièces qui tombent et le jeu en donne que 1 ou 2 » : mesuré au banc, ~1 pièce sur
	#    4 tombée DEVANT n'était pas comptée — poussée lentement, elle basculait presque à la verticale et passait sous le
	#    plateau avant que son bord arrière ait franchi la ligne. Tout ce qui tombe devant est gagné.
	for arr in [pieces, lots]:
		for i in range(arr.size() - 1, -1, -1):
			var b: RigidBody3D = arr[i]
			var bp := b.position
			if bp.z < BORD - 0.8 and bp.y > -0.5:
				continue
			if not b.get_meta("gagne", false) and (bp.z - float(b.get_meta("r")) > BORD or (bp.z > BORD and bp.y < 0.0)):
				b.set_meta("gagne", true)
				_sur_gain(b)
				if gel:
					return
			if bp.y < -1.2 or bp.z > BORD + 2.0:
				# un objet sorti du plateau sans être gagné (coincé, passé sous le sol) revient sur le tas
				if arr == lots and not b.get_meta("gagne", false):
					var k := str(b.get_meta("lot"))
					a_rendre.append(k)
					get_tree().create_timer(0.5).timeout.connect(_rendre.bind(k))
				elif arr == pieces and not b.get_meta("gagne", false):
					if bp.z > BORD - 0.6:
						ratees_au_bord += 1   # (mesure) tombée DEVANT sans avoir été comptée
					else:
						perdues += 1          # tombée dans une fente
						_nourrir_jauge()
				arr.remove_at(i)
				rendu.oublier(b)
				monde.remove_child(b)
				b.queue_free()
	us_script = lerpf(us_script, float(Time.get_ticks_usec() - t0), 0.05)


# ─────────────────────────────────────────────────────────────
# Le geste : on lâche la pièce AU-DESSUS du doigt, sur le bloc
# ─────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible or gel:
		return
	if decor_peint != null:
		# (02/10) le doigt touche la machine n'importe où : le lance-pièces le suit (machines/machine_decor.gd)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			doigt = event.pressed
			decor_peint.toucher(event.position, event.pressed)
		elif event is InputEventMouseMotion and doigt:
			decor_peint.glisser(event.position)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		doigt = event.pressed
		dernier_semis = Vector2(-9999, -9999)
		if event.pressed:
			_semer(event.position)
	elif event is InputEventMouseMotion and doigt:
		_semer(event.position)


# Pourquoi une pièce ne peut pas partir ("" : elle peut) — le lance-pièces le demande avant de la lâcher.
func refus_lacher() -> String:
	if machine_pleine():
		return "La machine est pleine : fais d'abord tomber des pièces."
	if GS.main_pieces <= 0:
		return "Plus de pièces : les Présages en donnent."
	return ""


# Le plafond des pièces lâchées (MAX_PIECES), plus la marge de la Supernova : ses pièces offertes ne bloquent pas le joueur ;
# revenue sous le plafond, la machine reprend son plafond (la marge s'efface).
func machine_pleine() -> bool:
	if pieces.size() < MAX_PIECES:
		marge_supernova = 0
	return pieces.size() >= MAX_PIECES + marge_supernova


func _semer(p: Vector2) -> void:
	if p.x < X0 * U or p.x > X1 * U or p.y < CADRE.position.y or p.y > _ecran(0.0, face_z, H_BLOC).y + 30.0:
		return
	if p.distance_to(dernier_semis) < SEMIS_DIST:
		return
	if machine_pleine():
		_indice("La machine est pleine : fais d'abord tomber des pièces.", Style.ALERTE)
		return
	if GS.main_pieces <= 0:
		_indice("Plus de pièces : les Présages en donnent.", Style.ALERTE)
		return
	dernier_semis = p
	# Sur le fronton, la pièce tombe au pied du mur ; sur le bloc, sous le doigt (le
	# dessus du bloc est dessiné plus haut que sa place : on vise la profondeur dessous).
	var z := p.y / U + H_BLOC * K_H
	z = clampf(z, MUR + R_PIECE + 0.02, face_z - R_PIECE - 0.02)
	var lachee := _lacher(clampf(p.x / U, X0 + R_PIECE, X1 - R_PIECE), z)
	if lachee == null:
		_indice("Trop de pièces ici : vise un endroit plus dégagé du bloc.", Style.ALERTE)
		return
	_sonner_a_la_pose(lachee)
	GS.main_pieces -= 1
	Presages.evenement("piece")
	GS.demander_sauvegarde()
	_maj_main()


# Le son de la pièce lâchée (29/09) : à SON premier contact (le plateau, le bloc, une autre pièce) — pas au geste : il
# tombe sur l'image où elle touche. 🔴 Seule cette pièce écoute ses contacts, et seulement jusqu'au premier : les 260 du
# tas ne les écoutent jamais (la physique ne tient déjà pas 60 images/s : D13). Garde-fou : sans contact en 0,5 s, rien.
func _sonner_a_la_pose(b: RigidBody3D) -> void:
	b.set_meta("lachee", true)          # (l'entrechoc ne la compte pas : elle a son son)
	b.contact_monitor = true
	b.max_contacts_reported = 1
	b.body_entered.connect(func(_autre: Node):
		Son.pose()
		if is_instance_valid(b):
			b.set_deferred("contact_monitor", false), CONNECT_ONE_SHOT)
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(b):
			b.remove_meta("lachee")
			if b.contact_monitor:
				b.set_deferred("contact_monitor", false))


# 🔴 Une vraie pièce ne tient pas en tour : lâchée sur une pile, elle glisse à côté.
#    On la pose donc à l'endroit le plus BAS tout près du doigt ; si tout y est déjà
#    trop haut, elle reste en réserve (vu au banc : des tours de 3 unités contre le fronton).
const PILE_MAX := 0.62        # au plus ~1 cm de pièces au-dessus du bloc (5 pièces)


func _lacher(x: float, z: float) -> RigidBody3D:
	var sol := (H_BLOC if z < face_z else 0.0) + EP_PIECE * 0.5
	var pres := _voisines(x, z, 1.9)
	if pres.is_empty():
		return _piece(Vector3(x, sol + 0.25, z))
	var meilleur := Vector3(x, _hauteur_libre(x, z, R_PIECE, sol, pres), z)
	for d in [Vector2(0.45, 0), Vector2(-0.45, 0), Vector2(0, 0.35), Vector2(0.4, 0.3), Vector2(-0.4, 0.3),
			Vector2(0.9, 0), Vector2(-0.9, 0), Vector2(0.8, 0.35), Vector2(-0.8, 0.35)]:
		if meilleur.y <= sol + 0.01:
			break
		var cx := clampf(x + d.x, X0 + R_PIECE, X1 - R_PIECE)
		var cz := clampf(z + d.y, MUR + R_PIECE + 0.02, face_z - R_PIECE - 0.02)
		var h := _hauteur_libre(cx, cz, R_PIECE, sol, pres)
		if h < meilleur.y - 0.02:
			meilleur = Vector3(cx, h, cz)
	if meilleur.y - sol > PILE_MAX:
		return null
	# lâchée d'assez bas pour ne jamais traverser une pièce en un pas de physique
	return _piece(meilleur + Vector3(0, 0.25, 0))


func _indice(t: String, col: Color) -> void:
	lbl_hint.text = t
	lbl_hint.add_theme_color_override("font_color", col)


# ─────────────────────────────────────────────────────────────
# Le tas : sauvegardé tel quel (position et orientation de chaque corps)
# ─────────────────────────────────────────────────────────────

func _charger() -> void:
	if GS.tas_geo == GEO_VERSION and GS.tas_pieces.size() > 0:
		t_bloc = float(GS.tas_bloc.get("t", 0.0))
		face_z = MILIEU - COURSE * cos(TAU * t_bloc / PERIODE)
		bloc.position.z = face_z - 2.0
		for p in GS.tas_pieces:
			if p.size() < 8:
				continue
			var b := _corps(Vector3(p[0], p[1], p[2]), R_PIECE, EP_PIECE, 1.0)
			b.quaternion = Quaternion(p[3], p[4], p[5], p[6]).normalized()
			b.set_meta("face", int(p[7]))
			pieces.append(b)
		for l in GS.tas_lots:
			var k := str(l.get("type", "etoile"))
			k = str(ANCIENS_LOTS.get(k, k))
			var pos := Vector3(float(l["x"]), float(l["y"]), float(l["z"]))
			var est_bille := types_de_lots().has(k) and bool(Volumes.objet(str(lot_def(k)["image"])).get("sphere", false))
			if est_bille:
				# une bille revient droite, posée là où elle a la place (son corps a changé le 26/09) —
				# la hauteur se cherche AVANT de la créer, sinon elle se verrait elle-même
				var r: float = lot_def(k)["r"]
				pos.y = maxf(pos.y, _hauteur_libre(pos.x, pos.z, r, r * Volumes.APLATI + 0.01))
			var b := _lot(k, pos)
			if l.get("bonus", false):
				b.set_meta("bonus", true)
			if not est_bille and l.has("q"):
				var q: Array = l["q"]
				b.quaternion = Quaternion(q[0], q[1], q[2], q[3]).normalized()
		# un objet perdu (sauvegarde coupée pendant un gain) revient sur le tas — s'il en reste aujourd'hui
		_completer_plateau()
		return
	# Pas de tas, ou celui de la poussette 2D : une machine neuve (la réserve, les
	# cartes et les objets gagnés ne bougent pas).
	_garnir()
	_sauver()


func _sauver() -> void:
	var cs: Array = []
	for b in pieces:
		if b.get_meta("gagne", false):
			continue
		var q := b.quaternion
		cs.append([snappedf(b.position.x, 0.001), snappedf(b.position.y, 0.001), snappedf(b.position.z, 0.001),
			snappedf(q.x, 0.0001), snappedf(q.y, 0.0001), snappedf(q.z, 0.0001), snappedf(q.w, 0.0001),
			int(b.get_meta("face", 0))])
	var ls: Array = []
	for b in lots:
		if b.get_meta("gagne", false):
			continue
		var q := b.quaternion
		var l := {"x": snappedf(b.position.x, 0.001), "y": snappedf(b.position.y, 0.001), "z": snappedf(b.position.z, 0.001),
			"q": [q.x, q.y, q.z, q.w], "type": str(b.get_meta("lot"))}
		if b.has_meta("bonus"):
			l["bonus"] = true
		ls.append(l)
	for k in a_rendre:
		ls.append({"x": (X0 + X1) * 0.5, "y": 0.5, "z": float(lot_def(k)["z"]), "q": [0, 0, 0, 1], "type": k})
	GS.tas_pieces = cs
	GS.tas_lots = ls
	GS.tas_bloc = {"t": t_bloc}
	GS.tas_geo = GEO_VERSION
	GS.save_tas()
	GS.demander_sauvegarde()


# ─────────────────────────────────────────────────────────────
# Le temps, les gains
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not visible:
		return
	horloge += delta
	if not gel:
		# minuit en pleine partie : le plateau d'un nouveau jour (Plateau.donnees le remet à zéro)
		if Plateau.aujourdhui() != _jour_vu:
			_completer_plateau()
			_maj_plateau_jour(false)
		anneau.queue_redraw()
		for i in range(particules.size() - 1, -1, -1):
			var pt: Dictionary = particules[i]
			pt["vie"] -= delta
			if pt["vie"] <= 0.0:
				particules.remove_at(i)
			else:
				pt["pos"] += pt["vel"] * delta
				pt["vel"] *= float(pt.get("amorti", 0.93))
		# Le bord où l'on gagne scintille : de fines étincelles jade en montent.
		etincelle_t += delta
		while etincelle_t >= 0.15 and decor_peint == null:
			etincelle_t -= 0.15
			var vie := randf_range(1.6, 2.6)
			particules.append({"pos": Vector2(randf_range(X0 * U + 10.0, X1 * U - 10.0), BORD * U - 4.0),
				"vel": Vector2(randf_range(-8.0, 8.0), -randf_range(60.0, 130.0)), "vie": vie, "vie0": vie,
				"col": Style.JADE, "r": randf_range(3.0, 5.0), "amorti": 1.0, "monte": true})
		for j in range(textes.size() - 1, -1, -1):
			var tx: Dictionary = textes[j]
			tx["vie"] -= delta
			if tx["vie"] <= 0.0:
				textes.remove_at(j)
			else:
				tx["pos"] += Vector2(0, -70.0) * delta
		# 🔴 Le tas s'écrit toutes les 20 s (et quand on quitte la poussette ou l'app) :
		#    toutes les 4 s, avec le reste, il faisait saccader le téléphone.
		sauve_t += delta
		if sauve_t > 20.0:
			sauve_t = 0.0
			_sauver()
	if outils.visible:
		lbl_perf.text = "%d images/s · physique %.1f ms (script %.1f) · rendu %.1f ms · %d pièces" % [
			Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			us_script / 1000.0, rendu.us_maj / 1000.0, pieces.size()]
	rendu.maj(pieces, lots, face_z)
	bloc2d.queue_redraw()
	effets.queue_redraw()
	lueur_bord.modulate.a = 0.75 + 0.25 * sin(horloge * 2.6)
	if supernova_t > 0.0 or _jauge_vue != _lunes_allumees():
		jauge2d.queue_redraw()
	supernova_fx.maj(supernova_t)


# Le bord, à l'écran, au droit de x : dans le décor peint, par la caméra ; sinon, la vue d'avant.
func _ecran_bord(x: float) -> Vector2:
	if decor_peint != null:
		return decor_peint.ecran(Vector3(x, 0.0, BORD))
	return _ecran(x, BORD, 0.0)


func _sur_gain(b: RigidBody3D) -> void:
	var pos := _ecran_bord(b.position.x)
	if b.has_meta("lot"):
		tombe.emit("lot")
		_gagner_objet(str(b.get_meta("lot")), pos, b.has_meta("bonus"))
		return
	tombe.emit("piece")
	Son.gain()                       # la cascade : chaque pièce qui suit de près monte d'une note
	# 🔴 Une pièce tombée va dans la réserve, et rien d'autre (Maxim, 25/09 : « les pièces, je pense
	#    qu'elles ne rajoutent pas d'XP, ça rajoute des pièces en réserve ») : elle y file.
	GS.main_pieces += 1
	GS.demander_sauvegarde()
	_eclat(pos, COL_PIECE, 6)
	if Effets.global == null or not is_visible_in_tree():
		_maj_main()
		return
	_reserve_retenue += 1
	Effets.global.envoler(tex_pieces[0], get_global_transform() * pos, ico_reserve.get_global_rect().get_center(), 46.0, 0.6,
		func():
			_reserve_retenue = maxi(0, _reserve_retenue - 1)
			_maj_main(true),
		0.95, false, 150.0, -150.0)
	_maj_main()


# 🔴 PLUS DE FENÊTRE « GAGNÉ » (Maxim, 25/09 : « les objets qu'on gagne dans la poussette, plus de
#    pop-up, on les voit s'envoler jusqu'au menu en haut pour aller augmenter les stats ») : la
#    machine ne s'arrête plus ; l'objet file vers son compteur, qui le reçoit en défilant.
# « bonus » : un objet offert par la Supernova — il ne compte pas dans le plateau du jour.
func _gagner_objet(t: String, pos: Vector2, bonus := false) -> void:
	if t == "coeur-etoile":
		_gagner_coeur(pos)
		return
	var d := lot_def(t)
	var cle := "poussiere" if t == "poussiere" else ("etoiles" if t == "etoile" else "pierres")
	var gain := 60 if t == "poussiere" else 1
	if bandeau != null:
		bandeau.retenir(cle, gain)
	if not bonus:
		Plateau.gagner(t)
	Presages.evenement("objet")
	Son.objet_tombe()               # (29/09) il tombe avec son amas : le gros paquet
	Son.objet(t)
	if not bonus and Plateau.restants() == 0:
		Presages.evenement("plateau_vide")
		get_tree().create_timer(0.55).timeout.connect(func(): Son.sonner("plateau-vide"))
	if t == "poussiere":
		GS.gagner(60, 0)
	elif t == "etoile":
		GS.gagner(0, 1)
	else:
		GS.gagner(0, 0, t.trim_prefix("pierre-"))
	# (29/09 : plus aucun objet ne revient — tout le plateau du jour est déjà posé : _completer_plateau)
	_eclat(pos, d["col"], 30)
	_maj_plateau_jour(true)
	if bandeau == null or Effets.global == null:
		return
	var image := str(d["image"])
	Effets.global.envoler(tex_lot[t], get_global_transform() * pos, bandeau.centre_icone(cle), 124.0, 1.05,
		func(): bandeau.recevoir(cle, gain, image))


func _rendre(k: String) -> void:
	if a_rendre.has(k):
		a_rendre.erase(k)
		_lot(k)


# Pour les captures et les outils : l'objet k est gagné, au milieu du bord.
func demo_gain(k: String) -> void:
	_gagner_objet(k, _ecran_bord((X0 + X1) * 0.5))


func _eclat(pos: Vector2, col: Color, n: int) -> void:
	for i in n:
		var a := randf() * TAU
		particules.append({"pos": pos, "vel": Vector2(cos(a), sin(a) - 0.6) * randf_range(200.0, 600.0),
			"vie": randf_range(0.32, 0.8), "col": col, "r": randf_range(3.0, 7.0)})


func _texte(pos: Vector2, s: String, col: Color, taille: int) -> void:
	textes.append({"pos": pos, "txt": s, "col": col, "vie": 1.1, "taille": taille})


# ─────────────────────────────────────────────────────────────
# Interface : la réserve, l'aide, les outils de test
# ─────────────────────────────────────────────────────────────

func _ui() -> void:
	# 🔴 Le cadre du bas refait (FEATURES ⑮, 26/09) : la réserve, plus propre — l'anneau autour de la
	#    pièce se remplit jusqu'à la suivante —, et à la place du « Dernier gain », le plateau du jour.
	var p := Style.panneau(self, Rect2(30, 1478, 1020, 262), Color(0.035, 0.05, 0.045, 0.86), 34)
	Style.libelle(p, "RÉSERVE", Rect2(44, 30, 400, 30), "etiquette", 22, Style.OR_FILET, HORIZONTAL_ALIGNMENT_LEFT, 5)
	anneau = Control.new()
	anneau.position = Vector2(34, 80)
	anneau.size = Vector2(150, 150)
	anneau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anneau.draw.connect(func():
		var c := Vector2(75, 75)
		anneau.draw_arc(c, 69.0, 0.0, TAU, 72, Color(0.81, 0.68, 0.43, 0.18), 9.0, true)
		if GS.main_pieces > 0:
			anneau.draw_arc(c, 69.0, 0.0, TAU, 72, Style.OR_VIF, 9.0, true))
	p.add_child(anneau)
	ico_reserve = Style.icone(anneau, tex_pieces[0], Rect2(21, 21, 108, 108))
	ico_reserve.pivot_offset = Vector2(54, 54)
	var ligne := HBoxContainer.new()
	ligne.position = Vector2(206, 92)
	ligne.size = Vector2(280, 100)
	ligne.alignment = BoxContainer.ALIGNMENT_BEGIN
	ligne.add_theme_constant_override("separation", 10)
	ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(ligne)
	lbl_main = _chiffre_or(ligne, 78)
	var sep := ColorRect.new()
	sep.color = Style.OR_FILET_2
	sep.position = Vector2(500, 42)
	sep.size = Vector2(2, 178)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(sep)
	# 🔴 Le plateau du jour (28/09, ⑧) : ses 12 objets, connus d'avance — l'étoile, les 3 pierres du jour, les
	#    8 poussières ; ceux qu'on a gagnés s'éteignent. Tout gagné : « Revient demain ».
	var x0 := 536.0
	Style.libelle(p, "PLATEAU DU JOUR", Rect2(x0, 30, 460, 30), "etiquette", 22, Style.OR_FILET, HORIZONTAL_ALIGNMENT_LEFT, 5)
	icones_pj = []
	for i in Plateau.total():
		var ic := Style.icone(p, Style.objet("poussiere-etoile"), Rect2(x0 + (i % 6) * 64.0, 74.0 + (i / 6) * 76.0, 58, 58))
		ic.pivot_offset = Vector2(29, 29)
		icones_pj.append(ic)
	lbl_pj_fin = Style.libelle(p, "Revient demain", Rect2(x0, 74, 380, 134), "italique", 44, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_pj_fin.add_theme_color_override("font_outline_color", Color("#0b0a10"))
	lbl_pj_fin.add_theme_constant_override("outline_size", 10)
	# le « + » : un plateau de plus (l'achat viendra avec la boutique, point ⑱)
	var plus := Button.new()
	plus.text = "+"
	plus.position = Vector2(x0 + 388, 170)
	plus.size = Vector2(72, 72)
	plus.add_theme_font_override("font", Style.police("normal"))
	plus.add_theme_font_size_override("font_size", 54)
	var rond := Style.boite(Color("#e6bf6c"), 36, Color("#7d5a22"), 3)
	rond.shadow_color = Color("#6b4a18")
	rond.shadow_size = 0
	rond.shadow_offset = Vector2(0, 6)
	rond.content_margin_bottom = 8
	for etat in ["normal", "hover", "pressed", "hover_pressed"]:
		plus.add_theme_stylebox_override(etat, rond)
	plus.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		plus.add_theme_color_override(c, Style.TEXTE_SUR_OR)
	p.add_child(plus)
	Style.jeu(plus)
	plus.pressed.connect(func(): Style.bulle(plus, "Trois cœurs d'étoile allument une Nouvelle machine (tu en as %d) — bientôt" % GS.coeurs))
	_maj_plateau_jour(false)

	var aide := HBoxContainer.new()
	aide.position = Vector2(0, 1762)
	aide.size = Vector2(1080, 70)
	aide.alignment = BoxContainer.ALIGNMENT_CENTER
	aide.add_theme_constant_override("separation", 16)
	aide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aide)
	var touche := Style.icone(aide, Style.texture("res://interface/toucher.svg"), Rect2(0, 0, 56, 56))
	touche.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_hint = Style.libelle(aide, "", Rect2(0, 0, 10, 70), "italique", 40, Style.SOURD)

	# Outils de test (dette D1) : cachés, un appui long sur l'onglet « La Poussette » les montre.
	outils = Control.new()
	outils.position = Vector2(0, 1856)
	outils.size = Vector2(1080, 330)
	outils.visible = false
	add_child(outils)
	Style.libelle(outils, "OUTILS DE TEST", Rect2(46, 0, 600, 36), "etiquette", 22, Style.SOURD, HORIZONTAL_ALIGNMENT_LEFT, 5)
	var b50 := Style.bouton(outils, "+50 pièces", Rect2(46, 46, 320, 104), false, 38)
	b50.pressed.connect(func():
		GS.main_pieces += 50
		GS.save_game()
		_maj_main())
	var bg := Style.bouton(outils, "Regarnir", Rect2(384, 46, 320, 104), false, 38)
	bg.pressed.connect(func():
		_garnir()
		_sauver())
	var braz := Style.bouton(outils, "RAZ", Rect2(722, 46, 312, 104), false, 38)
	braz.pressed.connect(func():
		PhysicsServer3D.set_active(true)
		GS.reset_tout()
		get_tree().reload_current_scene())
	var bsn := Style.bouton(outils, "Supernova", Rect2(46, 164, 320, 90), false, 36)     # (30/09) la voir tout de suite
	bsn.pressed.connect(func():
		if supernova_t <= 0.0:
			declencher_supernova())
	# (02/10) le décor de la machine, pour essayer les thèmes : un appui, le suivant (la machine se recharge, le tas gardé)
	bouton_decor = Style.bouton(outils, "Décor", Rect2(384, 164, 650, 90), false, 36)     # (son nom : _installer_decor)
	bouton_decor.pressed.connect(_decor_suivant)
	lbl_perf = Style.libelle(outils, "", Rect2(46, 266, 988, 44), "normal", 28, Style.SOURD)
	_maj_main()


func _decor_suivant() -> void:
	Reglages.decor_machine = MACHINE_DECOR.suivant(MACHINE_DECOR.theme)
	Reglages.sauver()
	if decor_peint != null:
		decor_peint.achever_pluie()
	if pieces.size() > 0:
		_sauver()
	PhysicsServer3D.set_active(true)
	rouvrir_outils = true
	get_tree().reload_current_scene()


func montrer_outils(v: bool) -> void:
	outils.visible = v


func _maj_main(arrivee := false) -> void:
	lbl_main.text = str(maxi(0, GS.main_pieces - _reserve_retenue))
	anneau.queue_redraw()
	if arrivee:
		var tw := ico_reserve.create_tween()
		tw.tween_property(ico_reserve, "scale", Vector2(1.18, 1.18), 0.08)
		tw.tween_property(ico_reserve, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if GS.main_pieces > 0:
		_indice("Glisse le doigt pour lâcher tes pièces." if decor_peint != null else "Glisse le doigt sur le bloc pour lâcher tes pièces.",
			Style.SOURD)


# Un chiffre de jeu : or, cerclé de sombre.
func _chiffre_or(parent: Control, taille: int) -> Label:
	var l := Style.libelle(parent, "", Rect2(0, 0, 10, 100), "normal", taille, Style.OR_VIF)
	l.add_theme_color_override("font_outline_color", Color("#1a1208"))
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_y", 5)
	return l


func _maj_plateau_jour(anime: bool) -> void:
	var l := Plateau.liste()
	var fini := Plateau.restants() == 0
	for i in mini(l.size(), icones_pj.size()):
		var ic: TextureRect = icones_pj[i]
		var gagne := bool(l[i]["gagne"])
		ic.texture = Style.objet(str(l[i]["image"]))
		var avant := ic.modulate.a
		ic.modulate = Color(1, 1, 1, 0.22 if gagne else 1.0) if not fini else Color(1, 1, 1, 0.12)
		# celui qu'on vient de gagner fait un petit bond avant de s'éteindre
		if anime and gagne and avant > 0.5:
			ic.scale = Vector2(1.3, 1.3)
			ic.create_tween().tween_property(ic, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lbl_pj_fin.visible = fini


# TOUT LE PLATEAU DU JOUR EST POSÉ (29/09 — Maxim : « mettre toutes les récompenses dispo directement sur le plateau, pas 3
# qu'on fait réapparaître ; quand un objet tombe, il tombe avec un petit amas de pièces qui fait un bruit plus lourd de plein
# de pièces qui tombent, c'est la sensation addictive qu'on cherche ») — au garnissage, au chargement, à minuit. Ce qui est
# déjà sur le tas compte. Où (Plateau.a_poser) : le ticket au fond ; les pierres rangées derrière ; la moitié des pierres
# n'importe où ; les poussières (l'XP) devant. Chaque objet est posé sur son AMAS : quelques pièces en couronne sous lui,
# qui partent avec lui.
# 🔴 L'AMAS NE DONNE PAS DE PIÈCES : sur une machine déjà garnie (un nouveau jour), ses pièces sont PRISES sur le plateau et
#    glissées sous l'objet — sinon chaque jour en offrait 60 (12 × 5), de quoi vider le plateau à moitié prix. Seule une
#    machine neuve (ou presque vide) les crée, et _garnir les compte dans ses 225.
# 🔴 LES BANDES SONT LE PRIX (banc du 29/09, sim_poussoir) : tout posé près du bord, le plateau se vidait pour 83 pièces
#    nettes au lieu de 123 à 175 (l'économie du 28/09 : ~200 pièces par jour) ; plus au fond, il retrouve son prix.
#    ⛔ Pas en frottant plus le plateau : il faut alors un tas plus haut pour que ça tombe, la machine touche son plafond
#    (MAX_PIECES) et se bloque, et les pièces avancent au compte-gouttes (des paquets plus PETITS — mesuré à 0,3 et 0,5).
const AMAS := 5
# 🔴 LE BLOC DU HAUT PRESQUE VIDE (29/09 — Maxim : « sur la poussette en haut, ne laisse que 4-5 pièces pas plus, comme ça
#    ça pousse le joueur à en mettre plus pour les faire tomber ») : une machine neuve n'y pose que SUR_BLOC pièces (avant :
#    15 % du garnissage, ~34) ; et chaque nouveau jour, les amas se font D'ABORD avec les pièces en trop sur le bloc.
const SUR_BLOC := 5
const AMAS_MARGE := 30            # des amas CRÉÉS peuvent dépasser le plafond des pièces lâchées (MAX_PIECES), un peu
const BANDES := {"fond": Vector2(9.75, 10.0), "pierre": Vector2(9.85, 10.5), "hasard": Vector2(9.85, 12.4),
	"xp": Vector2(10.7, 12.1)}
var _garnissage := false          # _garnir pose une machine neuve : les amas y sont créés


func _completer_plateau() -> void:
	_jour_vu = Plateau.aujourdhui()
	var manque := Plateau.a_poser()
	for b in lots:
		if b.get_meta("gagne", false) or b.has_meta("bonus"):
			continue
		for i in manque.size():
			if str(manque[i]["k"]) == str(b.get_meta("lot")):
				manque.remove_at(i)
				break
	for m in manque:
		_poser_avec_amas(str(m["k"]), BANDES[str(m["place"])])


# Une place libre dans la bande (le plus loin des autres objets, en 30 essais), l'amas, puis l'objet dessus.
func _poser_avec_amas(k: String, bande: Vector2) -> void:
	var r: float = lot_def(k)["r"]
	var meilleure := Vector2(randf_range(X0 + 1.0, X1 - 1.0), randf_range(bande.x, bande.y))
	var ecart_max := -INF
	for essai in 30:
		var c := Vector2(randf_range(X0 + r + 0.5, X1 - r - 0.5), randf_range(bande.x, bande.y))
		var ecart := INF
		for b in lots:
			if not b.get_meta("gagne", false):
				ecart = minf(ecart, Vector2(b.position.x - c.x, b.position.z - c.y).length() - r - float(b.get_meta("r")))
		if ecart > ecart_max:
			ecart_max = ecart
			meilleure = c
		if ecart > 0.45:
			break
	# les pièces de l'amas : d'abord celles en trop sur le bloc du haut (il redescend à SUR_BLOC), puis sur le plateau (loin
	# des objets) ; créées seulement sur une machine neuve
	var libres: Array = []
	if not _garnissage:
		var sur_bloc: Array = []
		for q in pieces:
			if q.position.z < face_z and q.position.z > MUR - 0.5 and q.position.y > H_BLOC * 0.5 and not q.get_meta("amas", false):
				sur_bloc.append(q)
		sur_bloc.shuffle()
		libres = sur_bloc.slice(SUR_BLOC)
	if not _garnissage and pieces.size() > 120:
		var du_plateau: Array = []
		for q in pieces:
			if q.position.z > MILIEU + COURSE + 0.3 and q.position.z < BORD - 0.8 and not q.get_meta("amas", false):
				var loin := true
				for b in lots:
					loin = loin and Vector2(b.position.x - q.position.x, b.position.z - q.position.z).length() > float(b.get_meta("r")) + 0.9
				if loin:
					du_plateau.append(q)
		du_plateau.shuffle()
		libres.append_array(du_plateau)
	var n := AMAS if libres.size() >= AMAS else clampi(MAX_PIECES + AMAS_MARGE - pieces.size(), 0, AMAS)
	for i in n:
		var a := TAU * i / maxf(1.0, n) + randf_range(-0.3, 0.3)
		var px := meilleure.x + cos(a) * r * 0.6
		var pz := meilleure.y + sin(a) * r * 0.6
		var h := _hauteur_libre(px, pz, R_PIECE, EP_PIECE * 0.5 + 0.01)
		var q: RigidBody3D
		if i < libres.size():
			q = libres[i]
			q.position = Vector3(px, h, pz)
			q.rotation = Vector3(0.0, randf() * TAU, 0.0)
			q.linear_velocity = Vector3.ZERO
			q.angular_velocity = Vector3.ZERO
		else:
			q = _piece(Vector3(px, h, pz))
		q.set_meta("amas", true)
	_lot(k, Vector3.INF, meilleure)



# ─────────────────────────────────────────────────────────────
# LA SUPERNOVA (30/09 — le « Furax » de Maxim ; DECISIONS 30/09). Les pièces tombées dans les fentes remplissent une jauge
# (la frise de lunes s'allume, une lune après l'autre) ; pleine : 30 s où la machine s'emballe — le poussoir ×2, une pluie
# de pièces OFFERTES sur le bloc, tout ce qui tombe devant compte double —, et un CŒUR D'ÉTOILE tombe sur le plateau à la
# fin (trois allument une Nouvelle machine). L'animation : supernova_fx.gd. Le son : Son.supernova.
# 🔴 (02/10) Dans le décor peint (machines/machine_decor.gd) — Maxim : « pas assez spectaculaire », « il n'y a pas de
#    récompense sur le plateau » : la pluie (offerte, toujours PLUIE_SUPERNOVA pièces) et le cœur d'étoile JAILLISSENT de
#    l'astrolabe et volent jusqu'au plateau, devant le bloc, dès le début ; le décor a sa propre animation.
# 🔴 (02/10 au soir — DECISIONS 02/10) PLUS DE MODE DE 30 S — Maxim : « le cœur d'étoile est impossible à avoir dans les
#    30 secondes […] ou alors on laisse tomber les 30 secondes, on fait tomber plein de pièces, le cœur et d'autres
#    poussières d'étoile ». La Supernova est un GROS LOT, d'un coup : le spectacle (~6 s : SUPERNOVA_S), la pluie d'or, des
#    poussières d'étoile offertes (hors du plateau du jour : la méta « bonus ») et le cœur ; plus de poussoir ×2, plus de
#    « tout compte double », plus de compte à rebours. Et ses pièces ne bloquent pas le joueur (marge_supernova :
#    « en mode Supernova, c'est frustrant d'être bloqué » — la machine vit près de son plafond, la pluie le dépassait).
# 🔴 Réglée au banc (sim_poussoir : les Supernovas par minute) — JAUGE_SUPERNOVA.
# ─────────────────────────────────────────────────────────────
const JAUGE_SUPERNOVA := 150
const SUPERNOVA_S := 6.0              # le spectacle, jusqu'au cœur posé (la jauge ne se remplit pas pendant)
const PLUIE_SUPERNOVA := 36
const POUSSIERES_SUPERNOVA := 3
var supernova_t := 0.0            # le temps qui reste du spectacle (0 : pas de Supernova)
var marge_supernova := 0          # les pièces offertes au-dessus du plafond : le joueur peut lâcher par-dessus
var supernovas := 0               # combien depuis l'ouverture (le banc les compte)
var _pluie := 0
var _pluie_t := 0.0
var _jauge_vue := -1
var jauge2d: Control
var supernova_fx: SupernovaFx


func _nourrir_jauge() -> void:
	if supernova_t > 0.0:
		return                    # pendant la Supernova, la jauge ne se remplit pas
	GS.jauge_supernova += 1
	GS.demander_sauvegarde()
	if GS.jauge_supernova >= JAUGE_SUPERNOVA:
		declencher_supernova()


func declencher_supernova() -> void:
	GS.jauge_supernova = 0
	supernova_t = SUPERNOVA_S
	supernovas += 1
	_pluie = PLUIE_SUPERNOVA
	_pluie_t = 0.4
	GS.demander_sauvegarde()
	marge_supernova = PLUIE_SUPERNOVA
	if decor_peint != null:
		_pluie = 0
		decor_peint.supernova(PLUIE_SUPERNOVA, POUSSIERES_SUPERNOVA, is_visible_in_tree())
		if is_visible_in_tree():
			Son.supernova(true)          # (la vibration : à l'explosion, machine_decor._eclater)
		return
	if is_visible_in_tree():
		Son.supernova()
		supernova_fx.lancer(SUPERNOVA_S)
		Reglages.vibrer(120)


# Chaque pas de physique pendant la Supernova : la pluie (une pièce offerte tous les dixièmes, sur le bloc), le temps.
func _tic_supernova(delta: float) -> void:
	supernova_t -= delta
	_pluie_t -= delta
	if _pluie > 0 and _pluie_t <= 0.0:
		_pluie_t = 0.1
		_pluie -= 1
		var z := randf_range(MUR + R_PIECE + 0.05, face_z - R_PIECE - 0.05)
		var b := _lacher(randf_range(X0 + R_PIECE, X1 - R_PIECE), z)
		if b != null:
			_sonner_a_la_pose(b)
	if supernova_t <= 0.0:
		supernova_t = 0.0
		_fin_supernova()


# La fin : le cœur d'étoile tombe au milieu du plateau (il faudra le pousser jusqu'au bord). Dans le décor peint, il est
# sorti de l'astrolabe au début (s'il n'a pas pu, il tombe maintenant) ; les lunes s'éteignent.
func _fin_supernova() -> void:
	if decor_peint != null:
		decor_peint.fin_supernova()
		return
	var x := randf_range(X0 + 2.0, X1 - 2.0)
	_lot("coeur-etoile", Vector3(x, 1.6, randf_range(10.6, 11.6)))
	if is_visible_in_tree():
		Son.sonner("recevoir")


func _gagner_coeur(pos: Vector2) -> void:
	GS.coeurs += 1
	GS.demander_sauvegarde()
	Son.objet_tombe()
	Son.objet("etoile")
	_eclat(pos, lot_def("coeur-etoile")["col"], 40)
	_texte(pos + Vector2(0, -40), "Cœur d'étoile  %d / 3" % mini(GS.coeurs, 3) if GS.coeurs <= 3 else "Cœur d'étoile  %d" % GS.coeurs,
		Style.OR_VIF, 46)
	_maj_plateau_jour(true)


# Combien de lunes allumées (0 à 9) ; toutes pendant la Supernova.
func _lunes_allumees() -> int:
	if supernova_t > 0.0:
		return 9
	return clampi(GS.jauge_supernova * 9 / JAUGE_SUPERNOVA, 0, 9)


# La jauge, par-dessus la frise : une lune allumée devient pleine et vive, cerclée net ; pendant la Supernova, elles
# pulsent toutes. (Pas de halo flou : les goûts de Maxim.)
func _dessiner_jauge() -> void:
	var v := jauge2d
	var n := _lunes_allumees()
	_jauge_vue = n
	var cx := (X0 + X1) * 0.5 * U
	var cy := CADRE.position.y + 18.0 + 118.0 + 96.0
	var pulse := 0.75 + 0.25 * sin(horloge * 9.0) if supernova_t > 0.0 else 1.0
	for i in n:
		var c := Vector2(cx + 54.0 * (i - 4), cy)
		v.draw_circle(c, 14.0, Color(Style.OR_VIF, pulse))
		v.draw_arc(c, 19.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.75, 0.9 * pulse), 2.5, true)


# ─────────────────────────────────────────────────────────────
# Le dessin, en perspective oblique : la hauteur remonte à l'écran.
# 🔴 En couches (25/09) : le fond et le fronton sont dessinés UNE fois ; seul le bloc
#    (quelques rectangles) et les effets se redessinent à chaque image ; les pièces et
#    les objets sont rendus en 3D par MachineRendu. Avant, tout se redessinait à chaque
#    image depuis GDScript : ~6 ms sur le PC, le premier poste de la poussette.
# ─────────────────────────────────────────────────────────────

func _ecran(x: float, z: float, h: float) -> Vector2:
	return Vector2(x * U, z * U - h * U * K_H)


func _dessiner_decor() -> void:
	var v := decor
	var ci := v.get_canvas_item()
	sb_cadre.draw(ci, CADRE)
	sb_filet.draw(ci, CADRE.grow(-14.0))
	for y in [CADRE.position.y, CADRE.end.y]:
		_losange(v, Vector2(CADRE.get_center().x, y), 11.0)
	# le plateau est un miroir du ciel
	var haut := _ecran(0.0, MILIEU - COURSE - 0.6, 0.0).y
	var r := Rect2(X0 * U - 8.0, haut, (X1 - X0) * U + 16.0, BORD * U - haut)
	v.draw_rect(r, Color("#08110f"), true)
	v.draw_texture_rect(tex_etoiles, r, true, Color(1, 1, 1, 0.5))
	for i in 6:
		var t := float(i) / 5.0
		var a := 0.16 * (1.0 - t)
		v.draw_rect(Rect2(r.position.x + t * 26.0, r.position.y, 26.0, r.size.y), Color(0, 0, 0, a), true)
		v.draw_rect(Rect2(r.end.x - (t + 1.0) * 26.0, r.position.y, 26.0, r.size.y), Color(0, 0, 0, a), true)
	# (29/09 : plus de lignes « banal, normal, rare » — tout le plateau du jour est posé, le ticket au fond, des pierres au
	#  hasard : les objets disent eux-mêmes où ils sont)
	# les fentes, le long des côtés, à l'avant : du noir, un filet d'or sur leur lèvre
	for gauche in [true, false]:
		var fx := X0 * U - 8.0 if gauche else (X1 - fente) * U
		var fw := fente * U + 8.0
		var fr := Rect2(fx, fente_z0 * U, fw, (fente_z1 - fente_z0) * U)
		v.draw_rect(fr, Color(0, 0, 0), true)
		var lx := fr.end.x if gauche else fr.position.x
		v.draw_line(Vector2(lx, fr.position.y), Vector2(lx, fr.end.y), Color(Style.OR, 0.75), 3.0)
		v.draw_line(Vector2(fr.position.x, fr.position.y), Vector2(fr.end.x, fr.position.y), Color(Style.OR, 0.75), 3.0)
		v.draw_line(Vector2(fr.position.x, fr.end.y), Vector2(fr.end.x, fr.end.y), Color(Style.OR, 0.75), 3.0)
	# la gouttière
	var x := X0 * U - 8.0
	var w := (X1 - X0) * U + 16.0
	v.draw_texture_rect(tex_jade_monte, Rect2(x, BORD * U - 84.0, w, 84.0), false, Color(1, 1, 1, 0.4))
	v.draw_rect(Rect2(x, BORD * U + 2.0, w, 32.0), Color(0.02, 0.035, 0.03), true)


func _losange(v: Control, c: Vector2, r: float) -> void:
	v.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]),
		Style.OR)


# Le dessus du bloc, ivoire, puis sa face avant dorée : la marche qu'on voit.
func _dessiner_bloc() -> void:
	var v := bloc2d
	var haut_bloc := _ecran(0.0, MUR - 0.4, H_BLOC).y
	var face_haut := _ecran(0.0, face_z, H_BLOC).y
	var face_bas := _ecran(0.0, face_z, 0.0).y
	var dessus := Rect2(X0 * U, haut_bloc, (X1 - X0) * U, face_haut - haut_bloc)
	if style_bloc == "ivoire" or not tex_blocs.has(style_bloc):
		v.draw_rect(dessus, Color("#f1ebdf"))
		v.draw_rect(Rect2(X0 * U + 18.0, haut_bloc, (X1 - X0) * U - 36.0, face_haut - haut_bloc - 14.0),
			Color(0.72, 0.57, 0.25, 0.5), false, 2.0)
	else:
		# la matière est ancrée sur la face avant : elle glisse avec le bloc, sous le fronton
		var tex: Texture2D = tex_blocs[style_bloc]
		var k := dessus.size.x / float(tex.get_width())
		var vu := minf(dessus.size.y / k, float(tex.get_height()))
		v.draw_texture_rect_region(tex, dessus, Rect2(0, float(tex.get_height()) - vu, float(tex.get_width()), vu))
		v.draw_rect(Rect2(X0 * U + 18.0, haut_bloc, (X1 - X0) * U - 36.0, face_haut - haut_bloc - 14.0),
			Style.OR_FILET, false, 3.0)
	v.draw_texture_rect(tex_face, Rect2(X0 * U, face_haut, (X1 - X0) * U, face_bas - face_haut), false)
	for i in 8:
		var t := float(i) / 7.0
		v.draw_rect(Rect2(X0 * U, face_bas + t * 40.0, (X1 - X0) * U, 7.0), Color(0, 0, 0, 0.3 * (1.0 - t)))


# Le fronton, par-dessus le bloc qui glisse dessous : dessiné une fois.
func _dessiner_fronton() -> void:
	var v := fronton2d
	var ci := v.get_canvas_item()
	var bas := _ecran(0.0, MUR, H_BLOC + 0.02).y
	var r := Rect2(X0 * U - 8.0, CADRE.position.y + 18.0, (X1 - X0) * U + 16.0, bas - CADRE.position.y - 18.0)
	sb_fronton.draw(ci, r)
	v.draw_texture_rect(tex_etoiles, r.grow(-8.0), true, Color(1, 1, 1, 0.55))
	var c := Vector2((X0 + X1) * 0.5 * U, r.position.y + 118.0)
	var f := Style.police("italique")
	var nom := "La Poussette"
	var w := f.get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1, 84).x
	v.draw_string(f, Vector2(c.x - w * 0.5, c.y + 26.0), nom, HORIZONTAL_ALIGNMENT_LEFT, -1, 84, Color(Style.IVOIRE, 0.94))
	_frise_lunes(v, c.x, c.y + 96.0)
	v.draw_rect(Rect2(r.position.x, bas - 26.0, r.size.x, 26.0), Color("#060908"), true)
	v.draw_rect(Rect2(r.position.x, bas - 28.0, r.size.x, 2.0), Style.OR_FILET, true)
	v.draw_rect(Rect2(r.position.x, bas - 3.0, r.size.x, 3.0), Style.OR, true)
	for i in 6:
		var t := float(i) / 5.0
		v.draw_rect(Rect2(X0 * U, bas + t * 20.0, (X1 - X0) * U, 4.0), Color(0, 0, 0, 0.26 * (1.0 - t)), true)


# Neuf lunes incrustées d'or, de la nouvelle à la nouvelle.
func _frise_lunes(v: Control, cx: float, cy: float) -> void:
	var suite := [0.0, 0.25, 0.5, 0.75, 1.0, -0.75, -0.5, -0.25, 0.0]
	for i in suite.size():
		var c := Vector2(cx + 54.0 * (i - 4), cy)
		_lune(v, c + Vector2(1.5, 2.0), 13.0, suite[i], Color(0.42, 0.30, 0.10, 0.35))
		_lune(v, c, 13.0, suite[i], Style.OR)


# k : la part éclairée, de 0 (nouvelle) à 1 (pleine) ; négatif : la lune décroît.
func _lune(v: Control, c: Vector2, r: float, k: float, col: Color) -> void:
	v.draw_arc(c, r, 0.0, TAU, 32, col, 1.6, true)
	var fk := absf(k)
	if fk < 0.001:
		return
	if fk > 0.999:
		v.draw_circle(c, r, col)
		return
	var cote := 1.0 if k > 0.0 else -1.0
	var rx := (1.0 - 2.0 * fk) * r
	var pts := PackedVector2Array()
	var n := 20
	for j in n + 1:
		var a := -PI * 0.5 + PI * float(j) / n
		pts.append(c + Vector2(cos(a) * r * cote, sin(a) * r))
	for j in range(1, n):
		var a2 := PI * 0.5 - PI * float(j) / n
		pts.append(c + Vector2(cos(a2) * rx * cote, sin(a2) * r))
	v.draw_colored_polygon(pts, col)


# Les étincelles qui montent du bord, les éclats d'un gain, les « +3 ».
func _dessiner_effets() -> void:
	var v := effets
	for pt in particules:
		var c: Color = pt["col"]
		if pt.get("monte", false):
			var vie0 := float(pt["vie0"])
			var al := clampf((vie0 - float(pt["vie"])) / 0.3, 0.0, 1.0) * clampf(float(pt["vie"]) / 0.8, 0.0, 1.0)
			v.draw_circle(pt["pos"], float(pt["r"]) * 0.6, Color(c, 0.8 * al))
		else:
			var a := clampf(float(pt["vie"]) / 0.80, 0.0, 1.0)
			v.draw_circle(pt["pos"], float(pt["r"]) * a, Color(c, a))
	var f := Style.police("fort")
	for tx in textes:
		var a2: float = clampf(float(tx["vie"]) / 1.1, 0.0, 1.0)
		var c2: Color = tx["col"]
		var ta: int = int(tx["taille"])
		var lw := f.get_string_size(str(tx["txt"]), HORIZONTAL_ALIGNMENT_LEFT, -1, ta).x
		v.draw_string(f, Vector2(float(tx["pos"].x) - lw * 0.5, float(tx["pos"].y)),
			str(tx["txt"]), HORIZONTAL_ALIGNMENT_LEFT, -1, ta, Color(c2, a2))
