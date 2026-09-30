class_name GuideCarre
extends Control

# ─────────────────────────────────────────────────────────────
# LE GUIDE DU PREMIER COMBAT (le Carré, 27/09). Maxim joue sans lire : la première partie
# s'apprend en jouant. Le reste de l'écran s'assombrit, un trou net montre quoi toucher, des
# anneaux de jade y battent (le même geste que « touche ici » sur la Nébuleuse), et une
# consigne de moins de huit mots, en gros.
# Le guide ne capte rien : c'est l'écran de combat qui n'accepte que le geste demandé.
# ─────────────────────────────────────────────────────────────

const JADE := Color("#7fd0b0")

var _voile: ColorRect
var _texte: Label
var _cible := Vector2.ZERO
var _anneaux := false
var _t := 0.0
var _trou_actuel := Rect2()


func _ready() -> void:
	size = Vector2(1080, 2400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_voile = ColorRect.new()
	_voile.size = size
	_voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://carre/voile_trou.gdshader")
	m.set_shader_parameter("taille", size)
	_voile.material = m
	add_child(_voile)
	_texte = Label.new()
	_texte.add_theme_font_override("font", Style.police("italique"))
	_texte.add_theme_font_size_override("font_size", 56)
	_texte.add_theme_color_override("font_color", Style.IVOIRE)
	_texte.add_theme_color_override("font_outline_color", Color("#06080a"))
	_texte.add_theme_constant_override("outline_size", 16)
	_texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texte.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texte.size = Vector2(980, 170)
	_texte.position.x = 50
	_texte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texte)
	modulate.a = 0.0
	visible = false


# Montrer un endroit à toucher : le trou, les anneaux au centre, la consigne au-dessus ou dessous.
func montrer(texte: String, trou: Rect2, texte_y: float) -> void:
	visible = true
	_anneaux = true
	_cible = trou.get_center()
	_texte.text = texte
	_texte.position.y = texte_y
	var m := _voile.material as ShaderMaterial
	var de := _trou_actuel if _trou_actuel.size.x > 0.0 else trou.grow(220.0)
	_trou_actuel = trou
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(k: float):
		var r := Rect2(de.position.lerp(trou.position, k), de.size.lerp(trou.size, k))
		m.set_shader_parameter("trou", Vector4(r.position.x, r.position.y, r.size.x, r.size.y)), 0.0, 1.0, 0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	_texte.pivot_offset = _texte.size * 0.5
	_texte.scale = Vector2(0.9, 0.9)
	tw.tween_property(_texte, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Une phrase seule, sans rien à toucher (le voile plus léger), le temps de la lire.
func dire(texte: String, texte_y: float, duree: float) -> void:
	visible = true
	_anneaux = false
	_trou_actuel = Rect2()
	var m := _voile.material as ShaderMaterial
	m.set_shader_parameter("trou", Vector4.ZERO)
	m.set_shader_parameter("noir", 0.35)
	_texte.text = texte
	_texte.position.y = texte_y
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_interval(duree)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await tw.finished
	m.set_shader_parameter("noir", 0.62)
	visible = false


func cacher() -> void:
	_anneaux = false
	_trou_actuel = Rect2()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): visible = false)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	queue_redraw()


# Les anneaux de jade qui battent au centre de la cible : deux ondes qui s'élargissent, un cœur.
func _draw() -> void:
	if not _anneaux:
		return
	for k in 2:
		var u := fposmod(_t / 1.2 + k * 0.5, 1.0)
		draw_arc(_cible, 22.0 + u * 70.0, 0.0, TAU, 64, Color(JADE, (1.0 - u) * 0.85), 5.0 - u * 2.5, true)
	draw_circle(_cible, 17.0, Color("#c9f6e4"), true, -1.0, true)
	draw_arc(_cible, 17.0, 0.0, TAU, 48, Color(JADE, 0.9), 3.0, true)
