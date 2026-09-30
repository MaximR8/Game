class_name Portails
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LES PORTAILS DE L'ASTROLABE (FEATURES ⑩, fiche acceptée le 28/09). On invoque dans un ciel :
#   · LE GRAND CIEL, permanent : les chances de toujours (GS.RARETES, GS.VARIANTES) ; le premier pack s'y ouvre ;
#   · LE CIEL DU PEINTRE (le Peintre est une vraie constellation ; un Full art, c'est la carte peinte en entier) :
#     le Full art y tombe deux fois plus (0,2 % au lieu de 0,1 %, pris sur la Base) ; il tombe toujours sur un Héros,
#     un Mythe ou une Légende (jamais un sbire) ; la centième invocation sans Full art en donne un d'office ; au
#     premier Full art, le ciel se referme pour de bon. Sa première invocation ×10 est offerte (Maxim, 28/09 : « c'est un
#     cadeau pour les utilisateurs ») : elle compte dans les 100.
# Maxim, 28/09 : « si l'utilisateur a dépensé 100 étoiles, la 100ème c'est d'office un Full art ».
#
# Dans GS.voyage["portails"] = {"peintre": {"n": invocations faites depuis le dernier Full art, "ferme", "offerte" (prise),
# "adieu" (le mot de la fermeture, montré)}}. Une partie qui n'a pas la clé : le compteur à 0, le ciel ouvert, le cadeau dû.
# Le tirage lui-même est dans GS (tirer, invoquer_multi) : ici, les règles de chaque ciel et ce qu'il retient.
# ─────────────────────────────────────────────────────────────

const LISTE := [
	{"id": "grand", "nom": "Le Grand Ciel", "court": "Grand Ciel"},
	{"id": "peintre", "nom": "Le Ciel du Peintre", "court": "Ciel du Peintre",
		"full_x": 2,                                   # le Full art, deux fois plus
		"rangs_full": ["heros", "mythe", "legende"],   # un Full art n'y est jamais un sbire
		"garantie": 100,                               # la centième invocation sans Full art en donne un
		"unique": true,                                # au premier Full art, le ciel se referme
		"offerte": true},                              # la première ×10 est offerte (Maxim, 28/09 : « une ×10, pas 1 »)
]
# À partir de là, le compteur passe en or : « Plus que 10 ! »
const ALERTE_GARANTIE := 10


static func fiche(id: String) -> Dictionary:
	for f in LISTE:
		if f["id"] == id:
			return f
	return LISTE[0]


# 🔴 Nettoyées sur place : une valeur mal formée ne casse rien, elle repart de zéro.
static func donnees(id: String) -> Dictionary:
	var tout = GS.voyage.get("portails", null)
	if typeof(tout) != TYPE_DICTIONARY:
		tout = {}
		GS.voyage["portails"] = tout
	var d = tout.get(id, null)
	if typeof(d) != TYPE_DICTIONARY:
		d = {}
		tout[id] = d
	var n = d.get("n", 0)
	d["n"] = maxi(0, int(n)) if typeof(n) in [TYPE_INT, TYPE_FLOAT] else 0
	for k in ["ferme", "offerte", "adieu"]:
		d[k] = bool(d.get(k, false))
	return d


static func ouvert(id: String) -> bool:
	return not (bool(fiche(id).get("unique", false)) and bool(donnees(id)["ferme"]))


# Les ciels qu'on voit dans l'Astrolabe, dans l'ordre.
static func ouverts() -> Array:
	var l := []
	for f in LISTE:
		if ouvert(str(f["id"])):
			l.append(str(f["id"]))
	return l


static func garantie(id: String) -> int:
	return int(fiche(id).get("garantie", 0))


# Les invocations faites depuis le dernier Full art (le compteur de la garantie).
static func compte(id: String) -> int:
	return int(donnees(id)["n"])


# Combien d'invocations encore, la dernière comprise, jusqu'au Full art garanti (0 : pas de garantie).
static func restant(id: String) -> int:
	var g := garantie(id)
	return maxi(1, g - compte(id)) if g > 0 else 0


static func offerte_due(id: String) -> bool:
	return bool(fiche(id).get("offerte", false)) and ouvert(id) and not bool(donnees(id)["offerte"])


# Ce que coûtent n invocations dans ce ciel : la première ×10, offerte, ne coûte rien (un ×1 se paie toujours).
const OFFERTE_N := 10


static func cout(id: String, n: int) -> int:
	return 0 if n == OFFERTE_N and offerte_due(id) else n


# Les poids des variantes dans ce ciel (sur 1000, comme GS.VARIANTES) : le Full art multiplié, pris sur la Base.
static func poids_variantes(id: String) -> Array:
	var p: Array = []
	for v in GS.VARIANTES:
		p.append(int(v["poids"]))
	var x := int(fiche(id).get("full_x", 1))
	if x > 1:
		var i := GS.rang_variante("full")
		var plus := int(p[i]) * (x - 1)
		p[i] = int(p[i]) + plus
		p[0] = int(p[0]) - plus
	return p


static func rangs_full(id: String) -> Array:
	return fiche(id).get("rangs_full", [])


# ─────────────────────────────────────────────────────────────
# Ce que GS.invoquer_multi retient (il sauvegarde lui-même)
# ─────────────────────────────────────────────────────────────

static func prendre_offerte(id: String) -> void:
	donnees(id)["offerte"] = true


static func compter(id: String) -> void:
	var d := donnees(id)
	d["n"] = int(d["n"]) + 1


# Un Full art est tombé : le compteur repart à zéro ; un ciel « unique » se referme (à la fin du tirage : un ×10 finit).
static func full_tombe(id: String) -> void:
	donnees(id)["n"] = 0


static func fermer(id: String) -> void:
	donnees(id)["ferme"] = true


# Le mot de la fermeture, montré une seule fois dans l'Astrolabe.
static func adieu_a_montrer(id: String) -> bool:
	var d := donnees(id)
	return bool(d["ferme"]) and not bool(d["adieu"])


static func adieu_vu(id: String) -> void:
	donnees(id)["adieu"] = true
	GS.save_game()
