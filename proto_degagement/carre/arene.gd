class_name Arene
extends RefCounted

# ─────────────────────────────────────────────────────────────
# CE QUE LE DUEL ET LE CLASSÉ PARTAGENT — étape 3 du Carré (fiche acceptée le 28/09).
#
# · Quand ils s'ouvrent : le boss de la 1ʳᵉ terre battu (le Chevalier sans tête). Avant, la 1ʳᵉ terre
#   apprend le jeu (Maxim joue sans lire), et le cadenas donne un but.
# · La poussière du jour : 30 par victoire, 5 victoires par jour, en Duel OU en Classé (Maxim, 28/09 :
#   « ok » — sinon, qui aime le Classé ferait des duels par corvée). Au-delà, on joue sans poussière.
#   Le jour, c'est celui du téléphone, comme le cadeau du jour.
# · Le combat en cours : écrit dès qu'il commence. « Quitter », ou l'app fermée en plein combat, le
#   compte comme une défaite — sinon, il suffirait de fermer l'app quand on perd.
#
# Dans GS.voyage : « jour » = {date, victoires} ; « en_cours » = l'adversaire du combat commencé.
# ─────────────────────────────────────────────────────────────

# 🔴 Provisoire (D11, en attente de l'économie ⑧).
const POUSSIERE_VICTOIRE := 30
const VICTOIRES_JOUR := 5

# Les outils de test (réseau local seulement, D1) : le Duel et le Classé ouverts sans toucher la partie.
static var ouvert_pour_test := false


static func ouvert() -> bool:
	return ouvert_pour_test or Aventure.gagne(Aventure.PAR_TERRE)


# « le Chevalier sans tête » : l'article en minuscule, au milieu d'une phrase.
static func boss_a_battre() -> String:
	var nom := str(Aventure.niveau(Aventure.PAR_TERRE)["nom"])
	for article in ["Le ", "La ", "Les ", "L'"]:
		if nom.begins_with(article):
			return article.to_lower() + nom.substr(article.length())
	return nom


# ─────────────────────────────────────────────────────────────
# La poussière du jour
# ─────────────────────────────────────────────────────────────

static func _jour() -> Dictionary:
	var j = GS.voyage.get("jour", null)
	var date := Time.get_date_string_from_system()
	if typeof(j) != TYPE_DICTIONARY or str(j.get("date", "")) != date:
		j = {"date": date, "victoires": 0}
	var v = j.get("victoires", 0)
	j["victoires"] = clampi(int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0, 0, VICTOIRES_JOUR)
	GS.voyage["jour"] = j
	return j


static func victoires_du_jour() -> int:
	return int(_jour()["victoires"])


# Ce que rapporterait une victoire maintenant (0 une fois les 5 du jour gagnées) : l'écran de combat
# retient d'autant le compteur du bandeau AVANT terminer(), puis fait s'envoler la poussière.
static func poussiere_prevue() -> int:
	return POUSSIERE_VICTOIRE if victoires_du_jour() < VICTOIRES_JOUR else 0


# Une victoire : compte dans le jour, et DONNE sa poussière tout de suite (avec le résultat : une app
# fermée pendant l'envol ne la perd pas). Rend ce qui a été donné.
static func compter_victoire() -> int:
	var j := _jour()
	if int(j["victoires"]) >= VICTOIRES_JOUR:
		return 0
	j["victoires"] = int(j["victoires"]) + 1
	GS.gagner(POUSSIERE_VICTOIRE, 0)
	return POUSSIERE_VICTOIRE


# ─────────────────────────────────────────────────────────────
# Un combat du Duel ou du Classé
# ─────────────────────────────────────────────────────────────

static func adversaire_suivant(mode: String) -> Dictionary:
	var graine := randi()
	return Classe.adversaire_suivant(graine) if mode == "classe" else Duel.adversaire_suivant(graine)


# Le combat commence : il est écrit tout de suite (une app fermée en plein combat le perd).
static func commencer(adv: Dictionary) -> void:
	GS.voyage["en_cours"] = {"mode": str(adv["mode"]), "chef": str(adv["chef"]), "chef_s": int(adv.get("chef_s", 1)),
		"nom": str(adv.get("nom", "")), "cote": int(adv.get("cote", 0))}
	GS.save_game()


static func en_cours() -> bool:
	return typeof(GS.voyage.get("en_cours", null)) == TYPE_DICTIONARY


# Le combat est fini (j, a : les cartes de chacun) : il est retenu, et rend ce que l'écran montre :
# {mode, resultat, poussiere, duel {avant, apres, delta} ou classe {…, voir Classe.enregistrer}}.
static func terminer(adv: Dictionary, j: int, a: int, interrompu := false) -> Dictionary:
	GS.voyage.erase("en_cours")
	var resultat := 1 if j > a else (0 if j == a else -1)
	var infos := adv.duplicate()
	infos["j"] = j
	infos["a"] = a
	var r := {"mode": str(adv.get("mode", "duel")), "resultat": resultat, "poussiere": 0}
	if resultat > 0:
		r["poussiere"] = compter_victoire()
	if r["mode"] == "classe":
		r["classe"] = Classe.enregistrer(resultat, infos, interrompu)
	else:
		r["duel"] = Duel.enregistrer(resultat, infos, interrompu)
	return r


# À l'ouverture du jeu : un combat resté en cours (app fermée, téléphone éteint) compte comme perdu.
# Rend le résultat ({} s'il n'y en avait pas) ; l'historique du mode le montre (« interrompu »).
static func solder_interrompu() -> Dictionary:
	if not en_cours():
		return {}
	var adv: Dictionary = GS.voyage["en_cours"]
	if str(adv.get("mode", "")) not in ["duel", "classe"]:
		GS.voyage.erase("en_cours")
		GS.save_game()
		return {}
	if adv.get("mode") == "classe":
		Classe.verifier_saison()        # un combat d'une saison finie compte dans la nouvelle, après sa récompense
	return terminer(adv, 0, 1, true)
