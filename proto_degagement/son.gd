class_name Son
extends Node

# ─────────────────────────────────────────────────────────────
# LE SON (29/09 — la femme du cousin : « ce serait encore pire si j'avais le son » ; puis Maxim : « faudrait mettre du son
# dans tout le jeu »). Un seul lecteur pour tout le jeu (main.gd le crée ; Son.global), deux bus (Reglages : Musique,
# Effets — déclarés dans default_bus_layout.tres).
#
# Les sons : proto_degagement/sons/<nom>.ogg, préparés par design/sons/preparer_jeu.py depuis les choix de Maxim sur la page
# d'écoute (design/canevas/sons/) — coupés à leur attaque (ils partent sur l'image où la chose arrive), au même pic ; le
# volume de chaque moment se règle ICI (NIVEAUX). Chargés à leur premier usage.
#   La Nébuleuse : pose (au contact de la pièce lâchée), entrechoc (une pièce qui tombe sur le tas), gain (en cascade), les
#   paquets, objet, plateau-vide. (Le poussoir ne fait plus aucun bruit : 29/09.)
#   L'interface : bouton (Style.jeu), onglet (la barre du bas), refus (un bouton éteint qu'on touche), recevoir.
#   L'invocation : sa bande-son (inv-*, une PARTITION calée sur le rituel : § partition), rarete-1…5 (de l'Or au Full art),
#                  rang (Mythe, Légende). (« portail » ne sert plus qu'à l'évolution.)
#   Le combat : carte-pose, choc (deux chiffres qui s'affrontent), retourne-combat (en cascade dans un même coup), pouvoir,
#               protege, victoire, defaite (l'égalité : un peu plus haut), parfait.
#   La collection : niveau, evolution.
#   Les musiques : musique (le jeu), musique-combat — une seule joue ; on passe de l'une à l'autre par un fondu du BUS.
# 🔴 Sur le web (les sons sont des échantillons du navigateur) : aucun changement de volume d'un son qui joue n'y passe —
#    un volume se règle AVANT play() ; les fondus se font sur le bus « Musique » (celui-là suit). (29/09 : « j'entends pas
#    le son ».)
# 🔴 Aucun son n'écoute les chocs entre pièces de la Nébuleuse : 260 corps en contact coûteraient trop à la physique (D13).
# Le navigateur ne laisse sortir le son qu'après le premier toucher.
# ─────────────────────────────────────────────────────────────

const PENTA := [0, 2, 4, 7, 9, 12]            # (la cascade des retournements du combat)
const MONTEE := [0.0, 0.7, 1.4, 2.1, 2.8, 3.5]  # (29/09) la cascade des pièces gagnées : discrète (de vraies pièces)
const CASCADE_S := 0.7
const PAQUET_S := 0.25
const NIVEAUX := {
	"pose": -7.0, "entrechoc": -13.0, "gain": -3.0, "paquet-1": -3.0, "paquet-2": -1.0, "objet": -9.0, "plateau-vide": 0.0,
	# (29/09 — « le son quand on gagne des objets […] il fait mal aux oreilles » : l'objet sortait 9 à 11 dB au-dessus des
	#  pièces ; 0 → −9, et son son refait : OB2, une octave plus bas, adouci)
	"bouton": -12.0, "onglet": -9.0, "refus": -6.0, "recevoir": -2.0,
	"portail": -4.0, "rarete": -2.0, "rang": -1.0,
	"carte-pose": -5.0, "choc": -8.0, "retourne-combat": -4.0, "pouvoir": -2.0, "protege": -4.0,
	"victoire": 0.0, "defaite": -2.0, "parfait": 0.0, "niveau": -3.0, "evolution": 0.0,
	# (musique −6 → −2 le 29/09 : à 60 % sur son bus, elle tombait vers −30 dB, trop bas pour un haut-parleur de téléphone)
	"musique": -2.0, "musique-combat": -2.0, "musique-nebuleuse": -2.0,
	# la partition de l'invocation (design/sons/invocation.py)
	# (29/09, au film : la révélation ne dépassait le souffle que de 5 dB — le souffle, la tension, les étoiles baissent)
	"inv-souffle": -8.0, "inv-etoile": -13.0, "inv-verrou": 0.0, "inv-aspiration": -5.0, "inv-apparition": -5.0,
	"inv-tension": -9.0, "inv-revelation": 0.0, "inv-flip": -7.0, "inv-arrivee": -12.0,
}
# La bande-son de l'invocation (29/09 — « ça doit être spectaculaire, ça doit marcher avec l'animation ») : deux ambiances
# comparées en film, Maxim a gardé « celeste » (IV1) — seule embarquée ; « cosmique » se refait pour un film
# (invocation.py --toutes). Les fichiers : sons/inv-<ambiance>-<nom>.ogg.
static var ambiance_invocation := "celeste"
const SOUFFLE_S := 1.6            # la durée du souffle rendu : le jeu l'étire à la durée du rituel (jusqu'au verrou)
const GAMME := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]    # les étoiles montent là-dessus, de la première à la dernière
const VOIX := 24            # (29/09 : 12 → 24 — les vraies pièces tintent ~1 s : une rafale au doigt en tient une vingtaine)

static var global: Son
static var journal: Array = []        # les tests lisent ce qui a sonné (nom, demi-tons)

var _flux := {}
var _voix: Array = []
var _k := 0
var _musique: AudioStreamPlayer
var _musique_nom := ""
var _cascade := -1
var _groupe := 0
var _dernier_gros := -10.0
var _dernier_choc := -10.0
var _dernier_gain := -10.0
var _derniere_pose := -10.0
var _dernier_bouton := -10.0
var _grains: Array = []
var _fondu: Tween
var _positions := {}          # où chaque musique en était : elle reprend là quand on revient sur son écran
var _depart_ms := 0
var _depart_pos := 0.0


func _ready() -> void:
	var i := 1
	while ResourceLoader.exists("res://sons/entrechoc-%d.ogg" % i):
		_grains.append(load("res://sons/entrechoc-%d.ogg" % i))
		i += 1
	for k in VOIX:
		var p := AudioStreamPlayer.new()
		p.bus = "Effets"
		add_child(p)
		_voix.append(p)
	_musique = AudioStreamPlayer.new()
	_musique.bus = "Musique"
	add_child(_musique)


func _charger(nom: String) -> AudioStream:
	if not _flux.has(nom):
		var chemin := "res://sons/%s.ogg" % ("piece-pose" if nom == "pose" else nom)
		_flux[nom] = load(chemin) if ResourceLoader.exists(chemin) else null
	return _flux[nom]


static func _t() -> float:
	return Time.get_ticks_msec() / 1000.0


# Un son, sur une voix libre (sinon la plus ancienne), à son niveau, décalé de quelques demi-tons.
# « niveau » : la clé de NIVEAUX quand elle diffère du nom du fichier (rarete-3 → rarete).
func jouer(nom: String, db := 0.0, demi_tons := 0.0, flux: AudioStream = null, niveau := "") -> void:
	var s: AudioStream = flux if flux != null else _charger(nom)
	journal.append([nom, demi_tons])
	if journal.size() > 300:
		journal.pop_front()
	if s == null:
		return
	var p: AudioStreamPlayer = null
	for v in _voix:
		if not (v as AudioStreamPlayer).playing:
			p = v
			break
	if p == null:
		p = _voix[_k % VOIX]
		_k += 1
	p.stream = s
	p.volume_db = float(NIVEAUX.get(niveau if niveau != "" else nom, 0.0)) + db
	p.pitch_scale = pow(2.0, demi_tons / 12.0)
	p.play()


static func sonner(nom: String, db := 0.0, demi_tons := 0.0) -> void:
	if global != null:
		global.jouer(nom, db, demi_tons)


# ── La Nébuleuse ─────────────────────────────────────────────

# Une pièce touche le plateau : un peu différente à chaque fois ; pas deux dans la même image (on en lâche en rafale).
static func pose() -> void:
	if global == null or _t() - global._derniere_pose < 0.05:
		return
	global._derniere_pose = _t()
	global.jouer("pose", randf_range(-2.0, 0.0), randf_range(-0.8, 0.8))


# Une pièce passe le bord. (29/09 — de VRAIES pièces : « ça fait jeton, on veut un bruit de pièce, comme dans les vrais coin
# pushers » ; « la satisfaction, c'est quand un gros paquet tombe d'un coup ».)
#   · la cascade MONTE, mais discrètement (MONTEE, ~3,5 demi-tons au plus) : une vraie pièce montée d'une octave sonnait
#     comme un jouet ; les pièces qui se suivent brillent un peu plus, sans faire une mélodie ;
#   · le PAQUET : les pièces tombées à moins de PAQUET_S l'une de l'autre forment un paquet ; à la 3ᵉ, le petit paquet
#     sonne (6 vraies chutes empilées), à la 7ᵉ le gros (16, et le choc du tas dans le bac) — une fois par paquet (au film :
#     à 4 et 9, 85 s de jeu n'avaient donné aucun gros paquet) ; un OBJET qui tombe l'amène toujours (objet_tombe) ;
#   · dans un paquet serré, une pièce sur deux se tait (le paquet les porte ; les voix restent libres).
static func gain() -> void:
	if global == null:
		return
	var t := _t()
	var suit := t - global._dernier_gain < CASCADE_S
	global._cascade = mini(global._cascade + 1, MONTEE.size() - 1) if suit else 0
	global._groupe = global._groupe + 1 if t - global._dernier_gain < PAQUET_S else 1
	var serre := t - global._dernier_gain < 0.04
	global._dernier_gain = t
	if global._groupe == 3:
		global.jouer("paquet-1", 0.0, randf_range(-0.5, 0.5))
	elif global._groupe == 7:
		_gros_paquet()
	if serre and global._groupe % 2 == 0:
		return
	global.jouer("gain", randf_range(-1.5, 0.0), float(MONTEE[global._cascade]) + randf_range(-0.4, 0.4))


# LA SUPERNOVA (30/09) : l'aspiration qui monte, puis la révélation et les cloches les plus riches — le gros son.
static func supernova() -> void:
	if global == null:
		return
	inv("aspiration", 2.0, 5.0)
	global.get_tree().create_timer(0.32).timeout.connect(func():
		inv("revelation", 2.0, 0.0)
		rarete(5))


# Le gros paquet : pas deux fois de suite (un objet qui tombe, puis les pièces de son amas).
static func _gros_paquet() -> void:
	if _t() - global._dernier_gros > 0.6:
		global._dernier_gros = _t()
		global.jouer("paquet-2", 0.0, randf_range(-0.5, 0.5))


# Un objet tombe : il tombe avec son amas (29/09 — « quand un objet tombe, il tombe avec un petit amas de pièces qui fait un
# bruit plus lourd de plein de pièces qui tombent, c'est la sensation addictive qu'on cherche »).
static func objet_tombe() -> void:
	if global != null:
		_gros_paquet()


# Un objet gagné : l'étoile au ton juste, la poussière plus claire, une pierre plus grave, la lune plus haut.
static func objet(t: String) -> void:
	var dt := 0.0
	var db := 0.0
	if t == "poussiere":
		dt = 2.0
		db = -4.0
	elif t == "pierre-lune":
		dt = 5.0                     # (29/09 : +7 → +5, −2 dB : une quinte au-dessus, il redevenait aigu)
		db = -2.0
	elif t.begins_with("pierre-"):
		dt = -3.0
		db = -2.0
	sonner("objet", db, dt)


# L'ENTRECHOC (29/09 — Maxim : « quand le plateau du haut se rétracte, il y a un son de jeton […] quand les pièces
# s'entrechoquent, c'est aussi un son de jeton ; ça doit être des pièces pour l'entrechoc, et le plateau qui se rétracte, pas
# de bruit ») : le poussoir ne sonne plus (c'était le « froissement », des grains de jetons à chaque poussée) ; une pièce qui
# TOMBE sur le tas (du bloc du haut, d'une pile) sonne quand elle y arrive : de vraies pièces sur des pièces, quatre prises.
static func entrechoc() -> void:
	if global == null or global._grains.is_empty() or _t() - global._dernier_choc < 0.08:
		return
	global._dernier_choc = _t()
	global.jouer("entrechoc", randf_range(-5.0, 0.0), randf_range(-2.0, 2.0), global._grains[randi() % global._grains.size()])


# ── L'interface ──────────────────────────────────────────────

# Un bouton touché : très court ; pas deux dans la même image (un bouton qui en déclenche un autre).
static func bouton() -> void:
	if global == null or _t() - global._dernier_bouton < 0.04:
		return
	global._dernier_bouton = _t()
	global.jouer("bouton", 0.0, randf_range(-0.5, 0.5))


# ── L'invocation, le combat ──────────────────────────────────

# Une carte rare se révèle : rang de variante 1 (Or) à 5 (Full art) ; la Base ne sonne pas.
static func rarete(rang_variante: int) -> void:
	if global != null and rang_variante >= 1:
		global.jouer("rarete-%d" % clampi(rang_variante, 1, 5), 0.0, 0.0, null, "rarete")


# Le rang annoncé : la Légende au ton juste, le Mythe un peu plus bas.
static func rang(r: String) -> void:
	if r == "legende":
		sonner("rang", 0.0, 0.0)
	elif r == "mythe":
		sonner("rang", -2.0, -3.0)


# La k-ième carte retournée d'un même coup (k = 0, 1, 2…) : chacune monte d'une note (une chaîne chante).
static func retourne_combat(k: int) -> void:
	sonner("retourne-combat", 0.0, float(PENTA[clampi(k, 0, PENTA.size() - 1)]))


# La fin d'un combat.
static func fin(j: int, a: int, parfait: bool) -> void:
	if parfait:
		sonner("parfait")
	elif j > a:
		sonner("victoire")
	elif j < a:
		sonner("defaite")
	else:
		sonner("defaite", 0.0, 3.0)


# ── La partition de l'invocation ─────────────────────────────

var _partition_gen := 0


# Un son de la bande-son de l'invocation, dans l'ambiance choisie.
static func inv(nom: String, db := 0.0, demi_tons := 0.0) -> void:
	if global != null:
		global.jouer("inv-%s-%s" % [ambiance_invocation, nom], db, demi_tons, null, "inv-" + nom)


# Joue une partition : [[instant (s), nom, dB, demi-tons], …], chaque son à son instant (le temps du jeu, comme le rituel).
# « encore » dit si elle vaut toujours (l'invocation n'a pas été passée d'un toucher, ni remplacée) ; une nouvelle
# partition, ou arreter_partition(), fait taire ce qui restait de l'ancienne.
static func partition(ev: Array, encore: Callable) -> void:
	if global == null:
		return
	global._partition_gen += 1
	var g := global._partition_gen
	for e in ev:
		var t := float(e[0])
		if t <= 0.0:
			inv(str(e[1]), float(e[2]), float(e[3]))
			continue
		global.get_tree().create_timer(t).timeout.connect(func():
			if global != null and global._partition_gen == g and encore.call():
				inv(str(e[1]), float(e[2]), float(e[3])))


static func arreter_partition() -> void:
	if global != null:
		global._partition_gen += 1


# Les étoiles d'une constellation qui s'allument (leurs instants) : chacune tinte, de plus en plus haut, de la première à la
# dernière ; pas deux dans les 45 ms (une ×10 en allume des dizaines).
static func notes_etoiles(instants: Array) -> Array:
	var ts := instants.duplicate()
	ts.sort()
	var gardes := []
	for t in ts:
		if gardes.is_empty() or float(t) - float(gardes[-1]) >= 0.045:
			gardes.append(float(t))
	var ev := []
	for k in gardes.size():
		var i := int(float(k) * GAMME.size() / maxf(1.0, gardes.size()))
		ev.append([gardes[k], "etoile", randf_range(-2.0, 0.0), float(GAMME[mini(i, GAMME.size() - 1)])])
	return ev


# Le souffle étiré à la durée voulue (jusqu'au verrou) : en demi-tons (plus long = un peu plus grave, comme un vrai ralenti).
static func demi_tons_pour(duree: float) -> float:
	return 12.0 * log(SOUFFLE_S / maxf(0.2, duree)) / log(2.0)


# ── Les musiques ─────────────────────────────────────────────

# La musique de fond au lancement, à son niveau d'emblée.
func musique() -> void:
	changer_musique("musique", false)


# DEUX MUSIQUES HORS COMBAT (29/09 — Maxim : « j'adore la CA8 et la CA0 […] une est plus calme et l'autre plus rythmée, on
# pourrait les utiliser dans 2 situations ? » ; puis « CA0 pour la Nébuleuse et l'autre pour le reste ») : la Nébuleuse a
# la plus calme (Starfield Romance, musique-nebuleuse.ogg) ; l'Astrolabe, l'Atlas, le Voyage et le Menu, la plus rythmée
# (First Light Particles, musique.ogg).
static func musique_de(ecran: String) -> String:
	return "musique-nebuleuse" if ecran == "nebuleuse" else "musique"


# Où en est la musique qui joue (le temps écoulé depuis son départ, bouclé) — sans demander au lecteur : sur le web, les
# sons sont des échantillons du navigateur.
func _position_actuelle() -> float:
	if _musique.stream == null:
		return 0.0
	var l := _musique.stream.get_length()
	var p := _depart_pos + (Time.get_ticks_msec() - _depart_ms) / 1000.0
	return fmod(p, l) if l > 0.0 else 0.0


# Passer d'une musique à l'autre (le jeu ⇄ le combat, la Nébuleuse ⇄ les autres écrans) : le bus « Musique » descend, la
# nouvelle part — là où elle en était (la musique du combat, du début) —, le bus remonte au volume des Réglages.
# 🔴 Le fondu se fait sur le BUS : sur le web, le volume d'un son qui joue ne suit pas.
func changer_musique(nom: String, fondu := true) -> void:
	if _fondu != null and _fondu.is_valid():
		_fondu.kill()
		Reglages.appliquer()          # un fondu coupé en route (des onglets touchés vite) : le bus remonte
	if nom == _musique_nom and _musique.playing:
		return
	var s := _charger(nom)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	var bus := AudioServer.get_bus_index("Musique")
	var cible := linear_to_db(maxf(Reglages.musique, 0.0001))
	var lancer := func():
		if _musique_nom != "" and _musique.playing:
			_positions[_musique_nom] = _position_actuelle()
		_musique_nom = nom
		_musique.stop()
		_musique.stream = s
		_musique.volume_db = float(NIVEAUX.get(nom, 0.0))
		var pos := 0.0 if nom == "musique-combat" else float(_positions.get(nom, 0.0))
		_musique.play(pos)
		_depart_ms = Time.get_ticks_msec()
		_depart_pos = pos
	if not fondu or bus < 0 or not _musique.playing:
		lancer.call()
		Reglages.appliquer()
		return
	_fondu = create_tween()
	_fondu.tween_method(func(v: float): AudioServer.set_bus_volume_db(bus, v), cible, -40.0, 0.35)
	_fondu.tween_callback(lancer)
	_fondu.tween_method(func(v: float): AudioServer.set_bus_volume_db(bus, v), -40.0, cible, 0.6)
	_fondu.tween_callback(Reglages.appliquer)
