class_name Decks
extends RefCounted

# ─────────────────────────────────────────────────────────────
# MES DECKS — la logique (27/09, sorti de l'étape 3 ; Maxim : « je pouvais pas faire mon propre
# deck, donc j'ai joué avec celui imposé »).
#
# Jusqu'à 6 decks de 5 cartes, poids 14 au plus ; un seul est choisi, c'est lui qui combat.
# Une carte se joue à un stade de I à celui qu'on a atteint (un stade plus bas allège le poids),
# dans une variante qu'on possède. Le premier deck est celui qu'on composait tout seul
# (VoyageEcran.deck_auto). Plus de cartes prêtées depuis le premier pack offert (28/09).
#
# Dans GS.voyage["decks"] = {"liste": [[{id, s, v}, …], …], "actif": k}, relue avec prudence :
# une carte inconnue ou qu'on n'a pas part, un stade trop haut redescend, une variante qu'on n'a pas
# redevient celle qu'on affiche, un doublon part, un deck garde 5 cartes au plus.
# ─────────────────────────────────────────────────────────────

const MAX_DECKS := 6


static func _donnees() -> Dictionary:
	var d = GS.voyage.get("decks", null)
	if typeof(d) != TYPE_DICTIONARY:
		d = {}
	var liste := []
	var brute = d.get("liste", [])
	if typeof(brute) == TYPE_ARRAY:
		for x in brute:
			if typeof(x) == TYPE_ARRAY and liste.size() < MAX_DECKS:
				liste.append(nettoyer(x))
	if liste.is_empty():
		liste.append(VoyageEcran.deck_auto())      # le premier deck : celui qu'on composait tout seul
	var a = d.get("actif", 0)
	var actif := int(a) if typeof(a) in [TYPE_INT, TYPE_FLOAT] else 0
	var propre := {"liste": liste, "actif": clampi(actif, 0, liste.size() - 1)}
	GS.voyage["decks"] = propre
	return propre


# ─────────────────────────────────────────────────────────────
# Les cartes
# ─────────────────────────────────────────────────────────────

# Le stade le plus haut qu'on peut jouer : celui qu'on a atteint (un sbire, un héros à une forme : 1).
static func stade_max(id: String) -> int:
	var f := MoteurCarre.fiche(id)
	if f.is_empty() or f["sbire"] or MoteurCarre.un_seul(id) or not GS.cartes.has(id):
		return 1
	return clampi(int(GS.cartes[id]["stade"]), 1, int(f["stades"]))


# Une carte de deck rendue jouable ; {} si elle ne l'est pas.
static func nettoyer_carte(c) -> Dictionary:
	if typeof(c) != TYPE_DICTIONARY:
		return {}
	var id := str(c.get("id", ""))
	var f := MoteurCarre.fiche(id)
	if f.is_empty():
		return {}
	if not GS.cartes.has(id):
		return {}
	var e: Dictionary = GS.cartes[id]
	var brut = c.get("s", 1)
	var s := clampi(int(brut) if typeof(brut) in [TYPE_INT, TYPE_FLOAT] else 1, 1, stade_max(id))
	var v := str(c.get("v", e["variante"]))
	if not (e["variantes"] as Array).has(v):
		v = str(e["variante"])
	return {"id": id, "s": s, "v": v}


static func nettoyer(cartes: Array) -> Array:
	var l := []
	var vus := {}
	for c in cartes:
		var p := nettoyer_carte(c)
		if p.is_empty() or vus.has(p["id"]) or l.size() >= MoteurCarre.TAILLE_DECK:
			continue
		vus[p["id"]] = true
		l.append(p)
	return l


static func valide(cartes: Array) -> bool:
	return cartes.size() == MoteurCarre.TAILLE_DECK and MoteurCarre.poids_deck(cartes) <= MoteurCarre.POIDS_MAX


# Pourquoi un deck ne peut pas combattre (le bouton éteint le dit) ; "" s'il le peut.
static func pourquoi(cartes: Array) -> String:
	var manque := MoteurCarre.TAILLE_DECK - cartes.size()
	if manque > 0:
		return "Il manque %d carte%s à ton deck" % [manque, "s" if manque > 1 else ""]
	var p := MoteurCarre.poids_deck(cartes)
	if p > MoteurCarre.POIDS_MAX:
		return "Trop lourd : %d / %d" % [p, MoteurCarre.POIDS_MAX]
	return ""


# Ajoute une carte possédée au deck, au stade le plus haut qui tient dans le poids, dans la variante
# qu'on affiche. Rend {"ok": bool, "raison": String}.
static func ajouter_carte(cartes: Array, id: String) -> Dictionary:
	if not GS.cartes.has(id):
		return {"ok": false, "raison": "Tu n'as pas cette carte"}
	for c in cartes:
		if c["id"] == id:
			return {"ok": false, "raison": "Déjà dans ton deck"}
	if cartes.size() >= MoteurCarre.TAILLE_DECK:
		return {"ok": false, "raison": "Ton deck a déjà 5 cartes"}
	for s in range(stade_max(id), 0, -1):
		var c := {"id": id, "s": s, "v": str(GS.cartes[id]["variante"])}
		if MoteurCarre.poids_deck(cartes + [c]) <= MoteurCarre.POIDS_MAX:
			cartes.append(c)
			return {"ok": true, "raison": ""}
	var p := MoteurCarre.poids_deck(cartes + [{"id": id, "s": 1, "v": "base"}])
	return {"ok": false, "raison": "Trop lourd : %d / %d" % [p, MoteurCarre.POIDS_MAX]}


# ─────────────────────────────────────────────────────────────
# Les decks
# ─────────────────────────────────────────────────────────────

static func liste() -> Array:
	return _donnees()["liste"]


static func actif() -> int:
	return int(_donnees()["actif"])


static func nom(k: int) -> String:
	return "Deck %d" % (k + 1)


# Le deck qui combat : une copie (le modifier ne change pas celui qui est gardé).
static func deck_actif() -> Array:
	var d := _donnees()
	return (d["liste"][d["actif"]] as Array).duplicate(true)


static func choisir(k: int) -> void:
	var d := _donnees()
	if k >= 0 and k < (d["liste"] as Array).size():
		d["actif"] = k
		GS.save_game()


# Remplace les cartes d'un deck (nettoyées), et l'écrit.
static func remplacer(k: int, cartes: Array) -> void:
	var d := _donnees()
	if k >= 0 and k < (d["liste"] as Array).size():
		d["liste"][k] = nettoyer(cartes)
		GS.save_game()


# Un nouveau deck, vide ; rend son rang, ou -1 s'il y en a déjà 6.
static func nouveau() -> int:
	var d := _donnees()
	var l: Array = d["liste"]
	if l.size() >= MAX_DECKS:
		return -1
	l.append([])
	GS.save_game()
	return l.size() - 1


# Supprime un deck (il en reste toujours un) ; le deck choisi suit.
static func supprimer(k: int) -> void:
	var d := _donnees()
	var l: Array = d["liste"]
	if l.size() <= 1 or k < 0 or k >= l.size():
		return
	l.remove_at(k)
	var a: int = d["actif"]
	if a > k or a >= l.size():
		d["actif"] = maxi(0, a - 1)
	GS.save_game()
