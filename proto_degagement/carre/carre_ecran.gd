class_name CarreEcran
extends Control

# ─────────────────────────────────────────────────────────────
# LE COMBAT : LE CARRÉ DES ASTRES (FEATURES ②, 27/09).
#
# Plein écran, sur le ciel du jeu (ni bandeau ni barre) : en haut l'adversaire et sa main
# (tout se voit), le score, le tapis de la fabrique (design/objets/render_carre.py), la bande
# qui dit ce qui vient de se passer, et ta main. On touche une carte puis une case, ou on la
# fait glisser. Chaque événement du moteur (carre/moteur_carre.gd) est montré dans l'ordre,
# cause puis effet : la pose, le pouvoir, les deux chiffres qui s'affrontent, le retournement.
#
# Maxim, 26/09 : « les looks doivent être design pro d'un jeu HD » — ni trait peint, ni icône
# plate : les pierres, les emblèmes et le tapis sont rendus en relief ; les étoiles sont
# celles de la couche d'effets du jeu (nettes, sans halo).
# ─────────────────────────────────────────────────────────────

signal fini(resultat: Dictionary)
signal quitte

const TAPIS_POS := Vector2(34, 304)
const TAPIS_TAILLE := Vector2(1012, 1372)
const CASE := Vector2(300, 420)
const ECART := 20.0
const CADRE := 36.0
const MARGE_CADRE := 14.0          # les cadres de case débordent de 14 px (render_carre.py)
const MAIN_Y := 2046.0
# 🔴 LES CHIFFRES DE LA MAIN SE LISENT (29/09 — la femme du cousin : « elle avait du mal à voir les numéros sur les
#    cartes ») : la main a gagné sa largeur (196 px au lieu de 186, 12 d'écart au lieu de 20), et surtout la carte
#    qu'on touche GROSSIT à la taille du plateau (LOUPE : 280 px, ×1,43), soulevée — ses chiffres comme ceux des cases.
#    La main adverse (78 px, illisible) descend en grand quand on la touche (MAIN_ADV_GRANDE).
const MAIN_L := 196.0
const MAIN_ECART := 12.0
const MAIN_ECHELLE := MAIN_L / 280.0
const LOUPE := 1.0
const LOUPE_LEVE := 30.0            # la carte agrandie monte d'autant (son bas reste au-dessus du bord de l'écran)
const MAIN_ADV_ECHELLE := 78.0 / 280.0
const MAIN_ADV_GRANDE := MAIN_L / 280.0
const MAIN_ADV_GRANDE_Y := 330.0
const JADE := Color("#7fd0b0")
const CARMIN := Color("#ec8f9a")

# Le premier combat, guidé (Maxim joue sans lire) : des cartes prêtées, pas de terre, et un coup
# de l'adversaire écrit d'avance pour que le deuxième coup retourne sa carte (10 contre 3).
const DECK_TUTO := [{"id": "golem", "s": 1, "v": "or"}, {"id": "kitsune", "s": 1, "v": "prisme"},
	{"id": "bahamut", "s": 1, "v": "elem"}, {"id": "thor", "s": 1, "v": "full"}, {"id": "doudou", "s": 1, "v": "base"}]
const ADV_TUTO := {"nom": "Wukong l'espiègle", "prenom": "Wukong", "niveau": "apprenti", "chef": "wukong", "chef_s": 1, "tuto": true,
	"deck": [{"id": "farfadet", "s": 1, "v": "base"}, {"id": "nian", "s": 1, "v": "base"}, {"id": "draugr", "s": 1, "v": "base"},
		{"id": "oni", "s": 1, "v": "base"}, {"id": "wukong", "s": 1, "v": "base"}]}
const TUTO_CASE_1 := 4          # Golem au centre
const TUTO_COUP_IA := [1, 5]    # Nian à sa droite (4 contre 5 : il ne prend rien)
const TUTO_CASE_2 := 2          # Kitsune au-dessus de Nian : son 10 contre le 3 de Nian
const GUIDE_Y := 1800.0         # la consigne : entre la bande et la main (agrandie : 29/09), sans rien recouvrir

var st: Dictionary = {}
var hasard: MoteurCarre.Hasard
var adversaire: Dictionary = {}    # {nom, niveau, chef, chef_s, deck} ; un niveau de l'Aventure a aussi n, terres, defi…
var bandeau: Bandeau               # à la fin d'un niveau, les gains s'y envolent (main.gd le montre par-dessus)
var montrer_bandeau := Callable()
var tour := "j"
var journal: Array = []            # un élément par coup : {camp, case, id, ev} — les défis de l'Aventure s'y lisent
var occupe := true
var choisie := -1
var termine := false

var _cases: Array = []             # par case : {pos, jade, rose, cible, gel, gemme, gemme_lib, carte}
var _main_j: Array = []            # CarteCarre
var _main_a: Array = []            # CarteCarre
var _couche_cartes: Control
var _score_j: Label
var _score_a: Label
var _statut: Label
var _bande_icone: Control
var _bande_embleme: TextureRect
var _bande_texte: RichTextLabel
var _glisse := {}                  # la carte qu'on fait glisser : {k, depart, decal (son centre moins le doigt), bouge}
var _loupe := -1                   # la carte de ta main sous le doigt (pas encore lâchée) : agrandie
var _cascade_coup := 0             # (29/09, le son) les cartes retournées dans ce coup : chacune sonne une note plus haut
var _adv_grande := false           # la main adverse, descendue en grand
var _voile_adv: ColorRect          # sous elle, le plateau s'assombrit
var _survol := -1                  # la case où elle tomberait si on la lâchait
var _t := 0.0
var tuto := false
var _tuto_etape := 0
var _permis := {"carte": -1, "case": -1}   # pendant le guide : le seul geste accepté (-1 : tout)
var _guide: GuideCarre


# ─────────────────────────────────────────────────────────────
# La mise en place
# ─────────────────────────────────────────────────────────────

func lancer(deck_j: Array, p_adversaire: Dictionary, graine: int, premier := "j") -> void:
	adversaire = p_adversaire
	hasard = MoteurCarre.Hasard.new(graine)
	st = MoteurCarre.nouvelle_partie(deck_j, adversaire["deck"], hasard, 3)
	tuto = bool(adversaire.get("tuto", false))
	if tuto:
		st["terres"] = {}
		premier = "j"
	elif adversaire.has("terres"):
		# un niveau de l'Aventure impose ses terres (aventure.gd) : toujours les mêmes
		st["terres"] = (adversaire["terres"] as Dictionary).duplicate()
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	await get_tree().create_timer(0.5).timeout
	if premier == "a":
		_tour_ia()
	else:
		_a_moi()


func _construire() -> void:
	# l'adversaire : son portrait dans un médaillon, son nom, son niveau, sa main
	var quitter := Style.bouton(self, "Quitter", Rect2(28, 64, 176, 84), false, 34)
	if adversaire.has("mode"):
		# 🔴 Au Duel et au Classé, quitter compte comme une défaite (arene.gd) : deux touches, pas une.
		quitter.pressed.connect(func():
			if quitter.text == "Sûr ?":
				quitte.emit()
				return
			quitter.text = "Sûr ?"
			Style.bulle(quitter, "Quitter compte comme une défaite")
			var tw := quitter.create_tween()          # (lié au bouton : il s'arrête avec lui)
			tw.tween_interval(2.5)
			tw.tween_callback(func(): quitter.text = "Quitter"))
	else:
		quitter.pressed.connect(func(): quitte.emit())
	var med := Control.new()
	med.position = Vector2(222, 38)
	med.size = Vector2(140, 140)
	med.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(med)
	_texture(med, "res://interface/medaillon-sombre.png", Rect2(Vector2.ZERO, med.size))
	_portrait(med, str(adversaire["chef"]), int(adversaire.get("chef_s", 1)), Rect2(Vector2(14, 14), Vector2(112, 112)))
	Style.libelle(self, _prenom(), Rect2(378, 58, 240, 64), "italique", 48, Style.IVOIRE)
	# sous son nom : son niveau (l'Aventure) ; sa cote (le Duel) ; la marche qu'on joue (le Classé)
	var sous := str(MoteurCarre.NIVEAUX[adversaire["niveau"]]).to_upper()
	if adversaire.get("mode", "") == "duel":
		sous = "COTE %s" % Style.nombre(int(adversaire.get("cote", 0)))
	elif adversaire.get("mode", "") == "classe":
		sous = Classe.nom_palier(int(adversaire.get("palier", 0))).to_upper()     # (« CLASSÉ · » mordait sur sa main)
	Style.libelle(self, sous, Rect2(380, 124, 240, 34), "etiquette", 22, Style.OR_VIF, HORIZONTAL_ALIGNMENT_LEFT, 4)

	# le score
	_score_j = Style.libelle(self, "Toi 0", Rect2(40, 208, 300, 80), "fort", 60, JADE)
	_score_a = Style.libelle(self, "0 Lui", Rect2(740, 208, 300, 80), "fort", 60, CARMIN, HORIZONTAL_ALIGNMENT_RIGHT)
	_statut = Label.new()
	_statut.add_theme_font_override("font", Style.police("etiquette", 4))
	_statut.add_theme_font_size_override("font_size", 25)
	_statut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_statut.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_statut.position = Vector2(330, 222)
	_statut.size = Vector2(420, 56)
	_statut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_statut)

	# le tapis, posé sur son ombre
	var ombre := Panel.new()
	ombre.position = TAPIS_POS
	ombre.size = TAPIS_TAILLE
	ombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.04, 1.0)
	sb.set_corner_radius_all(40)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 34
	sb.shadow_offset = Vector2(0, 16)
	ombre.add_theme_stylebox_override("panel", sb)
	add_child(ombre)
	_texture(self, "res://carre/tapis-carre.png", Rect2(TAPIS_POS, TAPIS_TAILLE))
	var n: int = st["n"]
	for i in n * n:
		var r := i / n
		var c := i % n
		var pos := TAPIS_POS + Vector2(CADRE + c * (CASE.x + ECART), CADRE + r * (CASE.y + ECART))
		var cadre_r := Rect2(pos - Vector2(MARGE_CADRE, MARGE_CADRE), CASE + Vector2(2 * MARGE_CADRE, 2 * MARGE_CADRE))
		var d := {"pos": pos}
		d["gel"] = _texture(self, "res://carre/case-gel.png", cadre_r)
		d["jade"] = _texture(self, "res://carre/case-jade.png", cadre_r)
		d["rose"] = _texture(self, "res://carre/case-rose.png", cadre_r)
		d["cible"] = _texture(self, "res://carre/case-cible.png", cadre_r)
		for k in ["gel", "jade", "rose", "cible"]:
			(d[k] as TextureRect).modulate.a = 0.0
		d["gemme"] = null
		d["carte"] = null
		if (st["terres"] as Dictionary).has(i):
			var ty := str(st["terres"][i])
			d["gemme"] = _texture(self, "res://objets/pierre-%s.png" % ty, Rect2(pos + CASE * 0.5 - Vector2(78, 108), Vector2(156, 156)))
			var nom_type := str(GS.TYPES[ty]["nom"]).to_upper()
			d["gemme_lib"] = Style.libelle(self, "%s  +1" % nom_type, Rect2(pos.x, pos.y + CASE.y * 0.5 + 60, CASE.x, 40), "etiquette", 24,
				(GS.TYPES[ty]["clair"] as Color), HORIZONTAL_ALIGNMENT_CENTER, 4)
		_cases.append(d)

	# la bande : ce qui vient de se passer, ou le pouvoir de la carte touchée
	var bande := Style.panneau(self, Rect2(34, 1696, 1012, 156), Color(0.035, 0.05, 0.047, 0.94), 30)
	_bande_icone = Control.new()
	_bande_icone.position = Vector2(26, 22)
	_bande_icone.size = Vector2(112, 112)
	_bande_icone.pivot_offset = _bande_icone.size * 0.5
	_bande_icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bande.add_child(_bande_icone)
	_texture(_bande_icone, "res://interface/medaillon-sombre.png", Rect2(Vector2.ZERO, _bande_icone.size))
	_bande_embleme = _texture(_bande_icone, "res://carre/pouvoir-foudre.png", Rect2(Vector2(24, 24), Vector2(64, 64)))
	_bande_texte = RichTextLabel.new()
	_bande_texte.bbcode_enabled = true
	_bande_texte.scroll_active = false
	_bande_texte.fit_content = false
	_bande_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bande_texte.position = Vector2(160, 20)
	_bande_texte.size = Vector2(826, 118)
	_bande_texte.add_theme_font_override("normal_font", Style.police("normal"))
	_bande_texte.add_theme_font_override("bold_font", Style.police("fort"))
	_bande_texte.add_theme_font_override("italics_font", Style.police("italique"))
	for k in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		_bande_texte.add_theme_font_size_override(k, 36)
	_bande_texte.add_theme_color_override("default_color", Style.IVOIRE)
	_bande_texte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bande.add_child(_bande_texte)
	_bande("", "[i]Touche une carte pour lire son pouvoir.[/i]")

	# les cartes : une seule couche, pour qu'elles volent de la main à la case sans changer de parent
	_couche_cartes = Control.new()
	_couche_cartes.size = size
	_couche_cartes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_couche_cartes)
	_voile_adv = ColorRect.new()
	_voile_adv.color = Color(0.01, 0.015, 0.02, 0.0)
	_voile_adv.position = Vector2(0, 290)
	_voile_adv.size = Vector2(1080, 1396)          # jusqu'à la bande, qui lit la carte touchée
	_voile_adv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_couche_cartes.add_child(_voile_adv)
	for c in st["main"]["a"]:
		var cc := _nouvelle_carte(c, "a")
		cc.scale = Vector2(MAIN_ADV_ECHELLE, MAIN_ADV_ECHELLE)
		_main_a.append(cc)
	for c in st["main"]["j"]:
		var cc := _nouvelle_carte(c, "j")
		cc.scale = Vector2(MAIN_ECHELLE, MAIN_ECHELLE)
		_main_j.append(cc)
	_ranger_mains(false)
	_maj_score()
	_guide = GuideCarre.new()
	add_child(_guide)


func _texture(parent: Control, chemin: String, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Style.texture(chemin)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.position = r.position
	t.size = r.size
	t.pivot_offset = r.size * 0.5
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


# Le portrait rond : l'illustration, recadrée sur la tête, dans le médaillon.
func _portrait(parent: Control, id: String, s: int, r: Rect2) -> void:
	var t := _texture(parent, "res://cartes/min/%s-%d.jpg" % [id, s], r)
	var m := ShaderMaterial.new()
	m.shader = preload("res://carre/portrait.gdshader")
	m.set_shader_parameter("region", VoyageEcran.REGION_VISAGE)
	t.material = m


func _nouvelle_carte(c: Dictionary, camp: String) -> CarteCarre:
	var cc := CarteCarre.new()
	_couche_cartes.add_child(cc)
	cc.configurer(c, camp)
	return cc


# Les mains : la tienne en bas, la sienne en haut à droite. La carte choisie, ou sous le doigt, se soulève et grandit à
# la taille du plateau (LOUPE) ; celle qu'on fait glisser suit le doigt, on n'y touche pas.
func _ranger_mains(anime := true) -> void:
	for k in _main_j.size():
		if _glisse.get("bouge", false) and k == _glisse["k"]:
			continue
		var cc: CarteCarre = _main_j[k]
		if k == choisie or k == _loupe:
			_couche_cartes.move_child(cc, -1)
			_placer(cc, _centre_loupe(k) - CarteCarre.TAILLE * 0.5, LOUPE, anime)
			continue
		# la carte tourne autour de son centre : on place son coin pour que son centre tombe au bon endroit
		_placer(cc, _rect_main(k).get_center() - CarteCarre.TAILLE * 0.5, MAIN_ECHELLE, anime)
	var na := _main_a.size()
	if _adv_grande:
		# descendue en grand, par-dessus le haut du plateau assombri
		var x0 := 540.0 - (na * MAIN_L + (na - 1) * MAIN_ECART) * 0.5
		for k in na:
			var ca: CarteCarre = _main_a[k]
			_couche_cartes.move_child(ca, -1)
			var centre := Vector2(x0 + k * (MAIN_L + MAIN_ECART) + MAIN_L * 0.5, MAIN_ADV_GRANDE_Y + MAIN_L * 0.7)
			_placer(ca, centre - CarteCarre.TAILLE * 0.5, MAIN_ADV_GRANDE, anime)
		return
	var la := 78.0
	var xa := 1046.0 - na * (la + 8.0) + 8.0
	for k in na:
		var ca: CarteCarre = _main_a[k]
		var pa := Vector2(xa + k * (la + 8.0), 52.0)
		_placer(ca, pa + Vector2(la, la * 1.4) * 0.5 - CarteCarre.TAILLE * 0.5, MAIN_ADV_ECHELLE, anime)


# La place d'une carte de ta main, au repos (non soulevée).
func _rect_main(k: int) -> Rect2:
	var nj := _main_j.size()
	var x0 := 540.0 - (nj * MAIN_L + (nj - 1) * MAIN_ECART) * 0.5
	return Rect2(Vector2(x0 + k * (MAIN_L + MAIN_ECART), MAIN_Y), Vector2(MAIN_L, MAIN_L * 1.4))


# Le centre d'une carte de ta main agrandie : au-dessus de sa place, sans sortir de l'écran.
func _centre_loupe(k: int) -> Vector2:
	var c := _rect_main(k).get_center() - Vector2(0, LOUPE_LEVE)
	var demi := CarteCarre.TAILLE.x * LOUPE * 0.5
	c.x = clampf(c.x, demi + 8.0, 1080.0 - demi - 8.0)
	return c


# La main adverse descend en grand (ou remonte) : le plateau s'assombrit dessous.
func _montrer_main_adv(v: bool) -> void:
	if _adv_grande == v:
		return
	_adv_grande = v
	if v:
		_couche_cartes.move_child(_voile_adv, -1)
	_voile_adv.create_tween().tween_property(_voile_adv, "color:a", 0.72 if v else 0.0, 0.2)
	_ranger_mains()


# Une carte ne suit qu'un seul mouvement : le nouveau arrête l'ancien (sinon les deux tirent sur
# sa position, et la carte prise au doigt repartait vers la main).
func _placer(cc: CarteCarre, coin: Vector2, e: float, anime: bool) -> void:
	_arreter(cc)
	if not anime:
		cc.position = coin
		cc.scale = Vector2(e, e)
		return
	var tw := cc.create_tween().set_parallel(true)
	tw.tween_property(cc, "position", coin, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(cc, "scale", Vector2(e, e), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cc.set_meta("tw", tw)


func _arreter(cc: CarteCarre) -> void:
	if cc.has_meta("tw"):
		(cc.get_meta("tw") as Tween).kill()
		cc.remove_meta("tw")


func _coin_case(i: int) -> Vector2:
	return (_cases[i]["pos"] as Vector2) + (CASE - CarteCarre.TAILLE) * 0.5


# ─────────────────────────────────────────────────────────────
# La bande, le score, le statut
# ─────────────────────────────────────────────────────────────

func _bande(id_pouvoir: String, texte: String, pulser := false) -> void:
	var a_pouvoir := MoteurCarre.POUVOIRS.has(id_pouvoir)
	_bande_icone.visible = a_pouvoir
	_bande_texte.position.x = 160.0 if a_pouvoir else 30.0
	_bande_texte.size.x = 826.0 if a_pouvoir else 956.0
	if a_pouvoir:
		_bande_embleme.texture = Style.texture("res://carre/pouvoir-%s.png" % MoteurCarre.POUVOIRS[id_pouvoir]["g"])
		if pulser:
			var tw := _bande_icone.create_tween()
			tw.tween_property(_bande_icone, "scale", Vector2(1.18, 1.18), 0.14)
			tw.tween_property(_bande_icone, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bande_texte.text = texte


# La fiche d'une carte, dans la bande : son nom, son pouvoir, quand il agit, ce qu'il fait.
func _fiche(c: Dictionary) -> void:
	var id := str(c["id"])
	var nom := MoteurCarre.nom(id)
	if not MoteurCarre.POUVOIRS.has(id):
		var ph := MoteurCarre.sans_pouvoir(id)
		_bande("", "[b]%s[/b] — [i]%s[/i]" % [nom, ph.left(1).to_lower() + ph.substr(1)])
		return
	var p: Dictionary = MoteurCarre.POUVOIRS[id]
	var s := MoteurCarre.stade_eff(id, int(c["s"]))
	_bande(id, "[b]%s · %s[/b] [i](%s)[/i] %s" % [nom, p["nom"], p["quand"], MoteurCarre.texte_pouvoir(id, s)], true)


func _maj_score() -> void:
	var j := 0
	var a := 0
	for d in _cases:
		var cc = d["carte"]
		if cc != null:
			if (cc as CarteCarre).camp == "j":
				j += 1
			else:
				a += 1
	for paire in [[_score_j, "Toi %d" % j], [_score_a, "%d Lui" % a]]:
		var l: Label = paire[0]
		if l.text != paire[1]:
			l.text = paire[1]
			l.pivot_offset = Vector2(0 if l == _score_j else l.size.x, l.size.y * 0.5)
			var tw := l.create_tween()
			tw.tween_property(l, "scale", Vector2(1.18, 1.18), 0.1)
			tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _mettre_statut(texte: String, couleur: Color) -> void:
	_statut.text = texte
	_statut.add_theme_color_override("font_color", couleur)
	var sb := Style.boite(Color(0.03, 0.045, 0.04, 0.92), 26, Color(couleur, 0.85), 3)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	_statut.add_theme_stylebox_override("normal", sb)


# ─────────────────────────────────────────────────────────────
# Le tour
# ─────────────────────────────────────────────────────────────

func _a_moi() -> void:
	tour = "j"
	occupe = false
	choisie = -1
	_mettre_statut("À TOI DE JOUER", JADE)
	_statut.modulate.a = 1.0
	_maj_cibles()
	if tuto and (_tuto_etape == 0 or _tuto_etape == 2):
		_tuto_etape += 1
		_tuto_vers_carte()


# Le guide montre la carte à prendre : Golem au premier tour, Kitsune au deuxième (la première de
# la main). Aussi quand on la lâche à côté : le guide y revient.
func _tuto_vers_carte() -> void:
	_permis = {"carte": 0, "case": -1}
	_guide.montrer("Glisse cette carte" if _tuto_etape == 1 else "Prends Kitsune", _rect_main(0).grow(14.0), GUIDE_Y)


# Le guide passe de la carte à la case où la poser.
func _tuto_vers_case() -> void:
	if not tuto or (_tuto_etape != 1 and _tuto_etape != 3) or _permis["case"] >= 0:
		return
	var i := TUTO_CASE_1 if _tuto_etape == 1 else TUTO_CASE_2
	_permis["case"] = i
	_guide.montrer("Pose-la au centre" if _tuto_etape == 1 else "Pose-la au-dessus de sa carte",
		Rect2(_cases[i]["pos"], CASE).grow(10.0), GUIDE_Y)


func _tour_ia() -> void:
	tour = "a"
	occupe = true
	_montrer_main_adv(false)          # sa main remonte : sa carte part de là
	_mettre_statut("%s JOUE…" % _prenom().to_upper(), CARMIN)
	_statut.modulate.a = 1.0
	_maj_cibles()
	await get_tree().create_timer(0.75).timeout
	if termine:
		return
	var m := MoteurCarre.coup_ia(st, hasard, "a", str(adversaire["niveau"]))
	if tuto and _tuto_etape == 2:
		m = TUTO_COUP_IA.duplicate()
	var cc: CarteCarre = _main_a[m[0]]
	# la carte se soulève dans sa main, puis vole vers sa case
	var tw := cc.create_tween()
	tw.tween_property(cc, "position:y", cc.position.y + 30.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	_main_a.remove_at(m[0])
	var trace := {}
	var ev := MoteurCarre.jouer_coup(st, "a", m, trace)
	journal.append({"camp": "a", "case": m[1], "id": str(cc.carte["id"]), "ev": ev})
	await _poser(cc, m[1], trace)
	_ranger_mains()
	await _animer("a", ev, m[1], trace)
	_suite("a")


func _jouer(k: int, i: int) -> void:
	occupe = true
	choisie = -1
	_statut.create_tween().tween_property(_statut, "modulate:a", 0.0, 0.15)
	_maj_cibles()
	if tuto and _permis["carte"] >= 0:
		_guide.cacher()
		_permis = {"carte": -1, "case": -1}
		_tuto_etape += 1
	var cc: CarteCarre = _main_j[k]
	_main_j.remove_at(k)
	var trace := {}
	var ev := MoteurCarre.jouer_coup(st, "j", [k, i], trace)
	journal.append({"camp": "j", "case": i, "id": str(cc.carte["id"]), "ev": ev})
	await _poser(cc, i, trace)
	_ranger_mains()
	await _animer("j", ev, i, trace)
	if tuto and _tuto_etape == 4:
		_tuto_etape = 5
		await _guide.dire("10 contre 3 : elle est à toi !", GUIDE_Y, 1.7)
		await _guide.dire("Le plus de cartes gagne.", GUIDE_Y, 1.5)
	_suite("j")


func _suite(qui: String) -> void:
	if termine:
		return
	if MoteurCarre.plein(st) or ((st["main"]["j"] as Array).is_empty() and (st["main"]["a"] as Array).is_empty()):
		_fin()
		return
	if qui == "j":
		_tour_ia()
	else:
		_a_moi()


func _prenom() -> String:
	return str(adversaire.get("prenom", GS.heros(str(adversaire["chef"])).get("nom", "Lui")))


# ─────────────────────────────────────────────────────────────
# Les animations : la pose, puis chaque événement, dans l'ordre
# ─────────────────────────────────────────────────────────────

func _poser(cc: CarteCarre, i: int, trace: Dictionary) -> void:
	_couche_cartes.move_child(cc, -1)
	var coin := _coin_case(i)
	var tw := cc.create_tween().set_parallel(true)
	tw.tween_property(cc, "position", coin, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(cc, "scale", Vector2(1.08, 1.08), 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	Son.sonner("carte-pose", randf_range(-1.0, 0.0), randf_range(-1.0, 1.0))
	var d: Dictionary = _cases[i]
	d["carte"] = cc
	var cadre: TextureRect = d[("jade" if cc.camp == "j" else "rose")]
	var tw2 := cc.create_tween().set_parallel(true)
	tw2.tween_property(cc, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.tween_property(cadre, "modulate:a", 1.0, 0.18)
	if d["gemme"] != null:
		tw2.tween_property(d["gemme"], "modulate:a", 0.0, 0.15)
		tw2.tween_property(d["gemme_lib"], "modulate:a", 0.0, 0.15)
	Reglages.vibrer(15)
	Effets.pour(self).etincelles(Rect2(coin, CarteCarre.TAILLE), 4, 20.0)
	_maj_chiffres(trace.get("pose", st))    # la carte posée, ses pouvoirs — pas encore les retournements
	_maj_score()
	await tw2.finished
	var posee: Dictionary = st["cases"][i]
	if posee.get("terre", false):
		_flotter("+1  %s" % str(GS.TYPES[st["terres"][i]]["nom"]), cc.get_global_rect().get_center() - Vector2(0, 60), Style.OR_VIF, 46)
		await get_tree().create_timer(0.45).timeout


# Les chiffres suivent le coup pas à pas (la trace du moteur) : un duel montre les deux chiffres qui
# se battent vraiment, et ce qui en découle (la Marée d'une carte qui change de camp, la Faim de
# Fenrir) n'apparaît qu'après, comme une conséquence.
func _animer(camp: String, ev: Array, i: int, trace: Dictionary) -> void:
	var fx := Effets.pour(self)
	var nb := 0
	_cascade_coup = 0
	var pouvoir_vu := false
	for j in ev.size():
		var e: Dictionary = ev[j]
		match str(e["t"]):
			"pouvoir":
				pouvoir_vu = true
				var cp: CarteCarre = _cases[e["i"]]["carte"]
				cp.pulser_pouvoir()
				Son.sonner("pouvoir")
				fx.etoile(cp.centre_pouvoir(), 40.0, 0.5)
				_maj_chiffres(trace.get(j, trace.get("pose", st)))
				var nom := MoteurCarre.nom(str(e["id"]))
				_bande(str(e["id"]), "[b]%s[/b] — %s" % [nom, e["txt"]], true)
				_flotter(str(MoteurCarre.POUVOIRS[e["id"]]["nom"]), cp.get_global_rect().get_center() - Vector2(0, 40), Style.OR_VIF, 44)
				await get_tree().create_timer(0.8).timeout
			"protege":
				var cp2: CarteCarre = _cases[e["i"]]["carte"]
				cp2.pulser_pouvoir()
				Son.sonner("protege")
				_flotter("Esquive !" if str(e["id"]) == "kitsune" else "Rempart !", cp2.get_global_rect().get_center(), Style.IVOIRE, 46)
				await get_tree().create_timer(0.45).timeout
			"flip":
				nb += 1
				await _duel_et_retournement(e)
				_maj_chiffres(trace.get(j, st))
			"anubis":
				var ca: CarteCarre = _cases[e["vers"]]["carte"]
				await _retourner(ca, int(e["vers"]), str(e["camp"]))
				_maj_chiffres(trace.get(j, st))
	_maj_chiffres()
	_maj_score()
	if not pouvoir_vu:
		if nb == 0:
			_bande("", "[i]%s[/i]" % ("Ta carte est posée." if camp == "j" else "%s pose sa carte." % _prenom()))
		else:
			_bande("", "%s [b]%d carte%s[/b]." % ["Tu retournes" if camp == "j" else "%s retourne" % _prenom(), nb, "s" if nb > 1 else ""])


# Les deux chiffres qui se touchent s'affrontent ; une étoile nette naît entre eux ; la carte
# perdante se retourne. Une prise en chaîne, ou en diagonale (Cerbère), est dite en toutes lettres.
func _duel_et_retournement(e: Dictionary) -> void:
	var de: int = e["de"]
	var vers: int = e["vers"]
	var a: CarteCarre = _cases[de]["carte"]
	var d: CarteCarre = _cases[vers]["carte"]
	var n: int = st["n"]
	var point: Vector2
	if e["diag"]:
		point = (a.get_global_rect().get_center() + d.get_global_rect().get_center()) * 0.5
	else:
		var cote := 0
		if vers == de + 1:
			cote = 1
		elif vers == de + n:
			cote = 2
		elif vers == de - 1:
			cote = 3
		a.pulser_chiffre(cote, true)
		d.pulser_chiffre(MoteurCarre.OPP[cote], false)
		point = (a.centre_pierre(cote) + d.centre_pierre(MoteurCarre.OPP[cote])) * 0.5
	var fx := Effets.pour(self)
	fx.etoile(point, 64.0, 0.55)
	Son.sonner("choc", 0.0, randf_range(-1.0, 1.0))
	for k in 3:
		fx.etoile(point + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 60.0), 18.0, 0.45, 0.08 + k * 0.06)
	Reglages.vibrer(20)
	await get_tree().create_timer(0.24).timeout
	if e["chaine"]:
		_flotter("En diagonale !" if e["diag"] else "En chaîne !", d.get_global_rect().get_center() - Vector2(0, 70), Style.OR_VIF, 50)
	await _retourner(d, vers, str(e["camp"]))


func _retourner(cc: CarteCarre, i: int, nouveau: String) -> void:
	_couche_cartes.move_child(cc, -1)
	Son.retourne_combat(_cascade_coup)
	_cascade_coup += 1
	var d: Dictionary = _cases[i]
	var vers: TextureRect = d["jade" if nouveau == "j" else "rose"]
	var depuis: TextureRect = d["rose" if nouveau == "j" else "jade"]
	await cc.retourner(nouveau, func():
		var tw := create_tween().set_parallel(true)
		tw.tween_property(vers, "modulate:a", 1.0, 0.2)
		tw.tween_property(depuis, "modulate:a", 0.0, 0.2))
	_maj_score()


# Les chiffres montrés, d'après un état du plateau : la fin du coup par défaut, ou un instant du
# coup pris dans la trace du moteur.
func _maj_chiffres(vue: Dictionary = {}) -> void:
	var s: Dictionary = st if vue.is_empty() else vue
	for i in (s["cases"] as Array).size():
		var cc = _cases[i]["carte"]
		if cc != null and s["cases"][i] != null:
			(cc as CarteCarre).maj_chiffres(MoteurCarre.valeurs(s, i))


func _flotter(texte: String, centre: Vector2, couleur: Color, taille: int) -> void:
	var l := Label.new()
	l.text = texte
	l.add_theme_font_override("font", Style.police("italique"))
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	l.add_theme_color_override("font_outline_color", Color("#0b0a10"))
	l.add_theme_constant_override("outline_size", 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.size = l.get_minimum_size()
	l.position = centre - l.size * 0.5
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.6, 0.6)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:y", l.position.y - 50.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


# ─────────────────────────────────────────────────────────────
# Les cases où l'on peut poser : un filet d'or qui respire ; le gel du Yéti
# ─────────────────────────────────────────────────────────────

func _maj_cibles() -> void:
	var libres := MoteurCarre.cases_pour(st, "j") if tour == "j" and not occupe and choisie >= 0 else []
	for i in _cases.size():
		var d: Dictionary = _cases[i]
		var c: TextureRect = d["cible"]
		c.set_meta("allume", libres.has(i))
		if not libres.has(i):
			c.modulate.a = 0.0
		var g: TextureRect = d["gel"]
		g.modulate.a = 1.0 if (st["cases"][i] == null and MoteurCarre.case_gelee(st, i)) else 0.0


func _process(delta: float) -> void:
	_t += delta
	var k := 0.55 + 0.45 * sin(_t * 4.2)
	for i in _cases.size():
		var c: TextureRect = _cases[i]["cible"]
		if c.get_meta("allume", false):
			c.modulate.a = 1.0 if i == _survol else k    # la case visée ne respire plus : elle brille
	# la carte qu'on fait glisser garde la taille du plateau (ses chiffres se lisent), un peu plus au-dessus d'une case
	# où elle peut tomber
	if _glisse.get("bouge", false):
		var cg: CarteCarre = _main_j[_glisse["k"]]
		var e := 1.04 if _survol >= 0 else LOUPE
		cg.scale = cg.scale.lerp(Vector2(e, e), 1.0 - exp(-18.0 * delta))


# ─────────────────────────────────────────────────────────────
# Le doigt : toucher une carte puis une case, ou la faire glisser
# ─────────────────────────────────────────────────────────────

func _gui_input(ev: InputEvent) -> void:
	var b := ev as InputEventMouseButton
	var m := ev as InputEventMouseMotion
	if b != null and b.button_index == MOUSE_BUTTON_LEFT:
		if b.pressed:
			_appui(b.position)
		else:
			_relache(b.position)
	elif m != null and not _glisse.is_empty():
		_glisser(m.position)


# 🔴 Le doigt se lit sur la PLACE de chaque carte au repos, pas sur son dessin : une carte agrandie déborde sur ses
#    voisines, et un doigt posé sur une voisine prenait l'agrandie. La carte agrandie répond aussi au-dessus de sa place
#    (là où elle est montée).
func _carte_main_sous(p: Vector2) -> int:
	for k in _main_j.size():
		var r := _rect_main(k)
		if k == choisie or k == _loupe:
			var haut := _centre_loupe(k).y - CarteCarre.TAILLE.y * LOUPE * 0.5
			r = Rect2(Vector2(r.position.x, haut), Vector2(r.size.x, r.end.y - haut))
		if r.has_point(p):
			return k
	return -1


func _case_sous(p: Vector2) -> int:
	for i in _cases.size():
		if Rect2(_cases[i]["pos"], CASE).has_point(p):
			return i
	return -1


func _appui(p: Vector2) -> void:
	if termine or _adv_grande:
		return
	var k := _carte_main_sous(p)
	if k >= 0 and (_permis["carte"] < 0 or k == _permis["carte"]):
		# le doigt se pose : la carte grandit tout de suite, à la taille du plateau (même quand ce n'est pas ton tour :
		# on la lit)
		if k != choisie:
			_loupe = k
			_ranger_mains()
			Reglages.vibrer(8)
		if tour == "j" and not occupe:
			# le point de la carte qu'on a pris reste sous le doigt : elle ne saute pas (son centre : celui de la carte
			# agrandie, là où elle va)
			_glisse = {"k": k, "depart": p, "decal": _centre_loupe(k) - p, "bouge": false}


func _glisser(p: Vector2) -> void:
	var g := _glisse
	if not g["bouge"] and p.distance_to(g["depart"]) > 22.0:
		g["bouge"] = true
		choisie = g["k"]
		var cc0: CarteCarre = _main_j[g["k"]]
		_arreter(cc0)
		cc0.z_index = 1                    # au-dessus du voile du guide
		_couche_cartes.move_child(cc0, -1)
		_ranger_mains()
		_maj_cibles()
		_fiche(st["main"]["j"][g["k"]])
		_tuto_vers_case()
	if g["bouge"]:
		var cc: CarteCarre = _main_j[g["k"]]
		var centre: Vector2 = p + g["decal"]
		cc.position = centre - CarteCarre.TAILLE * 0.5
		var i := _case_visee(centre)
		if i != _survol:
			_survol = i
			if i >= 0:
				Reglages.vibrer(10)


# La case où tomberait la carte qu'on fait glisser : la case permise la plus proche de son centre,
# pourvu que ce centre soit dessus ou tout près (un doigt ne vise pas au pixel). -1 : aucune.
func _case_visee(centre: Vector2) -> int:
	var meilleure := -1
	var d_min := INF
	for i in MoteurCarre.cases_pour(st, "j"):
		if _permis["case"] >= 0 and i != _permis["case"]:
			continue
		var r := Rect2(_cases[i]["pos"], CASE)
		if not r.grow(60.0).has_point(centre):
			continue
		var d := centre.distance_to(r.get_center())
		if d < d_min:
			d_min = d
			meilleure = i
	return meilleure


func _relache(p: Vector2) -> void:
	var g := _glisse
	_glisse = {}
	_survol = -1
	var avait_loupe := _loupe >= 0
	_loupe = -1
	if termine:
		return
	# la main adverse descendue : toucher l'une de ses cartes la lit ; ailleurs, elle remonte
	if _adv_grande:
		for q in _main_a.size():
			if (_main_a[q] as CarteCarre).get_global_rect().has_point(p):
				_fiche(st["main"]["a"][q])
				return
		_montrer_main_adv(false)
		return
	if not g.is_empty() and g["bouge"]:
		(_main_j[g["k"]] as CarteCarre).z_index = 0
		var i := _case_visee(p + g["decal"])
		if i >= 0:
			_jouer(g["k"], i)
		else:
			# lâchée à côté : elle revient dans la main (et le guide, sur elle)
			choisie = -1
			_ranger_mains()
			_maj_cibles()
			if tuto and _permis["carte"] >= 0:
				_tuto_vers_carte()
		return
	# un toucher sans glisser : la carte agrandie sous le doigt reprend sa place (sauf si elle devient la choisie, plus bas)
	if avait_loupe:
		_ranger_mains()
	var k := _carte_main_sous(p)
	if _permis["carte"] >= 0:
		# pendant le guide : la carte demandée, puis la case demandée — rien d'autre
		if k == _permis["carte"] and tour == "j" and not occupe:
			choisie = k
			_ranger_mains()
			_maj_cibles()
			_fiche(st["main"]["j"][k])
			_tuto_vers_case()
		elif _case_sous(p) == _permis["case"] and choisie >= 0 and tour == "j" and not occupe:
			_jouer(choisie, _permis["case"])
		return
	if k >= 0:
		_fiche(st["main"]["j"][k])
		if tour == "j" and not occupe:
			choisie = -1 if choisie == k else k
			_ranger_mains()
			_maj_cibles()
		return
	var i2 := _case_sous(p)
	if i2 >= 0:
		if st["cases"][i2] == null:
			if choisie >= 0 and tour == "j" and not occupe and MoteurCarre.cases_pour(st, "j").has(i2):
				_jouer(choisie, i2)
			elif (st["terres"] as Dictionary).has(i2):
				var ty := str(st["terres"][i2])
				_bande("", "[b]Terre de %s[/b] — une carte %s posée ici gagne [b]+1[/b] partout." % [str(GS.TYPES[ty]["nom"]).to_lower(), str(GS.TYPES[ty]["nom"]).to_lower()])
		else:
			_fiche(st["cases"][i2])
			(_cases[i2]["carte"] as CarteCarre).pulser_pouvoir()
		return
	# sa main, en petit en haut : elle descend en grand (et la carte touchée se lit)
	for q in _main_a.size():
		if (_main_a[q] as CarteCarre).get_global_rect().grow(6.0).has_point(p):
			_fiche(st["main"]["a"][q])
			_montrer_main_adv(true)
			return


# ─────────────────────────────────────────────────────────────
# La fin
# ─────────────────────────────────────────────────────────────

func _fin() -> void:
	termine = true
	if tuto:
		GS.voyage["tuto_carre"] = true
		GS.save_game()
	var j := MoteurCarre.compte(st, "j")
	var a := MoteurCarre.compte(st, "a")
	Son.fin(j, a, Aventure.defi_reussi("parfait", adversaire, journal, st))
	var titre := "Victoire" if j > a else ("Défaite" if j < a else "Égalité")
	_mettre_statut("GAGNÉ" if j > a else ("PERDU" if j < a else "ÉGALITÉ"), JADE if j >= a else CARMIN)
	_statut.modulate.a = 1.0
	_defis(j, a)
	if adversaire.has("n"):
		_fin_aventure(j, a)
		return
	if adversaire.has("mode"):
		_fin_arene(j, a)
		return
	await get_tree().create_timer(0.9).timeout
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.0)
	voile.size = size
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	voile.create_tween().tween_property(voile, "color:a", 0.25, 0.3)
	var p := Style.panneau(self, Rect2(60, 1690, 960, 640), Color(0.047, 0.063, 0.059, 0.97), 44)
	p.pivot_offset = p.size * 0.5
	p.scale = Vector2(0.9, 0.9)
	p.modulate.a = 0.0
	var tw := p.create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	Style.libelle(p, titre, Rect2(0, 50, 960, 150), "italique", 116, Style.OR_VIF if j >= a else Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	Style.libelle(p, "%d cartes à toi, %d à %s." % [j, a, _prenom()], Rect2(40, 214, 880, 70), "normal", 44, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	var rejouer := Style.bouton(p, "Rejouer", Rect2(110, 340, 740, 120), true, 52)
	var retour := Style.bouton(p, "Retour", Rect2(280, 490, 400, 84), false, 38)
	rejouer.pressed.connect(func(): fini.emit({"rejouer": true, "j": j, "a": a}))
	retour.pressed.connect(func(): fini.emit({"rejouer": false, "j": j, "a": a}))
	if j > a:
		Effets.pour(self).etincelles(Rect2(p.global_position + Vector2(220, 60), Vector2(520, 130)), 6, 26.0)


# Les défis des Présages (28/09, ⑧) : ce que ce combat fait avancer — pas le combat guidé. Les ★ nouvelles se
# lisent AVANT qu'Aventure.enregistrer ne les retienne (il le fait à l'arrivée des gains).
func _defis(j: int, a: int) -> void:
	if tuto:
		return
	Presages.evenement("combat")
	var pris := 0
	var chaine := false
	for c in journal:
		if c["camp"] != "j":
			continue
		for e in c["ev"]:
			if e["t"] == "flip" and e["camp"] == "j":
				pris += 1
				chaine = chaine or bool(e.get("chaine", false))
	Presages.evenement("retournement", pris)
	if chaine:
		Presages.evenement("chaine")
	if j <= a:
		return
	if adversaire.has("n"):
		Presages.evenement("aventure")
		var nouvelles := Aventure.etoiles(adversaire, journal, st) & ~Aventure.masque(int(adversaire["n"])) & 7
		Presages.evenement("etoile_aventure", Aventure.nb_etoiles(nouvelles))
	elif adversaire.get("mode", "") == "duel":
		Presages.evenement("duel")
	elif adversaire.get("mode", "") == "classe":
		Presages.evenement("classe")


# ─────────────────────────────────────────────────────────────
# La fin d'un niveau de l'Aventure : les ★ s'allument une à une, les gains s'envolent jusqu'au
# bandeau, puis « Niveau suivant », « Rejouer », « La terre ». La victoire parfaite (les 9 cartes
# à toi) a sa constellation d'or, qui relie les cartes : elle ne donne rien de plus, c'est pour la gloire.
# ─────────────────────────────────────────────────────────────

func _fin_aventure(j: int, a: int) -> void:
	var n: int = adversaire["n"]
	var m := Aventure.etoiles(adversaire, journal, st)
	var nouvelles := m & ~Aventure.masque(n) & 7
	var parfait := Aventure.defi_reussi("parfait", adversaire, journal, st)
	if parfait:
		_constellation_parfaite()
		await get_tree().create_timer(2.3).timeout
	else:
		await get_tree().create_timer(0.9).timeout
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.0)
	voile.size = size
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	voile.create_tween().tween_property(voile, "color:a", 0.3, 0.3)
	var p := Style.panneau(self, Rect2(60, 1400, 960, 920), Color(0.047, 0.063, 0.059, 0.97), 44)
	p.pivot_offset = p.size * 0.5
	p.scale = Vector2(0.9, 0.9)
	p.modulate.a = 0.0
	var tw := p.create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	var titre := "Parfait" if parfait else ("Victoire" if j > a else "Défaite")
	Style.libelle(p, titre, Rect2(0, 36, 960, 130), "italique", 108, Style.OR_VIF if j > a else Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	Style.libelle(p, "Les 9 cartes du Carré sont à toi." if parfait else "%d cartes à toi, %d à %s." % [j, a, _prenom()],
		Rect2(40, 166, 880, 56), "normal", 38, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)

	# les trois ★ : chacune s'allume à son tour (une nouvelle, avec ses étincelles)
	var allume := [0.0, 0.0, 0.0]
	var dessin := Dessin.ajouter(p, Rect2(0, 230, 960, 170), func(ci: CanvasItem):
		for k in 3:
			var c := Vector2(180.0 + k * 300.0, 80.0)
			Effets.dessiner_etoile(ci, c, 50.0, 0.3, 0.0, Dessin.GRIS)
			if allume[k] > 0.0:
				Effets.dessiner_etoile(ci, c, 64.0 * allume[k], 1.0, 0.0, Effets.OR_CLAIR))
	var legendes := ["Gagner", "6 cartes ou plus", Aventure.texte_defi(adversaire)]
	for k in 3:
		Style.libelle(p, legendes[k], Rect2(40.0 + k * 300.0, 400, 280, 90), "normal", 28,
			Style.OR_VIF if m & (1 << k) else Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var suivant := j > a and n < Aventure.NB_NIVEAUX
	var b1 := Style.bouton(p, "Niveau suivant" if suivant else "Rejouer", Rect2(110, 560, 740, 120), true, 50)
	var b2 := Style.bouton(p, "Rejouer" if suivant else "La terre", Rect2(110, 716, 350, 90), false, 36)
	var b3 := Style.bouton(p, "La terre", Rect2(500, 716, 350, 90), false, 36)
	b3.visible = suivant
	if not suivant:
		b2.position.x = 305
	var t: int = adversaire["terre"]
	b1.pressed.connect(func(): fini.emit({"suivant": n + 1} if suivant else {"rejouer": true}))
	b2.pressed.connect(func(): fini.emit({"rejouer": true} if suivant else {"terre": t}))
	b3.pressed.connect(func(): fini.emit({"terre": t}))
	for k in 3:
		if not (m & (1 << k)):
			continue
		await get_tree().create_timer(0.38).timeout
		var tw2 := create_tween()
		tw2.tween_method(func(v: float):
			allume[k] = v
			dessin.queue_redraw(), 0.0, 1.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if nouvelles & (1 << k):
			Effets.pour(self).etincelles(Rect2(p.global_position + Vector2(180.0 + k * 300.0 - 70, 240), Vector2(140, 140)), 5, 24.0)
			Reglages.vibrer(20)

	# ce que rapporte la 1ʳᵉ victoire : les gains s'envolent jusqu'au bandeau, montré par-dessus
	var g := {}
	if nouvelles & Aventure.ETOILE_VICTOIRE:
		var r := Aventure.recompense_victoire(n)
		g = {"poussiere": r["poussiere"], "etoiles": r["etoiles"], "pierre": ""}
		if montrer_bandeau.is_valid():
			montrer_bandeau.call()
		await get_tree().create_timer(0.3).timeout
	Dessin.gains_en_vol(bandeau, g, p.global_position + Vector2(480, 510), func(): Aventure.enregistrer(n, m))


# ─────────────────────────────────────────────────────────────
# La fin d'un combat du Duel ou du Classé (arene.gd). Le résultat est retenu TOUT DE SUITE : une app
# fermée pendant le panneau ne le perd pas (et ne le compte pas comme un abandon). Puis le panneau : la
# cote qui bouge, ou la barre des points et la marche passée ; la poussière du jour qui s'envole ;
# « Encore » (un nouvel adversaire, tout de suite) et « Retour ».
# ─────────────────────────────────────────────────────────────

var _poussiere_en_vol := 0       # ce que le bandeau retient et qui n'a pas encore pris son envol


func _exit_tree() -> void:
	# fermé avant l'envol : le bandeau reçoit quand même ce qu'il attendait
	if _poussiere_en_vol > 0 and bandeau != null and is_instance_valid(bandeau):
		bandeau.recevoir("poussiere", _poussiere_en_vol, "poussiere-etoile")
		_poussiere_en_vol = 0


func _fin_arene(j: int, a: int) -> void:
	var prevue := Arene.poussiere_prevue() if j > a else 0
	if prevue > 0 and bandeau != null:
		bandeau.retenir("poussiere", prevue)
		_poussiere_en_vol = prevue
	var r := Arene.terminer(adversaire, j, a)
	var mode := str(r["mode"])
	var donnee := int(r["poussiere"])
	# la victoire parfaite (les 9 cartes à toi) a sa constellation d'or, comme dans l'Aventure (Maxim, 28/09)
	var parfait := Aventure.defi_reussi("parfait", adversaire, journal, st)
	if parfait:
		_constellation_parfaite()
		await get_tree().create_timer(2.3).timeout
	else:
		await get_tree().create_timer(0.9).timeout
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.0)
	voile.size = size
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	voile.create_tween().tween_property(voile, "color:a", 0.3, 0.3)
	var p := Style.panneau(self, Rect2(60, 1380, 960, 940), Color(0.047, 0.063, 0.059, 0.97), 44)
	p.pivot_offset = p.size * 0.5
	p.scale = Vector2(0.9, 0.9)
	p.modulate.a = 0.0
	var tw := p.create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	var titre := "Parfait" if parfait else ("Victoire" if j > a else ("Défaite" if j < a else "Égalité"))
	Style.libelle(p, titre, Rect2(0, 30, 960, 130), "italique", 108, Style.OR_VIF if j > a else Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	Style.libelle(p, "Les 9 cartes du Carré sont à toi." if parfait else "%d cartes à toi, %d à %s." % [j, a, _prenom()],
		Rect2(40, 156, 880, 56), "normal", 38, Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
	if mode == "duel":
		var d: Dictionary = r["duel"]
		var delta := int(d["delta"])
		Style.libelle(p, "TA COTE", Rect2(0, 236, 960, 40), "etiquette", 24, Style.SOURD, HORIZONTAL_ALIGNMENT_CENTER, 5)
		# 🔴 « › », pas « → » : la flèche n'est dans aucune de nos polices (elle sortait en boîte, capture du 28/09)
		Style.libelle(p, "%s  ›  %s" % [Style.nombre(int(d["avant"])), Style.nombre(int(d["apres"]))], Rect2(0, 276, 960, 96), "fort", 68,
			Style.IVOIRE, HORIZONTAL_ALIGNMENT_CENTER)
		Style.libelle(p, ("%+d" % delta).replace("-", "−"), Rect2(0, 370, 960, 64), "fort", 46, JADE if delta >= 0 else CARMIN,
			HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_bilan_classe(p, r["classe"])
	# la poussière du jour
	if j > a:
		var texte := "Les %d victoires du jour sont faites : la poussière revient demain." % Arene.VICTOIRES_JOUR
		if donnee > 0:
			texte = "+%d poussière  ·  victoire %d sur %d du jour" % [donnee, Arene.victoires_du_jour(), Arene.VICTOIRES_JOUR]
		Style.libelle(p, texte, Rect2(40, 452, 880, 90), "normal", 32, Style.OR_VIF if donnee > 0 else Style.SOURD,
			HORIZONTAL_ALIGNMENT_CENTER, 0, true)
	var b1 := Style.bouton(p, "Encore", Rect2(110, 580, 740, 120), true, 52)
	var b2 := Style.bouton(p, "Retour", Rect2(280, 730, 400, 84), false, 38)
	b1.pressed.connect(func(): fini.emit({"encore": mode}))
	b2.pressed.connect(func(): fini.emit({"retour": mode}))
	if j > a:
		Effets.pour(self).etincelles(Rect2(p.global_position + Vector2(220, 40), Vector2(520, 130)), 6, 26.0)
	# la poussière s'envole jusqu'au bandeau, montré par-dessus
	if _poussiere_en_vol > 0:
		var n := _poussiere_en_vol
		if donnee != n:              # (jamais vu) ce qui a été donné n'est pas ce qu'on attendait
			bandeau.retenir("poussiere", -n)
			_poussiere_en_vol = 0
			return
		if montrer_bandeau.is_valid():
			montrer_bandeau.call()
		await get_tree().create_timer(0.3).timeout
		_poussiere_en_vol = 0
		if Effets.global != null and bandeau.is_visible_in_tree():
			Effets.global.envoler(Style.objet("poussiere-etoile"), p.global_position + Vector2(480, 490), bandeau.centre_icone("poussiere"),
				120.0, 1.0, func(): bandeau.recevoir("poussiere", n, "poussiere-etoile"))
		else:
			bandeau.recevoir("poussiere", n, "poussiere-etoile")


# Le Classé : l'emblème, la marche, la barre des points qui se remplit (ou se vide), la marche passée.
func _bilan_classe(p: Control, rc: Dictionary) -> void:
	var avant := int(rc["avant"])
	var apres := int(rc["apres"])
	var emb := Style.icone(p, ClasseEcran.embleme(Classe.rang_de(avant)), Rect2(70, 236, 170, 170))
	emb.pivot_offset = Vector2(85, 85)
	var nom := Style.libelle(p, Classe.nom_palier(avant), Rect2(270, 236, 650, 70), "italique", 54, Style.IVOIRE)
	# l'état de la barre dans un tableau : une lambda GDScript copie les variables locales qu'elle voit
	var etat := [0.0 if avant >= Classe.ZENITH else float(rc["points_avant"]) / Classe.POINTS_MARCHE, avant >= Classe.ZENITH]
	var zenith := avant >= Classe.ZENITH
	var barre := Dessin.ajouter(p, Rect2(272, 318, 640, 34), func(ci: CanvasItem):
		ci.draw_style_box(Style.boite(Color("#0b1411"), 17, Color(Style.OR, 0.5), 2), Rect2(0, 0, 640, 34))
		var f: float = 1.0 if etat[1] else clampf(etat[0], 0.0, 1.0)
		if f > 0.0:
			ci.draw_style_box(Style.boite(Style.OR_VIF if etat[1] else Style.JADE_F, 13, Color(0, 0, 0, 0), 0), Rect2(4, 4, maxf(26.0, 632.0 * f), 26)))
	var delta := int(rc["delta"])
	var texte := ("%+d points" % delta).replace("-", "−")
	var coul := JADE if delta > 0 else (CARMIN if delta < 0 else Style.SOURD)
	if bool(rc["plancher"]):
		texte = "Le rang %s te retient : tu n'en retombes pas." % Classe.nom_rang(apres)
		coul = Style.SOURD
	var sous := Style.libelle(p, texte, Rect2(272, 360, 650, 60), "fort", 34, coul, HORIZONTAL_ALIGNMENT_LEFT, 0, true)
	if zenith or delta == 0:
		return
	var fin := 0.0 if apres >= Classe.ZENITH else float(rc["points"]) / Classe.POINTS_MARCHE
	var tw := create_tween()
	tw.tween_interval(0.5)
	var remplir := func(de: float, a: float, t: float):
		tw.tween_method(func(v: float):
			etat[0] = v
			barre.queue_redraw(), de, a, t).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if bool(rc["monte"]):
		remplir.call(etat[0], 1.0, 0.5)
		tw.tween_callback(func():
			nom.text = Classe.nom_palier(apres)
			nom.add_theme_color_override("font_color", Style.OR_VIF)
			emb.texture = ClasseEcran.embleme(Classe.rang_de(apres))
			etat[1] = apres >= Classe.ZENITH
			etat[0] = 0.0
			sous.text = "Tu passes %s !" % Classe.nom_palier(apres)
			sous.add_theme_color_override("font_color", Style.OR_VIF)
			barre.queue_redraw()
			Effets.pour(self).etincelles(emb.get_global_rect(), 6, 26.0)
			Reglages.vibrer(30))
		tw.tween_property(emb, "scale", Vector2(1.18, 1.18), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(emb, "scale", Vector2.ONE, 0.2)
		if apres < Classe.ZENITH:
			remplir.call(0.0, fin, 0.4)
	elif bool(rc["descend"]):
		remplir.call(etat[0], 0.0, 0.4)
		tw.tween_callback(func():
			nom.text = Classe.nom_palier(apres)
			emb.texture = ClasseEcran.embleme(Classe.rang_de(apres))
			sous.text = "Tu redescends en %s." % Classe.nom_palier(apres)
			etat[0] = 1.0
			barre.queue_redraw())
		remplir.call(1.0, fin, 0.4)
	else:
		remplir.call(etat[0], fin, 0.5)


# Les 9 cartes reliées par un trait d'or, dans l'ordre d'un serpent (ligne par ligne).
func _constellation_parfaite() -> void:
	var nn: int = st["n"]
	var pts := PackedVector2Array()
	for l in nn:
		for c in nn:
			var i := l * nn + (c if l % 2 == 0 else nn - 1 - c)
			var cc = _cases[i]["carte"]
			if cc != null:
				pts.append((cc as CarteCarre).get_global_rect().get_center())
	var fx := Effets.pour(self)
	fx.constellation(pts, 2.2, 0.0, Effets.OR_CLAIR, 4.0, Effets.OR_CLAIR)
	for q in pts.size():
		fx.etoile(pts[q], 40.0, 0.6, 0.12 * q)
	_flotter("Parfait !", Vector2(540, 990), Style.OR_VIF, 72)
	Reglages.vibrer(40)
