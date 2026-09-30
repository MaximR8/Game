class_name Accueil
extends CanvasLayer

# ─────────────────────────────────────────────────────────────
# L'ACCUEIL DU PREMIER PACK (28/09) — Maxim joue sans lire : au tout premier lancement, le jeu
# montre du doigt, pas à pas, ce qu'il faut toucher : l'onglet Astrolabe (l'Atlas jusqu'au 28/09 : on invoque
# désormais dans l'Astrolabe), le pack offert, puis l'onglet
# Voyage et « Jouer » — le premier combat a son propre guide (carre/guide_carre.gd). Le reste de
# l'écran s'assombrit et ne répond pas ; des consignes de moins de huit mots.
# Le décor est celui du guide du combat (le voile percé, les anneaux de jade qui battent).
# Au-dessus de tout (la couche 20) : même de l'invocation ×10 de l'Atlas (couche 10).
# ─────────────────────────────────────────────────────────────

signal fini

var jeu: Node                 # main.gd : sa barre, ses écrans
var etape := ""               # astrolabe · ouvrir · pack · voyage · jouer
var _guide: GuideCarre
var _bloc: Bloqueur


# Tout l'écran capte le doigt, sauf le trou : seul ce qu'on montre répond.
class Bloqueur extends Control:
	var trou := Rect2()

	func _has_point(p: Vector2) -> bool:
		return not trou.has_point(p)


func _init() -> void:
	layer = 20


func _ready() -> void:
	_bloc = Bloqueur.new()
	_bloc.size = Vector2(1080, 2400)
	_bloc.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bloc)
	_guide = GuideCarre.new()
	add_child(_guide)


func commencer() -> void:
	etape = "astrolabe"
	_montrer("Ton premier pack t'attend", jeu.barre.rect_onglet("astrolabe"), 1880.0)


# main.gd le prévient à chaque changement d'écran.
func ecran(id: String) -> void:
	if etape == "astrolabe" and id == "astrolabe":
		etape = "ouvrir"
		await get_tree().create_timer(0.35).timeout      # l'écran finit d'arriver
		var b: Control = jeu.ecran_astrolabe.btn_dix
		b.pressed.connect(_pack_ouvert, CONNECT_ONE_SHOT)
		jeu.ecran_collec.multi_ferme.connect(_pack_referme, CONNECT_ONE_SHOT)
		var r := b.get_global_rect()
		# au-dessus du bouton, dans la place que l'Astrolabe laisse libre pendant le premier pack : dessous, il n'y a
		# plus que la barre (le bouton est en bas de la bannière)
		_montrer("Il est offert : ouvre-le !", r, r.position.y - 196.0)
	elif etape == "voyage" and id == "voyage":
		etape = "jouer"
		await get_tree().create_timer(0.35).timeout
		var r: Rect2 = jeu.ecran_voyage.bouton_jouer.get_global_rect()
		_montrer("Ton premier combat", r, r.end.y + 50.0)     # sous le bouton : au-dessus, le panneau a son titre


# Le pack s'ouvre : l'invocation ×10 prend l'écran, on s'efface jusqu'à ce qu'elle se referme.
func _pack_ouvert() -> void:
	etape = "pack"
	_bloc.visible = false
	_guide.cacher()


func _pack_referme() -> void:
	etape = "voyage"
	_montrer("À toi de jouer !", jeu.barre.rect_onglet("voyage"), 1985.0)     # sous la bannière de l'Astrolabe


# Le premier combat commence : son guide prend le relais.
func finir() -> void:
	etape = ""
	_bloc.visible = false
	_guide.cacher()
	fini.emit()
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(queue_free)


func _montrer(texte: String, trou: Rect2, texte_y: float) -> void:
	_bloc.visible = true
	_bloc.trou = trou
	_guide.montrer(texte, trou, texte_y)
