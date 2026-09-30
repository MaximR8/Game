class_name SupernovaFx
extends Control

# ─────────────────────────────────────────────────────────────
# L'ANIMATION DE LA SUPERNOVA (30/09 — Maxim : « Supernova, c'est top : on affiche le mot en gros dans l'animation avec
# des effets de lumière dessus » ; DECISIONS 30/09). Par-dessus la machine :
#   · un flash (le blanc qui retombe) ;
#   · le mot SUPERNOVA, énorme, en lettres d'or, qui jaillit ; un éclat de lumière le traverse (le reflet ne passe QUE sur
#     les lettres : clip_children) ; une gerbe d'étoiles NETTES (quatre branches, pas de halo flou — les goûts de Maxim) ;
#   · puis le mot se range en haut de la machine, petit, avec les secondes qui restent.
# La machine elle-même (le poussoir ×2, la pluie, tout compte double) : pusher_screen.gd § la Supernova.
# ─────────────────────────────────────────────────────────────

const OR_CLAIR := Color(1.0, 0.86, 0.46)
const CENTRE := Vector2(540, 860)

var _flash: ColorRect
var _mot: Label
var _reflet: ColorRect
var _etoiles: Array = []          # {pos, vel, vie, vie0, r, rot}
var _fin_t := 0.0
var _range := false               # le mot est rangé en haut : il compte les secondes


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash = ColorRect.new()
	_flash.size = size
	_flash.color = Color(1.0, 0.97, 0.88, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_mot = Label.new()
	_mot.text = "SUPERNOVA"
	_mot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mot.size = Vector2(1080, 220)
	_mot.position = CENTRE - _mot.size * 0.5
	_mot.pivot_offset = _mot.size * 0.5
	_mot.add_theme_font_override("font", Style.police("etiquette", 10))
	_mot.add_theme_font_size_override("font_size", 124)
	_mot.add_theme_color_override("font_color", OR_CLAIR)
	_mot.add_theme_color_override("font_outline_color", Color("#3a2306"))
	_mot.add_theme_constant_override("outline_size", 14)
	_mot.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	_mot.add_theme_constant_override("shadow_offset_x", 0)
	_mot.add_theme_constant_override("shadow_offset_y", 8)
	_mot.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW      # le reflet ne passe que sur les lettres
	_mot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mot.visible = false
	add_child(_mot)
	_reflet = ColorRect.new()
	_reflet.size = Vector2(240, 560)
	_reflet.rotation = deg_to_rad(18)
	_reflet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	# une bande de lumière, douce sur ses bords, ajoutée aux lettres
	sh.code = "shader_type canvas_item;\nrender_mode blend_add;\nvoid fragment() {\n\tfloat d = abs(UV.x - 0.5) * 2.0;\n\tCOLOR = vec4(1.0, 0.98, 0.9, 1.0) * pow(1.0 - d, 1.6) * 1.25;\n}\n"
	m.shader = sh
	_reflet.material = m
	_mot.add_child(_reflet)


# Le départ : le flash, le mot qui jaillit, la gerbe, deux passages de lumière ; puis le mot se range en haut.
func lancer(duree: float) -> void:
	_fin_t = duree
	_range = false
	_flash.color.a = 0.8
	create_tween().tween_property(_flash, "color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)
	_mot.visible = true
	_mot.modulate.a = 1.0
	_mot.position = CENTRE - _mot.size * 0.5
	_mot.scale = Vector2(0.25, 0.25)
	_mot.text = "SUPERNOVA"
	var tw := create_tween()
	tw.tween_property(_mot, "scale", Vector2(1.12, 1.12), 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mot, "scale", Vector2.ONE, 0.2)
	_balayer(0.25)
	_balayer(1.15)
	for i in 46:
		var a := randf() * TAU
		var v := randf_range(350.0, 1150.0)
		var vie := randf_range(0.7, 1.5)
		_etoiles.append({"pos": CENTRE + Vector2(randf_range(-260, 260), randf_range(-40, 40)), "vel": Vector2.from_angle(a) * v,
			"vie": vie, "vie0": vie, "r": randf_range(9.0, 22.0), "rot": randf() * TAU})
	# après 2,2 s : le mot se range en haut de la machine, petit, et compte les secondes
	# (🔴 l'attente PUIS le déplacement et la taille ENSEMBLE : un set_parallel après l'attente faisait tout partir d'un coup)
	var rangement := create_tween()
	rangement.tween_interval(2.2)
	rangement.tween_callback(func(): _range = true)
	rangement.tween_property(_mot, "position", Vector2(0, 300) - Vector2(0, _mot.size.y * 0.5), 0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	rangement.parallel().tween_property(_mot, "scale", Vector2(0.42, 0.42), 0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _balayer(apres: float) -> void:
	var tw := create_tween()
	tw.tween_interval(apres)
	tw.tween_callback(func(): _reflet.position = Vector2(-220, -150))
	tw.tween_property(_reflet, "position:x", 1200.0, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Chaque image : les secondes qui restent ; la gerbe.
func maj(reste: float) -> void:
	if _mot.visible and reste > 0.0 and _range:
		_mot.text = "SUPERNOVA  %d" % ceili(reste)
	if reste <= 0.0 and _mot.visible and _mot.modulate.a > 0.99:
		var tw := create_tween()
		tw.tween_property(_mot, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func(): _mot.visible = false)
	queue_redraw()


func _process(delta: float) -> void:
	if _etoiles.is_empty():
		return
	for i in range(_etoiles.size() - 1, -1, -1):
		var e: Dictionary = _etoiles[i]
		e["vie"] = float(e["vie"]) - delta
		if float(e["vie"]) <= 0.0:
			_etoiles.remove_at(i)
			continue
		e["pos"] += e["vel"] * delta
		e["vel"] *= 0.94
		e["rot"] = float(e["rot"]) + delta * 2.0
	queue_redraw()


# Des étoiles à quatre branches, nettes, qui rétrécissent en s'éteignant.
func _draw() -> void:
	for e in _etoiles:
		var k := clampf(float(e["vie"]) / float(e["vie0"]), 0.0, 1.0)
		var r := float(e["r"]) * (0.4 + 0.6 * k)
		var c: Vector2 = e["pos"]
		var pts := PackedVector2Array()
		for j in 8:
			var ang := float(e["rot"]) + j * PI / 4.0
			var rr := r if j % 2 == 0 else r * 0.28
			pts.append(c + Vector2.from_angle(ang) * rr)
		draw_colored_polygon(pts, Color(OR_CLAIR, k))
