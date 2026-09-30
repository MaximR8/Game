class_name Aventure
extends RefCounted

# ─────────────────────────────────────────────────────────────
# L'AVENTURE DU VOYAGE — étape 2 du Carré (FEATURES ligne 4, fiche acceptée le 27/09 : « Go »).
#
# 10 terres de légendes × 10 niveaux. Le 10ᵉ niveau d'une terre est son boss, écrit à la main ;
# les 90 autres sont FABRIQUÉS par une formule à partir de leur numéro (DECISIONS 26/09) : même
# numéro, même niveau — même adversaire, mêmes terres, mêmes réponses à tes coups. On peut
# chercher la bonne façon de le gagner : aucun hasard.
# 🔴 Changer les listes ci-dessous (les héros d'une terre, les sbires, les formules) change les
#    niveaux déjà joués. Les ★ gagnées restent, mais le niveau n'est plus le même.
#
# Les ★ d'un niveau (un masque de 3 bits, chacune gagnée une seule fois, toutes demandent de gagner) :
#   1 : gagner · 2 : gagner avec 6 cartes ou plus · 4 : réussir le défi du niveau.
# Les coffres d'une terre s'ouvrent à 10, 20 et 30 ★. Rejouer ne rapporte que les ★ qui manquent.
#
# La progression vit dans GS.voyage["aventure"] = {"etoiles": {"<n>": masque}, "coffres": {"<ch>": [seuils]}}.
# ─────────────────────────────────────────────────────────────

const NB_TERRES := 10
const PAR_TERRE := 10
const NB_NIVEAUX := NB_TERRES * PAR_TERRE

const ETOILE_VICTOIRE := 1
const ETOILE_SIX := 2
const ETOILE_DEFI := 4
const SEUILS_COFFRES := [10, 20, 30]

# 🔴 Réglages provisoires (fiche du 27/09, à revoir avec l'économie ⑧) — voir START_HERE D11.
const POUSSIERE_BASE := 30               # 1ʳᵉ victoire : 30 + 10 × terre
const POUSSIERE_PAR_TERRE := 10
const ETOILES_BOSS := 3                  # décidé le 26/09 : 3 étoiles d'invocation au boss

# Le défi de chaque rang (1 à 9). Un rang pair, c'est l'adversaire qui commence : il pose alors ses
# 5 cartes, le chef compris (« retourne sa carte » reste possible).
# Le boss commence toujours, et son défi est de retourner SA carte sur le plateau. 🔄 La fiche du 27/09 disait
# « la victoire parfaite » : au banc, un joueur moyen la réussit 0 à 7 % du temps contre un boss —
# le coffre de 30 ★ serait hors d'atteinte. La victoire parfaite garde son animation, pour la gloire.
const DEFIS_RANG := ["premiere", "chef", "chaine", "trois", "premiere", "chef", "chaine", "trois", "chaine"]
# La 1ʳᵉ terre (le tuto) n'a pas « 3 cartes en un coup » : l'Apprenti joue au hasard, ses cartes ne
# forment jamais le groupe qu'on prend d'un coup (1 à 18 % au banc du 27/09, contre 70 à 96 % ailleurs).
const DEFIS_RANG_TUTO := ["premiere", "chef", "chaine", "chef", "premiere", "chef", "chaine", "chef", "chaine"]
const DEFI_BOSS := "chef"
const DEFIS := {
	"premiere": "Garde ta première carte jusqu'à la fin",
	# 🔴 « Retourne », pas « Prends » : Maxim a lu « Prends la carte de Fenrir » comme une carte donnée en
	#    récompense (27/09). Rien n'est donné : les cartes ne viennent que des invocations (DECISIONS 26/09).
	"chef": "Retourne la carte de %s",
	"chaine": "Retourne une carte en chaîne",
	"trois": "Retourne 3 cartes en un seul coup",
	"parfait": "Victoire parfaite : les 9 cartes à toi",
}

# Les noms des adversaires qui mènent un niveau (Claude les a écrits ; Maxim valide sur les captures).
const NOMS := {
	"korrigan": "Korrigan le danseur", "kelpie": "Kelpie des lochs", "banshee": "Banshee la pleureuse",
	"chevalier": "Le Chevalier sans tête", "thor": "Thor le tonnant", "loki": "Loki le farceur",
	"troll": "Troll des ponts", "fenrir": "Fenrir déchaîné", "ifrit": "Ifrit de la lampe",
	"roc": "Le Roc des sables", "anubis": "Anubis, peseur d'âmes", "nian": "Nian du Nouvel An",
	"kitsune": "Kitsune aux neuf queues", "tikbalang": "Tikbalang des bambous", "yeti": "Yéti des cimes",
	"wukong": "Sun Wukong, roi des singes", "minotaure": "Minotaure du labyrinthe", "cuelebre": "Cuélebre des grottes",
	"cerbere": "Cerbère, gardien des Enfers", "doudou": "El Biète de Mons", "golem": "Golem d'argile",
	"georges": "Saint Georges", "babayaga": "Baba Yaga", "mothman": "Mothman du pont",
	"thunderbird": "L'Oiseau-Tonnerre", "wendigo": "Le Wendigo", "chupacabra": "Chupacabra le furtif",
	"quetzalcoatl": "Quetzalcoatl, serpent à plumes", "anansi": "Anansi le conteur", "bunyip": "Bunyip des marais",
	"bahamut": "Bahamut, qui porte le monde",
}

# Les dix terres (fiche du 27/09, point ①). « type » : ses terres sur le plateau, la pierre de son coffre.
# 🔴 Les sbires de l'Aventure : les six du 27/09, figés. Les sbires ajoutés depuis (les invocables,
#    MoteurCarre.SBIRES) ne changent pas ses 90 niveaux fabriqués.
const SBIRES_AVENTURE := ["draugr", "farfadet", "oni", "ondine", "follet", "raiju"]

# « heros » : ceux qui mènent ses niveaux ; « sbires » : ceux de la terre, d'abord.
const TERRES := [
	{"nom": "Les Landes celtes", "phrase": "Brume, menhirs, et des chevaux qui sortent des lacs.", "type": "eau",
		"heros": ["korrigan", "kelpie", "banshee"], "sbires": ["follet", "ondine", "farfadet"],
		"boss": {"chef": "chevalier", "v": "ombre", "niveau": "aventurier", "terres": ["esprit", "eau"],
			"replique": "J'ai perdu la tête. Pas la partie.",
			"deck": [["chevalier", 2], ["banshee", 2], ["kelpie", 1], ["follet", 1], ["ondine", 1]]}},
	{"nom": "Le Grand Nord", "phrase": "Là où le tonnerre a un nom, et le loup une chaîne.", "type": "glace",
		"heros": ["thor", "loki", "troll"], "sbires": ["draugr", "raiju"],
		"boss": {"chef": "fenrir", "v": "ombre", "niveau": "maitre", "terres": ["glace", "glace"],
			"replique": "Aucune chaîne ne m'a tenu. Ce n'est pas ton carré qui le fera.",
			"deck": [["fenrir", 2], ["thor", 1], ["loki", 1], ["troll", 2], ["draugr", 1]]}},
	{"nom": "L'Orient", "phrase": "Des génies dans les lampes, des oiseaux grands comme des nuages.", "type": "feu",
		"heros": ["ifrit", "roc"], "sbires": ["oni", "raiju"],
		"boss": {"chef": "anubis", "v": "or", "niveau": "maitre", "terres": ["feu", "esprit"],
			"replique": "Pose ta carte sur la balance. On verra ce qu'elle pèse.",
			"deck": [["anubis", 2], ["ifrit", 1], ["roc", 1], ["oni", 1], ["raiju", 1]]}},
	{"nom": "L'Asie", "phrase": "Neuf queues, un roi singe, et des neiges qui marchent.", "type": "nature",
		"heros": ["nian", "kitsune", "tikbalang", "yeti"], "sbires": ["farfadet", "follet"],
		"boss": {"chef": "wukong", "v": "elem", "niveau": "maitre", "terres": ["nature", "nature"],
			"replique": "Soixante-douze métamorphoses. Tu n'en as vu aucune.",
			"deck": [["wukong", 3], ["kitsune", 2], ["yeti", 1], ["tikbalang", 1], ["farfadet", 1]]}},
	{"nom": "La Méditerranée", "phrase": "Un labyrinthe, trois têtes, et la mer tout autour.", "type": "eau",
		"heros": ["minotaure", "cuelebre"], "sbires": ["ondine", "oni"],
		"boss": {"chef": "cerbere", "v": "ombre", "niveau": "maitre", "marge": 3, "terres": ["feu", "eau"],
			"replique": "Trois têtes, trois regards. Rien ne passe.",
			"deck": [["cerbere", 3], ["minotaure", 2], ["cuelebre", 2], ["oni", 1], ["ondine", 1]]}},
	{"nom": "Le Pays du Doudou", "phrase": "Chaque année, à Mons, le dragon revient danser.", "type": "feu",
		"heros": ["doudou", "golem"], "sbires": ["oni", "farfadet"],
		"boss": {"chef": "georges", "v": "or", "niveau": "maitre", "terres": ["feu", "nature"],
			"replique": "Le dragon, je l'ai battu cent fois. Toi, une seule suffira.",
			"deck": [["georges", 3], ["doudou", 3], ["golem", 2], ["oni", 1], ["farfadet", 1]]}},
	{"nom": "Les Forêts de l'Est", "phrase": "Au fond du bois, une cabane marche sur des pattes de poule.", "type": "esprit",
		"heros": [], "sbires": ["follet", "draugr"],
		"boss": {"chef": "babayaga", "v": "ombre", "niveau": "maitre", "terres": ["esprit", "esprit"],
			"replique": "Entre, mon petit. La cabane a faim.",
			"deck": [["babayaga", 3], ["banshee", 3], ["korrigan", 1], ["follet", 1], ["draugr", 1]]}},
	{"nom": "L'Amérique du Nord", "phrase": "Des ailes dans l'orage, et quelque chose d'affamé sous les pins.", "type": "foudre",
		"heros": ["mothman", "thunderbird"], "sbires": ["raiju", "draugr"],
		"boss": {"chef": "wendigo", "v": "ombre", "niveau": "maitre", "terres": ["glace", "foudre"],
			"replique": "J'ai toujours faim. Et tu sens la victoire.",
			"deck": [["wendigo", 3], ["mothman", 3], ["thunderbird", 3], ["raiju", 1], ["yeti", 1]]}},
	{"nom": "Les Terres aztèques", "phrase": "Sur les pyramides, le vent tourne avec le serpent à plumes.", "type": "nature",
		"heros": ["chupacabra"], "sbires": ["farfadet", "raiju"],
		"boss": {"chef": "quetzalcoatl", "v": "elem", "niveau": "maitre", "marge": -2, "terres": ["foudre", "nature"],
			"replique": "Le vent tourne toujours du côté du serpent à plumes.",
			"deck": [["quetzalcoatl", 3], ["chupacabra", 3], ["ifrit", 1], ["raiju", 1], ["kitsune", 1]]}},
	{"nom": "Le Bout du monde", "phrase": "Sous toutes les terres, un poisson immense porte le monde.", "type": "eau",
		"heros": ["anansi", "bunyip"], "sbires": ["ondine", "follet"],
		"boss": {"chef": "bahamut", "v": "full", "niveau": "maitre", "marge": 10, "terres": ["eau", "eau", "eau"],
			"replique": "Tout ce que tu as traversé repose sur mon dos.",
			"deck": [["bahamut", 3], ["anansi", 1], ["bunyip", 3], ["kelpie", 2], ["ondine", 1]]}},
]


# ─────────────────────────────────────────────────────────────
# Les niveaux
# ─────────────────────────────────────────────────────────────

static func terre_de(n: int) -> int:
	return (n - 1) / PAR_TERRE + 1


static func rang_de(n: int) -> int:
	return (n - 1) % PAR_TERRE + 1


# La force du deck adverse (rangs 1 à 9 ; MoteurCarre.force_deck : ses chiffres, et 2 par pouvoir) :
# elle monte de FORCE_DEBUT au premier niveau à FORCE_FIN au dernier.
# 🔴 Pas le poids : un sbire pèse 1 et vaut ~14, un héros au stade I pèse 2 et vaut ~24. Au poids, un
#    deck de 5 héros « pesait » 12 et écrasait le joueur (niveau 72 : 11 % au banc, 27/09).
const FORCE_DEBUT := 88
const FORCE_FIN := 112
const FORCE_TOLERANCE := 3             # l'ajustement s'arrête là…
const FORCE_ECART_MAX := 5             # …ou coincé un peu plus loin (un pas de plus dépasserait) : le test l'accepte
# Un boss garde ses cartes (écrites à la main), mais leurs stades s'ajustent à la force des niveaux
# de sa terre, plus FORCE_BOSS — et si ça ne suffit pas, un héros de sa cour devient un sbire de la
# terre (le boss, jamais). Écrits d'instinct, ils allaient de 102 à 132 (20 % à Fenrir dès la
# 2ᵉ terre, 71 % au premier boss — banc du 27/09).
const FORCE_BOSS := 6


static func force_cible(n: int) -> int:
	if rang_de(n) == PAR_TERRE:
		# « marge » : un boss dont les pouvoirs pèsent plus (ou moins) que ses chiffres (banc du 27/09)
		return force_cible(n - 1) + int(TERRES[terre_de(n) - 1]["boss"].get("marge", FORCE_BOSS))
	return FORCE_DEBUT + roundi(float(FORCE_FIN - FORCE_DEBUT) * float(n - 1) / float(NB_NIVEAUX - 2))


static func ia_de(n: int) -> String:
	var t := terre_de(n)
	if t == 1:
		return "apprenti"
	if t <= 4:
		return "aventurier"
	return "maitre"


# Les terres sur le plateau (rangs 1 à 9) : aucune pour apprendre, puis une, puis deux.
# (Trois terres d'un même type donnaient trop à qui en avait les cartes : banc du 27/09.)
static func nb_terres_de(n: int) -> int:
	if n <= 3:
		return 0
	if terre_de(n) == 1:
		return 1
	return 2


# Ceux qui mènent les niveaux d'une terre : ses héros ; s'il y en a moins de 3, ceux des terres
# d'avant (les plus proches d'abord). Jamais un sbire : il n'a pas de portrait.
static func chefs_de(t: int) -> Array:
	var l: Array = (TERRES[t - 1]["heros"] as Array).duplicate()
	var k := t - 2
	while l.size() < 3 and k >= 0:
		for id in TERRES[k]["heros"]:
			if l.size() < 3 and not l.has(id):
				l.append(id)
		k -= 1
	return l


# Un niveau : tout ce qu'il faut pour le montrer et le jouer (c'est aussi « l'adversaire » que
# reçoit l'écran de combat). Toujours le même pour un même numéro.
static func niveau(n: int) -> Dictionary:
	var t := terre_de(n)
	var r := rang_de(n)
	var terre: Dictionary = TERRES[t - 1]
	var h := MoteurCarre.Hasard.new(MoteurCarre.hacher("aventure-%d" % n))
	var d := {"n": n, "terre": t, "rang": r, "boss": r == PAR_TERRE, "graine": MoteurCarre.hacher("aventure-combat-%d" % n)}
	var types_terres: Array = []
	if d["boss"]:
		var b: Dictionary = terre["boss"]
		d["chef"] = b["chef"]
		d["niveau"] = b["niveau"]
		d["replique"] = b["replique"]
		d["defi"] = DEFI_BOSS
		d["premier"] = "a"
		var deck := []
		for c in b["deck"]:
			deck.append({"id": c[0], "s": int(c[1]), "v": str(b["v"]) if c[0] == b["chef"] else "base"})
		var pris := []
		for c in deck:
			pris.append(c["id"])
		_ajuster(deck, pris, force_cible(n), [], terre["sbires"], true)    # sa cour : des stades, sinon un héros → sbire
		d["deck"] = deck
		d["chef_s"] = int(deck[0]["s"])
		types_terres = b["terres"]
	else:
		var chefs := chefs_de(t)
		var chef: String = chefs[(r - 1) % chefs.size()]
		d["chef"] = chef
		d["niveau"] = ia_de(n)
		d["defi"] = (DEFIS_RANG_TUTO if t == 1 else DEFIS_RANG)[r - 1]
		d["premier"] = "j" if r % 2 == 1 else "a"
		d["deck"] = _deck(t, n, chef, h)
		d["chef_s"] = int(d["deck"][0]["s"])
		for k in nb_terres_de(n):
			types_terres.append(terre["type"])
	d["nom"] = str(NOMS.get(d["chef"], MoteurCarre.nom(d["chef"])))
	d["prenom"] = MoteurCarre.nom(d["chef"])
	d["terres"] = _placer_terres(types_terres, h)
	d["recompense"] = recompense_victoire(n)
	return d


# Le deck adverse d'un rang 1 à 9 : le chef en tête, puis 4 cartes de la terre et d'avant, tirées de
# la graine du niveau, puis ajustées à la force visée, un pas à la fois (le meilleur pas : un stade de
# plus ou de moins, un héros qui devient sbire ou l'inverse — le chef reste). Toujours le même deck.
static func _deck(t: int, n: int, chef: String, h: MoteurCarre.Hasard) -> Array:
	var cible := force_cible(n)
	var heros := []
	for k in t:
		for id in TERRES[k]["heros"]:
			if id != chef and not heros.has(id):
				heros.append(id)
	var sbires: Array = (TERRES[t - 1]["sbires"] as Array).duplicate()
	for s in SBIRES_AVENTURE:
		if not sbires.has(s):
			sbires.append(s)
	var deck := [{"id": chef, "s": _stade_au_hasard(chef, h), "v": "base"}]
	var pris := [chef]
	while deck.size() < MoteurCarre.TAILLE_DECK:
		var id: String
		if not heros.is_empty() and h.suivant() < 0.5:
			id = heros[int(floor(h.suivant() * heros.size()))]
		else:
			# les sbires de la terre d'abord : les premiers de la liste sortent plus souvent
			id = sbires[mini(int(floor(h.suivant() * h.suivant() * sbires.size())), sbires.size() - 1)]
		if pris.has(id):
			continue
		pris.append(id)
		deck.append({"id": id, "s": _stade_au_hasard(id, h), "v": "base"})
	MoteurCarre.melanger(heros, h)
	_ajuster(deck, pris, cible, heros, sbires, false)
	return deck


# chef_fixe : le boss garde son stade (le boss final dans sa forme « mignonne », c'est un contresens).
static func _ajuster(deck: Array, pris: Array, cible: int, heros: Array, sbires: Array, chef_fixe: bool) -> void:
	# d'abord le premier remplaçant de chaque carte (les niveaux d'avant le 27/09 restent les mêmes) ;
	# coincé trop loin, on essaie tous les remplaçants (les rangs, 27/09 : un Mythe, une Légende ont
	# de plus gros chiffres, et le premier remplaçant ne suffit plus toujours)
	for tous in [false, true]:
		if tous and absi(MoteurCarre.force_deck(deck) - cible) <= FORCE_ECART_MAX:
			return
		for garde in 30:
			if absi(MoteurCarre.force_deck(deck) - cible) <= FORCE_TOLERANCE:
				return
			var pas := _meilleur_pas(deck, pris, cible, heros, sbires, chef_fixe, tous)
			if pas.is_empty():
				break
			deck[pas["k"]] = pas["carte"]
			pris.erase(pas["ancien"])
			pris.append(pas["carte"]["id"])


# Parmi les retouches possibles (le chef ne change que de stade), celle qui rapproche le plus de la
# force visée ; {} si aucune ne rapproche.
static func _meilleur_pas(deck: Array, pris: Array, cible: int, heros: Array, sbires: Array, chef_fixe: bool, tous := false) -> Dictionary:
	var ecart0 := absi(MoteurCarre.force_deck(deck) - cible)
	var meilleur := {}
	var ecart_min := ecart0
	for k in deck.size():
		var c: Dictionary = deck[k]
		var id := str(c["id"])
		var f := MoteurCarre.fiche(id)
		var essais := []
		if not f["sbire"] and not MoteurCarre.un_seul(id) and not (chef_fixe and k == 0):
			for s in [int(c["s"]) - 1, int(c["s"]) + 1]:
				if s >= 1 and s <= int(f["stades"]):
					essais.append({"id": id, "s": s, "v": str(c.get("v", "base"))})
		if k > 0:
			for autre in (heros if f["sbire"] else sbires):
				if not pris.has(autre):
					essais.append({"id": autre, "s": 1, "v": "base"})
					if not tous:
						break
			# la seconde passe : un héros peut aussi céder sa place à un autre héros de la cour
			if tous and not f["sbire"]:
				for autre in heros:
					if not pris.has(autre):
						essais.append({"id": autre, "s": 1, "v": "base"})
		for e in essais:
			var essai := deck.duplicate()
			essai[k] = e
			var ecart := absi(MoteurCarre.force_deck(essai) - cible)
			if ecart < ecart_min:
				ecart_min = ecart
				meilleur = {"k": k, "carte": e, "ancien": id}
	return meilleur


static func _stade_au_hasard(id: String, h: MoteurCarre.Hasard) -> int:
	var f := MoteurCarre.fiche(id)
	if f["sbire"]:
		return 1
	return 1 + int(floor(h.suivant() * int(f["stades"])))


static func _placer_terres(types: Array, h: MoteurCarre.Hasard) -> Dictionary:
	var cases := [0, 1, 2, 3, 4, 5, 6, 7, 8]
	MoteurCarre.melanger(cases, h)
	var terres := {}
	for k in types.size():
		terres[cases[k]] = types[k]
	return terres


# La règle du niveau, en une ligne (l'écran d'avant le combat).
static func texte_defi(d: Dictionary) -> String:
	var t := str(DEFIS[d["defi"]])
	return t % str(d["prenom"]) if "%s" in t else t


static func regle(d: Dictionary) -> String:
	var terres: Dictionary = d["terres"]
	if terres.is_empty():
		return "Pas de terre : seuls les chiffres comptent."
	var par_type := {}
	for i in terres:
		par_type[terres[i]] = int(par_type.get(terres[i], 0)) + 1
	var morceaux := []
	for ty in par_type:
		var nom := str(GS.TYPES[ty]["nom"])
		morceaux.append("%d case%s de %s" % [par_type[ty], "s" if par_type[ty] > 1 else "", nom])
	return "Terres : %s. Une carte de ce type y gagne +1." % " et ".join(morceaux)


# ─────────────────────────────────────────────────────────────
# Les étoiles d'un combat
# ─────────────────────────────────────────────────────────────

# journal : un élément par coup joué, {camp, case, id, ev} (carre_ecran.gd le tient) ; st : la fin.
static func etoiles(d: Dictionary, journal: Array, st: Dictionary) -> int:
	var j := MoteurCarre.compte(st, "j")
	var a := MoteurCarre.compte(st, "a")
	if j <= a:
		return 0
	var m := ETOILE_VICTOIRE
	if j >= 6:
		m |= ETOILE_SIX
	if defi_reussi(str(d["defi"]), d, journal, st):
		m |= ETOILE_DEFI
	return m


static func defi_reussi(defi: String, d: Dictionary, journal: Array, st: Dictionary) -> bool:
	match defi:
		"premiere":
			for c in journal:
				if c["camp"] == "j":
					var posee = st["cases"][int(c["case"])]
					return posee != null and posee["camp"] == "j"
			return false
		"chef":
			for c in journal:
				if c["camp"] == "a" and c["id"] == d["chef"]:
					var posee = st["cases"][int(c["case"])]
					return posee != null and posee["camp"] == "j"
			return false
		"chaine", "trois":
			for c in journal:
				if c["camp"] != "j":
					continue
				var pris := 0
				for e in c["ev"]:
					if e["t"] == "flip" and e["camp"] == "j":
						pris += 1
						if defi == "chaine" and e["chaine"]:
							return true
				if defi == "trois" and pris >= 3:
					return true
			return false
		"parfait":
			var libres := 0
			for i in (st["cases"] as Array).size():
				if not (st["bloc"] as Array).has(i):
					libres += 1
			return MoteurCarre.compte(st, "j") == libres
	return false


static func nb_etoiles(masque: int) -> int:
	return (masque & 1) + ((masque >> 1) & 1) + ((masque >> 2) & 1)


# ─────────────────────────────────────────────────────────────
# La progression (GS.voyage["aventure"]) et les récompenses
# ─────────────────────────────────────────────────────────────

# Lue avec prudence : une sauvegarde abîmée ou d'avant l'Aventure donne une Aventure vierge.
static func _donnees() -> Dictionary:
	var a = GS.voyage.get("aventure", null)
	if typeof(a) != TYPE_DICTIONARY:
		a = {}
		GS.voyage["aventure"] = a
	if typeof(a.get("etoiles", null)) != TYPE_DICTIONARY:
		a["etoiles"] = {}
	if typeof(a.get("coffres", null)) != TYPE_DICTIONARY:
		a["coffres"] = {}
	return a


static func masque(n: int) -> int:
	var v = _donnees()["etoiles"].get(str(n), 0)
	return int(v) & 7 if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0


static func gagne(n: int) -> bool:
	return masque(n) & ETOILE_VICTOIRE != 0


static func niveau_ouvert(n: int) -> bool:
	return n >= 1 and n <= NB_NIVEAUX and (n == 1 or gagne(n - 1))


static func terre_ouverte(t: int) -> bool:
	return t == 1 or gagne((t - 1) * PAR_TERRE)


static func etoiles_terre(t: int) -> int:
	var total := 0
	for r in PAR_TERRE:
		total += nb_etoiles(masque((t - 1) * PAR_TERRE + r + 1))
	return total


static func etoiles_total() -> int:
	var total := 0
	for t in NB_TERRES:
		total += etoiles_terre(t + 1)
	return total


# Le prochain combat : le premier niveau pas encore gagné ; tout gagné, le premier qui n'a pas ses 3 ★.
static func prochain() -> int:
	for n in range(1, NB_NIVEAUX + 1):
		if not gagne(n):
			return n
	for n in range(1, NB_NIVEAUX + 1):
		if masque(n) != 7:
			return n
	return NB_NIVEAUX


static func recompense_victoire(n: int) -> Dictionary:
	return {"poussiere": POUSSIERE_BASE + POUSSIERE_PAR_TERRE * terre_de(n),
		"etoiles": ETOILES_BOSS if rang_de(n) == PAR_TERRE else 0}


# Retient le résultat d'un combat, donne ce qui est dû, et le dit :
# {nouvelles (masque des ★ gagnées pour la première fois), premiere_victoire, poussiere, etoiles}.
# Rejouer ne rapporte que les ★ qui manquent ; la récompense de victoire, une seule fois.
static func enregistrer(n: int, m: int) -> Dictionary:
	var avant := masque(n)
	var nouvelles := m & ~avant & 7
	var r := {"nouvelles": nouvelles, "premiere_victoire": false, "poussiere": 0, "etoiles": 0}
	if nouvelles == 0:
		return r
	_donnees()["etoiles"][str(n)] = avant | nouvelles
	if nouvelles & ETOILE_VICTOIRE:
		var g := recompense_victoire(n)
		r["premiere_victoire"] = true
		r["poussiere"] = g["poussiere"]
		r["etoiles"] = g["etoiles"]
		GS.gagner(g["poussiere"], g["etoiles"])     # écrit la sauvegarde s'il y a des étoiles
	GS.save_game()                                 # les ★ s'écrivent tout de suite
	return r


static func recompense_coffre(t: int, seuil: int) -> Dictionary:
	match seuil:
		10:
			return {"poussiere": 0, "etoiles": 0, "pierre": str(TERRES[t - 1]["type"])}
		20:
			return {"poussiere": 0, "etoiles": 1, "pierre": ""}
		30:
			return {"poussiere": 0, "etoiles": 2, "pierre": "lune"}
	return {"poussiere": 0, "etoiles": 0, "pierre": ""}


static func coffre_ouvert(t: int, seuil: int) -> bool:
	var l = _donnees()["coffres"].get(str(t), [])
	if typeof(l) != TYPE_ARRAY:
		return false
	for x in l:
		if typeof(x) in [TYPE_INT, TYPE_FLOAT] and int(x) == seuil:
			return true
	return false


# Les coffres d'une terre qu'on peut ouvrir : seuil atteint, pas encore ouvert.
static func coffres_prets(t: int) -> Array:
	var l := []
	var e := etoiles_terre(t)
	for s in SEUILS_COFFRES:
		if e >= s and not coffre_ouvert(t, s):
			l.append(s)
	return l


# Ouvre un coffre (une seule fois) et donne son contenu ; {} s'il n'est pas prêt.
static func ouvrir_coffre(t: int, seuil: int) -> Dictionary:
	if not coffres_prets(t).has(seuil):
		return {}
	var c: Dictionary = _donnees()["coffres"]
	var l = c.get(str(t), [])
	if typeof(l) != TYPE_ARRAY:
		l = []
	l.append(seuil)
	c[str(t)] = l
	var g := recompense_coffre(t, seuil)
	GS.gagner(g["poussiere"], g["etoiles"], g["pierre"])
	GS.save_game()
	return g
