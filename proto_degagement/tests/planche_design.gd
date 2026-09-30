extends Node

# La planche du design des cartes : la même carte dans ses six variantes, puis un sbire et des
# full art — en combat (la carte du Carré, pierres jade) puis dans l'Atlas. Vrai rendu, pour
# juger d'un coup d'œil si le full art se distingue des autres. Les pages vont dans le dossier
# donné après « -- ».
#
#   Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/planche_design.tscn -- <dossier> [prefixe]

const LARGEUR := 300.0
const PAS_X := 345.0
const PAS_Y := 470.0
const CARTES := [
	["thor", 3, "base"], ["thor", 3, "or"], ["thor", 3, "ombre"],
	["thor", 3, "elem"], ["thor", 3, "prisme"], ["thor", 3, "full"],
	["farfadet", 1, "base"], ["bahamut", 2, "base"], ["bahamut", 2, "full"],
]


func _ready() -> void:
	GS.sauvegarde_active = false
	var args := OS.get_cmdline_user_args()
	var dossier: String = args[0] if args.size() > 0 else OS.get_user_data_dir()
	var prefixe: String = args[1] if args.size() > 1 else "planche"
	# 🔴 Une image en pleine définition (1080 × 2400), quelle que soit la fenêtre : un
	#    SubViewport, pas l'écran (la fenêtre est rabotée à la taille du moniteur).
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 1480)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var fond := ColorRect.new()
	fond.color = Color("#0c0f0e")
	fond.size = Vector2(vp.size)
	vp.add_child(fond)
	for mode in ["combat", "atlas"]:
		var noeuds: Array = []
		for i in CARTES.size():
			var spec: Array = CARTES[i]
			var pos := Vector2(45 + (i % 3) * PAS_X, 60 + (i / 3) * PAS_Y)
			if mode == "combat":
				var cc := CarteCarre.new()
				vp.add_child(cc)
				cc.configurer({"id": spec[0], "s": spec[1], "v": spec[2]}, "j")
				cc.scale = Vector2.ONE * LARGEUR / CarteCarre.LARGEUR
				cc.position = pos + (cc.scale - Vector2.ONE) * CarteCarre.TAILLE * 0.5
				noeuds.append(cc)
			else:
				var c := CarteView.new()
				vp.add_child(c)
				c.configurer(MoteurCarre.heros_carte(str(spec[0])), int(spec[1]), str(spec[2]), LARGEUR, true)
				c.position = pos
				noeuds.append(c)
		await get_tree().create_timer(1.4).timeout
		vp.get_texture().get_image().save_png(dossier.path_join("%s_%s.png" % [prefixe, mode]))
		print("planche %s : ok" % mode)
		for n in noeuds:
			vp.remove_child(n)
			n.queue_free()
	get_tree().quit(0)
