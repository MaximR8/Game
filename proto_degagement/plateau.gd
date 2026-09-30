class_name Plateau
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LE PLATEAU DU JOUR (lot A de ⑧, « la journée » — fiche acceptée le 28/09).
#
# La Nébuleuse rapportait sans fond (~48 étoiles par heure de jeu : banc du 28/09) ; Maxim, 23/09 :
# « ça doit être dur d'avoir une invocation ×10 ». Chaque jour, elle porte 12 objets, CONNUS D'AVANCE :
# 1 étoile, 3 pierres, 8 poussières. La machine décide QUAND on les gagne, jamais CE QU'on gagne
# (lisible, zéro hasard). Les 3 pierres du jour sont écrites par le calendrier (la même journée pour
# tout le monde) ; la lune y tombe comme avant, 12 fois sur 100. Une fois tout gagné, le plateau
# n'en porte plus : « revient demain ».
# 🔴 C'est ce qui permettra de vendre des pièces (Maxim, 28/09 : « on met des pièces dans les packs ») sans
#    vendre de puissance : des pièces en plus font finir son plateau plus vite, pas gagner plus.
#
# Dans GS.voyage["plateau"] = {date, poussiere, etoile, pierre} : ce qu'on a gagné ce jour-là, par rang.
# ─────────────────────────────────────────────────────────────

const RANGS := ["poussiere", "etoile", "pierre"]          # rang 0 (près du bord), 1, 2 (au fond)
const CONTENU := {"poussiere": 8, "etoile": 1, "pierre": 3}
const PIERRES := ["feu", "foudre", "eau", "glace", "nature", "esprit"]
const CHANCE_LUNE := 0.12

# Les tests fixent le jour ici (« AAAA-MM-JJ ») ; vide : l'horloge du téléphone.
static var date_test := ""


static func aujourdhui() -> String:
	return date_test if date_test != "" else Time.get_date_string_from_system()


# 🔴 Nettoyées sur place, et remises à zéro quand le jour a changé.
static func donnees() -> Dictionary:
	var d = GS.voyage.get("plateau", null)
	if typeof(d) != TYPE_DICTIONARY:
		d = {}
		GS.voyage["plateau"] = d
	var jour := aujourdhui()
	if str(d.get("date", "")) != jour:
		d.clear()
		d["date"] = jour
	for r in RANGS:
		var v = d.get(r, 0)
		d[r] = clampi(int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0, 0, int(CONTENU[r]))
	return d


static func total() -> int:
	var n := 0
	for r in RANGS:
		n += int(CONTENU[r])
	return n


static func rang_de(k: String) -> int:
	if k == "poussiere":
		return 0
	if k == "etoile":
		return 1
	return 2


# Les 3 pierres d'un jour : écrites par le calendrier (même jour, mêmes pierres).
static func pierres_du_jour(jour: String) -> Array:
	var h := MoteurCarre.Hasard.new(MoteurCarre.hacher("plateau-" + jour))
	var l := []
	for k in int(CONTENU["pierre"]):
		if h.suivant() < CHANCE_LUNE:
			l.append("lune")
		else:
			l.append(PIERRES[int(floor(h.suivant() * PIERRES.size()))])
	return l


static func restant(rang: int) -> int:
	var r: String = RANGS[rang]
	return int(CONTENU[r]) - int(donnees()[r])


static func restants() -> int:
	return restant(0) + restant(1) + restant(2)


# L'objet de ce rang à poser sur le plateau ; "" s'il n'en reste plus aujourd'hui.
static func prochain(rang: int) -> String:
	if restant(rang) <= 0:
		return ""
	match rang:
		0:
			return "poussiere"
		1:
			return "etoile"
	var d := donnees()
	return "pierre-" + str(pierres_du_jour(d["date"])[int(d["pierre"])])


# Un objet de la machine est gagné : il compte dans son rang (le gain lui-même, c'est GS.gagner). Une pierre du jour est
# retenue par son nom : depuis que TOUT le plateau est posé (29/09), elles ne tombent plus dans l'ordre.
static func gagner(k: String) -> void:
	var d := donnees()
	var r: String = RANGS[rang_de(k)]
	d[r] = mini(int(CONTENU[r]), int(d[r]) + 1)
	if r == "pierre":
		var g: Array = d.get("pierres_gagnees", []) if typeof(d.get("pierres_gagnees")) == TYPE_ARRAY else []
		g.append(k.trim_prefix("pierre-"))
		d["pierres_gagnees"] = g
	GS.demander_sauvegarde()


# Les pierres du jour, chacune gagnée ou non (par leur nom ; une sauvegarde d'avant le 29/09 : dans l'ordre).
static func _pierres_etat() -> Array:
	var d := donnees()
	var ps := pierres_du_jour(d["date"])
	var reste: Array = (d["pierres_gagnees"] as Array).duplicate() if typeof(d.get("pierres_gagnees")) == TYPE_ARRAY else []
	var l := []
	var par_nom := 0
	for k in ps.size():
		var gagne := reste.has(ps[k])
		if gagne:
			reste.erase(ps[k])
			par_nom += 1
		l.append({"pierre": str(ps[k]), "gagne": gagne})
	# les autres pierres gagnées (une sauvegarde d'avant le 29/09, sans leur nom ; une pierre de la veille restée sur le tas)
	# éteignent les suivantes, dans l'ordre
	var sans_nom := int(d["pierre"]) - par_nom
	for e in l:
		if sans_nom > 0 and not bool(e["gagne"]):
			e["gagne"] = true
			sans_nom -= 1
	return l


# Les 12 objets du jour, dans l'ordre où on les montre : l'étoile, les pierres, les poussières.
# [{image, gagne}] — « image » : le nom de l'objet (Style.objet).
static func liste() -> Array:
	var d := donnees()
	var l := []
	for k in int(CONTENU["etoile"]):
		l.append({"image": "etoile-invocation", "gagne": k < int(d["etoile"])})
	for p in _pierres_etat():
		l.append({"image": "pierre-" + str(p["pierre"]), "gagne": bool(p["gagne"])})
	for k in int(CONTENU["poussiere"]):
		l.append({"image": "poussiere-etoile", "gagne": k < int(d["poussiere"])})
	return l


# ── TOUT LE PLATEAU EST POSÉ (29/09 — Maxim : « mettre toutes les récompenses dispo directement sur le plateau, pas 3 qu'on
#    fait réapparaître » ; « 1 ticket d'invocation, la moitié des pierres aléatoirement sur le plateau et le reste en ordre
#    XP ») : le ticket au fond ; la moitié des pierres n'importe où (une surprise, même près du bord) ; les autres pierres,
#    puis les poussières (l'XP), rangées par valeur du fond vers le bord. Le jour décide quelles pierres vont au hasard
#    (sur 3 : 1 ou 2) — la même journée pour tout le monde, comme les pierres elles-mêmes.

static func pierres_au_hasard(jour: String) -> Array:
	var ps := pierres_du_jour(jour)
	var h := MoteurCarre.Hasard.new(MoteurCarre.hacher("plateau-places-" + jour))
	var n := ps.size() / 2 + (1 if ps.size() % 2 == 1 and h.suivant() < 0.5 else 0)
	var ordre := range(ps.size())
	for i in range(ordre.size() - 1, 0, -1):                 # un mélange écrit par le jour
		var j := int(floor(h.suivant() * (i + 1)))
		var t = ordre[i]
		ordre[i] = ordre[j]
		ordre[j] = t
	var l := []
	for k in ps.size():
		l.append(ordre.find(k) < n)
	return l


# Ce qu'il reste à poser aujourd'hui, et comment : [{k, place}] — place : "fond" (le ticket), "pierre" (rangée),
# "hasard" (une pierre n'importe où), "xp" (une poussière, devant).
static func a_poser() -> Array:
	var d := donnees()
	var l := []
	for k in restant(1):
		l.append({"k": "etoile", "place": "fond"})
	var hasard := pierres_au_hasard(d["date"])
	var etat := _pierres_etat()
	for i in etat.size():
		if not bool(etat[i]["gagne"]):
			l.append({"k": "pierre-" + str(etat[i]["pierre"]), "place": "hasard" if bool(hasard[i]) else "pierre"})
	for k in restant(0):
		l.append({"k": "poussiere", "place": "xp"})
	return l
