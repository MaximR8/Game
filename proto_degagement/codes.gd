class_name Codes
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LES CODES CADEAUX (29/09 — Maxim : « faudrait mettre un Redeem code, comme ça je peux mettre des codes promos »).
# Sans serveur : le jeu lit un fichier posé À CÔTÉ de lui sur le NAS, `codes/codes.json` (web/codes/), que Maxim remplit
# d'une commande (codes_cadeaux/codes.py) — sans réexporter le jeu. Chez les cousins aussi : le portier sert ce fichier
# comme le reste (même adresse, même cookie).
# 🔴 Les codes n'y sont PAS en clair : seulement leur empreinte (SHA-256 d'un sel et du code normalisé). Lire le fichier
#    ne donne aucun code.
# Un code : sa récompense (étoiles, poussière, pièces, éclats, pierres), sa date de fin. Une fois par PARTIE (les
# empreintes utilisées, dans GS.voyage["codes"]) ; avec les comptes, le serveur prendra le relais (une fois par compte).
#
# codes.json = {"v": 1, "sel": "…", "codes": {"<empreinte>": {"recompense": {"etoiles": 10}, "fin": "2026-12-31"}}}
# ─────────────────────────────────────────────────────────────

const CHEMIN := "codes/codes.json"
# (01/10) la table vit AUSSI sur le serveur : l'app n'a pas de site à côté d'elle (« il me dit que je suis pas en ligne »).
# L'administrateur des codes (un compte du serveur, codes_cadeaux/codes.py) la pose en « config/codes », lisible par tous.
const ADMIN := "595ada12-1c93-4a51-856a-f61ea46bb58f"
const RECOMPENSES := ["etoiles", "poussiere", "pieces", "eclats", "pierres"]

static var table_test: Dictionary = {}      # les tests posent la table ici (hors du web, pas de fichier à lire)


# Majuscules, sans espace ni tiret : « noel-2026 » = « NOEL 2026 » = « NOEL2026 ».
static func normaliser(code: String) -> String:
	var s := ""
	for ch in code.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			s += ch
	return s


static func empreinte(code: String, sel: String) -> String:
	return (sel + normaliser(code)).sha256_text()


static func utilises() -> Array:
	var u = GS.voyage.get("codes", null)
	if typeof(u) != TYPE_ARRAY:
		u = []
		GS.voyage["codes"] = u
	return u


# Ce que vaut un code, dans une table lue : {"ok", "raison" (vide · inconnu · expire · deja · table), "recompense", "h"}.
static func verifier(table: Dictionary, code: String, aujourdhui: String) -> Dictionary:
	if normaliser(code).length() < 4:
		return {"ok": false, "raison": "vide"}
	if typeof(table.get("codes", null)) != TYPE_DICTIONARY or typeof(table.get("sel", null)) != TYPE_STRING:
		return {"ok": false, "raison": "table"}
	var h := empreinte(code, str(table["sel"]))
	var e = (table["codes"] as Dictionary).get(h, null)
	if typeof(e) != TYPE_DICTIONARY:
		return {"ok": false, "raison": "inconnu"}
	var fin := str(e.get("fin", ""))
	if fin != "" and aujourdhui > fin:
		return {"ok": false, "raison": "expire"}
	if utilises().has(h):
		return {"ok": false, "raison": "deja"}
	var r = e.get("recompense", {})
	return {"ok": typeof(r) == TYPE_DICTIONARY and not (r as Dictionary).is_empty(), "raison": "", "recompense": r, "h": h}


# Donne la récompense d'un code vérifié, retient qu'il est pris, sauvegarde. Rend ce qui a été donné (nettoyé).
static func encaisser(v: Dictionary) -> Dictionary:
	if not bool(v.get("ok", false)) or utilises().has(str(v["h"])):
		return {}
	var r: Dictionary = v["recompense"]
	var donne := {}
	for cle in RECOMPENSES:
		if not r.has(cle):
			continue
		if cle == "pierres":
			var ps = r["pierres"]
			if typeof(ps) != TYPE_DICTIONARY:
				continue
			var pd := {}
			for t in ps:
				var n := clampi(int(ps[t]), 0, 99)
				if GS.PIERRES.has(str(t)) and n > 0:
					GS.pierres[str(t)] = int(GS.pierres.get(str(t), 0)) + n
					pd[str(t)] = n
			if not pd.is_empty():
				donne["pierres"] = pd
			continue
		var n := clampi(int(r[cle]), 0, 100000)
		if n <= 0:
			continue
		match cle:
			"etoiles":
				GS.etoiles += n
			"poussiere":
				GS.poussiere += n
			"pieces":
				GS.main_pieces += n
			"eclats":
				GS.eclats += n
		donne[cle] = n
	utilises().append(str(v["h"]))
	GS.save_game()
	GS.changed.emit()
	return donne


# La phrase de ce qui a été reçu : « 10 étoiles, 200 poussières ».
static func phrase(donne: Dictionary) -> String:
	var l := []
	var noms := {"etoiles": ["étoile", "étoiles"], "poussiere": ["poussière", "poussières"], "pieces": ["pièce", "pièces"],
		"eclats": ["éclat", "éclats"]}
	for cle in ["etoiles", "poussiere", "pieces", "eclats"]:
		if donne.has(cle):
			var n := int(donne[cle])
			l.append("%s %s" % [Style.nombre(n), noms[cle][0 if n == 1 else 1]])
	if donne.has("pierres"):
		for t in donne["pierres"]:
			var n := int(donne["pierres"][t])
			var nom := str(GS.NOMS_PIERRES.get(t, "pierre"))
			l.append("%d %s" % [n, nom if n == 1 else nom.replace("pierre ", "pierres ")])
	return ", ".join(l)


# Lire la table : sur le web, le fichier à côté du jeu (sans cache : un code ajouté se voit tout de suite) ; ailleurs,
# la table des tests. Rend {} si on n'a pas pu la lire (hors ligne, fichier absent).
static func lire_table(arbre: SceneTree) -> Dictionary:
	# d'abord le serveur (l'app, le web) ; le fichier du NAS en secours (le web seulement)
	if Compte.global != null and Compte.global.actif:
		var t: Dictionary = await Compte.global.lire_public("config", "codes", ADMIN)
		if not t.is_empty():
			return t
	if not OS.has_feature("web"):
		return table_test
	JavaScriptBridge.eval("window.__codes = null; fetch('%s?t=' + Date.now(), {cache: 'no-store', credentials: 'same-origin'})" % CHEMIN
		+ ".then(r => r.ok ? r.text() : '').then(t => { window.__codes = t; }).catch(e => { window.__codes = ''; });", true)
	var limite := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < limite:
		await arbre.process_frame
		var t = JavaScriptBridge.eval("window.__codes", true)
		if t != null:
			var d = JSON.parse_string(str(t)) if str(t) != "" else null
			return d if typeof(d) == TYPE_DICTIONARY else {}
	return {}
