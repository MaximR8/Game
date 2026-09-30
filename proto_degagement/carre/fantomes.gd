class_name Fantomes
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LES ADVERSAIRES DU DUEL ET DU CLASSÉ (étape 3 du Carré, fiche acceptée le 28/09).
#
# Sans backend, on ne joue pas contre d'autres joueurs : on joue contre l'ordinateur, présenté comme
# un personnage du jeu (« Thor le tonnant », les noms de l'Aventure), JAMAIS comme un faux joueur
# (Maxim, 28/09 : « oui ok pour l'instant »). Quand il y aura des comptes (⑯), on dira « joueur » sans
# avoir menti avant.
#
# Toute sa force tient dans UN chiffre, sa cote : la cote du Duel, ou celle d'une marche du Classé
# (classe.gd). Elle règle ensemble son deck (MoteurCarre.force_deck visée) et l'ordinateur qui le joue.
# Son deck est un deck de JOUEUR : 5 cartes différentes, poids 14 au plus, des stades qui existent,
# des cartes qu'on peut avoir (héros et sbires invocables). Sa carte de tête — un héros, qui lui prête
# son portrait — est d'une variante plus rare à mesure qu'il est fort : la prestance se voit avant de
# se gagner.
# Même cote et même graine : même adversaire (aucun Math.random : les tests et le banc le rejouent).
# ─────────────────────────────────────────────────────────────

# 🔴 Réglés au banc (tests/banc_fantomes, 28/09) — changer ces chiffres déplace tous les adversaires.
const COTE_BAS := 800            # le plus faible des adversaires…
const COTE_HAUT := 1800          # …et le plus fort (au-delà : pareil)
const FORCE_BAS := 85            # la force de deck visée à COTE_BAS (le plus faible deck de joueur : 79)…
const FORCE_HAUT := 140           # …et à COTE_HAUT : le meilleur deck de joueur (140, banc du 28/09 ; un premier pack : ~114)
const FORCE_TOLERANCE := 2
# L'ordinateur : l'Apprenti en bas, l'Aventurier au milieu, le Maître en haut. Entre deux, il est tiré
# au sort à chaque combat, dans une part qui glisse de l'un à l'autre : sans ça, le passage au Maître
# était un mur (banc du 28/09 : les joueurs moyens tombaient de 70 % à 25 % de victoires d'une cote à l'autre).
const IA_APPRENTI := [0.05, 0.25]     # sous 0,05 : toujours l'Apprenti ; au-dessus de 0,25 : jamais
const IA_MAITRE := [0.40, 0.70]       # sous 0,40 : jamais le Maître ; au-dessus de 0,70 : toujours
# La variante de la carte de tête, par tranche de force.
const VARIANTE_SEUILS := [[0.35, "base"], [0.55, "or"], [0.70, "ombre"], [0.82, "elem"], [0.93, "prisme"], [2.0, "full"]]


static func force_de(cote: int) -> float:
	return clampf(float(cote - COTE_BAS) / float(COTE_HAUT - COTE_BAS), 0.0, 1.0)


static func _seuil(table: Array, f: float) -> String:
	for s in table:
		if f < float(s[0]):
			return str(s[1])
	return str(table[-1][1])


# La part d'Apprenti et de Maître à une cote (le reste : l'Aventurier).
static func parts_ia(cote: int) -> Vector2:
	var f := force_de(cote)
	return Vector2(clampf((IA_APPRENTI[1] - f) / (IA_APPRENTI[1] - IA_APPRENTI[0]), 0.0, 1.0),
		clampf((f - IA_MAITRE[0]) / (IA_MAITRE[1] - IA_MAITRE[0]), 0.0, 1.0))


static func ia_de(cote: int, h: MoteurCarre.Hasard) -> String:
	var p := parts_ia(cote)
	var u := h.suivant()
	if u < p.x:
		return "apprenti"
	if u < p.x + p.y:
		return "maitre"
	return "aventurier"


static func force_visee(cote: int) -> int:
	return roundi(lerpf(FORCE_BAS, FORCE_HAUT, force_de(cote)))


# L'adversaire d'un combat : tout ce que reçoit l'écran de combat (comme un niveau de l'Aventure, sans
# « n » : ni ★ ni terres imposées ; les terres viennent de la graine du combat).
static func adversaire(cote: int, graine: int) -> Dictionary:
	var h := MoteurCarre.Hasard.new(graine)
	var deck := deck_de_force(force_visee(cote), h)
	var chef := str(deck[0]["id"])
	deck[0]["v"] = _seuil(VARIANTE_SEUILS, force_de(cote))
	return {"nom": str(Aventure.NOMS.get(chef, MoteurCarre.nom(chef))), "prenom": MoteurCarre.nom(chef),
		"chef": chef, "chef_s": int(deck[0]["s"]), "niveau": ia_de(cote, h), "deck": deck, "cote": cote,
		"graine": MoteurCarre.hacher("combat-%d" % graine)}


# ─────────────────────────────────────────────────────────────
# Le deck
# ─────────────────────────────────────────────────────────────

static var _pool: Array = []


# Les cartes qu'un joueur peut avoir : les héros, et les sbires illustrés.
static func pool() -> Array:
	if _pool.is_empty():
		for x in GS.HEROS:
			_pool.append(str(x["id"]))
		_pool.append_array(MoteurCarre.sbires_invocables())
	return _pool


static func legal(deck: Array) -> bool:
	if deck.size() != MoteurCarre.TAILLE_DECK or MoteurCarre.poids_deck(deck) > MoteurCarre.POIDS_MAX:
		return false
	var vus := {}
	var heros := 0
	for c in deck:
		var f := MoteurCarre.fiche(str(c["id"]))
		if f.is_empty() or vus.has(c["id"]) or int(c["s"]) < 1 or int(c["s"]) > int(f["stades"]):
			return false
		vus[c["id"]] = true
		if not f["sbire"]:
			heros += 1
	return heros >= 1


static func _carte_au_hasard(id: String, h: MoteurCarre.Hasard) -> Dictionary:
	var stades := int(MoteurCarre.fiche(id)["stades"])
	return {"id": id, "s": 1 + int(floor(h.suivant() * stades)), "v": "base"}


static func _deck_au_hasard(h: MoteurCarre.Hasard) -> Array:
	var p := pool()
	for essai in 60:
		var deck := []
		var pris := {}
		while deck.size() < MoteurCarre.TAILLE_DECK:
			var id: String = p[int(floor(h.suivant() * p.size()))]
			if pris.has(id):
				continue
			pris[id] = true
			deck.append(_carte_au_hasard(id, h))
		if legal(deck):
			return deck
	# le secours (jamais vu au banc) : un héros au stade I et quatre sbires
	var secours := [{"id": str(GS.HEROS[0]["id"]), "s": 1, "v": "base"}]
	for id in MoteurCarre.sbires_invocables().slice(0, 4):
		secours.append({"id": id, "s": 1, "v": "base"})
	return secours


# Une retouche au hasard : une carte change de stade, ou cède sa place à une autre. {} si elle rend le
# deck illégal.
static func _retouche(deck: Array, h: MoteurCarre.Hasard) -> Array:
	var d := deck.duplicate(true)
	var k := int(floor(h.suivant() * d.size()))
	var id := str(d[k]["id"])
	var stades := int(MoteurCarre.fiche(id)["stades"])
	if stades > 1 and h.suivant() < 0.5:
		d[k]["s"] = clampi(int(d[k]["s"]) + (1 if h.suivant() < 0.5 else -1), 1, stades)
	else:
		var p := pool()
		var autre: String = p[int(floor(h.suivant() * p.size()))]
		d[k] = _carte_au_hasard(autre, h)
	return d if legal(d) else []


# Un deck légal dont la force approche la cible : on part d'un deck au hasard, et on garde, pas après
# pas, la meilleure de quelques retouches au hasard. Toujours le même pour une même graine.
static func deck_de_force(cible: int, h: MoteurCarre.Hasard) -> Array:
	var deck := _deck_au_hasard(h)
	var ecart := absi(MoteurCarre.force_deck(deck) - cible)
	var coince := 0
	for pas in 120:
		if ecart <= FORCE_TOLERANCE or coince >= 6:
			break
		var meilleur := []
		var e_min := ecart
		for essai in 30:
			var d := _retouche(deck, h)
			if d.is_empty():
				continue
			var e := absi(MoteurCarre.force_deck(d) - cible)
			if e < e_min:
				e_min = e
				meilleur = d
		if meilleur.is_empty():
			coince += 1
			continue
		coince = 0
		deck = meilleur
		ecart = e_min
	# la carte de tête : le héros le plus fort (il prête son portrait)
	var tete := -1
	for k in deck.size():
		if not MoteurCarre.fiche(str(deck[k]["id"]))["sbire"] and (tete < 0 or MoteurCarre.force(deck[k]) > MoteurCarre.force(deck[tete])):
			tete = k
	var c = deck[tete]
	deck.remove_at(tete)
	deck.insert(0, c)
	return deck
