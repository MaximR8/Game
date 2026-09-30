extends Node

# Le test des portails de l'Astrolabe (⑩, 28/09) — sans écran.
#
#   1. Le Grand Ciel ne change pas : ses chances, son tirage, et il ne touche pas au compteur du Peintre.
#   2. Le Ciel du Peintre : le Full art à 0,2 % (mesuré), jamais sur un sbire ; les pourcentages affichés, calculés.
#   3. Le cadeau : la première ×10 offerte (un ×1 se paie toujours) — le refus ET le passage.
#   4. Le compteur : chaque carte compte (un ×10 : 10) ; la centième est un Full art d'office ; le ×10 va au bout ;
#      le ciel se referme, et refuse ensuite (sans prendre d'étoile).
#   5. Le banc : des milliers de joueurs jusqu'au Full art — jamais au-delà de 100, ~18 % avant la garantie.
#   6. Jamais en double ; une collection complète ne casse rien ; l'outil de test ne referme rien.
#   7. La sauvegarde : l'aller-retour ; une vieille partie (sans la clé) ; une valeur mal formée.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_portails.tscn
#
# Attendu : « RESULTAT: OK » et aucune ligne « SCRIPT ERROR ».

var erreurs := 0
var verifs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	_grand_ciel()
	_peintre_taux()
	_cadeau()
	_compteur()
	_banc()
	_sans_double()
	_sauvegarde()
	print("%d vérifications" % verifs)
	print("RESULTAT: %s" % ("OK" if erreurs == 0 and verifs > 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	if not vrai:
		erreurs += 1
		if erreurs <= 30:
			print("  ✗ " + quoi)


func _neuf(etoiles: int) -> void:
	GS.voyage = {}
	GS.cartes = {}
	GS.etoiles = etoiles


func _pct(l: Array, id: String) -> float:
	for e in l:
		if e["id"] == id:
			return float(e["pct"])
	return -1.0


func _somme(l: Array) -> float:
	var s := 0.0
	for e in l:
		s += float(e["pct"])
	return s


# ─────────────────────────────────────────────────────────────

func _grand_ciel() -> void:
	_neuf(30)
	var v := GS.probas("grand")
	_ok("Grand Ciel : Full art 0,1 %%, Base 73,9 %% (%s)" % str(v), is_equal_approx(_pct(v, "full"), 0.1) and is_equal_approx(_pct(v, "base"), 73.9))
	_ok("Grand Ciel : les mêmes chances que sans ciel", str(GS.probas()) == str(v) and str(GS.probas_cartes()) == str(GS.probas_cartes("grand")))
	var c := GS.probas_cartes("grand")
	_ok("Grand Ciel : Sbire 60, Héros 25, Mythe 11, Légende 4", is_equal_approx(_pct(c, "sbire"), 60.0) and is_equal_approx(_pct(c, "heros"), 25.0)
		and is_equal_approx(_pct(c, "mythe"), 11.0) and is_equal_approx(_pct(c, "legende"), 4.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2809
	var n := 300000
	var full := 0
	var sbires_full := 0
	for i in n:
		var x := GS.tirer(rng, "grand")
		if x[1] == "full":
			full += 1
			if GS.est_sbire(str(x[0])):
				sbires_full += 1
	var taux := 100.0 * full / n
	_ok("Grand Ciel : Full art mesuré %.3f %% (0,1 attendu)" % taux, absf(taux - 0.1) < 0.025)
	_ok("Grand Ciel : un Full art peut y être un sbire (%d sur %d)" % [sbires_full, full], sbires_full > 0)
	var lot := GS.invoquer_multi(10, "grand")
	_ok("Grand Ciel : un ×10 coûte 10 étoiles", lot.size() == 10 and GS.etoiles == 20)
	_ok("Grand Ciel : il ne touche pas au compteur du Peintre", Portails.compte("peintre") == 0 and Portails.offerte_due("peintre"))
	_ok("Grand Ciel : chaque carte dit son ciel", str(lot[0].get("portail", "")) == "grand" and not bool(lot[0].get("garanti", true)))


func _peintre_taux() -> void:
	_neuf(0)
	var v := GS.probas("peintre")
	_ok("Peintre : Full art 0,2 %, Base 73,8 %, total 100", is_equal_approx(_pct(v, "full"), 0.2) and is_equal_approx(_pct(v, "base"), 73.8)
		and is_equal_approx(_somme(v), 100.0))
	var c := GS.probas_cartes("peintre")
	_ok("Peintre : les rangs en tiennent compte (Sbire %.2f, Héros %.3f, total %.4f)" % [_pct(c, "sbire"), _pct(c, "heros"), _somme(c)],
		is_equal_approx(_pct(c, "sbire"), 59.88) and absf(_pct(c, "heros") - 25.075) < 0.001 and absf(_somme(c) - 100.0) < 0.0001)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1409
	var n := 500000
	var full := 0
	var full_sbire := 0
	var full_rangs := {}
	var sbires := 0
	for i in n:
		var x := GS.tirer(rng, "peintre")
		var sb := GS.est_sbire(str(x[0]))
		if sb:
			sbires += 1
		if x[1] == "full":
			full += 1
			if sb:
				full_sbire += 1
			var rg := MoteurCarre.rang(str(x[0]))
			full_rangs[rg] = int(full_rangs.get(rg, 0)) + 1
	var taux := 100.0 * full / n
	_ok("Peintre : Full art mesuré %.3f %% (0,2 attendu)" % taux, absf(taux - 0.2) < 0.03)
	_ok("Peintre : jamais un sbire en Full art (%d)" % full_sbire, full_sbire == 0)
	_ok("Peintre : les Full art, rang par rang %s (Héros ~62 %%)" % str(full_rangs),
		absf(float(full_rangs.get("heros", 0)) / full - 0.625) < 0.06 and int(full_rangs.get("legende", 0)) > 0)
	var ps := 100.0 * sbires / n
	_ok("Peintre : les sbires mesurés %.2f %% (59,88 affiché)" % ps, absf(ps - 59.88) < 0.3)
	var force := GS.tirer(rng, "peintre", true)
	_ok("la garantie : un Full art d'office, sur un héros", force[1] == "full" and not GS.est_sbire(str(force[0])))


func _cadeau() -> void:
	_neuf(0)
	_ok("le cadeau est dû, dans un Peintre ouvert", Portails.offerte_due("peintre") and Portails.ouvert("peintre"))
	_ok("sans étoile : un ×10 offert, oui", GS.peut_invoquer(10, "peintre") and Portails.cout("peintre", 10) == 0)
	_ok("sans étoile : un ×1, non (le cadeau est un ×10)", not GS.peut_invoquer(1, "peintre") and GS.invoquer_multi(1, "peintre").is_empty())
	_ok("sans étoile : le Grand Ciel, non", not GS.peut_invoquer(10, "grand"))
	var lot := GS.invoquer_multi(10, "peintre")
	_ok("le cadeau : 10 cartes, aucune étoile prise, elles comptent dans les 100", lot.size() == 10 and GS.etoiles == 0
		and Portails.compte("peintre") == 10 and Portails.restant("peintre") == 90)
	_ok("le cadeau pris : il n'est plus dû", not Portails.offerte_due("peintre") and not GS.peut_invoquer(10, "peintre"))
	GS.etoiles = 10
	_ok("ensuite : un ×10 coûte 10 étoiles", GS.invoquer_multi(10, "peintre").size() == 10 and GS.etoiles == 0 and Portails.compte("peintre") == 20)
	# un ×1 avec le cadeau encore dû : 1 étoile, et le cadeau reste
	_neuf(1)
	_ok("un ×1 avant le cadeau : 1 étoile, le cadeau reste dû", GS.invoquer_multi(1, "peintre").size() == 1 and GS.etoiles == 0
		and Portails.offerte_due("peintre") and Portails.compte("peintre") == 1)


func _compteur() -> void:
	_neuf(1000)
	_ok("au départ : garanti dans 100", Portails.restant("peintre") == 100)
	GS.invoquer_multi(10, "peintre")          # (le cadeau)
	var sans_full := Portails.ouvert("peintre")
	if sans_full:
		_ok("un ×10 : le compteur avance de 10 (garanti dans 90)", Portails.compte("peintre") == 10 and Portails.restant("peintre") == 90)
	# la centième : 200 essais, chaque fois le compteur à 95 et un ×10
	var au_5e := 0
	var avant := 0
	var bon := true
	for essai in 200:
		_neuf(10)
		GS.voyage["portails"] = {"peintre": {"n": 95, "offerte": true}}
		var lot := GS.invoquer_multi(10, "peintre")
		var premier := -1
		for i in lot.size():
			if lot[i]["variante"] == "full":
				premier = i
				break
		if premier == 4:
			au_5e += 1
			bon = bon and bool(lot[4]["garanti"]) and not GS.est_sbire(str(lot[4]["heros"]["id"]))
		elif premier >= 0 and premier < 4:
			avant += 1
			bon = bon and not bool(lot[premier]["garanti"])
		else:
			bon = false
		bon = bon and lot.size() == 10 and GS.etoiles == 0 and not Portails.ouvert("peintre")
	_ok("la centième : toujours un Full art au plus tard (%d à la 100e, %d avant)" % [au_5e, avant], bon and au_5e + avant == 200 and au_5e > 180)
	# refermé : tout est refusé, sans prendre d'étoile
	GS.etoiles = 50
	_ok("refermé : ni ×1 ni ×10, aucune étoile prise", not GS.peut_invoquer(1, "peintre") and GS.invoquer_multi(1, "peintre").is_empty()
		and GS.invoquer_multi(10, "peintre").is_empty() and GS.etoiles == 50)
	_ok("refermé : il n'est plus dans l'Astrolabe, le Grand Ciel si", Portails.ouverts() == ["grand"])
	_ok("refermé : plus de cadeau à montrer", not Portails.offerte_due("peintre"))
	_ok("refermé : le mot d'adieu, une fois", Portails.adieu_a_montrer("peintre"))
	Portails.adieu_vu("peintre")
	_ok("le mot vu : plus jamais", not Portails.adieu_a_montrer("peintre"))
	# la garantie tombe sur la 100e même en ×1
	_neuf(10)
	GS.voyage["portails"] = {"peintre": {"n": 99, "offerte": true}}
	var r := GS.invoquer_multi(1, "peintre")
	_ok("à 99, la suivante : le Full art garanti", r.size() == 1 and r[0]["variante"] == "full" and bool(r[0]["garanti"]) and not Portails.ouvert("peintre"))


func _banc() -> void:
	var joueurs := 12000
	var pire := 0
	var avant_garantie := 0
	var total := 0
	var casse := 0
	for j in joueurs:
		_neuf(100000)
		var k := 0
		while Portails.ouvert("peintre") and k < 150:
			var lot := GS.invoquer_multi(1, "peintre")
			k += 1
			if lot.size() != 1:
				casse += 1
				break
		pire = maxi(pire, k)
		total += k
		if k < 100:
			avant_garantie += 1
	var part := 100.0 * avant_garantie / joueurs
	print("banc : %d joueurs, Full art en %.1f invocations en moyenne, le pire à %d, %.1f %% avant la garantie" % [joueurs, float(total) / joueurs, pire, part])
	_ok("banc : personne au-delà de 100 (le pire : %d)" % pire, pire <= 100 and casse == 0)
	# 1 − 0,998^99 ≈ 18 % (la première, offerte, compte ; ici tout le monde a des étoiles)
	_ok("banc : %.1f %% ont leur Full art avant la garantie (~18 attendu)" % part, absf(part - 18.0) < 2.5)


func _sans_double() -> void:
	# tous les héros ont le Full art, sauf un Mythe : la garantie tombe sur lui
	_neuf(10)
	var seul := str(GS.ids_du_rang("mythe")[0])
	for rg in ["heros", "mythe", "legende"]:
		for id in GS.ids_du_rang(rg):
			GS.cartes[id] = {"stade": 1, "niveau": 1, "variante": "base", "variantes": ["base"] if id == seul else ["base", "full"]}
	GS.voyage["portails"] = {"peintre": {"n": 99, "offerte": true}}
	var r := GS.invoquer_multi(1, "peintre")
	_ok("jamais en double : le seul héros sans Full art l'a (%s)" % seul, r.size() == 1 and str(r[0]["heros"]["id"]) == seul
		and bool(r[0]["nouvelle_variante"]))
	# tous l'ont : un Full art quand même (un doublon, ses éclats), sans casser
	_neuf(10)
	for rg in ["heros", "mythe", "legende"]:
		for id in GS.ids_du_rang(rg):
			GS.cartes[id] = {"stade": 1, "niveau": 1, "variante": "full", "variantes": ["base", "full"]}
	GS.voyage["portails"] = {"peintre": {"n": 99, "offerte": true}}
	r = GS.invoquer_multi(1, "peintre")
	_ok("tous l'ont : un doublon de Full art (300 éclats de plus), rien ne casse", r.size() == 1 and bool(r[0]["doublon"]) and int(r[0]["eclats"]) == 305)
	# l'outil de test « Full art » ne referme pas le ciel
	_neuf(0)
	GS.donner_carte_test("full")
	_ok("l'outil de test ne touche pas au Peintre", Portails.ouvert("peintre") and Portails.compte("peintre") == 0 and Portails.offerte_due("peintre"))


func _sauvegarde() -> void:
	_neuf(0)
	GS.invoquer_multi(10, "peintre")
	var n := Portails.compte("peintre")
	var texte := JSON.stringify(GS.donnees_sauvegarde())
	_neuf(0)
	GS.lire_sauvegarde(JSON.parse_string(texte), false)
	_ok("l'aller-retour : le compteur (%d), le cadeau pris" % n, Portails.compte("peintre") == n and n >= 1 and not Portails.offerte_due("peintre"))
	# une vieille partie : pas de clé
	var vieille := {"v": 4, "etoiles": 3, "voyage": {"tuto_carre": true}}
	GS.lire_sauvegarde(vieille, false)
	_ok("une vieille partie : le Peintre ouvert, à 0, le cadeau dû", Portails.ouvert("peintre") and Portails.compte("peintre") == 0
		and Portails.offerte_due("peintre") and GS.peut_invoquer(10, "peintre"))
	# mal formée
	GS.voyage["portails"] = "abîmé"
	_ok("mal formée : repart de zéro", Portails.compte("peintre") == 0 and Portails.ouvert("peintre"))
	GS.voyage["portails"] = {"peintre": {"n": "trois", "ferme": 1}}
	_ok("mal formée (un compte en texte) : 0, et « ferme » lu", Portails.compte("peintre") == 0 and not Portails.ouvert("peintre"))
