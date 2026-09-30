class_name Duel
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LE DUEL — étape 3 du Carré (DECISIONS 26/09 ; fiche acceptée le 28/09).
#
# Un adversaire de ta force : ta cote (1 000 au départ), et lui, à 100 près au-dessus ou en dessous
# (fantomes.gd). Une victoire fait monter la cote, une défaite la fait baisser, d'autant plus que
# l'écart était grand (la formule d'Elo) : on se pose là où l'on gagne une partie sur deux, cartes et
# jeu compris. Le Duel n'a pas d'autre enjeu : c'est là qu'on essaie un deck.
#
# Dans GS.voyage["duel"] = {cote, joues, historique (les 5 derniers)}. Relue avec prudence.
# ─────────────────────────────────────────────────────────────

const COTE_DEPART := 1000
const ECART := 100
const K := 24
const HISTORIQUE := 5


# Nettoyées sur place (comme Classe.donnees).
static func donnees() -> Dictionary:
	var d = GS.voyage.get("duel", null)
	if typeof(d) != TYPE_DICTIONARY:
		d = {}
		GS.voyage["duel"] = d
	var cote = d.get("cote", COTE_DEPART)
	var joues = d.get("joues", 0)
	d["cote"] = maxi(0, int(cote)) if typeof(cote) in [TYPE_INT, TYPE_FLOAT] else COTE_DEPART
	d["joues"] = maxi(0, int(joues)) if typeof(joues) in [TYPE_INT, TYPE_FLOAT] else 0
	if typeof(d.get("historique", null)) != TYPE_ARRAY:
		d["historique"] = []
	return d


static func cote() -> int:
	return donnees()["cote"]


# Ce que rapporte (ou coûte) un combat : 1 gagné, 0,5 égalité, 0 perdu.
static func variation(ma_cote: int, sa_cote: int, score: float) -> int:
	var attendu := 1.0 / (1.0 + pow(10.0, float(sa_cote - ma_cote) / 400.0))
	return roundi(K * (score - attendu))


static func adversaire_suivant(graine: int) -> Dictionary:
	var h := MoteurCarre.Hasard.new(graine ^ 0x5bd1e995)
	var sa_cote := maxi(0, cote() + roundi((h.suivant() * 2.0 - 1.0) * ECART))
	var adv := Fantomes.adversaire(sa_cote, graine)
	adv["mode"] = "duel"
	return adv


# Retient un duel (1 : gagné, 0 : égalité, −1 : perdu) ; rend {avant, apres, delta}.
static func enregistrer(resultat: int, adv: Dictionary, interrompu := false) -> Dictionary:
	var d := donnees()
	var avant: int = d["cote"]
	var delta := variation(avant, int(adv.get("cote", avant)), 1.0 if resultat > 0 else (0.5 if resultat == 0 else 0.0))
	d["cote"] = maxi(0, avant + delta)
	d["joues"] = int(d["joues"]) + 1
	var h: Array = d["historique"]
	h.push_front({"chef": str(adv.get("chef", "")), "chef_s": int(adv.get("chef_s", 1)), "nom": str(adv.get("nom", "")),
		"cote": int(adv.get("cote", 0)), "res": resultat, "j": int(adv.get("j", 0)), "a": int(adv.get("a", 0)),
		"delta": delta, "interrompu": interrompu})
	while h.size() > HISTORIQUE:
		h.pop_back()
	GS.save_game()
	return {"avant": avant, "apres": d["cote"], "delta": delta}
