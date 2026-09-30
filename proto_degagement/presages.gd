class_name Presages
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LES PRÉSAGES : LES DÉFIS DU JOUR ET DE LA SEMAINE (lot A de ⑧, « la journée » — fiche acceptée le 28/09).
#
# Maxim, 23/09 : « des missions hebdo et journalières pour avoir des pièces » ; 28/09 : « arrêter de donner
# des pièces à la minute et en faire gagner dans les défis journaliers et hebdo ». Les pièces ne se
# rechargent plus : ce sont les défis qui les donnent (et le cadeau du jour).
#
# · 3 défis par jour, choisis par le calendrier (même jour, même tirage), et seulement parmi ce que le
#   joueur a ouvert (un nouveau joueur n'a pas de duel à gagner) : un de la Nébuleuse, un du Voyage, un
#   de plus (Voyage ou Atlas). Ils sont fixés à la première lecture du jour : ils ne changent plus ensuite.
# · Chacun : 50 pièces. Les 3 reçus : 1 pierre de lune.
# · La semaine (du lundi au dimanche) : les 3 défis faits 5 jours → 3 étoiles et 200 pièces.
# · Rien n'est donné tout seul : « Recevoir » (l'écran des Présages), et l'onglet porte un point tant
#   qu'il y a quelque chose à recevoir.
#
# Les événements arrivent d'ailleurs par evenement(cle, n) : la Nébuleuse (objet, pièce, plateau vidé),
# le combat (combat, retournement, chaîne, victoires de l'Aventure, du Duel, du Classé), l'Atlas
# (niveau, invocation).
#
# Dans GS.voyage["presages"] = {date, defis: [{id, fait, recu}], bonus, semaine: {id, jours: [dates], recu}}.
# ─────────────────────────────────────────────────────────────

# 🔴 Provisoire (D11, ⑧) : à relire avec le banc de la journée.
const PIECES_DEFI := 35           # banc du 28/09 : vider le plateau coûte 123 (vite) à 175 (calme) pièces nettes ;
#   29/09 : tout le plateau posé, les fentes — il coûte ~85 (vite) à ~120 (calme) : 60 → 35 (et la semaine 200 → 120),
#   pour que vider le plateau prenne toujours la plus grande part des pièces du jour (Maxim : « que les gens achètent
#   des pièces pour jouer plus à la machine »)
const LUNE_BONUS := 1
const JOURS_SEMAINE := 5
const ETOILES_SEMAINE := 3
const PIECES_SEMAINE := 120

# Les défis. « cle » : l'événement qui les fait avancer ; « n » : combien ; « groupe » : d'où il vient
# (l'onglet où l'on va le faire) ; « si » : quand il peut être proposé (_possible).
const DEFIS := {
	"plateau": {"texte": "Vide le plateau du jour", "cle": "plateau_vide", "n": 1, "groupe": "nebuleuse", "si": ""},
	"objets": {"texte": "Gagne 6 objets dans la Nébuleuse", "cle": "objet", "n": 6, "groupe": "nebuleuse", "si": ""},
	"pieces": {"texte": "Lâche 80 pièces", "cle": "piece", "n": 80, "groupe": "nebuleuse", "si": ""},
	"aventure": {"texte": "Gagne un niveau de l'Aventure", "cle": "aventure", "n": 1, "groupe": "voyage", "si": "tuto"},
	"etoiles": {"texte": "Gagne 2 ★ dans l'Aventure", "cle": "etoile_aventure", "n": 2, "groupe": "voyage", "si": "etoiles"},
	"duels": {"texte": "Gagne 2 duels", "cle": "duel", "n": 2, "groupe": "voyage", "si": "arene"},
	"classe": {"texte": "Gagne un combat classé", "cle": "classe", "n": 1, "groupe": "voyage", "si": "arene"},
	"combats": {"texte": "Joue 3 combats", "cle": "combat", "n": 3, "groupe": "voyage", "si": "tuto"},
	"retourne": {"texte": "Retourne 12 cartes", "cle": "retournement", "n": 12, "groupe": "voyage", "si": "tuto"},
	"chaine": {"texte": "Retourne une carte en chaîne", "cle": "chaine", "n": 1, "groupe": "voyage", "si": "tuto"},
	"niveau": {"texte": "Fais monter une carte", "cle": "niveau", "n": 1, "groupe": "atlas", "si": "niveau"},
	"invoque": {"texte": "Invoque une carte", "cle": "invocation", "n": 1, "groupe": "atlas", "si": "etoile"},
}

static var date_test := ""


static func aujourdhui() -> String:
	return date_test if date_test != "" else Time.get_date_string_from_system()


# La semaine d'un jour : la date de son lundi (« AAAA-MM-JJ »).
static func semaine_de(jour: String) -> String:
	var t := Time.get_unix_time_from_datetime_string(jour + "T12:00:00")
	var j := Time.get_datetime_dict_from_unix_time(t)
	var decal := (int(j["weekday"]) + 6) % 7                 # dimanche 0 → 6 ; lundi 1 → 0
	return Time.get_date_string_from_unix_time(t - decal * 86400)


static func _possible(si: String) -> bool:
	match si:
		"tuto":
			return bool(GS.voyage.get("tuto_carre", false))
		"etoiles":
			return bool(GS.voyage.get("tuto_carre", false)) and Aventure.etoiles_total() <= Aventure.NB_NIVEAUX * 3 - 2
		"arene":
			return Arene.ouvert()
		"niveau":
			for id in GS.cartes:
				if GS.peut_monter(str(id)):          # (pas au niveau maximum, et assez de poussière)
					return true
			return false
		"etoile":
			return GS.etoiles >= 1
	return true


# Les 3 défis d'un jour : le calendrier mélange la liste (même jour, même ordre), puis on prend le premier
# possible de la Nébuleuse, le premier du Voyage, et le suivant possible hors Nébuleuse (sinon, de la Nébuleuse).
static func choisir(jour: String) -> Array:
	var ids: Array = DEFIS.keys()
	ids.sort()
	MoteurCarre.melanger(ids, MoteurCarre.Hasard.new(MoteurCarre.hacher("presages-" + jour)))
	var pris := []
	for groupe in ["nebuleuse", "voyage"]:
		for id in ids:
			if DEFIS[id]["groupe"] == groupe and _possible(DEFIS[id]["si"]):
				pris.append(id)
				break
	for hors_nebuleuse in [true, false]:
		for id in ids:
			if pris.size() >= 3:
				break
			if pris.has(id) or (hors_nebuleuse and DEFIS[id]["groupe"] == "nebuleuse") or not _possible(DEFIS[id]["si"]):
				continue
			pris.append(id)
	return pris.slice(0, 3)


# 🔴 Nettoyées sur place ; un nouveau jour tire ses 3 défis (une fois) ; une nouvelle semaine repart de zéro.
static func donnees() -> Dictionary:
	var d = GS.voyage.get("presages", null)
	if typeof(d) != TYPE_DICTIONARY:
		d = {}
		GS.voyage["presages"] = d
	var jour := aujourdhui()
	var defis = d.get("defis", null)
	var propres := []
	if typeof(defis) == TYPE_ARRAY and str(d.get("date", "")) == jour:
		for e in defis:
			if typeof(e) == TYPE_DICTIONARY and DEFIS.has(str(e.get("id", ""))):
				var f = e.get("fait", 0)
				propres.append({"id": str(e["id"]), "fait": clampi(int(f) if typeof(f) in [TYPE_INT, TYPE_FLOAT] else 0, 0,
					int(DEFIS[str(e["id"])]["n"])), "recu": bool(e.get("recu", false))})
	if str(d.get("date", "")) != jour or propres.is_empty():
		propres = []
		for id in choisir(jour):
			propres.append({"id": id, "fait": 0, "recu": false})
		d["date"] = jour
		d["bonus"] = false
	d["defis"] = propres
	d["bonus"] = bool(d.get("bonus", false))
	var s = d.get("semaine", null)
	if typeof(s) != TYPE_DICTIONARY or str(s.get("id", "")) != semaine_de(jour):
		s = {"id": semaine_de(jour), "jours": [], "recu": false}
	var jours := []
	if typeof(s.get("jours", null)) == TYPE_ARRAY:
		for x in s["jours"]:
			if typeof(x) == TYPE_STRING and not jours.has(x):
				jours.append(x)
	s["jours"] = jours
	s["recu"] = bool(s.get("recu", false))
	d["semaine"] = s
	return d


static func fini(e: Dictionary) -> bool:
	return int(e["fait"]) >= int(DEFIS[e["id"]]["n"])


static func tous_finis() -> bool:
	for e in donnees()["defis"]:
		if not fini(e):
			return false
	return true


# Un événement du jeu : fait avancer les défis du jour qui l'attendent.
static func evenement(cle: String, n := 1) -> void:
	if n <= 0:
		return
	var d := donnees()
	var change := false
	for e in d["defis"]:
		var def: Dictionary = DEFIS[e["id"]]
		if def["cle"] != cle or fini(e):
			continue
		e["fait"] = mini(int(def["n"]), int(e["fait"]) + n)
		change = true
	if not change:
		return
	# la semaine : ce jour compte dès que ses 3 défis sont faits
	if tous_finis():
		var jours: Array = d["semaine"]["jours"]
		if not jours.has(d["date"]):
			jours.append(d["date"])
	GS.demander_sauvegarde()
	GS.changed.emit()                     # l'onglet des Présages allume son point


# Ce qu'il y a à recevoir (le point de l'onglet).
static func a_recevoir() -> int:
	var d := donnees()
	var n := 0
	for e in d["defis"]:
		if fini(e) and not bool(e["recu"]):
			n += 1
	if bonus_pret():
		n += 1
	if semaine_prete():
		n += 1
	return n


static func bonus_pret() -> bool:
	var d := donnees()
	if bool(d["bonus"]) or (d["defis"] as Array).is_empty():
		return false
	for e in d["defis"]:
		if not bool(e["recu"]):
			return false
	return true


static func semaine_prete() -> bool:
	var s: Dictionary = donnees()["semaine"]
	return not bool(s["recu"]) and (s["jours"] as Array).size() >= JOURS_SEMAINE


# Recevoir : le défi k (0 à 2), « bonus » ou « semaine ». Donne, écrit, et rend ce qui a été donné
# ({pieces, etoiles, pierre}) — {} si ce n'était pas prêt.
static func recevoir(quoi) -> Dictionary:
	var d := donnees()
	var g := {}
	if typeof(quoi) == TYPE_INT:
		var k: int = quoi
		if k < 0 or k >= (d["defis"] as Array).size():
			return {}
		var e: Dictionary = d["defis"][k]
		if not fini(e) or bool(e["recu"]):
			return {}
		e["recu"] = true
		g = {"pieces": PIECES_DEFI}
	elif quoi == "bonus":
		if not bonus_pret():
			return {}
		d["bonus"] = true
		g = {"pierre": "lune"}
	elif quoi == "semaine":
		if not semaine_prete():
			return {}
		d["semaine"]["recu"] = true
		g = {"etoiles": ETOILES_SEMAINE, "pieces": PIECES_SEMAINE}
	else:
		return {}
	GS.main_pieces += int(g.get("pieces", 0))
	GS.gagner(0, int(g.get("etoiles", 0)), str(g.get("pierre", "")))
	GS.save_game()
	return g
