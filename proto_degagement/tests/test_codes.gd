extends Node

# Le test des codes cadeaux et des réglages (29/09) — sans écran.
#
#   1. L'empreinte : la même que celle de codes_cadeaux/codes.py (calculée en Python : sinon aucun code ne marcherait,
#      sans une erreur) ; la normalisation (tirets, espaces, minuscules).
#   2. Vérifier : inconnu, expiré, vide, table abîmée — le refus ; un bon code — le passage.
#   3. Encaisser : la récompense arrive (étoiles, poussière, pièces, éclats, pierres), une fois ; la seconde : « déjà ».
#   4. La sauvegarde garde les codes pris ; une vieille partie n'en a aucun.
#   5. Les réglages : les deux bus existent, à leur volume ; zéro les rend muets ; les vibrations se coupent.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_codes.tscn

var erreurs := 0
var verifs := 0


func _ready() -> void:
	GS.sauvegarde_active = false
	Reglages.actif = false
	_empreinte()
	_verifier()
	_encaisser()
	_reglages()
	print("%d vérifications" % verifs)
	print("RESULTAT: %s" % ("OK" if erreurs == 0 and verifs > 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	if not vrai:
		erreurs += 1
		print("  ✗ " + quoi)


func _table() -> Dictionary:
	var sel := "sel-test"
	return {"v": 1, "sel": sel, "codes": {
		Codes.empreinte("NOEL2026", sel): {"recompense": {"etoiles": 10, "poussiere": 300}, "fin": "2026-12-31"},
		Codes.empreinte("VIEUX", sel): {"recompense": {"etoiles": 1}, "fin": "2026-01-01"},
		Codes.empreinte("PIERRES", sel): {"recompense": {"pierres": {"lune": 2, "feu": 1, "inconnue": 5}, "pieces": 40, "eclats": 50}, "fin": ""},
	}}


func _empreinte() -> void:
	_ok("la même empreinte qu'en Python", Codes.empreinte("noel-2026", "sel-test") == "ffc1a6d79b7d173ca399442815127d0fb9b867066870b7ba6e6006f8f0dc1805")
	_ok("normaliser : « noel-2026 » → NOEL2026", Codes.normaliser("noel-2026") == "NOEL2026")
	_ok("normaliser : «  Bien venue! » → BIENVENUE", Codes.normaliser("  Bien venue! ") == "BIENVENUE")


func _verifier() -> void:
	GS.voyage = {}
	var t := _table()
	_ok("un code inconnu : refusé", Codes.verifier(t, "FAUX1234", "2026-09-29")["raison"] == "inconnu")
	_ok("un code expiré : refusé", Codes.verifier(t, "vieux", "2026-09-29")["raison"] == "expire")
	_ok("trop court : refusé", Codes.verifier(t, "ab", "2026-09-29")["raison"] == "vide")
	_ok("une table abîmée : refusée", Codes.verifier({"codes": "x"}, "NOEL2026", "2026-09-29")["raison"] == "table")
	var v := Codes.verifier(t, "Noel 2026", "2026-09-29")
	_ok("un bon code, écrit autrement : accepté", bool(v["ok"]) and int(v["recompense"]["etoiles"]) == 10)
	_ok("le dernier jour compte encore", bool(Codes.verifier(t, "NOEL2026", "2026-12-31")["ok"]))
	_ok("le lendemain : expiré", Codes.verifier(t, "NOEL2026", "2027-01-01")["raison"] == "expire")


func _encaisser() -> void:
	GS.voyage = {}
	GS.etoiles = 2
	GS.poussiere = 0
	GS.main_pieces = 5
	GS.eclats = 0
	GS.pierres = {}
	var t := _table()
	var d := Codes.encaisser(Codes.verifier(t, "NOEL2026", "2026-09-29"))
	_ok("encaissé : +10 étoiles, +300 poussières (%s)" % Codes.phrase(d), GS.etoiles == 12 and GS.poussiere == 300)
	_ok("la seconde fois : « déjà »", Codes.verifier(t, "NOEL2026", "2026-09-29")["raison"] == "deja")
	_ok("encaisser deux fois ne donne rien", Codes.encaisser({"ok": true, "h": Codes.utilises()[0], "recompense": {"etoiles": 10}}).is_empty()
		and GS.etoiles == 12)
	d = Codes.encaisser(Codes.verifier(t, "pierres", "2026-09-29"))
	_ok("les pierres (une inconnue ignorée), les pièces, les éclats (%s)" % Codes.phrase(d), int(GS.pierres.get("lune", 0)) == 2
		and int(GS.pierres.get("feu", 0)) == 1 and not GS.pierres.has("inconnue") and GS.main_pieces == 45 and GS.eclats == 50)
	var texte := JSON.stringify(GS.donnees_sauvegarde())
	GS.voyage = {}
	GS.lire_sauvegarde(JSON.parse_string(texte), false)
	_ok("la sauvegarde garde les codes pris", Codes.verifier(t, "NOEL2026", "2026-09-29")["raison"] == "deja")
	GS.lire_sauvegarde({"v": 4, "voyage": {}}, false)
	_ok("une vieille partie : aucun code pris", bool(Codes.verifier(t, "NOEL2026", "2026-09-29")["ok"]))


func _reglages() -> void:
	Reglages.musique = 0.5
	Reglages.effets = 0.0
	Reglages.vibrations = false
	Reglages.appliquer()
	var im := AudioServer.get_bus_index("Musique")
	var ie := AudioServer.get_bus_index("Effets")
	_ok("les deux bus existent", im >= 0 and ie >= 0)
	_ok("la musique à 50 % : −6 dB", absf(AudioServer.get_bus_volume_db(im) - linear_to_db(0.5)) < 0.01 and not AudioServer.is_bus_mute(im))
	_ok("les effets à zéro : muets", AudioServer.is_bus_mute(ie))
	Reglages.appliquer()
	_ok("appliquer deux fois ne double pas les bus", AudioServer.bus_count == 3)
