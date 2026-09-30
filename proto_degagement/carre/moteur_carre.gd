class_name MoteurCarre
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LE CARRÉ DES ASTRES — les règles et l'ordinateur (FEATURES ②, 27/09).
#
# Repris ligne à ligne du prototype web v2 (design/canevas/arene/src/c2_carre3.js),
# celui que Maxim a joué et validé : mêmes chiffres, mêmes pouvoirs, même ordinateur.
# 🔴 Le banc de parité (tests/test_carre.gd) rejoue des centaines de parties des deux
#    moteurs et les compare coup par coup : une règle recopiée de travers donnerait un
#    score faux sans la moindre erreur.
#
# Une partie est un dictionnaire (« st ») :
#   n, cases (n × n : null ou une carte posée), terres {case: type}, bloc [cases gouffre],
#   gel {case: {contre, jusqua}}, tour, uid, main {"j": [...], "a": [...]}.
# Une carte en main : {id, s (stade), v (variante)}.
# Une carte posée : {uid, id, s, v, camp, ch [haut, droite, bas, gauche], pose, faim, …}.
# ─────────────────────────────────────────────────────────────

const OPP := [2, 3, 0, 1]
const MODELES := {"frappeur": [9, 6, 4, 3], "garde": [6, 6, 6, 5], "appui": [8, 5, 5, 4], "sbire": [5, 4, 3, 2]}
const TAILLE_DECK := 5
const POIDS_MAX := 14

# Les sbires (27/09) : les cartes communes — un seul stade, poids 1, pas de pouvoir.
# « image » : illustré, donc invocable (il entre dans la collection) ; les autres ne sont que des
# adversaires de l'Aventure, avec leur pierre pour visage (aventure.gd, SBIRES_AVENTURE).
# « modele » : ses chiffres, s'ils ne sont pas ceux d'un sbire ordinaire (MODELES.sbire : 14 de somme).
const SBIRES := [
	{"id": "draugr", "nom": "Draugr", "type": "glace", "pays": "Scandinavie"},
	{"id": "farfadet", "nom": "Farfadet", "type": "nature", "pays": "France"},
	{"id": "oni", "nom": "Oni", "type": "feu", "pays": "Japon"},
	{"id": "ondine", "nom": "Ondine", "type": "eau", "pays": "Europe"},
	{"id": "follet", "nom": "Feu follet", "type": "esprit", "pays": "Europe", "image": true},
	{"id": "raiju", "nom": "Raijū", "type": "foudre", "pays": "Japon"},
	# 🔴 Le Chinchin et l'Homme de feuilles : inspirés de Maxim et de son papa (27/09) — les deux
	#    meilleurs sbires, jamais meilleurs qu'un héros : 17 de somme (un sbire : 14 ; un héros : 22 à 31).
	#    Mesuré au banc (tests/banc_cartes -- 20000 0 poids, 27/09) : Homme de feuilles 48,1 %, Chinchin
	#    47,7 %, les autres sbires 42 à 45,5 %, le héros le plus faible 48,5 %.
	{"id": "chinchin", "nom": "Chinchin", "type": "esprit", "pays": "Belgique", "image": true, "modele": [7, 4, 3, 3]},
	{"id": "hommefeuilles", "nom": "Homme de feuilles", "type": "nature", "pays": "Belgique", "image": true, "modele": [6, 5, 3, 3]},
	{"id": "diable", "nom": "Diable du Doudou", "type": "feu", "pays": "Belgique", "image": true},
	{"id": "esprit_foudre", "nom": "Esprit de foudre", "type": "foudre", "image": true},
	{"id": "esprit_eau", "nom": "Esprit d'eau", "type": "eau", "image": true},
	{"id": "esprit_feu", "nom": "Esprit de feu", "type": "feu", "image": true},
	{"id": "esprit_sylvestre", "nom": "Esprit sylvestre", "type": "nature", "image": true},
	{"id": "esprit_roche", "nom": "Esprit de roche", "type": "nature", "image": true},
]

# LES RANGS DES HÉROS (27/09) — Maxim : « rendre plus difficile à avoir les plus forts », puis, entre
# trois voies, « plus fort mais plus lourd » : un Mythe a +1 à son chiffre le plus faible ; une Légende
# +1 à ses deux plus faibles, et pèse 1 de plus dans le deck (on en met moins). Leur rareté au tirage :
# GS.RARETES. Un héros absent d'ici est un Héros. Le classement suit la stature du personnage dans les
# légendes (dieux et êtres cosmiques : Légendes) — proposé par Claude le 27/09 ; Maxim, 28/09 : « je te fais
# confiance, on verra les retours des utilisateurs ».
const RANGS := {
	"thor": "legende", "loki": "legende", "bahamut": "legende", "quetzalcoatl": "legende",
	"anubis": "legende", "fenrir": "legende", "wukong": "legende", "thunderbird": "legende",
	"cerbere": "mythe", "kitsune": "mythe", "nian": "mythe", "minotaure": "mythe", "roc": "mythe", "ifrit": "mythe",
	"babayaga": "mythe", "golem": "mythe", "wendigo": "mythe", "doudou": "mythe", "georges": "mythe",
}
const BONUS_RANG := {"heros": 0, "mythe": 1, "legende": 3}
const POIDS_RANG := {"heros": 0, "mythe": 0, "legende": 1}
# Mesuré au banc (tests/banc_cartes -- 8000 0 poids, 27/09) : dans des decks de 14, une carte gagne
# ~52 % (Héros), ~53 % (Mythe), ~51 % (Légende), ~45 % (sbire) — le poids de la Légende paie son bonus :
# un deck de Légendes ne gagne pas à coup sûr.
# Le banc de parité rejoue le moteur du prototype web, qui n'a pas de rangs (tests/test_carre.gd).
static var rangs_actifs := true

# La roue des types (provisoire, FEATURES ⑫ bis) : ses clés sont les types des terres.
const TYPES_TERRES := ["feu", "glace", "nature", "eau", "foudre", "esprit"]

# Les pouvoirs : l'emblème (carre/pouvoir-<g>.png), le nom, quand il agit, et sa phrase.
const POUVOIRS := {
	"thor": {"g": "foudre", "nom": "Foudre", "quand": "à la pose"},
	"kitsune": {"g": "esquive", "nom": "Esquive", "quand": "toujours"},
	"golem": {"g": "rempart", "nom": "Rempart", "quand": "après sa pose"},
	"bahamut": {"g": "maree", "nom": "Marée", "quand": "tant qu'il est posé"},
	"yeti": {"g": "gel", "nom": "Gel", "quand": "à la pose"},
	"loki": {"g": "meta", "nom": "Métamorphose", "quand": "à la pose"},
	"anubis": {"g": "ame", "nom": "Pesée des âmes", "quand": "quand il est retourné"},
	"fenrir": {"g": "faim", "nom": "Faim", "quand": "quand il retourne"},
	"cerbere": {"g": "tetes", "nom": "Trois têtes", "quand": "quand il attaque"},
	"babayaga": {"g": "maledic", "nom": "Malédiction", "quand": "à la pose"},
}


static func texte_pouvoir(id: String, s: int) -> String:
	var fort := s == 3
	match id:
		"thor":
			return "Ses côtés qui touchent une carte adverse gagnent +%d." % (2 if fort else 1)
		"kitsune":
			return "Jamais retournée par une chaîne. Et au tour qui suit sa pose, jamais retournée du tout." if fort \
				else "Jamais retournée par une chaîne : seule une carte posée contre elle peut la prendre."
		"golem":
			return "Personne ne peut le retourner pendant les 2 tours adverses qui suivent sa pose." if fort \
				else "Personne ne peut le retourner au tour adverse qui suit sa pose."
		"bahamut":
			return "Tes cartes qui le touchent gagnent +%d partout." % (2 if fort else 1)
		"yeti":
			return "Les cases vides qui le touchent gèlent : ton adversaire ne peut pas y poser à son prochain tour." if fort \
				else "La case vide face à son côté le plus faible gèle : ton adversaire ne peut pas y poser à son prochain tour."
		"loki":
			return "Garde, côté par côté, le plus fort entre ses chiffres et ceux de la carte voisine la plus forte." if fort \
				else "Prend les chiffres de la carte voisine la plus forte (amie ou ennemie), moins 1."
		"anubis":
			return "Tu reprends aussitôt %s. Une fois par partie." % ("les 2 cartes adverses voisines les plus faibles" if fort else "la carte adverse voisine la plus faible")
		"fenrir":
			return "Chaque carte qu'il retourne lui donne +1 partout (au plus +%d)." % (3 if fort else 2)
		"cerbere":
			return "Attaque aussi en diagonale, avec %s de ses deux chiffres de ce coin." % ("le plus grand" if fort else "le plus petit")
		"babayaga":
			return "Les cartes adverses qui la touchent perdent %d partout." % (2 if fort else 1)
	return ""


# Ce que dit une carte sans pouvoir : la bande du combat, le dos de la carte (dos_info.gd).
static func sans_pouvoir(id: String) -> String:
	if bool(fiche(id).get("sbire", false)):
		return "Un sbire : pas de pouvoir, mais il ne pèse que 1."
	return "Pas de pouvoir : ses chiffres sont un peu plus hauts."


# ─────────────────────────────────────────────────────────────
# Le hasard du web, à l'identique (entiers 32 bits non signés)
# ─────────────────────────────────────────────────────────────

const M32 := 0xFFFFFFFF


static func imul(a: int, b: int) -> int:
	a &= M32
	b &= M32
	return ((a & 0xFFFF) * b + ((((a >> 16) * b) & 0xFFFF) << 16)) & M32


static func hacher(s: String) -> int:
	var x := 2166136261
	for i in s.length():
		x = (x ^ s.unicode_at(i)) & M32
		x = imul(x, 16777619)
	return x


# Le générateur « mulberry32 » du web : un objet qui garde son état.
class Hasard:
	var graine := 0

	func _init(g: int) -> void:
		graine = g & MoteurCarre.M32

	func suivant() -> float:
		graine = (graine + 0x6D2B79F5) & MoteurCarre.M32
		var t := MoteurCarre.imul(graine ^ (graine >> 15), 1 | graine)
		t = ((t + MoteurCarre.imul(t ^ (t >> 7), 61 | t)) & MoteurCarre.M32) ^ t
		return float((t ^ (t >> 14)) & MoteurCarre.M32) / 4294967296.0


static func melanger(a: Array, h: Hasard) -> Array:
	for i in range(a.size() - 1, 0, -1):
		var j := int(floor(h.suivant() * (i + 1)))
		var x = a[i]
		a[i] = a[j]
		a[j] = x
	return a


# Un tri STABLE (celui du web l'est) : à égalité, l'ordre d'arrivée est gardé — sans lui,
# l'ordinateur ne choisit pas le même coup que le web.
static func trier(a: Array, avant: Callable) -> Array:
	var out := a.duplicate()
	for i in range(1, out.size()):
		var x = out[i]
		var j := i - 1
		while j >= 0 and float(avant.call(out[j], x)) > 0.0:
			out[j + 1] = out[j]
			j -= 1
		out[j + 1] = x
	return out


# ─────────────────────────────────────────────────────────────
# Les fiches : un héros du jeu, ou un sbire
# ─────────────────────────────────────────────────────────────

static var _fiches := {}
static var _chiffres := {}


static func fiche(id: String) -> Dictionary:
	if _fiches.is_empty():
		for h in GS.HEROS:
			_fiches[h["id"]] = {"id": h["id"], "nom": h["nom"], "type": h["type"], "role": str(h["role"]).to_lower(),
				"stades": (h["formes"] as Array).size(), "sbire": false}
		for s in SBIRES:
			_fiches[s["id"]] = {"id": s["id"], "nom": s["nom"], "type": s["type"], "role": "sbire", "stades": 1, "sbire": true,
				"pays": str(s.get("pays", "")), "image": bool(s.get("image", false)), "modele": s.get("modele", [])}
	return _fiches.get(id, {})


# Ce que la carte (CarteView) sait dessiner : le héros du jeu, ou un sbire. Un sbire sans
# illustration montre sa pierre élémentaire (carte_view.gd, « sbire »).
static func heros_carte(id: String) -> Dictionary:
	var f := fiche(id)
	if not f["sbire"]:
		return GS.heros(id)
	for sb in SBIRES:
		if sb["id"] == id:
			return sbire_carte(sb)
	return {}


# La fiche de carte d'un sbire, depuis son entrée de SBIRES (sans passer par GS : le tirage s'en sert
# aussi dans les tests hors du jeu).
static func sbire_carte(sb: Dictionary) -> Dictionary:
	return {"id": str(sb["id"]), "nom": sb["nom"], "type": sb["type"], "role": "Sbire", "pays": str(sb.get("pays", "")),
		"formes": ["Sbire"], "cadrage": [0.4], "sbire": true}


# Les sbires qu'on peut invoquer : ceux qui ont leur illustration.
static func sbires_invocables() -> Array:
	var l := []
	for s in SBIRES:
		if bool(s.get("image", false)):
			l.append(str(s["id"]))
	return l


static func nom(id: String) -> String:
	return str(fiche(id).get("nom", id))


static func un_seul(id: String) -> bool:
	var f := fiche(id)
	return not f["sbire"] and int(f["stades"]) == 1


static func stade_eff(id: String, s: int) -> int:
	if fiche(id)["sbire"]:
		return 1
	return 3 if un_seul(id) else s


static func poids(id: String, s: int) -> int:
	if fiche(id)["sbire"]:
		return 1
	var p := 4 if un_seul(id) else s + 1
	return p + (int(POIDS_RANG[rang(id)]) if rangs_actifs else 0)


# Le rang d'une carte : « sbire », « heros », « mythe » ou « legende ».
static func rang(id: String) -> String:
	var f := fiche(id)
	if f.is_empty():
		return "heros"
	if f["sbire"]:
		return "sbire"
	return str(RANGS.get(id, "heros"))


static func poids_deck(cartes: Array) -> int:
	var p := 0
	for c in cartes:
		p += poids(str(c["id"]), int(c["s"]))
	return p


# La force d'une carte : la somme de ses chiffres, et 2 de plus si elle a un pouvoir. Sert à composer
# le deck automatique (voyage_ecran.gd) et à doser les adversaires de l'Aventure (aventure.gd).
static func force(c: Dictionary) -> int:
	return somme(chiffres_de(str(c["id"]), int(c["s"]))) + (2 if POUVOIRS.has(str(c["id"])) else 0)


static func force_deck(cartes: Array) -> int:
	var f := 0
	for c in cartes:
		f += force(c)
	return f


static func type_de(id: String) -> String:
	return str(fiche(id)["type"])


static func _base(id: String) -> Array:
	var h := Hasard.new(hacher("carre-" + id))
	var f := fiche(id)
	var propre: Array = f.get("modele", [])
	var t: Array = (propre if not propre.is_empty() else MODELES.get(f["role"], MODELES["appui"]) as Array).duplicate()
	var rot := int(floor(h.suivant() * 4))
	var r := []
	for i in 4:
		r.append(t[(i + rot) % 4])
	# un sbire aux chiffres écrits à la main les garde tels quels (tournés seulement)
	if not propre.is_empty():
		return r
	var a := int(floor(h.suivant() * 4))
	var b := (a + 1 + int(floor(h.suivant() * 3))) % 4
	if r[a] < 9 and r[b] > 2:
		r[a] += 1
		r[b] -= 1
	return r


# Les quatre chiffres d'une carte : haut, droite, bas, gauche.
static func chiffres_de(id: String, s: int) -> Array:
	var cle := "%s%d%s" % [id, s, "" if rangs_actifs else "-"]
	if _chiffres.has(cle):
		return (_chiffres[cle] as Array).duplicate()
	var r := _base(id)
	var f := fiche(id)
	if not f["sbire"]:
		var st := stade_eff(id, s)
		# sans pouvoir, ou un pouvoir discret : +1
		if not POUVOIRS.has(id) or id == "kitsune" or id == "bahamut":
			r[r.find(r.max())] += 1
		var idx := [0, 1, 2, 3]
		if st >= 2:
			for i in trier(idx, func(x, y): return float(r[y] - r[x]) if r[y] != r[x] else float(x - y)).slice(0, 3):
				r[i] += 1
		if st >= 3:
			for i in trier(idx, func(x, y): return float(r[x] - r[y]) if r[x] != r[y] else float(x - y)).slice(0, 3):
				r[i] += 1
		# le rang : +1 à ses chiffres les plus faibles (Mythe : 1, Légende : 2)
		var bonus := int(BONUS_RANG[rang(id)]) if rangs_actifs else 0
		if bonus > 0:
			for i in trier(idx, func(x, y): return float(r[x] - r[y]) if r[x] != r[y] else float(x - y)).slice(0, bonus):
				r[i] += 1
		for i in 4:
			r[i] = mini(10, r[i])
	_chiffres[cle] = r.duplicate()
	return r


# ─────────────────────────────────────────────────────────────
# Les règles
# ─────────────────────────────────────────────────────────────

static func autre(camp: String) -> String:
	return "a" if camp == "j" else "j"


# Les voisines d'une case : [case, côté] (0 haut, 1 droite, 2 bas, 3 gauche).
static func orth(n: int, i: int) -> Array:
	var l := i / n
	var c := i % n
	var v := []
	if l > 0:
		v.append([i - n, 0])
	if c < n - 1:
		v.append([i + 1, 1])
	if l < n - 1:
		v.append([i + n, 2])
	if c > 0:
		v.append([i - 1, 3])
	return v


# Les coins : [case, côté vertical, côté horizontal].
static func diag(n: int, i: int) -> Array:
	var l := i / n
	var c := i % n
	var v := []
	for q in [[-1, 1, 0, 1], [1, 1, 2, 1], [1, -1, 2, 3], [-1, -1, 0, 3]]:
		var ll: int = l + q[0]
		var cc: int = c + q[1]
		if ll >= 0 and cc >= 0 and ll < n and cc < n:
			v.append([ll * n + cc, q[2], q[3]])
	return v


# Les chiffres d'une carte posée, avec la Marée de Bahamut autour d'elle.
static func valeurs(st: Dictionary, i: int) -> Array:
	var c: Dictionary = st["cases"][i]
	var v: Array = (c["ch"] as Array).duplicate()
	for o in orth(st["n"], i):
		var b = st["cases"][o[0]]
		if b != null and b["camp"] == c["camp"] and b["id"] == "bahamut":
			for s in 4:
				v[s] += 2 if int(b["s"]) == 3 else 1
	for s in 4:
		v[s] = mini(10, v[s])
	return v


static func somme(v: Array) -> int:
	var t := 0
	for x in v:
		t += int(x)
	return t


static func protegee(st: Dictionary, i: int, par_chaine: bool) -> bool:
	var c: Dictionary = st["cases"][i]
	if c["id"] == "kitsune" and (par_chaine or (int(c["s"]) == 3 and int(st["tour"]) <= int(c["pose"]) + 1)):
		return true
	if c["id"] == "golem" and int(st["tour"]) <= int(c["pose"]) + (3 if int(c["s"]) == 3 else 1):
		return true
	return false


static func libre(st: Dictionary, i: int) -> bool:
	return st["cases"][i] == null and not (st["bloc"] as Array).has(i)


# `trace` (pour l'écran seulement) : s'il est donné, il reçoit l'état du plateau juste après la pose et
# ses pouvoirs (« pose »), puis après chaque événement du retournement (clé : son rang dans la liste).
# 🔴 Sans lui, l'écran montrait pendant tout le coup les chiffres de la FIN du coup : une carte prise à
#    côté de Bahamut y gagnait déjà sa Marée, et le duel montrait « 6 contre 6 » pour un 6 contre 5
#    (Maxim, 27/09 : « il avait moins de points et ça a retourné ma carte quand même »).
static func poser(st: Dictionary, camp: String, carte: Dictionary, i: int, trace = null) -> Array:
	var n: int = st["n"]
	st["tour"] = int(st["tour"]) + 1
	st["uid"] = int(st["uid"]) + 1
	var id := str(carte["id"])
	var c := {"uid": st["uid"], "id": id, "s": stade_eff(id, int(carte["s"])), "v": str(carte.get("v", "base")), "camp": camp,
		"ch": chiffres_de(id, int(carte["s"])), "pose": st["tour"], "faim": 0}
	var terres: Dictionary = st["terres"]
	if terres.has(i) and str(terres[i]) == type_de(id):
		for s in 4:
			c["ch"][s] = mini(10, int(c["ch"][s]) + 1)
		c["terre"] = true
	st["cases"][i] = c
	var ev := []
	var fort := int(c["s"]) == 3
	if id == "thor":
		var k := 2 if fort else 1
		var e := _ennemis(st, i, camp)
		for o in e:
			c["ch"][o[1]] = mini(10, int(c["ch"][o[1]]) + k)
		if not e.is_empty():
			ev.append({"t": "pouvoir", "i": i, "id": id, "txt": "Foudre : +%d face à l'ennemi" % k})
	if id == "loki":
		var voisines := []
		for o in orth(n, i):
			if st["cases"][o[0]] != null:
				voisines.append(valeurs(st, o[0]))
		voisines = trier(voisines, func(a, b): return float(somme(b) - somme(a)))
		if not voisines.is_empty():
			var v: Array = voisines[0]
			for s in 4:
				c["ch"][s] = maxi(int(c["ch"][s]), int(v[s])) if fort else maxi(1, int(v[s]) - 1)
			ev.append({"t": "pouvoir", "i": i, "id": id, "txt": "Métamorphose : il copie la plus forte"})
	if id == "babayaga":
		var k := 2 if fort else 1
		var e := _ennemis(st, i, camp)
		for o in e:
			var d: Dictionary = st["cases"][o[0]]
			for s in 4:
				d["ch"][s] = maxi(1, int(d["ch"][s]) - k)
		if not e.is_empty():
			ev.append({"t": "pouvoir", "i": i, "id": id, "txt": "Malédiction : −%d aux voisines" % k})
	if id == "yeti":
		var vides := []
		for o in orth(n, i):
			if libre(st, o[0]):
				vides.append(o)
		var gel := vides
		if not fort:
			gel = trier(vides, func(a, b): return float(int(c["ch"][a[1]]) - int(c["ch"][b[1]]))).slice(0, 1)
		for o in gel:
			st["gel"][o[0]] = {"contre": autre(camp), "jusqua": int(st["tour"]) + 1}
		if not gel.is_empty():
			ev.append({"t": "pouvoir", "i": i, "id": id, "txt": "Gel : %s" % (("%d cases gelées" % gel.size()) if gel.size() > 1 else "une case gelée")})
	if trace != null:
		trace["pose"] = cloner(st)
	# Les retournements, en chaîne : chaque carte prise attaque à son tour, pour le camp qui l'a prise.
	# 🔴 Une carte qui a changé de camp depuis (reprise par Anubis) n'attaque plus : sinon les deux
	#    camps se relancent la chaîne sans fin (vu au banc le 27/09 : Cerbère en diagonale, Anubis
	#    retourné — le combat se figeait). Anubis « reprend », il ne lance pas de chaîne.
	var file := [[i, camp]]
	while not file.is_empty():
		var tete: Array = file.pop_front()
		var k: int = tete[0]
		var a: Dictionary = st["cases"][k]
		var camp_a := str(a["camp"])
		if camp_a != str(tete[1]):
			continue
		var cibles := []
		for o in orth(n, k):
			cibles.append({"m": o[0], "s": o[1], "diag": false})
		if a["id"] == "cerbere":
			for o in diag(n, k):
				cibles.append({"m": o[0], "sv": o[1], "sh": o[2], "diag": true})
		for cb in cibles:
			if str(st["cases"][k]["camp"]) != camp_a:
				break
			var m: int = cb["m"]
			var d = st["cases"][m]
			if d == null or str(d["camp"]) == camp_a:
				continue
			var x: int
			var y: int
			if cb["diag"]:
				var va := valeurs(st, k)
				x = maxi(va[cb["sv"]], va[cb["sh"]]) if int(a["s"]) == 3 else mini(va[cb["sv"]], va[cb["sh"]])
				var vd := valeurs(st, m)
				y = mini(vd[OPP[cb["sv"]]], vd[OPP[cb["sh"]]])
			else:
				x = valeurs(st, k)[cb["s"]]
				y = valeurs(st, m)[OPP[cb["s"]]]
			if x > y and not protegee(st, m, k != i):
				var ancien := str(d["camp"])
				d["camp"] = camp_a
				ev.append({"t": "flip", "de": k, "vers": m, "a": x, "b": y, "chaine": k != i, "diag": cb["diag"], "prev": ancien, "camp": camp_a})
				_tracer(trace, st, ev)
				file.append([m, camp_a])
				if a["id"] == "fenrir" and int(a["faim"]) < (3 if int(a["s"]) == 3 else 2):
					a["faim"] = int(a["faim"]) + 1
					for s in 4:
						a["ch"][s] = mini(10, int(a["ch"][s]) + 1)
					ev.append({"t": "pouvoir", "i": k, "id": "fenrir", "txt": "Faim : +1 partout"})
					_tracer(trace, st, ev)
				if d["id"] == "anubis" and not d.get("use_anubis", false):
					d["use_anubis"] = true
					var pris := []
					for o in orth(n, m):
						var q = st["cases"][o[0]]
						if q != null and str(q["camp"]) == camp_a:
							pris.append(o[0])
					pris = trier(pris, func(p, q2): return float(somme(valeurs(st, p)) - somme(valeurs(st, q2)))).slice(0, 2 if int(d["s"]) == 3 else 1)
					for m2 in pris:
						st["cases"][m2]["camp"] = ancien
						ev.append({"t": "anubis", "de": m, "vers": m2, "prev": camp_a, "camp": ancien})
						_tracer(trace, st, ev)
					if not pris.is_empty():
						ev.append({"t": "pouvoir", "i": m, "id": "anubis", "txt": "Pesée des âmes : une carte reprise"})
						_tracer(trace, st, ev)
			elif x > y:
				ev.append({"t": "protege", "i": m, "id": d["id"]})
				_tracer(trace, st, ev)
	return ev


static func _tracer(trace, st: Dictionary, ev: Array) -> void:
	if trace != null:
		trace[ev.size() - 1] = cloner(st)


static func _ennemis(st: Dictionary, i: int, camp: String) -> Array:
	var e := []
	for o in orth(st["n"], i):
		var q = st["cases"][o[0]]
		if q != null and str(q["camp"]) != camp:
			e.append(o)
	return e


static func compte(st: Dictionary, camp: String) -> int:
	var k := 0
	for c in st["cases"]:
		if c != null and str(c["camp"]) == camp:
			k += 1
	return k


static func cloner(st: Dictionary) -> Dictionary:
	var cases := []
	for c in st["cases"]:
		if c == null:
			cases.append(null)
		else:
			var d: Dictionary = (c as Dictionary).duplicate()
			d["ch"] = (c["ch"] as Array).duplicate()
			cases.append(d)
	return {"n": st["n"], "cases": cases, "terres": st["terres"], "bloc": st["bloc"], "gel": (st["gel"] as Dictionary).duplicate(),
		"tour": st["tour"], "uid": st["uid"], "main": {"j": (st["main"]["j"] as Array).duplicate(), "a": (st["main"]["a"] as Array).duplicate()}}


static func plein(st: Dictionary) -> bool:
	for i in (st["cases"] as Array).size():
		if st["cases"][i] == null and not (st["bloc"] as Array).has(i):
			return false
	return true


# Les cases où un camp peut poser : pas celles que le Yéti a gelées contre lui (s'il en reste d'autres).
static func cases_pour(st: Dictionary, camp: String) -> Array:
	var l := []
	for i in (st["cases"] as Array).size():
		if libre(st, i):
			l.append(i)
	var sans_gel := []
	for i in l:
		var g = st["gel"].get(i, null)
		if not (g != null and str(g["contre"]) == camp and int(g["jusqua"]) >= int(st["tour"]) + 1):
			sans_gel.append(i)
	return sans_gel if not sans_gel.is_empty() else l


static func case_gelee(st: Dictionary, i: int) -> bool:
	var g = st["gel"].get(i, null)
	return g != null and int(g["jusqua"]) >= int(st["tour"]) + 1


static func coups(st: Dictionary, camp: String) -> Array:
	var cs := cases_pour(st, camp)
	var vus := {}
	var l := []
	var main: Array = st["main"][camp]
	for h in main.size():
		var c: Dictionary = main[h]
		var cle := "%s%d" % [c["id"], int(c["s"])]
		if vus.has(cle):
			continue
		vus[cle] = true
		for i in cs:
			l.append([h, i])
	return l


static func jouer_coup(st: Dictionary, camp: String, coup: Array, trace = null) -> Array:
	var main: Array = (st["main"][camp] as Array).duplicate()
	var c: Dictionary = main[coup[0]]
	main.remove_at(coup[0])
	st["main"][camp] = main
	return poser(st, camp, c, coup[1], trace)


# ─────────────────────────────────────────────────────────────
# L'ordinateur, en trois niveaux (réglés au banc le 26/09 : un débutant bat l'Apprenti)
# ─────────────────────────────────────────────────────────────

const NIVEAUX := {"apprenti": "Apprenti", "aventurier": "Aventurier", "maitre": "Maître"}


static func coup_ia(st: Dictionary, h: Hasard, moi: String, niveau: String) -> Array:
	var lui := autre(moi)
	var tous := []
	for m in coups(st, moi):
		var s := cloner(st)
		jouer_coup(s, moi, m)
		tous.append({"m": m, "s": s, "v": compte(s, moi) - compte(s, lui)})
	if niveau == "apprenti":
		if h.suivant() < 0.55:
			return tous[int(floor(h.suivant() * tous.size()))]["m"]
		tous = trier(tous, func(a, b): return float(b["v"] - a["v"]))
		return tous[int(floor(h.suivant() * mini(5, tous.size())))]["m"]
	if niveau == "aventurier":
		var meilleur = null
		for c in tous:
			var v := float(c["v"]) + h.suivant() * 1.2
			if meilleur == null or v > float(meilleur["v"]):
				meilleur = {"v": v, "m": c["m"]}
		return meilleur["m"]
	var best = null
	for c in trier(tous, func(a, b): return float(b["v"] - a["v"])).slice(0, 10):
		var pire := int(c["v"])
		var s1: Dictionary = c["s"]
		if not plein(s1) and not (s1["main"][lui] as Array).is_empty():
			for r in coups(s1, lui):
				var s2 := cloner(s1)
				jouer_coup(s2, lui, r)
				pire = mini(pire, compte(s2, moi) - compte(s2, lui))
		var v := float(pire) + h.suivant() * 0.5
		if best == null or v > float(best["v"]):
			best = {"v": v, "m": c["m"]}
	return best["m"]


# ─────────────────────────────────────────────────────────────
# Une nouvelle partie : les terres (2 en 3 × 3, 3 et un gouffre en 4 × 4), tirées au hasard
# ─────────────────────────────────────────────────────────────

static func nouvelle_partie(main_j: Array, main_a: Array, h: Hasard, n := 3) -> Dictionary:
	var cs := []
	for i in n * n:
		cs.append(i)
	melanger(cs, h)
	var ty := melanger(TYPES_TERRES.duplicate(), h)
	var nt := 3 if n == 4 else 2
	var terres := {}
	for k in nt:
		terres[cs[k]] = ty[k]
	var bloc := [cs[nt]] if n == 4 else []
	var cases := []
	cases.resize(n * n)
	return {"n": n, "cases": cases, "terres": terres, "bloc": bloc, "gel": {}, "tour": 0, "uid": 0,
		"main": {"j": main_j.duplicate(true), "a": main_a.duplicate(true)}}
