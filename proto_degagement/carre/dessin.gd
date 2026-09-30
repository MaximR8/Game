class_name Dessin
extends Control

# ─────────────────────────────────────────────────────────────
# Un calque qui se dessine par une fonction : les étoiles des niveaux, les traits d'une
# constellation, un cadenas (le Voyage, 27/09). Tout est tracé net, avec les étoiles du ciel
# (Effets.dessiner_etoile) : ni halo, ni flou (les goûts de Maxim : « des étoiles nettes »).
# ─────────────────────────────────────────────────────────────

const GRIS := Color("#8f9994")

var f: Callable


static func ajouter(parent: Node, rect: Rect2, fonction: Callable) -> Dessin:
	var d := Dessin.new()
	d.position = rect.position
	d.size = rect.size
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.f = fonction
	parent.add_child(d)
	return d


func _draw() -> void:
	if f.is_valid():
		f.call(self)


# Trois étoiles côte à côte : allumées (d'or) ou éteintes (une ombre d'étoile).
static func trois_etoiles(ci: CanvasItem, centre: Vector2, r: float, masque: int, ecart := 2.5) -> void:
	for k in 3:
		var p := centre + Vector2((k - 1) * r * ecart, 0)
		if masque & (1 << k):
			Effets.dessiner_etoile(ci, p, r, 1.0, 0.0, Effets.OR_CLAIR)
		else:
			Effets.dessiner_etoile(ci, p, r * 0.8, 0.3, 0.0, GRIS)


# Le cadenas des menus scellés (barre_nav.gd), à l'échelle e, centré sur p.
static func cadenas(ci: CanvasItem, p: Vector2, e := 1.0, c := GRIS) -> void:
	ci.draw_rect(Rect2(p + Vector2(-13.5, -3.0) * e, Vector2(27, 19) * e), c, true)
	ci.draw_arc(p + Vector2(0, -3.0) * e, 8.0 * e, PI, TAU, 16, c, 4.0 * e, true)


# Le portrait rond d'un héros : son illustration, recadrée sur la tête (carre/portrait.gdshader).
static func portrait(parent: Control, id: String, s: int, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Style.texture("res://cartes/min/%s-%d.jpg" % [id, s])
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://carre/portrait.gdshader")
	m.set_shader_parameter("region", VoyageEcran.REGION_VISAGE)
	t.material = m
	parent.add_child(t)
	return t


# Un médaillon sombre (interface/medaillon-sombre.png) avec un portrait dedans.
static func medaillon(parent: Control, id: String, s: int, r: Rect2) -> Control:
	var med := Control.new()
	med.position = r.position
	med.size = r.size
	med.pivot_offset = r.size * 0.5
	med.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(med)
	var fond := TextureRect.new()
	fond.texture = Style.texture("res://interface/medaillon-sombre.png")
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.size = r.size
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	med.add_child(fond)
	var bord := r.size.x * 0.1
	portrait(med, id, s, Rect2(Vector2(bord, bord), r.size - Vector2(2 * bord, 2 * bord)))
	return med


# 🔴 LES GAINS S'ENVOLENT JUSQU'AU BANDEAU (Maxim, 24/09 : « pas de pop-up ») : le compteur attend
#    (retenir), on donne (donner : c'est là que GS change), puis chaque objet s'envole de « depart »
#    jusqu'à son compteur, qui le reçoit en défilant. g : {poussiere, etoiles, pierre}.
#    Sans bandeau visible, on donne seulement.
static func gains_en_vol(bandeau: Bandeau, g: Dictionary, depart: Vector2, donner: Callable) -> void:
	var vols := []
	if int(g.get("poussiere", 0)) > 0:
		vols.append(["poussiere", int(g["poussiere"]), "poussiere-etoile"])
	if int(g.get("etoiles", 0)) > 0:
		vols.append(["etoiles", int(g["etoiles"]), "etoile-invocation"])
	if str(g.get("pierre", "")) != "":
		vols.append(["pierres", 1, "pierre-%s" % g["pierre"]])
	var en_vol := bandeau != null and bandeau.is_visible_in_tree() and Effets.global != null
	if en_vol:
		for v in vols:
			bandeau.retenir(v[0], v[1])
	donner.call()
	if not en_vol:
		return
	for k in vols.size():
		var v: Array = vols[k]
		bandeau.get_tree().create_timer(0.2 * k).timeout.connect(func():
			Effets.global.envoler(Style.objet(v[2]), depart, bandeau.centre_icone(v[0]), 120.0, 1.0,
				func(): bandeau.recevoir(v[0], v[1], v[2])))
