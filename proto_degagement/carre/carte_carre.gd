class_name CarteCarre
extends Control

# ─────────────────────────────────────────────────────────────
# UNE CARTE DU CARRÉ (FEATURES ②, 27/09) : la carte de l'Atlas elle-même (ses six variantes,
# ses effets, ses quatre chiffres sur le cadre — carte_view.gd, v6), à la couleur de son camp
# (jade : les tiennes, carmin : les siennes), avec ses bonus du moment.
#
# La carte se construit toujours à 280 px de large (sa taille sur le plateau) ; dans les
# mains, on la réduit (scale) — elle garde ainsi la même netteté en volant vers sa case.
# ─────────────────────────────────────────────────────────────

const LARGEUR := 280.0
const U := LARGEUR / 100.0
const TAILLE := Vector2(LARGEUR, LARGEUR * 1.4)
const PLUS := Color("#ffd873")
const MOINS := Color("#ff9d8a")

var carte: Dictionary = {}        # {id, s, v}
var camp := "j"
var vue: CarteView


func configurer(p_carte: Dictionary, p_camp: String) -> void:
	carte = p_carte
	camp = p_camp
	size = TAILLE
	pivot_offset = TAILLE * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vue = CarteView.new()
	add_child(vue)
	var id := str(carte["id"])
	vue.configurer(MoteurCarre.heros_carte(id), forme_de(carte), str(carte.get("v", "base")), LARGEUR, true)
	vue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	maj_chiffres(MoteurCarre.chiffres_de(id, int(carte["s"])))
	mettre_camp(camp)


# La forme dessinée d'une carte (le numéro de son illustration).
# 🔴 Un héros à une seule forme (Korrigan, Ifrit, Anansi) se bat comme un stade III, mais n'a qu'UNE
#    illustration : on dessine sa forme, pas son stade de combat (sinon : image manquante, et le dessin
#    de la carte plantait — trouvé par tests/test_aventure, 27/09).
static func forme_de(carte: Dictionary) -> int:
	var id := str(carte["id"])
	return mini(MoteurCarre.stade_eff(id, int(carte["s"])), int(MoteurCarre.fiche(id)["stades"]))


# Les chiffres montrés ; comparés à ceux de la carte nue : plus haut en or, plus bas en rouge pâle.
func maj_chiffres(vals: Array) -> void:
	var base := MoteurCarre.chiffres_de(str(carte["id"]), int(carte["s"]))
	for k in 4:
		var l: Label = vue.nombres[k]
		l.text = str(vals[k])
		var c := CarteView.IVOIRE
		if int(vals[k]) > int(base[k]):
			c = PLUS
		elif int(vals[k]) < int(base[k]):
			c = MOINS
		l.add_theme_color_override("font_color", c)


func mettre_camp(c: String) -> void:
	camp = c
	var tex := Style.texture("res://carre/chiffre-%s.png" % ("jade" if c == "j" else "rose"))
	for t in vue.pierres:
		(t as TextureRect).texture = tex


# Le centre d'une pierre, dans le repère de l'écran.
func centre_pierre(cote: int) -> Vector2:
	return get_global_transform() * ((CarteView.PIERRES[cote] as Vector2) * U)


func centre_pouvoir() -> Vector2:
	return get_global_transform() * (CarteView.POUVOIR_POS * U)


# Le chiffre qui se bat : il enfle (celui qui gagne), ou tremble (celui qui perd).
func pulser_chiffre(cote: int, gagne: bool) -> void:
	var t: TextureRect = vue.pierres[cote]
	var tw := t.create_tween()
	if gagne:
		tw.tween_property(t, "scale", Vector2(1.5, 1.5), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(t, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var x0 := t.position.x
		for dx in [-5.0, 5.0, -3.0, 0.0]:
			tw.tween_property(t, "position:x", x0 + dx, 0.05)


func pulser_pouvoir() -> void:
	var p := vue.pouvoir
	if p == null:
		return
	var tw := p.create_tween()
	tw.tween_property(p, "scale", Vector2(1.6, 1.6), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# LE RETOURNEMENT : la carte se soulève, fait un tour complet sur elle-même — on voit son dos
# à mi-course — et retombe à la couleur de son nouveau camp. `au_dos` est appelé quand le dos
# est visible (pour changer la couleur de la case au même instant).
func retourner(nouveau: String, au_dos := Callable()) -> void:
	var y0 := position.y
	var s0 := scale.y
	var tw := create_tween()
	tw.tween_property(self, "position:y", y0 - 14.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2(s0 * 1.07, s0 * 1.07), 0.10)
	tw.tween_property(self, "scale:x", 0.0, 0.11).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		vue.montrer_recto(false)
		if au_dos.is_valid():
			au_dos.call())
	tw.tween_property(self, "scale:x", s0 * 1.07, 0.11).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale:x", 0.0, 0.11).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		vue.montrer_recto(true)
		mettre_camp(nouveau))
	tw.tween_property(self, "scale:x", s0 * 1.07, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(s0, s0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "position:y", y0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
