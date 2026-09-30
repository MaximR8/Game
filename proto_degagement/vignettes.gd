class_name Vignettes
extends Node

# LES CARTES DE LA GRILLE, EN IMAGES (25/09) — pensé pour des CENTAINES de cartes.
#
# · Chaque carte est photographiée UNE fois (une vraie CarteView, rendue hors écran, à la
#   résolution de l'écran) et gardée sur le téléphone (user://vignettes/). On la photographie
#   quand on l'obtient ou qu'elle change (demander()), pendant l'écran de résultat ; ce qui
#   manque encore passe par l'écran « Préparation » de la collection.
# · En mémoire, seules les photos récemment vues (LRU, MEMOIRE) ; une photo absente de la
#   mémoire est relue du téléphone, UNE par image au plus : défiler ne fige jamais.
# 🔴 Avant : les cartes se construisaient (50 à 100 ms chacune au téléphone) et s'animaient
#    pendant qu'on défilait — « ça donne mal aux yeux » (Maxim, 25/09).

signal prete(cle: String, tex: Texture2D)
signal photo_prise(restantes: int)

const DOSSIER := "user://vignettes"
# À incrémenter quand le dessin des cartes change : toutes les photos sont refaites.
const VERSION := 6      # 6 (28/09) : le rang de chaque carte dans son bandeau, en couleur ; 2 : la carte du Carré (v6) ; 3 : le prismatique, le nom du full art ; 4 : les rangs ;
                        # 5 : le prismatique irisé, les images du Chinchin et de l'Homme de feuilles (28/09)
const MEMOIRE := 48           # photos gardées en mémoire (≈ 1,7 Mo chacune au téléphone)

var largeur := 486.0
var echelle := 1.0
var _textures := {}           # clé -> Texture2D (les MEMOIRE dernières vues)
var _ordre: Array = []        # les clés, de la plus ancienne vue à la plus récente
var _a_lire: Array = []       # clés à relire du téléphone, une par image
var _a_photographier: Array = []   # [clé, héros, stade, variante, recto]
var _en_cours := false
var dos: Texture2D            # le dos : toujours en mémoire (toutes les cartes à découvrir)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DOSSIER)
	_effacer_anciennes()


# Les photos d'un dessin périmé ne resserviront jamais : elles ne font qu'encombrer le téléphone.
func _effacer_anciennes() -> void:
	var fin := "-v%d.webp" % VERSION
	for f in DirAccess.get_files_at(DOSSIER):
		if not f.ends_with(fin):
			var err := DirAccess.remove_absolute(DOSSIER.path_join(f))
			if err != OK:
				push_warning("Vignette périmée non effacée : %s (%s)" % [f, error_string(err)])


func cle(id: String, stade: int, variante: String, recto: bool) -> String:
	var px := int(round(largeur * echelle))
	if not recto:
		return "dos-%d-v%d" % [px, VERSION]
	return "%s-%d-%s-%d-v%d" % [id, stade, variante, px, VERSION]


func _chemin(k: String) -> String:
	return DOSSIER.path_join(k + ".webp")


var _connues := {}            # les clés qu'on sait présentes sur le téléphone (on ne redemande pas au disque)


func existe(k: String) -> bool:
	if _textures.has(k) or _connues.has(k):
		return true
	if FileAccess.file_exists(_chemin(k)):
		_connues[k] = true
		return true
	return false


# La marge autour de la carte, où tombe son ombre (CarteView : 8 u).
func marge() -> float:
	return 8.0 * largeur / 100.0


# ─────────────────────────────────────────────────────────────
# Lire : tout de suite si c'est en mémoire, sinon au plus une par image
# ─────────────────────────────────────────────────────────────

# La photo d'une clé si elle est en mémoire ; sinon null, et elle arrivera par « prete »
# (relue du téléphone, ou photographiée si elle n'existe pas encore).
func texture(k: String) -> Texture2D:
	if _textures.has(k):
		_ordre.erase(k)
		_ordre.append(k)
		return _textures[k]
	if not _a_lire.has(k):
		_a_lire.append(k)
		set_process(true)
	return null


# Ce qu'on ne regarde plus n'a plus besoin d'être lu (défilement rapide).
func oublier_demandes() -> void:
	_a_lire.clear()


func _process(_d: float) -> void:
	if _a_lire.is_empty():
		set_process(false)
		return
	var k: String = _a_lire.pop_front()
	if _textures.has(k):
		return
	if FileAccess.file_exists(_chemin(k)):
		var img := Image.load_from_file(_chemin(k))
		if img != null and not img.is_empty():
			_garder(k, ImageTexture.create_from_image(img))


func _garder(k: String, t: Texture2D) -> void:
	_connues[k] = true
	if k.begins_with("dos-"):
		dos = t
	_textures[k] = t
	_ordre.erase(k)
	_ordre.append(k)
	while _ordre.size() > MEMOIRE:
		var vieille: String = _ordre.pop_front()
		if not vieille.begins_with("dos-"):
			_textures.erase(vieille)
	prete.emit(k, t)


# ─────────────────────────────────────────────────────────────
# Photographier
# ─────────────────────────────────────────────────────────────

# Demander la photo d'une carte (si elle n'existe pas encore) : à l'obtention, à l'évolution.
func demander(h: Dictionary, stade: int, variante: String, recto := true) -> void:
	var k := cle(str(h["id"]), stade, variante, recto)
	if existe(k):
		return
	for f in _a_photographier:
		if f[0] == k:
			return
	_a_photographier.append([k, h, stade, variante, recto])
	if not _en_cours:
		_photographier.call_deferred()


func restantes() -> int:
	return _a_photographier.size() + (1 if _en_cours else 0)


# Une carte à la fois : la construire hors écran, attendre qu'elle soit dessinée, la
# photographier, la garder.
func _photographier() -> void:
	if _en_cours or _a_photographier.is_empty():
		return
	_en_cours = true
	var f: Array = _a_photographier.pop_front()
	var m := marge()
	var base := Vector2(largeur + 2.0 * m, largeur * 1.4 + 2.0 * m)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.size = Vector2i(ceili(base.x * echelle), ceili(base.y * echelle))
	vp.size_2d_override = Vector2i(ceili(base.x), ceili(base.y))
	vp.size_2d_override_stretch = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var c := CarteView.new()
	vp.add_child(c)
	c.configurer(f[1], f[2], f[3], largeur, f[4])
	c.position = Vector2(m, m)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	remove_child(vp)
	vp.queue_free()
	if img != null and not img.is_empty():
		img.save_webp(_chemin(str(f[0])), true, 0.92)
		_garder(str(f[0]), ImageTexture.create_from_image(img))
	_en_cours = false
	photo_prise.emit(restantes())
	if not _a_photographier.is_empty():
		await get_tree().process_frame
		_photographier()
