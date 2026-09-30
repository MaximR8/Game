class_name DosInfo
extends Control

# ─────────────────────────────────────────────────────────────
# LE DOS D'UNE CARTE, EN GRAND (27/09) — ce qu'on voit en retournant la carte de l'Atlas du
# doigt (carte_3d.gd) : sa légende et son pouvoir, posés sur le dos de sa variante. Maxim :
# « il faut que leur pouvoir soit lisible quelque part… au dos, une note : la légende, et son
# pouvoir ». Le pouvoir dit la même phrase que la bande du combat (MoteurCarre.texte_pouvoir).
# ─────────────────────────────────────────────────────────────

const IVOIRE := Color("#efe9dc")
const SOURD := Color("#a39aa8")
const OR := Color("#d9b56a")
const LARGEUR_TEXTE := 76.0    # en u

var _u := 8.2


func configurer(h: Dictionary, stade: int, variante: String, largeur: float) -> void:
	_u = largeur / 100.0
	var u := _u
	size = Vector2(largeur, largeur * 1.4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in get_children():
		remove_child(c)
		c.queue_free()
	# dessous : le dos de sa variante (il trahit sa rareté, comme à l'invocation)
	var fond := CarteView.new()
	add_child(fond)
	fond.configurer(h, stade, variante, largeur, false)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# un panneau sombre, cerclé d'or, pour que le texte se lise
	var panneau := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.043, 0.039, 0.058, 0.9)
	sb.set_corner_radius_all(int(round(3.2 * u)))
	sb.set_border_width_all(maxi(1, int(round(0.3 * u))))
	sb.border_color = Color(OR, 0.45)
	sb.anti_aliasing = true
	panneau.add_theme_stylebox_override("panel", sb)
	panneau.position = Vector2(7.0, 7.0) * u
	panneau.size = Vector2(86.0, 126.0) * u
	panneau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panneau)

	var col := VBoxContainer.new()
	col.position = Vector2(12.0, 9.0) * u
	col.size = Vector2(LARGEUR_TEXTE, 122.0) * u
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", int(round(1.0 * u)))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	var id := str(h["id"])
	var formes: Array = h["formes"]
	_texte(col, str(h["nom"]), "titre", 7.0, IVOIRE)
	# la forme, et le rang du héros (Mythe, Légende : plus rares, plus forts — MoteurCarre.RANGS)
	var ligne := str(formes[stade - 1])
	var r := MoteurCarre.rang(id)
	if r != "sbire":
		ligne += " · " + GS.rang_nom(r)
	_texte(col, ligne.to_upper(), "gras", 2.9, SOURD, 0.12)
	var infos: PackedStringArray = []
	# (un sbire a déjà « SBIRE » sur la ligne du dessus : pas deux fois)
	var role := "" if bool(h.get("sbire", false)) else str(h.get("role", ""))
	for t in [role, str(GS.TYPES.get(str(h["type"]), {}).get("nom", "")), str(h.get("pays", ""))]:
		if t != "":
			infos.append(t)
	_texte(col, " · ".join(infos).to_upper(), "gras", 2.4, Color(OR, 0.85), 0.14)

	var legende := Legendes.de(id)
	if legende != "":
		_filet(col)
		_texte(col, "LA LÉGENDE", "gras", 2.6, OR, 0.2)
		_texte(col, legende, "italique", 3.9, IVOIRE, 0.0, true)

	_filet(col)
	_texte(col, "SON POUVOIR", "gras", 2.6, OR, 0.2)
	if MoteurCarre.POUVOIRS.has(id):
		var p: Dictionary = MoteurCarre.POUVOIRS[id]
		var rang := HBoxContainer.new()
		rang.alignment = BoxContainer.ALIGNMENT_CENTER
		rang.add_theme_constant_override("separation", int(round(2.4 * u)))
		rang.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(rang)
		var embleme := Control.new()
		embleme.custom_minimum_size = Vector2(12.0, 12.0) * u
		embleme.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rang.add_child(embleme)
		_image(embleme, "res://interface/medaillon-sombre.png", Rect2(Vector2.ZERO, embleme.custom_minimum_size))
		var e := 12.0 * u * 0.62
		_image(embleme, "res://carre/pouvoir-%s.png" % p["g"], Rect2(Vector2(12.0 * u - e, 12.0 * u - e) * 0.5, Vector2(e, e)))
		var noms := VBoxContainer.new()
		noms.alignment = BoxContainer.ALIGNMENT_CENTER
		noms.add_theme_constant_override("separation", 0)
		noms.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rang.add_child(noms)
		_texte(noms, str(p["nom"]), "titre", 4.8, IVOIRE, 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
		var quand := str(p["quand"])
		_texte(noms, quand.left(1).to_upper() + quand.substr(1), "italique", 3.3, SOURD, 0.0, false, HORIZONTAL_ALIGNMENT_LEFT)
		_texte(col, MoteurCarre.texte_pouvoir(id, MoteurCarre.stade_eff(id, stade)), "normal", 3.7, IVOIRE, 0.0, true)
	else:
		_texte(col, MoteurCarre.sans_pouvoir(id), "italique", 3.8, IVOIRE, 0.0, true)


func _texte(parent: Control, texte: String, role: String, taille_u: float, couleur: Color,
		espacement_em := 0.0, retour := false, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var s := maxi(6, int(round(taille_u * _u)))
	var l := Label.new()
	l.text = texte
	l.add_theme_font_override("font", CarteView.police(role, int(round(espacement_em * s))))
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", couleur)
	l.horizontal_alignment = align
	if retour:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = LARGEUR_TEXTE * _u
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


# Un filet d'or, un losange au milieu : entre le nom, la légende et le pouvoir.
func _filet(parent: Control) -> void:
	var f := Control.new()
	f.custom_minimum_size = Vector2(LARGEUR_TEXTE, 3.4) * _u
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.draw.connect(func():
		var u := _u
		var y := f.size.y * 0.5
		var m := f.size.x * 0.5
		f.draw_line(Vector2(m - 22.0 * u, y), Vector2(m - 2.2 * u, y), Color(OR, 0.5), maxf(1.0, 0.25 * u), true)
		f.draw_line(Vector2(m + 2.2 * u, y), Vector2(m + 22.0 * u, y), Color(OR, 0.5), maxf(1.0, 0.25 * u), true)
		var d := 1.1 * u
		f.draw_colored_polygon(PackedVector2Array([Vector2(m, y - d), Vector2(m + d, y), Vector2(m, y + d), Vector2(m - d, y)]), OR))
	parent.add_child(f)


func _image(parent: Control, chemin: String, r: Rect2) -> void:
	var t := TextureRect.new()
	t.texture = Style.texture(chemin)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
