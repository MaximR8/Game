class_name Classe
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LE CLASSÉ — étape 3 du Carré (DECISIONS 26/09 ; fiche acceptée le 28/09).
#
# Une échelle de 6 rangs : Météore → Comète → Aurore → Éclipse → Galaxie → Zénith (Maxim, 28/09 : « OK » ;
# Poussière, Étoile, Nébuleuse, Constellation et Légende disaient déjà autre chose dans le jeu). Les cinq
# premiers ont 3 marches (III, II, I) de 100 points ; le Zénith n'en a pas, ses points s'accumulent.
# Une victoire +25, une défaite −20 ; le surplus passe à la marche suivante, le manque fait redescendre.
# Chaque RANG atteint est un plancher pour la saison : on n'en retombe pas.
#
# La force de l'adversaire vient de la MARCHE, pas du joueur (Maxim, 28/09 : « ça doit se mériter ») :
# qui cale reste là. Réglée au banc (tests/banc_fantomes) : le meilleur joueur simulé, avec le meilleur
# deck, touche le Zénith ; un joueur moyen cale au milieu.
#
# La saison, c'est le mois du calendrier (DECISIONS 26/09 : tout suit un calendrier écrit d'avance, rien à
# lancer à la main). À la première ouverture dans un nouveau mois : la récompense du meilleur rang de la
# saison finie (si on y a joué), puis on redescend d'un rang par mois passé. Une horloge qui recule ne
# fait jamais revenir une saison.
#
# Dans GS.voyage["classe"] = {saison "AAAA-MM", palier 0-15, points, meilleur, joues, historique, fin}
# (« fin » : la saison qui vient de finir, à montrer une fois). Relue avec prudence.
# ─────────────────────────────────────────────────────────────

const RANGS := [
	{"id": "meteore", "nom": "Météore"},
	{"id": "comete", "nom": "Comète"},
	{"id": "aurore", "nom": "Aurore"},
	{"id": "eclipse", "nom": "Éclipse"},
	{"id": "galaxie", "nom": "Galaxie"},
	{"id": "zenith", "nom": "Zénith"},
]
const MARCHES := 3
const ZENITH := 15                      # le palier du Zénith (5 rangs × 3 marches avant lui)
const POINTS_MARCHE := 100
const GAIN := 25
const PERTE := 20

# 🔴 Réglés au banc (tests/banc_fantomes, 28/09) : la cote de l'adversaire à chaque marche.
const COTE_PALIER_0 := 800
const COTE_PAR_PALIER := 60

# 🔴 Provisoire (D11, en attente de l'économie ⑧) : [étoiles, poussière] selon le meilleur rang.
const RECOMPENSES := [[0, 50], [1, 100], [1, 200], [2, 300], [3, 400], [5, 500]]

# Les saisons, mois par mois : les constellations du ciel du soir (écrites le 28/09, à valider sur les captures).
const SAISONS := ["d'Orion", "des Gémeaux", "du Lion", "de la Grande Ourse", "du Dragon", "d'Hercule",
	"du Scorpion", "de l'Aigle", "de la Lyre", "du Cygne", "de Pégase", "de Cassiopée"]
const MOIS := ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre",
	"octobre", "novembre", "décembre"]
const HISTORIQUE := 5

# Les tests fixent la date ici ({year, month, day}) ; vide : l'horloge du téléphone.
static var date_test := {}


# ─────────────────────────────────────────────────────────────
# Les paliers
# ─────────────────────────────────────────────────────────────

static func rang_de(p: int) -> int:
	return mini(clampi(p, 0, ZENITH) / MARCHES, RANGS.size() - 1)


# 3, 2 ou 1 (la marche III est la première d'un rang) ; 0 au Zénith.
static func marche_de(p: int) -> int:
	if p >= ZENITH:
		return 0
	return MARCHES - p % MARCHES


static func nom_rang(p: int) -> String:
	return str(RANGS[rang_de(p)]["nom"])


static func nom_palier(p: int) -> String:
	var m := marche_de(p)
	return nom_rang(p) if m == 0 else "%s %s" % [nom_rang(p), ["", "I", "II", "III"][m]]


# Le plancher : la première marche du plus haut rang atteint.
static func plancher_de(meilleur: int) -> int:
	return mini(rang_de(meilleur) * MARCHES, ZENITH)


static func cote_adversaire(p: int) -> int:
	return COTE_PALIER_0 + clampi(p, 0, ZENITH) * COTE_PAR_PALIER


# ─────────────────────────────────────────────────────────────
# Les données
# ─────────────────────────────────────────────────────────────

static func _entier(v, defaut: int) -> int:
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else defaut


# 🔴 Nettoyées SUR PLACE : toujours le même dictionnaire (un écran qui le garde écrit au bon endroit).
static func donnees() -> Dictionary:
	var c = GS.voyage.get("classe", null)
	if typeof(c) != TYPE_DICTIONARY:
		c = {}
		GS.voyage["classe"] = c
	var s = c.get("saison", "")
	c["saison"] = str(s) if typeof(s) == TYPE_STRING and _saison_valide(str(s)) else ""
	c["palier"] = clampi(_entier(c.get("palier"), 0), 0, ZENITH)
	c["points"] = maxi(0, _entier(c.get("points"), 0))
	c["joues"] = maxi(0, _entier(c.get("joues"), 0))
	if typeof(c.get("historique", null)) != TYPE_ARRAY:
		c["historique"] = []
	if typeof(c.get("fin", null)) != TYPE_DICTIONARY:
		c["fin"] = {}
	c["meilleur"] = clampi(_entier(c.get("meilleur"), 0), c["palier"], ZENITH)
	if c["palier"] < ZENITH:
		c["points"] = mini(c["points"], POINTS_MARCHE - 1)
	return c


static func _saison_valide(s: String) -> bool:
	var morceaux := s.split("-")
	return morceaux.size() == 2 and morceaux[0].is_valid_int() and morceaux[1].is_valid_int() \
		and int(morceaux[1]) >= 1 and int(morceaux[1]) <= 12


static func aujourdhui() -> Dictionary:
	return date_test if not date_test.is_empty() else Time.get_date_dict_from_system()


static func saison_du(d: Dictionary) -> String:
	return "%04d-%02d" % [int(d["year"]), int(d["month"])]


static func saison_actuelle() -> String:
	return saison_du(aujourdhui())


# Le nombre de mois de la saison a à la saison b (négatif si b est avant a).
static func mois_entre(a: String, b: String) -> int:
	var x := a.split("-")
	var y := b.split("-")
	return (int(y[0]) - int(x[0])) * 12 + int(y[1]) - int(x[1])


static func nom_saison(s: String) -> String:
	return "Saison %s" % SAISONS[int(s.split("-")[1]) - 1]


# Au milieu d'une phrase : « la saison du Cygne » (la constellation garde sa majuscule).
static func nom_saison_phrase(s: String) -> String:
	return "saison %s" % SAISONS[int(s.split("-")[1]) - 1]


static func mois_de(s: String) -> String:
	return MOIS[int(s.split("-")[1]) - 1]


# Les jours qui restent avant la fin du mois (le dernier jour : 1).
static func jours_restants() -> int:
	var d := aujourdhui()
	var y := int(d["year"])
	var m := int(d["month"])
	var longueurs := [31, 29 if (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	return int(longueurs[m - 1]) - int(d["day"]) + 1


static func recompense(rang: int) -> Dictionary:
	var r: Array = RECOMPENSES[clampi(rang, 0, RECOMPENSES.size() - 1)]
	return {"etoiles": int(r[0]), "poussiere": int(r[1])}


# ─────────────────────────────────────────────────────────────
# La saison
# ─────────────────────────────────────────────────────────────

# À chaque arrivée sur le Voyage, et avant chaque combat classé. Une saison finie : sa récompense est
# DONNÉE ET ÉCRITE ici, avant d'être montrée (« fin », que l'écran lit puis efface) — une app fermée
# pendant le panneau ne la redonne pas, et ne la perd pas. Rend « fin » s'il vient d'être écrit, {} sinon.
static func verifier_saison() -> Dictionary:
	var c := donnees()
	var maintenant := saison_actuelle()
	if c["saison"] == "":
		c["saison"] = maintenant
		GS.save_game()
		return {}
	var n := mois_entre(c["saison"], maintenant)
	if n <= 0:
		return {}                       # la même saison, ou une horloge qui a reculé : rien ne change
	var r_meilleur := rang_de(c["meilleur"])
	var g := recompense(r_meilleur) if int(c["joues"]) > 0 else {"etoiles": 0, "poussiere": 0}
	var r_nouveau := maxi(0, rang_de(c["palier"]) - n)
	var fin := {"saison": c["saison"], "rang": r_meilleur, "joues": int(c["joues"]),
		"etoiles": g["etoiles"], "poussiere": g["poussiere"], "nouveau": r_nouveau * MARCHES}
	c["saison"] = maintenant
	c["palier"] = r_nouveau * MARCHES
	c["meilleur"] = c["palier"]
	c["points"] = 0
	c["joues"] = 0
	c["historique"] = []
	c["fin"] = fin
	if g["etoiles"] > 0 or g["poussiere"] > 0:
		GS.gagner(g["poussiere"], g["etoiles"])
	GS.save_game()
	return fin


# Le mois a changé depuis la saison retenue (verifier_saison() a quelque chose à faire).
static func saison_changee() -> bool:
	var c := donnees()
	return c["saison"] != "" and mois_entre(c["saison"], saison_actuelle()) > 0


# Ce que verifier_saison() va donner, sans rien changer ({} : rien). L'écran retient d'autant les
# compteurs du bandeau AVANT, pour les faire s'envoler ensuite.
static func recompense_en_attente() -> Dictionary:
	var c := donnees()
	if c["saison"] == "" or mois_entre(c["saison"], saison_actuelle()) <= 0 or int(c["joues"]) <= 0:
		return {}
	return recompense(rang_de(c["meilleur"]))


# Le panneau de fin de saison a été vu.
static func fin_vue() -> void:
	donnees()["fin"] = {}
	GS.save_game()


# ─────────────────────────────────────────────────────────────
# Un combat
# ─────────────────────────────────────────────────────────────

# Retient un combat classé (1 : gagné, 0 : égalité, −1 : perdu) et rend ce qui a bougé :
# {avant, apres (paliers), points_avant, points, delta, monte, descend, plancher (vrai si le plancher a retenu)}.
static func enregistrer(resultat: int, adv: Dictionary = {}, interrompu := false) -> Dictionary:
	var c := donnees()
	var p: int = c["palier"]
	var pts: int = c["points"]
	var r := {"avant": p, "points_avant": pts, "monte": false, "descend": false, "plancher": false}
	var delta := 0
	if resultat > 0:
		delta = GAIN
		pts += GAIN
		if p < ZENITH and pts >= POINTS_MARCHE:
			p += 1
			pts = pts - POINTS_MARCHE if p < ZENITH else 0
			r["monte"] = true
	elif resultat < 0:
		delta = -PERTE
		pts -= PERTE
		if pts < 0:
			if p > plancher_de(c["meilleur"]):
				p -= 1
				pts += POINTS_MARCHE
				r["descend"] = true
			else:
				r["plancher"] = true
				pts = 0
	c["palier"] = p
	c["points"] = pts
	c["meilleur"] = maxi(int(c["meilleur"]), p)
	c["joues"] = int(c["joues"]) + 1
	var h: Array = c["historique"]
	h.push_front({"chef": str(adv.get("chef", "")), "chef_s": int(adv.get("chef_s", 1)), "nom": str(adv.get("nom", "")),
		"res": resultat, "j": int(adv.get("j", 0)), "a": int(adv.get("a", 0)), "delta": delta, "interrompu": interrompu})
	while h.size() > HISTORIQUE:
		h.pop_back()
	r["apres"] = p
	r["points"] = pts
	r["delta"] = delta
	GS.save_game()
	return r


static func adversaire_suivant(graine: int) -> Dictionary:
	var p: int = donnees()["palier"]
	var adv := Fantomes.adversaire(cote_adversaire(p), graine)
	adv["mode"] = "classe"
	adv["palier"] = p
	return adv
